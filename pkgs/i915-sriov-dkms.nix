{
  stdenv,
  fetchFromGitHub,
  kernel,
}:
stdenv.mkDerivation rec {
  name = "i915-sriov-dkms-${version}";
  version = "2025.12.10.1";
  src = fetchFromGitHub {
    owner = "strongtz";
    repo = "i915-sriov-dkms";
    rev = "d20c39b0c59ef9811042e7100b2e78f93869225c";
    hash = "sha256-kLbtslvJ77tvjYYxIPpSJIUM3gsL/RTesBV5WPOjqyY=";
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
