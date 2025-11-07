#!/usr/bin/env bash

# Automated Phase 3 load test runner.
# Builds on the manual steps previously used to gather metrics for COMPARISON_REPORT.md.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESULTS_DIR="$ROOT_DIR/phase3-results"
LOAD_TEST_DIR="$ROOT_DIR/load-tests"
CONTAINER_NAME="poc-app"
NETWORK_NAME="poc-net"
CPU_LIMIT="1.0"
MEMORY_LIMIT="1g"
PORT_MAPPING="8080:8080"
HEALTH_MAX_ATTEMPTS=120
STATS_INTERVAL=2

APPS=(
  "gin poc-gin http://localhost:8080/health"
  "fiber poc-fiber http://localhost:8080/health"
  "spring poc-spring-jvm http://localhost:8080/health"
  "quarkus poc-quarkus-native http://localhost:8080/health"
)

TESTS=(plaintext json cpu db interaction)

SUMMARY_TREND="avg,min,med,max,p(90),p(95),p(99)"

TOTAL_APPS=${#APPS[@]}
TOTAL_TESTS=${#TESTS[@]}
TOTAL_STEPS=$((TOTAL_APPS * (TOTAL_TESTS + 1)))
CURRENT_STEP=0

utc_now_iso() {
  date -u +"%Y-%m-%dT%H:%M:%SZ"
}

utc_stamp() {
  date -u +"%Y%m%dT%H%M%SZ"
}

ensure_network() {
  if ! docker network ls --format '{{.Name}}' | grep -qx "$NETWORK_NAME"; then
    docker network create "$NETWORK_NAME" >/dev/null
  fi
}

ensure_db() {
  if ! docker ps --format '{{.Names}}' | grep -qx "db"; then
    (cd "$ROOT_DIR" && docker compose up -d db)
  fi
}

cleanup_container() {
  docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
}

wait_for_health() {
  local health_url="$1"
  for attempt in $(seq 1 "$HEALTH_MAX_ATTEMPTS"); do
    if curl -s -f "$health_url" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.5
  done
  echo "ERROR: Service failed health check at $health_url" >&2
  docker logs "$CONTAINER_NAME" || true
  return 1
}

capture_idle_stats() {
  local outfile="$1"
  docker stats "$CONTAINER_NAME" --no-stream >"$outfile"
}

summarize_stream_stats() {
  local raw_file="$1"
  local summary_json="$2"
  local summary_txt="$3"

  if [[ ! -s "$raw_file" ]]; then
    cat >"$summary_json" <<'EOF'
{
  "samples": 0
}
EOF
    cat >"$summary_txt" <<'EOF'
Samples: 0
CPU avg (%): n/a
CPU max (%): n/a
Mem avg (MiB): n/a
Mem max (MiB): n/a
EOF
    return
  fi

  jq -sr '
    def parse_cpu: (.CPUPerc | sub("%";"") | tonumber);
    def parse_mem:
      (try (.MemUsage | capture("^(?<val>[0-9.]+)(?<unit>[A-Za-z]+)")) catch {"val":"0","unit":"B"}) as $m
      | ($m.unit | ascii_upcase) as $unit
      | ($m.val | tonumber)
        * (if $unit == "GIB" or $unit == "GB" then 1024
           elif $unit == "MIB" or $unit == "MB" then 1
           elif $unit == "KIB" or $unit == "KB" then 1/1024
           elif $unit == "B" then 1/(1024*1024)
           else 1 end);
    if length == 0 then
      {samples: 0}
    else
      (map(parse_cpu)) as $cpu
      | (map(parse_mem)) as $mem
      | {
          samples: length,
          cpu_avg: ($cpu | add / length),
          cpu_max: ($cpu | max),
          mem_avg_mib: ($mem | add / length),
          mem_max_mib: ($mem | max)
        }
    end
  ' "$raw_file" >"$summary_json"

  local samples
  samples=$(jq -r '.samples' "$summary_json")

  if [[ "$samples" == "0" || "$samples" == "null" ]]; then
    cat >"$summary_txt" <<'EOF'
Samples: 0
CPU avg (%): n/a
CPU max (%): n/a
Mem avg (MiB): n/a
Mem max (MiB): n/a
EOF
    return
  fi

  local cpu_avg cpu_max mem_avg mem_max
  cpu_avg=$(jq -r '.cpu_avg' "$summary_json")
  cpu_max=$(jq -r '.cpu_max' "$summary_json")
  mem_avg=$(jq -r '.mem_avg_mib' "$summary_json")
  mem_max=$(jq -r '.mem_max_mib' "$summary_json")

  printf "Samples: %s\n" "$samples" >"$summary_txt"
  printf "CPU avg (%%): %.2f\n" "$cpu_avg" >>"$summary_txt"
  printf "CPU max (%%): %.2f\n" "$cpu_max" >>"$summary_txt"
  printf "Mem avg (MiB): %.2f\n" "$mem_avg" >>"$summary_txt"
  printf "Mem max (MiB): %.2f\n" "$mem_max" >>"$summary_txt"
}

progress() {
  local message="$1"
  CURRENT_STEP=$((CURRENT_STEP + 1))
  local percent=$((CURRENT_STEP * 100 / TOTAL_STEPS))
  printf '[%3d%%] %s\n' "$percent" "$message"
}

capture_metadata() {
  local app_name="$1"
  local startup="$2"
  local image="$3"
  local outdir="$4"

  local image_info
  image_info="$(docker image inspect "$image")"
  local arch
  arch="$(printf '%s\n' "$image_info" | jq -r '.[0].Architecture')"
  local size
  size="$(printf '%s\n' "$image_info" | jq -r '.[0].Size')"

  cat >"$outdir/metadata.json" <<EOF
{
  "app": "$app_name",
  "image": "$image",
  "startup_seconds": $startup,
  "image_architecture": "$arch",
  "image_size_bytes": $size,
  "generated_at": "$(utc_now_iso)"
}
EOF
}

sample_docker_stats() {
  local monitor_pid="$1"
  local outfile="$2"

  while kill -0 "$monitor_pid" 2>/dev/null; do
    docker stats "$CONTAINER_NAME" --no-stream --format '{{json .}}' >>"$outfile" 2>/dev/null || true
    sleep "$STATS_INTERVAL"
  done

  docker stats "$CONTAINER_NAME" --no-stream --format '{{json .}}' >>"$outfile" 2>/dev/null || true
}

run_test_suite() {
  local app_name="$1"
  local image="$2"
  local health_url="$3"
  local outdir="$RESULTS_DIR/$app_name"

  if [[ -d "$outdir" ]]; then
    local stamp
    stamp="$(utc_stamp)"
    mkdir -p "$RESULTS_DIR/archive"
    mv "$outdir" "$RESULTS_DIR/archive/${app_name}_${stamp}"
  fi
  rm -rf "$outdir"
  mkdir -p "$outdir"

  cleanup_container

  echo "==> Starting $app_name ($image)"
  local start_ts end_ts startup_seconds
  start_ts=$(date +%s)

  docker run -d \
    --name "$CONTAINER_NAME" \
    --net "$NETWORK_NAME" \
    --cpus "$CPU_LIMIT" \
    --memory "$MEMORY_LIMIT" \
    --platform linux/arm64 \
    -p "$PORT_MAPPING" \
    "$image" >/tmp/poc_app_cid.txt

  wait_for_health "$health_url"
  end_ts=$(date +%s)
  startup_seconds=$((end_ts - start_ts))
  echo "    Startup time: ${startup_seconds}s"
  progress "Startup completed for $app_name"

  capture_metadata "$app_name" "$startup_seconds" "$image" "$outdir"
  capture_idle_stats "$outdir/idle_stats.txt"

  for test in "${TESTS[@]}"; do
    local script="$LOAD_TEST_DIR/${test}_test.js"
    if [[ ! -f "$script" ]]; then
      echo "WARNING: Missing script $script, skipping." >&2
      continue
    fi

    local log="$outdir/${test}.log"
    local json="$outdir/${test}.json"
    local stats_raw="$outdir/${test}_stats_raw.jsonl"
    local stats_json="$outdir/${test}_stats_summary.json"
    local stats_txt="$outdir/${test}_stats.txt"

    echo "    Running $test load test..."

    : >"$stats_raw"
    (
      cd "$LOAD_TEST_DIR"
      k6 run \
        --summary-trend-stats "$SUMMARY_TREND" \
        --summary-export "$json" \
        "$script"
    ) >"$log" 2>&1 &
    local k6_pid=$!

    sample_docker_stats "$k6_pid" "$stats_raw" &
    local stats_pid=$!

    wait "$k6_pid"
    local k6_status=$?

    wait "$stats_pid" 2>/dev/null || true

    if [[ $k6_status -ne 0 ]]; then
      echo "ERROR: k6 run for $test failed with exit code $k6_status (see $log)." >&2
      exit $k6_status
    fi

    summarize_stream_stats "$stats_raw" "$stats_json" "$stats_txt"
    progress "Completed $test test for $app_name"
  done

  docker stop "$CONTAINER_NAME" >/dev/null 2>&1 || true
  docker rm "$CONTAINER_NAME" >/dev/null 2>&1 || true
}

main() {
  ensure_network
  ensure_db

  command -v jq >/dev/null 2>&1 || {
    echo "ERROR: jq is required to capture image metadata." >&2
    exit 1
  }

  for entry in "${APPS[@]}"; do
    read -r app image health <<<"$entry"
    run_test_suite "$app" "$image" "$health"
  done

  echo "All load tests completed. Results stored under $RESULTS_DIR/"
}

main "$@"
