#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
source "$repo_root/flash-common.sh"

event_log=$(mktemp)
trap 'rm -f "$event_log"' EXIT

wait_for_device() {
    printf 'wait\n' >>"$event_log"
    printf '/tmp/NICENANO\n'
}

flash_firmware() {
    local side=$1
    local file=$2
    local destination=$3
    printf 'flash:%s:%s:%s\n' "$side" "$file" "$destination" >>"$event_log"
}

flash_pair "left.uf2" "right.uf2" "GAUCHE" "DROIT"
expected=(
    "wait"
    "flash:GAUCHE:left.uf2:/tmp/NICENANO"
    "wait"
    "flash:DROIT:right.uf2:/tmp/NICENANO"
)

[[ $(<"$event_log") == "$(printf '%s\n' "${expected[@]}")" ]]

for script in flash.sh reset.sh; do
    [[ -f "$repo_root/$script" ]]
    script_content=$(<"$repo_root/$script")
    [[ "$script_content" == *"flash_pair"* ]]
    [[ "$script_content" != *"select opt"* ]]
    [[ "$script_content" != *"read -p"* ]]
done

echo "flash scripts tests: PASS"
