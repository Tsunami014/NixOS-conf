#!/usr/bin/env bash

if [ -f .envrc ]; then
    echo ".envrc file already exists!"
else
    echo ".envrc file does not exist, creating..."
    echo "# A bash file sourced when inside this directory

# For nix packages:
# use nix -p packagename -p anotherPackage.Name
# use nix -p athird.package

# Python starter:
# use nix \
#     -p python313 \
#     -p python313Packages.pip \
#     -p python313Packages.setuptools \
#     -p python313Packages.wheel \
" > .envrc
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
direnv allow .
