#!/bin/bash

NODES=$(oc get nodes -l cluster.ocs.openshift.io/openshift-storage= -o jsonpath='{.items[*].metadata.name}')

echo "ODF Egress"

echo "================================"
echo "Nodes: $NODES"
echo

for NODE in $NODES; do
  echo "============================================================"
  echo "NODE: $NODE"
  echo "============================================================"

  oc debug node/$NODE -- chroot /host bash -c "

    echo
    echo '--- Egress Connectivity (node-level) ---'
    curl -I --connect-timeout 5 https://www.redhat.com || echo 'Egress HTTPS failed'
  "
done