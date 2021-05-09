{ stdenv
, rustPlatform
, lib
, fetchFromGitHub
, pkg-config
, fontconfig
, python3
, openssl
, perl
, dbus
, libX11
, xcbutil
, libxcb
, xcbutilimage
, xcbutilkeysyms
, xcbutilwm # contains xcb-ewmh among others
, libxkbcommon
, libglvnd # libEGL.so.1
, egl-wayland
, wayland
, libGLU
, libGL
, freetype
, zlib
}:
let
  runtimeDeps = [
    zlib
    fontconfig
    freetype
    libX11
    xcbutil
    libxcb
    xcbutilimage
    xcbutilkeysyms
    xcbutilwm
    libxkbcommon
    dbus
    libglvnd
    egl-wayland
    wayland
    libGLU
    libGL
    openssl
  ];
in

rustPlatform.buildRustPackage rec {
  pname = "wezterm-nightly";
  version = "20210502-nightly";

  src = fetchFromGitHub {
    owner = "wez";
    repo = "wezterm";
    rev = "3f7122cb3f9d2fd92fb836e2f4b2aa7b839b6c86";
    sha256 = "sha256-9HPhb7Vyy5DwBW1xeA6sEIBmmOXlky9lPShu6ZoixPw=";
    fetchSubmodules = true;
  };

  postPatch = ''
    echo ${version} > .tag
  '';

  cargoSha256 = "sha256-vkq/ZnSHMXKNNzlWATPqnwzJGNso0XmH5DDXKiIvPCw=";

  nativeBuildInputs = [
    pkg-config
    python3
    perl
  ];

  buildInputs = runtimeDeps;

  preFixup = lib.optionalString stdenv.isLinux ''
    for artifact in wezterm wezterm-gui wezterm-mux-server strip-ansi-escapes; do
      patchelf --set-rpath "${lib.makeLibraryPath runtimeDeps}" $out/bin/$artifact
    done
  '';

  # prevent further changes to the RPATH
  dontPatchELF = true;

  meta = with lib; {
    description = "A GPU-accelerated cross-platform terminal emulator and multiplexer written by @wez and implemented in Rust";
    homepage = "https://wezfurlong.org/wezterm";
    license = licenses.mit;
    maintainers = with maintainers; [ steveej SuperSandro2000 ];
    platforms = platforms.unix;
  };
}