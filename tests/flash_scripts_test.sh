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

source "$repo_root/flash-common.sh"
find_mount_point() {
    printf '/tmp/NICENANO\n'
}

wait_output=$(wait_for_device "TEST" 2>/dev/null)
[[ "$wait_output" == "/tmp/NICENANO" ]]

source "$repo_root/flash-common.sh"
probe_state=$(mktemp)
probe_log=$(mktemp)
probe_status=$(mktemp)
trap 'rm -f "$event_log" "$probe_state" "$probe_log" "$probe_status"' EXIT
find_mount_point() {
    if [[ ! -s "$probe_state" ]]; then
        printf 'first-attempt\n' >"$probe_state"
        return 1
    fi
    printf '/tmp/NICENANO\n'
}
sleep() {
    printf 'sleep:%s\n' "$1" >>"$probe_log"
}

wait_output=$(wait_for_device "GAUCHE" 2>"$probe_status")
[[ "$wait_output" == "/tmp/NICENANO" ]]
[[ $(<"$probe_log") == "sleep:5" ]]
grep -q "GAUCHE" "$probe_status"

for script in flash.sh reset.sh; do
    [[ -f "$repo_root/$script" ]]
    script_content=$(<"$repo_root/$script")
    [[ "$script_content" == *"flash_pair"* ]]
    [[ "$script_content" != *"select opt"* ]]
    [[ "$script_content" != *"read -p"* ]]
done

echo "flash scripts tests: PASS"
