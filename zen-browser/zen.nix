{
  pkgs,
  lib,
  stdenv,
  fetchurl,
  undmg,
  makeWrapper,
  autoPatchelfHook,
  pango,
  gtk3,
  glibc,
  alsa-lib,
}:

let
  myZenVersion = "1.0.1-a.4";
  x86_64-darwin-hash = "02ybjby2hs76vbckhjk8r92i86w953f5nbx51vqyp47fhcb9q4ik";
  aarch64-darwin-hash = "09c9ah3x46il23pf2kc9azc7j26jvb37djn5x6b173i3mdkvlx33";
  x86_64-linux-hash = "1d85h80zad3l7cra5vjjxihr1vhg8h6jq6vf4888ms0n7ds1v33q";
  sources = {
    x86_64-darwin = fetchurl {
      url = "https://github.com/zen-browser/desktop/releases/download/${myZenVersion}/zen.macos-x64.dmg";
      sha256 = x86_64-darwin-hash;
    };
    aarch64-darwin = fetchurl {
      url = "https://github.com/zen-browser/desktop/releases/download/${myZenVersion}/zen.macos-aarch64.dmg";
      sha256 = aarch64-darwin-hash;
    };
    x86_64-linux = fetchurl {
      url = "https://github.com/zen-browser/desktop/releases/download/${myZenVersion}/zen.linux-generic.tar.bz2";
      sha256 = x86_64-linux-hash;
    };
  };
in stdenv.mkDerivation (finalAttrs: {
  pname = "zen-browser";
  version = "${myZenVersion}";

  src = sources.${stdenv.hostPlatform.system} or (throw "unsupported system: ${stdenv.hostPlatform.system}");

  dontUnpack = stdenv.isDarwin;
  unpackPhase = ''
    mkdir -p $out
    tar xjvf ${finalAttrs.src} -C $out
  '';

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook stdenv.cc.cc.lib pango gtk3 glibc alsa-lib ];
  buildInputs = [ makeWrapper ] ++ lib.optionals stdenv.isDarwin [ undmg ];

  buildPhase = if stdenv.isDarwin then ''
    undmg ${finalAttrs.src}
    mkdir -p $out/bin
    cp -r "Zen Browser.app" $out
    makeWrapper "$out/Zen Browser.app/Contents/MacOS/zen" "$out/bin/zen"
  '' else ''
    mkdir -p $out/bin
    makeWrapper "$out/zen/zen-bin" "$out/bin/zen"
  '';
})
