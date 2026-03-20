#!/bin/bash
# oc -n openshift-storage exec deploy/rook-ceph-tools -- ceph osd tree
# oc -n openshift-storage exec deploy/rook-ceph-tools -- ceph osd metadata #(disk real )
# oc -n openshift-storage exec deploy/rook-ceph-tools -- ceph-volume lvm list #(local vs runtime, shared)
# oc -n openshift-storage exec deploy/rook-ceph-tools -- ceph osd df #( Raw installed ) 
# oc -n openshift-storage exec deploy/rook-ceph-tools -- ceph df #( usage capacity )
# oc -n openshift-storage exec deploy/rook-ceph-tools -- ceph health detail
# oc -n openshift-storage exec deploy/rook-ceph-tools -- ceph status

#!/bin/bash
# ====================================================
# OpenShift ODF / Ceph Pre-Check Script
# Purpose: Collect non-disruptive evidences of the
#          current ODF (Ceph) state before upgrade
# ====================================================

set -o pipefail

NS="openshift-storage"

echo "===================================================="
echo "ODF / Ceph Pre-Upgrade Assessment"
echo "Date: $(date)"
echo "Cluster API: $(oc whoami --show-server)"
echo "Namespace: $NS"
echo "===================================================="
echo

# ----------------------------------------------------
# Helper function to print section headers
# ----------------------------------------------------
section () {
  echo
  echo "----------------------------------------------------"
  echo "$1"
  echo "----------------------------------------------------"
}

# ----------------------------------------------------
# Detect Ceph tools pod (required for ceph CLI)
# ----------------------------------------------------
section "Ceph Tools Pod Availability"

CEPH_TOOLS_POD=$(oc -n $NS get pod -l app=rook-ceph-tools -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)

if [[ -z "$CEPH_TOOLS_POD" ]]; then
  echo "Ceph tools pod not found. Ceph CLI checks cannot be executed."
  exit 1
else
  oc -n $NS get pod -l app=rook-ceph-tools
fi

# ----------------------------------------------------
# ODF-01 – Ceph OSD topology and placement
# Validates number of OSDs, hosts and distribution
# ----------------------------------------------------
section "ODF-01 – Ceph OSD Tree (Topology & Placement)"
oc -n $NS exec deploy/rook-ceph-tools -- ceph osd tree

# ----------------------------------------------------
# ODF-02 – Ceph OSD metadata
# Validates:
# - Disk type (SSD/NVMe/HDD)
# - Device mapping
# - Ceph & OS versions
# ----------------------------------------------------
section "ODF-02 – Ceph OSD Metadata (Disk Type & OS)"
oc -n $NS exec deploy/rook-ceph-tools -- ceph osd metadata

# ----------------------------------------------------
# ODF-03 – OSD-level disk utilization
# Validates per-OSD usage and balance
# ----------------------------------------------------
section "ODF-03 – Ceph OSD Disk Utilization"
oc -n $NS exec deploy/rook-ceph-tools -- ceph osd df

# ----------------------------------------------------
# ODF-04 – Cluster-wide raw capacity and pools usage
# ----------------------------------------------------
section "ODF-04 – Ceph Cluster Capacity & Pools"
oc -n $NS exec deploy/rook-ceph-tools -- ceph df

# ----------------------------------------------------
# ODF-05 – Ceph health details
# Confirms cluster is HEALTH_OK and no warnings/errors
# ----------------------------------------------------
section "ODF-05 – Ceph Health Detail"
oc -n $NS exec deploy/rook-ceph-tools -- ceph health detail

# ----------------------------------------------------
# ODF-06 – Ceph cluster status summary
# Validates MONs, OSDs, MDS, RGW and PGs state
# ----------------------------------------------------
section "ODF-06 – Ceph Status Summary"
oc -n $NS exec deploy/rook-ceph-tools -- ceph status

# ----------------------------------------------------
# ODF-08 – Ceph pools configuration
# Uses the rook-ceph-operator deployment to run ceph CLI
# ----------------------------------------------------
section "ODF-08 – Ceph Pools Detail"
oc exec -n $NS deploy/rook-ceph-operator -- \
  ceph -c /var/lib/rook/openshift-storage/openshift-storage.config \
  osd pool ls detail

# ----------------------------------------------------
# ODF-09 – CRUSH rules
# Validates placement strategy and failure domains
# ----------------------------------------------------
section "ODF-09 – Ceph CRUSH Rules"
oc exec -n $NS deploy/rook-ceph-operator -- \
  ceph -c /var/lib/rook/openshift-storage/openshift-storage.config \
  osd crush rule dump

# ----------------------------------------------------
# ODF-10 – Ceph authentication keys
# Inventory of Ceph clients and permissions
# ----------------------------------------------------
section "ODF-10 – Ceph Auth Keys"
oc exec -n $NS deploy/rook-ceph-operator -- \
  ceph -c /var/lib/rook/openshift-storage/openshift-storage.config \
  auth list

echo
echo "===================================================="
echo "ODF / Ceph Pre-Check completed successfully"
echo "===================================================="