{ pkgs ? import <nixpkgs> {} }:

pkgs.writeShellApplication {
  name = "profile";

  runtimeInputs = with pkgs; [
    python3
    python3Packages.snakeviz
  ];

  text = ''
    if [ $# -eq 0 ]; then
        echo "Usage: profile <script.py> <args>"
        exit 1
    fi

    python -m cProfile -o /tmp/temp.dat "$@" || ret=$?
    trap - INT

    if [ "$ret" -eq 130 ]; then
        echo "Python Process terminated!"
    fi

    if [ -f /tmp/temp.dat ]; then
        snakeviz /tmp/temp.dat
    else
        echo "Profile data missing!"
    fi

    echo "Finished!"
  '';
}
