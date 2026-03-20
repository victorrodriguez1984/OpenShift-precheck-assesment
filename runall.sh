#!/bin/bash
# ====================================================
# Peru Issue – Unified Execution Wrapper
# Purpose:
#   Run all diagnostic scripts and consolidate outputs
#   into a uniquely identified file including:
#     - Cluster ID
#     - Timestamp
# ====================================================

set -o pipefail

# ----------------------------------------------------
# Identify cluster and timestamp
# ----------------------------------------------------
CLUSTER_ID=$(oc get clusterversion version -o jsonpath='{.spec.clusterID}' 2>/dev/null)
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

if [[ -z "$CLUSTER_ID" ]]; then
  CLUSTER_ID="unknown-cluster"
fi

OUTPUT_FILE="outputs_${CLUSTER_ID}_${TIMESTAMP}.txt"

SCRIPTS=(
  "upgrade.sh"
  "storage.sh"
  "net-mtu.sh"
  "egress.sh"
  "error.sh"
)

# ----------------------------------------------------
# Header
# ----------------------------------------------------
{
  echo "===================================================="
  echo "Peru Issue – Consolidated Diagnostic Output"
  echo "Cluster ID : $CLUSTER_ID"
  echo "Timestamp  : $TIMESTAMP"
  echo "Date       : $(date)"
  echo "Host       : $(hostname)"
  echo "User       : $(whoami)"
  echo "Directory  : $(pwd)"
  echo "===================================================="
  echo
} > "$OUTPUT_FILE"

# ----------------------------------------------------
# Execute scripts
# ----------------------------------------------------
for SCRIPT in "${SCRIPTS[@]}"; do
  {
    echo "----------------------------------------------------"
    echo "Running script : $SCRIPT"
    echo "Start time     : $(date)"
    echo "----------------------------------------------------"
  } | tee -a "$OUTPUT_FILE"

  if [[ -x "./$SCRIPT" ]]; then
    ./"$SCRIPT" >> "$OUTPUT_FILE" 2>&1
    RC=$?
    echo >> "$OUTPUT_FILE"
    echo "Exit code      : $RC" | tee -a "$OUTPUT_FILE"
  else
    echo "ERROR: $SCRIPT not found or not executable" | tee -a "$OUTPUT_FILE"
  fi

  {
    echo "End time       : $(date)"
    echo
  } | tee -a "$OUTPUT_FILE"
done

# ----------------------------------------------------
# Footer
# ----------------------------------------------------
{
  echo "===================================================="
  echo "All scripts executed"
  echo "Output file: $OUTPUT_FILE"
  echo "===================================================="
} | tee -a "$OUTPUT_FILE"