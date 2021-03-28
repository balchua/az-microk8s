#!/bin/sh

until microk8s.status --wait-ready; 
  do sleep 5; echo "waiting for worker status.."; 
done

echo "adding main node ${main_node} dns to CSR." 
sed -i 's@#MOREIPS@DNS.99 = ${main_node}\n#MOREIPS\n@g' /var/snap/microk8s/current/certs/csr.conf.template; 
echo 'done.'

sleep 10  
sudo microk8s add-node --token ${cluster_token} --token-ttl ${cluster_token_ttl_seconds}
sudo microk8s config > /tmp/config/client.config

echo "updating kubeconfig"
sed -i 's/127.0.0.1:16443/${main_node}/g' /tmp/config/client.config
