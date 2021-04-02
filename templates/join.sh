#!/bin/sh

until microk8s status --wait-ready; 
  do sleep 3; echo "waiting for worker status.."; 
done

echo "adding main node ${main_node} dns to CSR."
sed -i 's@#MOREIPS@DNS.99 = ${main_node}\n#MOREIPS\n@g' /var/snap/microk8s/current/certs/csr.conf.template
echo "done."

sleep 30           
sudo microk8s join ${main_node}:25000/${cluster_token}

# Finally check if the node is ready
microk8s status --wait-ready