#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
keymap="$repo_root/config/Corne.keymap"

function_layer=$(sed -n '/        function_layer {/,/        };/p' "$keymap")

[[ "$function_layer" == *"&kp RA(N1)"* ]]
[[ "$function_layer" == *"&kp RA(N2)"* ]]
[[ "$function_layer" == *"&kp RA(E)"* ]]

echo "function layer symbols test: PASS"
