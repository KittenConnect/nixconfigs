{ lib
, buildPythonPackage
, fetchPypi
}:

buildPythonPackage rec {
  pname = "favicons";
  version = "0.2.2";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "";
  };

  doCheck = false;
}