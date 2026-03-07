# ipset-firewall.nix
#
# A NixOS module for ASN/CIDR-based ingress filtering using ipset + iptables/ip6tables.
# Dual-stack: maintains paired _v4 (hash:net inet) and _v6 (hash:net inet6) sets
# for every named allowedSet, with mirrored iptables + ip6tables rules.
#
# Usage — in any system's configuration.nix (or flake):
#
#   imports = [ ./ipset-firewall.nix ];
#
#   services.ipsetFirewall = {
#     enable = true;
#     allowedSets = {
#       can_ips = {
#         asns          = [ "AS812" "AS577" "AS852" ];
#         cidrs         = [ "203.0.113.0/24" "2001:db8::/32" ];
#         uptimerobotIps = true;   # also allow UptimeRobot probe IPs on ports 80/443
#       };
#       office = {
#         cidrs         = [ "198.51.100.0/28" "2001:db8:1::/48" ];
#         restrictPorts = [ 22 ];
#       };
#     };
#     defaultDrop     = true;
#     refreshInterval = "Mon *-*-* 03:00:00";
#   };
{
  config,
  lib,
  pkgs,
  ...
}:
with lib; let
  cfg = config.services.ipsetFirewall;

  # UptimeRobot publishes a combined IPv4+IPv6 plain-text list: one bare IP per
  # line, no CIDR suffix (e.g. "69.162.124.227", "2a01:4f8:c17:b8f::2").
  # ipset hash:net accepts bare IPs (treats them as /32 or /128 implicitly).
  # We split the list by family the same way we split static CIDRs.
  uptimerobotUrl = "https://cdn.uptimerobot.com/api/IPv4andIPv6.txt";

  # ---------------------------------------------------------------------------
  # Fetch prefixes for a single ASN from the RIPE API.
  # $2 = "v4" → IPv4 only; "v6" → IPv6 only.
  # ---------------------------------------------------------------------------
  fetchAsnScript = pkgs.writeShellScript "ipset-fetch-asn" ''
    set -euo pipefail
    ASN="$1"
    FAMILY="$2"
    echo "  Fetching $ASN ($FAMILY) from RIPE..." >&2

    PREFIXES=$(${pkgs.curl}/bin/curl -sf --max-time 30 \
      "https://stat.ripe.net/data/announced-prefixes/data.json?resource=$ASN" \
      | ${pkgs.jq}/bin/jq -r '.data.prefixes[].prefix') \
      || { echo "  WARNING: failed to fetch $ASN" >&2; exit 0; }

    if [ "$FAMILY" = "v4" ]; then
      echo "$PREFIXES" | grep -E '^[0-9]' || true
    else
      echo "$PREFIXES" | grep ':' || true
    fi
  '';

  # ---------------------------------------------------------------------------
  # Fetch UptimeRobot probe IPs and write them split by family into two files.
  # $1 = output path for v4 IPs; $2 = output path for v6 IPs.
  # ---------------------------------------------------------------------------
  fetchUptimerobotScript = pkgs.writeShellScript "ipset-fetch-uptimerobot" ''
    set -euo pipefail
    V4_OUT="$1"
    V6_OUT="$2"
    echo "  Fetching UptimeRobot probe IPs..." >&2

    ALL=$(${pkgs.curl}/bin/curl -sf --max-time 30 "${uptimerobotUrl}") \
      || { echo "  WARNING: failed to fetch UptimeRobot IP list" >&2; exit 0; }

    # IPv4: starts with a digit; IPv6: contains a colon
    echo "$ALL" | grep -E '^[0-9]'  >> "$V4_OUT" || true
    echo "$ALL" | grep ':'           >> "$V6_OUT" || true

    V4_COUNT=$(echo "$ALL" | grep -cE '^[0-9]' || true)
    V6_COUNT=$(echo "$ALL" | grep -c ':'        || true)
    echo "  UptimeRobot: $V4_COUNT v4 IPs, $V6_COUNT v6 IPs" >&2
  '';

  # ---------------------------------------------------------------------------
  # Main load/refresh script.
  # Each named set produces: <n>_v4 (inet) and <n>_v6 (inet6).
  # Sources per set: static cidrs + ASN RIPE lookups + optional UptimeRobot list.
  # ---------------------------------------------------------------------------
  loadScript = pkgs.writeShellScript "ipset-firewall-load" ''
    set -euo pipefail
    STATE_DIR="${cfg.stateDir}"
    mkdir -p "$STATE_DIR"
    IPSET="${pkgs.ipset}/bin/ipset"

    ${concatStringsSep "\n\n" (mapAttrsToList (name: set: ''
        echo "==> Building sets: ${name}_v4 / ${name}_v6" >&2

        V4_FILE="$STATE_DIR/${name}_v4.cidrs"
        V6_FILE="$STATE_DIR/${name}_v6.cidrs"
        : > "$V4_FILE"
        : > "$V6_FILE"

        # --- Split static CIDRs by family ---
        ${concatMapStringsSep "\n" (
            cidr:
              if hasInfix ":" cidr
              then ''echo "${cidr}" >> "$V6_FILE"''
              else ''echo "${cidr}" >> "$V4_FILE"''
          )
          set.cidrs}

        # --- Fetch dynamic ASN prefixes (RIPE API) ---
        ${concatMapStringsSep "\n" (asn: ''
            ${fetchAsnScript} "${asn}" v4 >> "$V4_FILE"
            ${fetchAsnScript} "${asn}" v6 >> "$V6_FILE"
          '')
          set.asns}

        # --- Optionally fetch UptimeRobot probe IPs ---
        ${optionalString set.uptimerobotIps ''
          ${fetchUptimerobotScript} "$V4_FILE" "$V6_FILE"
        ''}

        # --- Deduplicate and strip blanks/comments ---
        for F in "$V4_FILE" "$V6_FILE"; do
          grep -v -e '^[[:space:]]*$' -e '^#' "$F" \
            | sort -u > "$F.tmp" && mv "$F.tmp" "$F"
        done

        V4_COUNT=$(wc -l < "$V4_FILE")
        V6_COUNT=$(wc -l < "$V6_FILE")
        echo "  ${name}_v4: $V4_COUNT entries  |  ${name}_v6: $V6_COUNT entries" >&2

        # --- Create live sets if they don't exist yet ---
        $IPSET create -exist "${name}_v4"     hash:net family inet  comment
        $IPSET create -exist "${name}_v6"     hash:net family inet6 comment
        $IPSET create -exist "${name}_v4_tmp" hash:net family inet  comment
        $IPSET create -exist "${name}_v6_tmp" hash:net family inet6 comment

        # --- Populate tmp sets ---
        $IPSET flush "${name}_v4_tmp"
        while IFS= read -r entry; do
          $IPSET add "${name}_v4_tmp" "$entry" 2>/dev/null || \
            echo "  WARN: skipping bad v4 entry: $entry" >&2
        done < "$V4_FILE"

        $IPSET flush "${name}_v6_tmp"
        while IFS= read -r entry; do
          $IPSET add "${name}_v6_tmp" "$entry" 2>/dev/null || \
            echo "  WARN: skipping bad v6 entry: $entry" >&2
        done < "$V6_FILE"

        # --- Atomic swap ---
        $IPSET swap "${name}_v4_tmp" "${name}_v4"
        $IPSET swap "${name}_v6_tmp" "${name}_v6"
        $IPSET destroy "${name}_v4_tmp"
        $IPSET destroy "${name}_v6_tmp"
        echo "  Swapped ${name}_v4 and ${name}_v6 successfully." >&2
      '')
      cfg.allowedSets)}

    # --- Persist for restore-on-boot ---
    ${pkgs.ipset}/bin/ipset save > "$STATE_DIR/ipset.conf"
    echo "==> ipset state saved to $STATE_DIR/ipset.conf" >&2
  '';

  # ---------------------------------------------------------------------------
  # Restore script — runs before the firewall on every boot.
  # ---------------------------------------------------------------------------
  restoreScript = pkgs.writeShellScript "ipset-firewall-restore" ''
    set -euo pipefail
    CONF="${cfg.stateDir}/ipset.conf"
    if [ -f "$CONF" ]; then
      echo "Restoring ipset state from $CONF" >&2
      ${pkgs.ipset}/bin/ipset restore -f "$CONF" || \
        echo "WARNING: ipset restore failed, sets will be empty until next refresh" >&2
    else
      echo "No saved ipset state found; creating empty sets" >&2
      ${concatStringsSep "\n" (mapAttrsToList (name: _: ''
        ${pkgs.ipset}/bin/ipset create -exist "${name}_v4" hash:net family inet  comment
        ${pkgs.ipset}/bin/ipset create -exist "${name}_v6" hash:net family inet6 comment
      '')
      cfg.allowedSets)}
    fi
  '';

  # ---------------------------------------------------------------------------
  # ASN sets → ports 80/443; static CIDR-only sets → restrictPorts.
  # ---------------------------------------------------------------------------
  effectivePorts = _name: set:
    if set.asns != []
    then [80 443]
    else set.restrictPorts;

  # ---------------------------------------------------------------------------
  # Dual-stack firewall rules: mirrored iptables (v4) + ip6tables (v6).
  # ---------------------------------------------------------------------------
  firewallRules = concatStringsSep "\n" (mapAttrsToList (
      name: set: let
        ports = effectivePorts name set;

        mkPortRules = ipt: suffix:
          concatMapStringsSep "\n" (port: ''
            ${ipt} -A nixos-fw -p tcp --dport ${toString port} \
              -m set --match-set ${name}_${suffix} src -j nixos-fw-accept
            ${optionalString cfg.defaultDrop ''
              ${ipt} -A nixos-fw -p tcp --dport ${toString port} -j DROP
            ''}
          '')
          ports;

        mkAllPortsRule = ipt: suffix:
          optionalString set.allowAllPorts ''
            ${ipt} -A nixos-fw -m set --match-set ${name}_${suffix} src -j nixos-fw-accept
          '';
      in ''
        # --- Safety net: ensure sets exist before referencing them ---
        ${pkgs.ipset}/bin/ipset create -exist ${name}_v4 hash:net family inet  comment
        ${pkgs.ipset}/bin/ipset create -exist ${name}_v6 hash:net family inet6 comment

        # --- IPv4 rules ---
        ${mkPortRules "iptables" "v4"}
        ${mkAllPortsRule "iptables" "v4"}

        # --- IPv6 rules ---
        ${mkPortRules "ip6tables" "v6"}
        ${mkAllPortsRule "ip6tables" "v6"}
      ''
    )
    cfg.allowedSets);

  # ---------------------------------------------------------------------------
  # Teardown rules for extraStopCommands.
  # ---------------------------------------------------------------------------
  stopRules = concatStringsSep "\n" (mapAttrsToList (
      name: set: let
        ports = effectivePorts name set;

        mkDelPortRules = ipt: suffix:
          concatMapStringsSep "\n" (port: ''
            ${ipt} -D nixos-fw -p tcp --dport ${toString port} \
              -m set --match-set ${name}_${suffix} src -j nixos-fw-accept 2>/dev/null || true
            ${optionalString cfg.defaultDrop ''
              ${ipt} -D nixos-fw -p tcp --dport ${toString port} -j DROP 2>/dev/null || true
            ''}
          '')
          ports;

        mkDelAllPortsRule = ipt: suffix:
          optionalString set.allowAllPorts ''
            ${ipt} -D nixos-fw -m set --match-set ${name}_${suffix} src -j nixos-fw-accept 2>/dev/null || true
          '';
      in ''
        ${mkDelPortRules "iptables" "v4"}
        ${mkDelAllPortsRule "iptables" "v4"}
        ${mkDelPortRules "ip6tables" "v6"}
        ${mkDelAllPortsRule "ip6tables" "v6"}
      ''
    )
    cfg.allowedSets);
in {
  # ===========================================================================
  # Options
  # ===========================================================================
  options.services.ipsetFirewall = {
    enable = mkEnableOption "ipset-based ASN/CIDR firewall (dual-stack)";

    allowedSets = mkOption {
      default = {};
      description = ''
        Attribute set of named ipsets. Each entry produces two kernel sets:
        <n>_v4 (inet) and <n>_v6 (inet6), with mirrored iptables and
        ip6tables rules. Static CIDRs are automatically routed to the correct
        family based on whether they contain a colon.
      '';
      type = types.attrsOf (types.submodule {
        options = {
          cidrs = mkOption {
            type = types.listOf types.str;
            default = [];
            example = ["203.0.113.0/24" "2001:db8::/32"];
            description = ''
              Static CIDR blocks to permanently include. IPv4 and IPv6 CIDRs
              can be mixed — they are automatically split into the correct
              family sets.
            '';
          };

          asns = mkOption {
            type = types.listOf types.str;
            default = [];
            example = ["AS812" "AS577" "AS852"];
            description = ''
              ASNs whose announced prefixes will be fetched from the RIPE API
              for both IPv4 and IPv6. Sets with ASNs are automatically
              restricted to ports 80 and 443.
            '';
          };

          uptimerobotIps = mkOption {
            type = types.bool;
            default = false;
            description = ''
              When true, fetch UptimeRobot's current probe IP list from
              ${uptimerobotUrl} and merge it into this set.

              UptimeRobot publishes a plain-text file of bare IPs (one per
              line, no CIDR suffix) covering all their global monitoring
              probes. Both IPv4 and IPv6 entries are included and
              automatically routed to the correct family set.

              Enable this on whichever set covers your web ports (80/443) to
              ensure UptimeRobot health checks are never blocked by the
              defaultDrop rules.
            '';
          };

          restrictPorts = mkOption {
            type = types.listOf types.port;
            default = [];
            example = [22 8006];
            description = ''
              TCP ports to restrict for static CIDR-only sets (no asns).
              Ignored when asns is non-empty — ASN sets always use 80/443.
            '';
          };

          allowAllPorts = mkOption {
            type = types.bool;
            default = false;
            description = ''
              Unconditionally accept all traffic from sources in this set on
              all ports. Applies to both IPv4 and IPv6.
            '';
          };
        };
      });
    };

    defaultDrop = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Append DROP rules for restricted ports in both iptables and ip6tables.
        Traffic from addresses not in any matching set will be silently dropped.
      '';
    };

    refreshOnBoot = mkOption {
      type = types.bool;
      default = true;
      description = "Fetch fresh ASN prefixes and UptimeRobot IPs at boot (requires internet).";
    };

    refreshInterval = mkOption {
      type = types.nullOr types.str;
      default = "Mon *-*-* 03:00:00";
      example = "daily";
      description = ''
        Systemd OnCalendar expression for periodic CIDR/IP refresh.
        Set to null to disable the timer entirely.
      '';
    };

    stateDir = mkOption {
      type = types.str;
      default = "/var/lib/ipset-firewall";
      description = "Directory for persisted CIDR lists and ipset save state.";
    };
  };

  # ===========================================================================
  # Implementation
  # ===========================================================================
  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.allowedSets != {};
        message = "services.ipsetFirewall.allowedSets must not be empty.";
      }
    ];

    environment.systemPackages = with pkgs; [ipset curl jq];

    # -------------------------------------------------------------------------
    # 1. Restore saved state BEFORE the firewall starts.
    # -------------------------------------------------------------------------
    systemd.services.ipset-firewall-restore = {
      description = "Restore ipset state before firewall (dual-stack)";
      before = ["firewall.service"];
      wantedBy = ["multi-user.target"];
      after = ["local-fs.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = restoreScript;
      };
    };

    # -------------------------------------------------------------------------
    # 2. Load/refresh service — fetches ASN + UptimeRobot data, atomic reload.
    # -------------------------------------------------------------------------
    systemd.services.ipset-firewall-load = {
      description = "Load/refresh ipset CIDR sets from ASN + UptimeRobot data";
      after = ["network-online.target" "ipset-firewall-restore.service"];
      wants = ["network-online.target"];
      wantedBy = mkIf cfg.refreshOnBoot ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = loadScript;
        StateDirectory = baseNameOf cfg.stateDir;
      };
    };

    # -------------------------------------------------------------------------
    # 3. Optional periodic refresh timer.
    # -------------------------------------------------------------------------
    systemd.timers.ipset-firewall-load = mkIf (cfg.refreshInterval != null) {
      description = "Periodic refresh of ipset sets (ASN + UptimeRobot)";
      wantedBy = ["timers.target"];
      timerConfig = {
        OnCalendar = cfg.refreshInterval;
        Persistent = true;
      };
    };

    # -------------------------------------------------------------------------
    # 4. Inject dual-stack iptables + ip6tables rules into the NixOS firewall.
    # -------------------------------------------------------------------------
    networking.firewall.extraCommands = firewallRules;
    networking.firewall.extraStopCommands = stopRules;
  };
}
