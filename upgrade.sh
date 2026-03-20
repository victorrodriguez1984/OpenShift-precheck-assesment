#!/bin/bash
set -o pipefail

NS="openshift-storage"

echo "===================================================="
echo "OpenShift & ODF Upgrade Pre-Check"
echo "Date: $(date)"
echo "Cluster: $(oc whoami --show-server)"
echo "===================================================="
echo

# -----------------------------
# Helper functions
# -----------------------------
section () {
  echo
  echo "----------------------------------------------------"
  echo "$1"
  echo "----------------------------------------------------"
}

wait_for_pod () {
  local label=$1
  echo "Waiting for pod with label: $label"
  oc -n $NS wait pod -l "$label" --for=condition=Ready --timeout=120s 2>/dev/null
}

# -----------------------------
# Ceph tools presence
# -----------------------------
section "Ceph Tools Pod"
oc -n $NS get pod -l app=rook-ceph-tools || echo "Ceph tools pod not found"

CEPH_TOOLS_POD=$(oc -n $NS get pod -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [[ -n "$CEPH_TOOLS_POD" ]]; then
  wait_for_pod "app=rook-ceph-tools"
else
  echo "Ceph tools not available – Ceph runtime checks will be skipped"
fi

# -----------------------------
# U-01 Current OpenShift version
# -----------------------------
section "U-01 – Current OpenShift Version"
oc get clusterversion
oc get clusterversion version -o yaml

# -----------------------------
# U-02 / U-03 – Problems & known issues
# -----------------------------
section "U-02 / U-03 – Cluster Operators & Conditions"
oc get clusterversion version -o jsonpath='{.status.conditions}{"\n"}'
oc get clusteroperators
oc  get pdb -A # Check for any PDBs that might block upgrades

section "Recent Cluster Events"
oc get events -A --sort-by=.lastTimestamp | tail -100

# -----------------------------
# U-04 – Planned upgrades
# -----------------------------
section "U-04 – Planned Upgrade"
oc adm upgrade

# -----------------------------
# U-05 – Previous upgrade attempts
# -----------------------------
section "U-05 – Upgrade History"
oc get clusterversion version -o yaml | sed -n '/history:/,/^status:/p'

# -----------------------------
# U-06 – Upgrade method & channel
# -----------------------------
section "U-06 – Upgrade Channel & Lifecycle"
oc get clusterversion version -o yaml | grep -i channel

# -----------------------------
# U-07 – Scope of issues (DC / nodes)
# -----------------------------
section "U-07 – Node Distribution"
oc get nodes -o wide

# -----------------------------
# U-08 – Operator & ODF alignment
# -----------------------------
section "U-08 – Operators, CSVs & Subscriptions"
oc get csv -A
oc get subscription -A
oc get storagecluster -n $NS

# -----------------------------
# U-09 – ODF capacity before upgrade
# -----------------------------
section "U-09 – ODF Capacity"

if [[ -n "$CEPH_TOOLS_POD" ]]; then
  oc -n $NS exec deploy/rook-ceph-tools -- ceph df
else
  echo "Ceph tools not available – falling back to PVC inventory"
fi

oc get pvc -A

# -----------------------------
# U-10 – InstallPlans
# -----------------------------
section "U-10 – InstallPlans"
oc get installplan -A

for ip in $(oc get installplan -A -o jsonpath='{.items[*].metadata.name}'); do
  echo
  echo "InstallPlan: $ip"
  oc describe installplan $ip -n $NS 2>/dev/null || true
done

# -----------------------------
# U-11 – Upgrade sequence
# -----------------------------
section "U-11 – Upgrade Sequence"
oc get clusterversion version -o yaml | grep -A5 history
oc get csv -n $NS
oc get clusteroperators

# -----------------------------
# Insights
# -----------------------------
section "Red Hat Insights"
oc get insightsoperators || echo "Insights operator not installed"

echo
echo "===================================================="
echo "Upgrade Pre-Check Completed"
echo "===================================================="