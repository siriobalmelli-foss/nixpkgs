{ stdenv, lib, fetchgit, flex, bison, pkg-config, which
, pythonSupport ? true, python, swig, libyaml
}:

stdenv.mkDerivation rec {
  pname = "dtc";
  version = "1.5.1";

  src = fetchgit {
    url = "https://git.kernel.org/pub/scm/utils/dtc/dtc.git";
    rev = "refs/tags/v${version}";
    sha256 = "1jhhfrg22h53lvm2lqhd66pyk20pil08ry03wcwyx1c3ln27k73z";
  };

  buildInputs = [ libyaml ];
  nativeBuildInputs = [ flex bison pkg-config which ] ++ lib.optionals pythonSupport [ python swig ];

  postPatch = ''
    patchShebangs pylibfdt/
  '';

  makeFlags = [ "PYTHON=python" ];
  installFlags = [ "INSTALL=install" "PREFIX=$(out)" "SETUP_PREFIX=$(out)" ];

  doCheck = true;

  meta = with lib; {
    description = "Device Tree Compiler";
    homepage = "https://git.kernel.org/cgit/utils/dtc/dtc.git";
    license = licenses.gpl2Plus; # dtc itself is GPLv2, libfdt is dual GPL/BSD
    maintainers = [ maintainers.dezgeg ];
    platforms = platforms.unix;
  };
}
