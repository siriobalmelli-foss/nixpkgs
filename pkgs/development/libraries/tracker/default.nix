{ lib, stdenv
, fetchurl
, fetchpatch
, gettext
, meson
, ninja
, pkg-config
, asciidoc
, gobject-introspection
, python3
, gtk-doc
, docbook-xsl-nons
, docbook_xml_dtd_45
, libxml2
, glib
, wrapGAppsNoGuiHook
, vala
, sqlite
, libxslt
, libstemmer
, gnome
, icu
, libuuid
, libsoup
, json-glib
, systemd
, dbus
, substituteAll
}:

stdenv.mkDerivation rec {
  pname = "tracker";
  version = "3.1.1";

  outputs = [ "out" "dev" "devdoc" ];

  src = fetchurl {
    url = "mirror://gnome/sources/${pname}/${lib.versions.majorMinor version}/${pname}-${version}.tar.xz";
    sha256 = "sha256-Q3bi6YRUBm9E96JC5FuZs7/kwDtn+rGauw7Vhsp0iuc=";
  };

  patches = [
    (substituteAll {
      src = ./fix-paths.patch;
      inherit asciidoc;
    })

    # Add missing build target dependencies to fix parallel building of docs.
    # TODO: Upstream this.
    ./fix-docs.patch

    # Fix 32bit datetime issue, use this upstream patch until 3.1.2 lands
    # https://gitlab.gnome.org/GNOME/tracker/-/merge_requests/401
    (fetchpatch {
      url = "https://gitlab.gnome.org/GNOME/tracker/merge_requests/401.patch";
      sha256 = "QEf+ciGkkCzanmtGO0aig6nAxd+NxjvuNi4RbNOwZEA=";
    })
  ];

  nativeBuildInputs = [
    meson
    ninja
    vala
    pkg-config
    asciidoc
    gettext
    libxslt
    wrapGAppsNoGuiHook
    gobject-introspection
    gtk-doc
    docbook-xsl-nons
    docbook_xml_dtd_45
    python3 # for data-generators
    systemd # used for checks to install systemd user service
    dbus # used for checks and pkg-config to install dbus service/s
  ];

  buildInputs = [
    glib
    libxml2
    sqlite
    icu
    libsoup
    libuuid
    json-glib
    libstemmer
  ];

  checkInputs = with python3.pkgs; [
    pygobject3
    tappy
  ];

  mesonFlags = [
    "-Ddocs=true"
  ];

  doCheck = true;

  postPatch = ''
    patchShebangs utils/g-ir-merge/g-ir-merge
    patchShebangs utils/data-generators/cc/generate
    patchShebangs tests/functional-tests/test-runner.sh.in
    patchShebangs tests/functional-tests/*.py
    patchShebangs examples/python/endpoint.py
  '';

  preCheck = ''
    # (tracker-store:6194): Tracker-CRITICAL **: 09:34:07.722: Cannot initialize database: Could not open sqlite3 database:'/homeless-shelter/.cache/tracker/meta.db': unable to open database file
    export HOME=$(mktemp -d)

    # Our gobject-introspection patches make the shared library paths absolute
    # in the GIR files. When running functional tests, the library is not yet installed,
    # though, so we need to replace the absolute path with a local one during build.
    # We are using a symlink that will be overridden during installation.
    mkdir -p $out/lib
    ln -s $PWD/src/libtracker-sparql/libtracker-sparql-3.0.so $out/lib/libtracker-sparql-3.0.so.0
  '';

  checkPhase = ''
    runHook preCheck

    dbus-run-session \
      --config-file=${dbus.daemon}/share/dbus-1/session.conf \
      meson test --print-errorlogs

    runHook postCheck
  '';

  postCheck = ''
    # Clean up out symlinks
    rm -r $out/lib
  '';

  passthru = {
    updateScript = gnome.updateScript {
      packageName = pname;
      versionPolicy = "none";
    };
  };

  meta = with lib; {
    homepage = "https://wiki.gnome.org/Projects/Tracker";
    description = "Desktop-neutral user information store, search tool and indexer";
    maintainers = teams.gnome.members;
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
  };
}
