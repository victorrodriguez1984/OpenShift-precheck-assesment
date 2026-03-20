#!/bin/bash

NODES=$(oc get nodes -l cluster.ocs.openshift.io/openshift-storage= -o jsonpath='{.items[*].metadata.name}')

echo "ODF Infra Validation (Extended)"
echo "================================"
echo "Nodes: $NODES"
echo

for NODE in $NODES; do
  echo "============================================================"
  echo "NODE: $NODE"
  echo "============================================================"

  oc debug node/$NODE -- chroot /host bash -c "
    echo
    echo '--- Interfaces & MTU (relevant ones) ---'
    for iface in ens5 br-ex br-int ovn-k8s-mp0 genev_sys_6081; do
      if ip link show \$iface >/dev/null 2>&1; then
        mtu=\$(ip link show \$iface | awk '/mtu/ {print \$5}')
        echo \"\$iface -> MTU \$mtu\"
      fi
    done

    echo
    echo '--- NIC Speed ---'
    ethtool ens5 2>/dev/null | grep -E 'Speed|Duplex'

    echo
    echo '--- Routing Table ---'
    ip route

    echo
    echo '--- DNS Resolution (node-level) ---'
    nslookup redhat.com || echo 'DNS lookup failed'

    # echo
    # echo '--- Egress Connectivity (node-level) ---'
    # curl -I --connect-timeout 5 https://www.redhat.com || echo 'Egress HTTPS failed'
  "

  echo
  echo "--- Latency to other ODF nodes ---"
  for TARGET in $NODES; do
    if [ "$TARGET" != "$NODE" ]; then
      TARGET_IP=$(oc get node $TARGET -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
      echo "Ping $TARGET ($TARGET_IP)"
      oc debug node/$NODE -- chroot /host ping -c 3 $TARGET_IP 2>/dev/null | grep rtt || echo "Ping failed"
    fi
  done

  echo
done