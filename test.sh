#!/usr/bin/env bash
# test.sh – run an ngspice batch simulation inside Docker and validate results.
#
# Usage: ./test.sh [image]
#   image  Docker image to test (default: aanas0sayed/docker-ngspice)
#
# Exit codes:
#   0  all .meas checks passed
#   1  simulation failed or a measurement was out of range

set -euo pipefail

IMAGE="${1:-aanas0sayed/docker-ngspice}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="$SCRIPT_DIR/test"
NETLIST="rc_filter.cir"
OUTPUT_FILE="$TEST_DIR/output.log"

echo "==> ngspice headless batch test"
echo "    image  : $IMAGE"
echo "    netlist: $TEST_DIR/$NETLIST"
echo ""

# ── Run ngspice inside the container ─────────────────────────────────────────
# ngspice -b runs in batch mode and prints .meas results to stdout.
docker run --rm \
    --volume "$TEST_DIR:/sim" \
    "$IMAGE" -b /sim/"$NETLIST" > "$OUTPUT_FILE" 2>&1

echo "==> Simulation output:"
echo "------------------------------------------------------------"
cat "$OUTPUT_FILE"
echo "------------------------------------------------------------"
echo ""

# ── Validate .meas results ────────────────────────────────────────────────────
echo "==> Validating .meas results..."

PASS=1

check_meas_range() {
    local name="$1" lo="$2" hi="$3"
    local line val

    # ngspice batch output format: "name  =  1.234567e+00"
    line=$(grep -i "^${name}" "$OUTPUT_FILE" 2>/dev/null | head -n1)

    if [[ -z "$line" ]]; then
        echo "  FAIL  '${name}' not found in output"
        PASS=0
        return
    fi

    if echo "$line" | grep -qi "failed"; then
        echo "  FAIL  $line"
        PASS=0
        return
    fi

    # Strip everything up to the first '=' so the name (e.g. "tau_rise") can't
    # match the number regex via its own letters.
    val=$(echo "$line" | sed 's/^[^=]*=//' | grep -oE '[0-9]+\.?[0-9]*([eE][+-]?[0-9]+)?' | head -n1)

    if awk -v v="$val" -v lo="$lo" -v hi="$hi" 'BEGIN{exit !(v>=lo && v<=hi)}'; then
        printf "  PASS  %-14s = %s  (expected [%s, %s])\n" "$name" "$val" "$lo" "$hi"
    else
        printf "  FAIL  %-14s = %s  (expected [%s, %s])\n" "$name" "$val" "$lo" "$hi"
        PASS=0
    fi
}

# V(out) max: 5·(1−e⁻⁵) ≈ 4.966 V — accept 4.9 to 5.0
check_meas_range "vout_max"  4.9    5.0
# Steady-state average (last 1 ms): > 4.9 V
check_meas_range "vout_ss"   4.9    5.0
# τ crossing time ≈ 1 ms — accept 0.9 ms to 1.1 ms
check_meas_range "tau_rise"  0.0009 0.0011

echo ""
if [[ "$PASS" -eq 1 ]]; then
    echo "==> All checks PASSED."
else
    echo "==> Test FAILED – one or more .meas values out of range."
    exit 1
fi
