{
  stdenv,
  fetchFromGitHub,
  kernel,
}:
stdenv.mkDerivation rec {
  name = "i915-sriov-dkms-${version}";
  version = "2026.09.16";
  src = fetchFromGitHub {
    owner = "strongtz";
    repo = "i915-sriov-dkms";
    rev = "b42c0f87643c07e06b4f53bbedfb3b728da222e1";
    hash = "sha256-MJDR3r/OeCo0Uc4yrk7G2jlzVy5p7JMsJh7E2j74hJw=";
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
