{ lib
, poetry
, buildPythonPackage
, fetchPypi
, poetry-core
, masonry
, pillow
, reportlab
# , rlpycairo
, svglib
, typer
}:

buildPythonPackage rec {
  pname = "favicons";
  version = "0.2.2";
  format = "pyproject";

  src = fetchPypi {
    inherit pname version;
    hash = "sha256-V3SeazFFtIXZ6ptiOdxnn7wA0JKoc1RcAYwDWXq84ck=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'poetry.masonry.api' 'poetry.core.masonry.api' \
      --replace-fail 'poetry>=0.12' 'poetry-core' \
      --replace-fail 'pillow = "^10.2.0"' 'pillow = ">=10.2.0"' \
      --replace-fail 'rich = "^13.7.0"' 'rich = ">=13.7.0"' \
      --replace-fail 'rlpycairo = "^0.3.0"' ""
  '';

  dependencies = [
       pillow
       reportlab
       # rlpycairo
       svglib
       typer

        #  rich<14.0.0,>=13.7.0 not satisfied by version 14.1.0
  ];

  nativeBuildInputs = [
    poetry-core
    masonry
  ];

  doCheck = false;
}
