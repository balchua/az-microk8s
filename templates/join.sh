#!/bin/sh

until microk8s status --wait-ready; 
  do sleep 3; echo "waiting for worker status.."; 
done

if microk8s status | grep "datastore master nodes: 127.0.0.1:19001" > /dev/null 2>&1; then

  echo "adding main node ${main_node} dns to CSR."
  sed -i 's@#MOREIPS@DNS.99 = ${main_node}\n#MOREIPS\n@g' /var/snap/microk8s/current/certs/csr.conf.template
  echo "done."

  sleep 30           
  sudo microk8s join ${main_node}:25000/${cluster_token}

  # Finally check if the node is ready
  microk8s status --wait-ready
else
  echo "Join process already done. Nothing to do"
fi  