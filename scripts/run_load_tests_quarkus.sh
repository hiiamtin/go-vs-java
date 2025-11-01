#!/usr/bin/env bash
set -euo pipefail
export QUARKUS_IMAGE="${QUARKUS_IMAGE:-poc-quarkus-native}"
"$(dirname "$0")/run_load_tests_for_app.sh" quarkus "$@"
