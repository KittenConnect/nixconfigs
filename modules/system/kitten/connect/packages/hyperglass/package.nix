{
  pkgs,
  fetchFromGitHub ? pkgs.fetchFromGitHub,
  pythonPackages ? pkgs.python311Packages,
  buildPythonApplication ? pythonPackages.buildPythonApplication,
  # fetchPypi,
  # setuptools,
  # wheel,
  # hatchling,
  # aiofiles,
  # distro,
  # # favicons,
  # httpx,
  # litestar,
  # loguru,
  # netmiko,
  # paramiko,
  # pillow,
  # psutil,
  # py-cpuinfo,
  # pydantic-extra-types,
  # pydantic-settings,
  # pydantic,
  # pyjwt,
  # pyyaml,
  # redis,
  # rich,
  # toml,
  # typer,
  # uvicorn,
  # uvloop,
  # xmltodict,
  ...
}:

buildPythonApplication {

  pname = "hyperglass";

  version = "2.0.5";

  src = ./.;

  # do not run tests

  doCheck = false;

  # specific to buildPythonPackage, see its reference

  pyproject = true;

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail 'distro==1.8.0' 'distro>=1.8.0' \
      --replace-fail 'httpx==0.24.0' 'httpx>=0.24.0' \
      --replace-fail 'netmiko==4.1.2' 'netmiko>=4.1.2' \
      --replace-fail 'paramiko==3.4.0' 'paramiko>=3.4.0' \
      --replace-fail 'psutil==5.9.4' 'psutil>=5.9.4' \
      --replace-fail 'redis==4.5.4' 'redis>=4.5.4' \
      --replace-fail 'uvicorn==0.21.1' 'uvicorn>=0.21.1' \
      --replace-fail 'xmltodict==0.13.0' 'xmltodict>=0.13.0' \
      --replace-fail 'Pillow==10.2.0' 'Pillow>=10.2.0' \
      --replace-fail 'PyJWT==2.6.0' 'PyJWT>=2.6.0'

    sed -i /favicons==/d pyproject.toml

  '';

  build-system = with pythonPackages; [
    setuptools
    wheel
  ];

  makeWrapperArgs = ["--prefix" "PATH" ":" "${pkgs.nodejs}/bin"];

  dependencies = with pythonPackages; [
    hatchling
    aiofiles
    distro
    # favicons
    httpx
    litestar
    loguru
    netmiko
    paramiko
    pillow
    psutil
    py-cpuinfo
    pydantic-extra-types
    pydantic-settings
    pydantic
    pyjwt
    pyyaml
    redis
    rich
    toml
    uvicorn
    uvloop
    xmltodict

    (pythonPackages.overrideScope (final: prev: {
      typer = pkgs.callPackage ./_typer.nix {
        inherit (pkgs) lib stdenv fetchpatch;
          inherit (pythonPackages)
            buildPythonPackage
            click
            colorama
            coverage
            fetchPypi
            flit-core
            pytest-sugar
            pytest-xdist
            pytestCheckHook
            pythonOlder
            rich
            shellingham
            typing-extensions
            ;
      };
      })
    ).typer
  ];
}
