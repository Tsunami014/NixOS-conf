# These are programs that shall reside in the Documents folder
{ pkgs ? import <nixpkgs> {}, python3Packages }:

let
  _gitscript = name: ''
    if [ ! -d "$HOME/Documents/${name}" ]; then
      echo "Does not exist, cloning..."
      git clone "https://github.com/Tsunami014/${name}" "$HOME/Documents/${name}"
    fi
  '';
  mkscript = name: script: ''
    ${_gitscript name}
    python3 "$HOME/Documents/${name}/${script}" "$@"
  '';
  mkdirscript = name: script: ''
    ${_gitscript name}
    dir="$HOME/Documents/${name}"
    if [ ! -f "$dir/.envrc" ]; then
      cd "$dir"
      dirinit pyadvreq
      cd -
    fi
    direnv exec "$dir" python3 "$dir/${script}" "$@" 2>/dev/null
  '';
in

pkgs.symlinkJoin {
  name = "document-scripts";

  paths = [
    (pkgs.writeShellApplication {
      name = "studyrng";
      runtimeInputs = with pkgs; [python3];
      text = (mkscript "studyRng" "main.py");
    })
  ];
}
