{
  lib,
  buildGo122Module,
  fetchFromGitHub,
}:
buildGo122Module rec {
  pname = "tc4400_exporter";
  version = "0.0.1";

  src = fetchFromGitHub {
    owner = "mikeodr";
    repo = "tc4400_exporter";
    rev = "daa0eacf062abf3acf9ad8ea40142b28029b3a35";
    hash = "sha256-ElVYw5gCIMHJsQjdKT5NBDmMODj3WR424ZTKupAa0x4=";
  };

  vendorHash = "sha256-IQS5DE1/r+qPTg4qxuU9LcGPJpJLe6cdL9tgPHk6MHE";

  meta = with lib; {
    description = "Prometheus exporter for the Technicolor TC4400 DOCSIS 3.1 cable modem";
    homepage = "https://github.com/mikeodr/tc4400_exporter";
    license = lib.licenses.asl20;
    maintainers = with maintainers; [mikeodr];
  };
}
