
# OpenShift Assessment Toolkit

This repository contains a set of **non-disruptive diagnostic scripts**
used to assess OpenShift clusters before upgrades, go-live events, or
incident analysis.

## Minimum Permissions
- Cluster Viewer role for cluster-wide read access 
- Namespace-specific read access for workload and resource details
- Exec access to pods for in-depth diagnostics (optional but recommended)

## What this does
- Collects upgrade readiness information
- Validates ODF / Ceph health and capacity
- Checks networking (MTU, egress)
- Consolidates outputs with cluster ID and timestamps

## What this does NOT do
- No configuration changes
- No remediation actions
- No automated fixes

## Usage

```bash
chmod +x *.sh
./run-all.sh
