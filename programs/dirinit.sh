#!/usr/bin/env bash

templOpts="Template options:
- blank (default) - blank
- nix - a tutorial on how to use nix
- py - setup python with nix
- pyadv - setup python advanced with nix (for packages that aren't avaliable on nix)
- pyvenv - setup python using a virtual environment
- cmake - setup cmake
"

case "${1-}" in
    --help | -h | help)
        echo "dirinit [template] [--force] [--show]
Will make a .envrc file with a template (if not provided will be blank)
Even if already exists, this tool can help by adding git ignores and stuff
A .envrc file is a bash file sourced when inside this directory.

Options:
--force - recreate the .envrc even if it already exists
--show - print the template that would have been used and exit

$templOpts" ;;
esac

if [ ! "${2-}" == "--force" ] && [ ! "${2-}" == "--show" ] && [ -f .envrc ]; then
    echo ".envrc file already exists!"
else
    case "${1-}" in
        py)
            tmplNam="python"
            tmpl=$(cat <<'EOF'
use nix \
  -p python313 \
  -p python313Packages.debugpy
EOF
);;
        pyadv)
            tmplNam="python advanced"
            tmpl=$(cat <<'EOF'
use nix \
  -p python313 \
  -p python313Packages.pip \
  -p python313Packages.setuptools \
  -p python313Packages.wheel

export _LOCAL_PY_PKGS="${PWD}/.pypkgs"
export PYTHONPATH="${_LOCAL_PY_PKGS}:${PYTHONPATH}"

mkdir -p "${_LOCAL_PY_PKGS}"
if [ ! -f "${_LOCAL_PY_PKGS}/.gitignore" ]; then
  echo "*" > "${_LOCAL_PY_PKGS}/.gitignore"
fi

python -m pip install --target "${_LOCAL_PY_PKGS}" stubgen-pyx
EOF
);;
        pyvenv)
            tmplNam="python with virtual environment"
            tmpl=$(cat <<'EOF'
use nix \
  -p python313 \
  -p python313Packages.pip \
  -p python313Packages.setuptools \
  -p python313Packages.wheel

export venvFold=".venv"
if [[ ! -d "$venvFold" ]]; then
  echo "Venv does not exist, creating..."
  python3 -m venv "$venvFold"
  echo "*" > "$venvFold/.gitignore"
fi
# pip install something
echo "Loading python config..."
source "$venvFold/bin/activate"
EOF
);;
        cmake)
            tmplNam="cmake"
            tmpl=$(cat <<'EOF'
use nix -p cmake \
    -p clang-tools -p vscode-extensions.vadimcn.vscode-lldb # \
    #-p qt6.qtbase -p qt6.qtbase.dev \
    #-p qt6.qtwayland -p qt6.wrapQtAppsHook

lldb_pth=$(nix eval --raw nixpkgs#vscode-extensions.vadimcn.vscode-lldb)/share/vscode/extensions/vadimcn.vscode-lldb/adapter
export PATH="$lldb_pth:$PATH"
EOF
);;
        nix)
            tmplNam="nix tutorial"
            tmpl=$(cat <<'EOF'
# use nix -p packagename -p anotherPackage.Name
# use nix -p athird.package \
#     -p fourthPkg
EOF
);;
        blank | "") tmplNam="blank"; tmpl="" ;;
        *)
            echo "Unknown template '${1-}'!"
            echo "$templOpts"
            exit 1
        ;;
    esac
    if [ "${2-}" == "--show" ]; then
        echo "$tmplNam"
        echo "$tmpl"
        exit 0
    fi
    echo "Generating new .envrc file with template '$tmplNam'.."
    rm -f .envrc
    echo "$tmpl" > .envrc
fi

if [ -d .git ]; then
    echo "Excluding from git..."
    git rm --cached .envrc 2>/dev/null && echo "Removed from git tracking" || echo "Not being tracked!"
    if cat .git/info/exclude | grep -q .envrc; then
        echo "Already in git excludes!"
    else
        echo ".envrc" >> .git/info/exclude
        echo "Added to git excludes!"
    fi
else
    echo "Cannot add to git excludes, .git folder does not exist!"
fi
mkdir -p .direnv
if [ -d .direnv ] && [ ! -f .direnv/.gitignore ]; then
    echo "Adding a .gitignore for .direnv folder..."
    echo "*" > .direnv/.gitignore
fi

# Everything must be done before here, I think something something exits early
echo "Allowing config..."
direnv allow .
echo "Done!"
