{
  stdenv,
  fetchFromGitHub,
  kernel,
}:
stdenv.mkDerivation rec {
  name = "i915-sriov-dkms-${version}";
  # Pinned to a commit past the 2026.05.06 tag: fixes build against
  # kernels whose pci_resize_resource() takes 4 args (kernel 6.18.40
  # here already has the new signature that upstream only handled by
  # LINUX_VERSION_CODE >= 6.19 checks). Bump to a tagged release once
  # one is cut that includes this fix.
  version = "unstable-2026-07-28";
  src = fetchFromGitHub {
    owner = "strongtz";
    repo = "i915-sriov-dkms";
    rev = "e3c384c19719afdd8fe480f5e39e2a49763843f6";
    hash = "sha256-pf57l1bxKOSpv930lyXU8ODV3lpDSjp4bM4NUYBtqi8=";
  };
  nativeBuildInputs = kernel.moduleBuildDependencies;
  makeFlags = [
    "-C"
    "${kernel.dev}/lib/modules/${kernel.modDirVersion}/build"
    "M=$(PWD)"
    "modules"
  ];
  installPhase = ''
    find . -name "*.ko" -exec install -Dm644 {} $out/lib/modules/${kernel.modDirVersion}/kernel/drivers/gpu/drm/i915/{} \;
  '';
}
