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
  myZenVersion = "1.0.2-b.3";
  x86_64-darwin-hash = "";
  aarch64-darwin-hash = "16bhh415wjd05gjja173z3ivmqjgxbzwdnpilsgp1dsdgjfwk9r4";
  x86_64-linux-hash = "0zw92hxgf6zs5d9867rdam11h2rp1s5bk7xbqlnzjlkf94in85s1";
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
