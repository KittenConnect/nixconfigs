{ lib
, poetry
, buildPythonPackage
, setuptools
, fetchPypi
, cookiecutter
, docopt
, schema
, inquirer
, ruamel-yaml
, gitpython
, clint
, py
}:

buildPythonPackage rec {
  pname = "masonry";
  version = "0.1.2";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-OnZJhzlZNqcVsgf1vpUPdUOOfT2vhd0J0p2qAGVx+vA=";
  };

  postPatch = ''
    substituteInPlace setup.py \
      --replace-fail \
        'repo_root = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))' \
        'repo_root = os.path.dirname(os.path.abspath(__file__))' \
      --replace-fail '"root": ".."' '"root": "."'
  '';

  build-system = [ setuptools ];

  dependencies = [
    cookiecutter
    docopt
    schema
    inquirer
    ruamel-yaml
    gitpython
    clint
    py
  ];

  doCheck = false;
}
