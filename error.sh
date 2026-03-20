#!/bin/bash

#!/bin/bash

NODES=$(oc get nodes -l cluster.ocs.openshift.io/openshift-storage= -o jsonpath='{.items[*].metadata.name}')

echo "ODF Network Error Counters"
echo "=========================="
echo

for NODE in $NODES; do
  echo "============================================================"
  echo "NODE: $NODE"
  echo "============================================================"

  oc debug node/$NODE -- chroot /host bash -c "
    echo
    echo '--- Interface Error Counters ---'
    ip -s link show | awk '
      /^[0-9]+:/ { iface=\$2 }
      /RX:/ { getline; rx=\$0 }
      /TX:/ { getline; tx=\$0; print iface \"\\n  RX \" rx \"\\n  TX \" tx \"\\n\" }
    '

    echo
    echo '--- ethtool Statistics (ens5) ---'
    ethtool -S ens5 2>/dev/null | egrep -i 'error|drop|miss|fail|timeout' || echo 'No error counters reported'

    echo
    echo '--- Kernel Network Errors ---'
    netstat -s | egrep -i 'error|drop|overflow' || echo 'No kernel-level errors detected'
  "

  echo
done