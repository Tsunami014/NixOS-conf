{ lib, fetchurl, appimageTools }:
let
  pname = "saleae-logic-2";
  version = "2.4.40";
  src = fetchurl {
    url = "https://downloads2.saleae.com/logic2/Logic-${version}-linux-x64.AppImage";
    sha256 = "sha256-TG7fH8b0L/O8RjlMB3QJM3/8my49uBX2RwufrVWDgpI=";
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  extraPkgs = pkgs: with pkgs; [
    stdenv.cc.cc.lib
    libxcrypt-legacy
    libusb1
  ];

  meta = with lib; {
    homepage = "https://www.saleae.com/";
    description = "Software for Saleae logic analyzers";
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = [ Tsunami014 maintainers.j-hui ];
  };
}
