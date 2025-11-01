#!/usr/bin/env bash
set -euo pipefail
"$(dirname "$0")/run_load_tests_for_app.sh" spring "$@"
