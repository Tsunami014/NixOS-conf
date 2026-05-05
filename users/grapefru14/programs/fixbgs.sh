#!/usr/bin/env bash
set -euo pipefail

DIR="${1:-../backgrounds}"

shopt -s nullglob

declare -A files_by_base

normalize_base() {
  local stem="$1"
  local cleaned="$stem"
  local next

  # Strip trailing numbers/brackets until stable
  while :; do
    next="$(
      printf '%s' "$cleaned" | sed -E \
        -e 's/[[:space:]]*[\(\[\{].*$//' \
        -e 's/[[:space:]]*[0-9]+$//' \
        -e 's/[[:space:]]+$//'
    )"

    [[ "$next" == "$cleaned" ]] && break
    cleaned="$next"
  done

  [[ -n "$cleaned" ]] || cleaned="image"
  printf '%s' "$cleaned"
}

# Collect files
while IFS= read -r -d '' path; do
  filename=${path##*/}
  stem=${filename%.*}
  ext=${filename##*.}

  case "${ext,,}" in
    png|jpg|jpeg) ;;
    *) continue ;;
  esac

  base="$(normalize_base "$stem")"

  files_by_base["$base"]+="${path}"$'\n'
done < <(find "$DIR" -maxdepth 1 -type f -print0)

# Process each group (sorted for deterministic output)
for base in "${!files_by_base[@]}"; do

  # Read into array and sort
  mapfile -t srcs < <(printf "%s" "${files_by_base[$base]}" | sed '/^$/d' | sort)

  count=${#srcs[@]}
  width=${#count}

  temps=()
  finals=()

  # Build rename plan
  for i in "${!srcs[@]}"; do
    src="${srcs[$i]}"
    filename=${src##*/}
    ext=${filename##*.}

    num=$(printf "%0*d" "$width" "$i")

    final="$DIR/${base}${num}.${ext}"
    tmp="$DIR/.tmp_$$_${i}_${RANDOM}.${ext}"

    finals+=("$final")
    temps+=("$tmp")
  done

  # Phase 1: move to temp names
  for i in "${!srcs[@]}"; do
    mv -- "${srcs[$i]}" "${temps[$i]}"
  done

  # Phase 2: move to final names
  for i in "${!temps[@]}"; do
    mv -- "${temps[$i]}" "${finals[$i]}"
  done

done
