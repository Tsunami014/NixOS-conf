#!/usr/bin/env bash

case "${1-}" in
    git)
        if [ ! -d .git ]; then
            echo "Cannot add to git excludes, .git folder does not exist!"
            exit 1
        fi
        git rm --cached .envrc 2>/dev/null && echo "Removed from git tracking" || echo "Not being tracked!"
        if cat .git/info/exclude | grep -q .envrc; then
            echo "Already in git excludes!"
            exit 0
        fi
        echo ".envrc" >> .git/info/exclude
        echo "Added to git excludes!"
        direnv allow .
        ;;
    python)
        if [ ! -d .venv ]; then
            echo "Creating python virtual environment..."
            python3 -m venv .venv
        fi
        if [ ! -f .envrc ] || ! cat .envrc | grep -q -P "^(source|.) +\\.venv/bin/activate$"; then
            echo 'source .venv/bin/activate' > .envrc
        else
            echo "Virtual environment is already being sourced from .envrc!"
            exit 1
        fi
        direnv allow .
        ;;
    allow)
        direnv allow .
        ;;
    *)
        echo "Dirtools - for using direnv more efficiently
Usage:
  dirtools git - adds the .envrc file to the git excludes
  dirtools python - makes a python3 virtual environment if it doesn't exist and adds it to the .envrc for automatic loading
  dirtools allow - shorthand for direnv allow .
";;
esac
