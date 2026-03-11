#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage:
  scripts/pack-love.sh [output.love] [--ref <git-ref>]

Examples:
  scripts/pack-love.sh
  scripts/pack-love.sh dist/noahs-playroom.love
  scripts/pack-love.sh dist/noahs-playroom.love --ref HEAD

Notes:
  - Default mode packages files from the current working tree using Git file listing:
      git ls-files --cached --others --exclude-standard
    This excludes files ignored by .gitignore.
  - --ref mode packages a committed snapshot using git archive.
EOF
}

if ! command -v git >/dev/null 2>&1; then
    echo "Error: git is required." >&2
    exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
    echo "Error: zip is required." >&2
    exit 1
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [[ -z "$repo_root" ]]; then
    echo "Error: run this script inside a git repository." >&2
    exit 1
fi

cd "$repo_root"

repo_name="$(basename "$repo_root")"
output="dist/${repo_name}.love"
ref=""

args=()
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --ref)
            shift
            if [[ $# -eq 0 ]]; then
                echo "Error: --ref requires a git ref (for example: HEAD)." >&2
                exit 1
            fi
            ref="$1"
            ;;
        *)
            args+=("$1")
            ;;
    esac
    shift
done

if [[ ${#args[@]} -gt 1 ]]; then
    echo "Error: too many positional arguments." >&2
    usage
    exit 1
fi

if [[ ${#args[@]} -eq 1 ]]; then
    output="${args[0]}"
fi

if [[ "$output" != *.love ]]; then
    output="${output}.love"
fi

if [[ "$output" = /* ]]; then
    output_abs="$output"
else
    output_abs="$repo_root/$output"
fi

mkdir -p "$(dirname "$output_abs")"
rm -f "$output_abs"

if [[ -n "$ref" ]]; then
    git archive --format=zip --output "$output_abs" "$ref"
else
    tmp_list="$(mktemp)"
    trap 'rm -f "$tmp_list"' EXIT

    git ls-files --cached --others --exclude-standard > "$tmp_list"

    file_count="$(wc -l < "$tmp_list" | tr -d '[:space:]')"
    if [[ "$file_count" -eq 0 ]]; then
        echo "Error: no files selected for packaging." >&2
        exit 1
    fi

    # -X strips extra file attributes for a cleaner, more reproducible archive.
    zip -q -X "$output_abs" -@ < "$tmp_list"
fi

size="$(du -h "$output_abs" | awk '{print $1}')"
echo "Packed: $output_abs"
echo "Size:   $size"
