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
  myZenVersion = "1.0.0-a.39";
  x86_64-darwin-hash = "1d5362lymvsq78q5l32ya3ab0fw90pik91fpy447hlr6d4j7ppqr";
  aarch64-darwin-hash = "1c3w0s85vp08vwwfl6z2iqnmcp3jl6ifjzqs96rzlbvjxy9p2qwy";
  x86_64-linux-hash = "1vwccsnhgnrpvw25y3n79ai0mpb9y3x75z31251bwim9ibm1n1i0";
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
      url = "https://github.com/zen-browser/desktop/releases/download/${myZenVersion}/zen.linux-specific.tar.bz2";
      sha256 = x86_64-linux-hash;
    };
    aarch64-linux = fetchurl {
      url = "https://github.com/zen-browser/desktop/releases/download/${myZenVersion}/zen.linux-specific.tar.bz2";
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
    addAutoPatchelfSearchPath $out
  '';

  nativeBuildInputs = lib.optionals stdenv.isLinux [ autoPatchelfHook stdenv.cc.cc.lib pango gtk3 glibc alsa-lib ];
  buildInputs = [ makeWrapper ] ++ lib.optionals stdenv.isDarwin [ undmg ];

  buildPhase = lib.optionalString stdenv.isDarwin ''
    undmg ${finalAttrs.src}
    mkdir -p $out/bin
    cp -r "Zen Browser.app" $out
    makeWrapper "$out/Zen Browser.app/Contents/MacOS/zen" "$out/bin/zen"
  '';
})
