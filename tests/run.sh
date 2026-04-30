#!/usr/bin/env bash
# Run the noethervim-tex test suite via plenary.busted.
set -euo pipefail

cd "$(dirname "$0")/.."

nvim --headless \
  -u tests/minimal_init.lua \
  -c "PlenaryBustedDirectory tests/ { minimal_init = 'tests/minimal_init.lua' }"
