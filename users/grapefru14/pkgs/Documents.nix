# These are programs that shall reside in the Documents folder
{ pkgs ? import <nixpkgs> {} }:

let
  mkscript = name: script: ''
    if [ ! -d "$HOME/Documents/${name}" ]; then
      echo "Does not exist, cloning..."
      git clone "https://github.com/Tsunami014/${name}" "$HOME/Documents/${name}"
    fi

    chmod +x "$HOME/Documents/${name}/${script}"
    exec "$HOME/Documents/${name}/${script}" "$@"
  '';
in

pkgs.symlinkJoin {
  name = "document-scripts";

  paths = [
    (pkgs.writeShellApplication {
      name = "studyrng";

      runtimeInputs = with pkgs; [
        python3
      ];

      text = (mkscript "studyRng" "main.py");
    })
  ];
}
