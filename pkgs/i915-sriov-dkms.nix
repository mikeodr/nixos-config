{
  stdenv,
  fetchFromGitHub,
  kernel,
}:
stdenv.mkDerivation rec {
  name = "i915-sriov-dkms-${version}";
  version = "2026.08.12.1";
  src = fetchFromGitHub {
    owner = "strongtz";
    repo = "i915-sriov-dkms";
    rev = "d52b7023ce6eefc8c7128cdc7ea931a056703c1c";
    hash = "sha256-pSah4/69DUCizibWlRJr7iXZIWg2y7hMs2fqWE3hsdk=";
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
