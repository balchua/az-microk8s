# Azure Terraform Microk8s

**This currently works for `1.19+` channel, as the token generation is not yet merged with the latest stable Microk8s version.**

Bootstrap an Highly available MicroK8s in Azure with Terraform.

For example to bootstrap a 3 node MicroK8s.

```hcl
module "az-microk8s" {
    //source = "git::https://github.com/balchua/az-microk8s"
    source = "../"
    region = "southeastasia"
    cluster_name = "hades"
    host_cidr = "10.0.0.0/16" 
    node_type = "Standard_DS3_v2"
    node_count = "3"
    microk8s_channel = "latest/stable"
    cluster_token = "PoiuyTrewQasdfghjklMnbvcxz123409"
    cluster_token_ttl_seconds = 3600    
}

```

**The `cluster_token` must be 32 alphanumeric characters long.**

## Azure TF environment variables

You must have these environment variables present.

```shell

# Azure stuffs
ARM_SUBSCRIPTION_ID=<your subscription id>
ARM_CLIENT_ID=<your client id>
ARM_CLIENT_SECRET=<your client secret>
ARM_TENANT_ID=<your tenant id>

TF_VAR_client_id=<your client id, same as ARM_CLIENT_ID>
TF_VAR_client_secret=<your client secret, same as ARM_CLIENT_SECRET>

```

## Creating the cluster

Simply run the `terraform plan` and then `terraform apply`.

__It takes a few minutes to bootstrap the cluster.__

Once terraform completes, you should be able to see the cluster.

## Where is Kube config file?

The module automatically downloads the kubeconfig file to your local machine in `/tmp/client.config`
In order to access the Kubernetes cluster from your local machine.

`export KUBECONFIG=/tmp/client.config`

You should have access to the cluster.

Example:

```shell

thor@norse:~/workspace/terra-work/microk8s-azure/example$ kubectl get nodes -o wide
NAME                           STATUS                     ROLES    AGE     VERSION                     INTERNAL-IP   EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION     CONTAINER-RUNTIME
microk8s-cetacean-controller   Ready,SchedulingDisabled   master   9m5s    v1.18.2-41+8545d23a1e1569   10.0.128.4    <none>        Ubuntu 18.04.4 LTS   5.3.0-1020-azure   containerd://1.2.5
microk8s-cetacean-worker-0     Ready                      <none>   7m24s   v1.18.2-41+8545d23a1e1569   10.0.0.4      <none>        Ubuntu 18.04.4 LTS   5.3.0-1020-azure   containerd://1.2.5

```
Or getting all info.

```shell
thor@norse:~/workspace/terra-work/microk8s-azure/example$ kubectl get all -A
NAMESPACE     NAME                                          READY   STATUS    RESTARTS   AGE
kube-system   pod/coredns-588fd544bf-cxp5n                  1/1     Running   0          6m17s
linkerd       pod/linkerd-controller-6d44b755f-dh47w        2/2     Running   0          6m3s
linkerd       pod/linkerd-destination-cd6b7ff58-6pb56       2/2     Running   0          6m3s
linkerd       pod/linkerd-grafana-5cf7cf64fb-lz8s4          2/2     Running   0          6m2s
linkerd       pod/linkerd-identity-55b867bc7c-4ddgz         2/2     Running   0          6m3s
linkerd       pod/linkerd-prometheus-6745c4547b-q5z8d       2/2     Running   0          6m2s
linkerd       pod/linkerd-proxy-injector-67f75c65f8-lcd7n   2/2     Running   0          6m2s
linkerd       pod/linkerd-sp-validator-79cf4d9cc-2lcsr      2/2     Running   0          6m2s
linkerd       pod/linkerd-tap-6bb6c48d96-2f2hj              2/2     Running   0          6m2s
linkerd       pod/linkerd-web-7867bbd9b4-b5889              2/2     Running   0          6m3s

NAMESPACE     NAME                             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                  AGE
default       service/kubernetes               ClusterIP   10.152.183.1     <none>        443/TCP                  18m
kube-system   service/kube-dns                 ClusterIP   10.152.183.10    <none>        53/UDP,53/TCP,9153/TCP   6m17s
linkerd       service/linkerd-controller-api   ClusterIP   10.152.183.120   <none>        8085/TCP                 6m3s
linkerd       service/linkerd-dst              ClusterIP   10.152.183.216   <none>        8086/TCP                 6m3s
linkerd       service/linkerd-grafana          ClusterIP   10.152.183.234   <none>        3000/TCP                 6m2s
linkerd       service/linkerd-identity         ClusterIP   10.152.183.192   <none>        8080/TCP                 6m3s
linkerd       service/linkerd-prometheus       ClusterIP   10.152.183.9     <none>        9090/TCP                 6m2s
linkerd       service/linkerd-proxy-injector   ClusterIP   10.152.183.65    <none>        443/TCP                  6m2s
linkerd       service/linkerd-sp-validator     ClusterIP   10.152.183.25    <none>        443/TCP                  6m2s
linkerd       service/linkerd-tap              ClusterIP   10.152.183.87    <none>        8088/TCP,443/TCP         6m2s
linkerd       service/linkerd-web              ClusterIP   10.152.183.157   <none>        8084/TCP,9994/TCP        6m3s

NAMESPACE     NAME                                     READY   UP-TO-DATE   AVAILABLE   AGE
kube-system   deployment.apps/coredns                  1/1     1            1           6m17s
linkerd       deployment.apps/linkerd-controller       1/1     1            1           6m3s
linkerd       deployment.apps/linkerd-destination      1/1     1            1           6m3s
linkerd       deployment.apps/linkerd-grafana          1/1     1            1           6m2s
linkerd       deployment.apps/linkerd-identity         1/1     1            1           6m3s
linkerd       deployment.apps/linkerd-prometheus       1/1     1            1           6m2s
linkerd       deployment.apps/linkerd-proxy-injector   1/1     1            1           6m2s
linkerd       deployment.apps/linkerd-sp-validator     1/1     1            1           6m2s
linkerd       deployment.apps/linkerd-tap              1/1     1            1           6m2s
linkerd       deployment.apps/linkerd-web              1/1     1            1           6m3s

NAMESPACE     NAME                                                DESIRED   CURRENT   READY   AGE
kube-system   replicaset.apps/coredns-588fd544bf                  1         1         1       6m17s
linkerd       replicaset.apps/linkerd-controller-6d44b755f        1         1         1       6m3s
linkerd       replicaset.apps/linkerd-destination-cd6b7ff58       1         1         1       6m3s
linkerd       replicaset.apps/linkerd-grafana-5cf7cf64fb          1         1         1       6m2s
linkerd       replicaset.apps/linkerd-identity-55b867bc7c         1         1         1       6m3s
linkerd       replicaset.apps/linkerd-prometheus-6745c4547b       1         1         1       6m2s
linkerd       replicaset.apps/linkerd-proxy-injector-67f75c65f8   1         1         1       6m2s
linkerd       replicaset.apps/linkerd-sp-validator-79cf4d9cc      1         1         1       6m2s
linkerd       replicaset.apps/linkerd-tap-6bb6c48d96              1         1         1       6m2s
linkerd       replicaset.apps/linkerd-web-7867bbd9b4              1         1         1       6m3s

NAMESPACE   NAME                              SCHEDULE      SUSPEND   ACTIVE   LAST SCHEDULE   AGE
linkerd     cronjob.batch/linkerd-heartbeat   12 7 * * *    False     0        <none>          6m3s


```


## Enabling addons

To enable addons, user must `ssh` into the master node, using the public IP.

By default the your locally defined public key `~/.ssh/id_rsa.pub` is added to all the nodes.

To override this, add a location of your public and private keys to the variables `ssh_public_key` and `ssh_private_key`.

Example:

```hcl
module "az-microk8s" {
    //source = "git::https://github.com/balchua/az-microk8s"
    source = "../"
    region = "southeastasia"
    cluster_name = "hades"
    host_cidr = "10.0.0.0/16" 
    node_type = "Standard_DS3_v2"
    node_count = "3"
    microk8s_channel = "latest/edge"
    cluster_token = "PoiuyTrewQasdfghjklMnbvcxz123409"
    cluster_token_ttl_seconds = 3600
    ssh_public_key = "/data/keys/my_public_key"
    ssh_private_key = "/data/keys/my_private_key"  
}

```

The user to use is `ubuntu`

```shell
$ ssh ubuntu@52.139.249.29
The authenticity of host '52.139.249.29 (52.139.249.29)' can't be established.
ECDSA key fingerprint is SHA256:UYgdrL7aLMQ+gDHaTpXgbQXiUdYM173DKhwNV0tTqVY.
Are you sure you want to continue connecting (yes/no)? yes
Warning: Permanently added '52.139.249.29' (ECDSA) to the list of known hosts.
Welcome to Ubuntu 18.04.4 LTS (GNU/Linux 5.3.0-1020-azure x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/advantage

  System information as of Sun May 10 07:01:05 UTC 2020

  System load:  0.0               Processes:           147
  Usage of /:   6.3% of 28.90GB   Users logged in:     0
  Memory usage: 13%               IP address for eth0: 10.0.128.4
  Swap usage:   0%


3 packages can be updated.
2 updates are security updates.


Last login: Sun May 10 06:49:41 2020 from 42.60.150.92
ubuntu@microk8s-cetacean-controller:~$ microk8s.enable linkerd
Fetching Linkerd2 version v2.7.0.
2.7.0
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
100   644  100   644    0     0   1164      0 --:--:-- --:--:-- --:--:--  1166
100 34.3M  100 34.3M    0     0  6029k      0  0:00:05  0:00:05 --:--:-- 7346k
Enabling Linkerd2
Enabling DNS
Applying manifest
serviceaccount/coredns created
configmap/coredns created
deployment.apps/coredns created
service/kube-dns created
clusterrole.rbac.authorization.k8s.io/coredns created
clusterrolebinding.rbac.authorization.k8s.io/coredns created
Restarting kubelet
Adding argument --cluster-domain to nodes.
Applying to node microk8s-cetacean-worker-0.
Adding argument --cluster-dns to nodes.
Applying to node microk8s-cetacean-worker-0.
Restarting nodes.
Applying to node microk8s-cetacean-worker-0.
DNS is enabled
namespace/linkerd created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-identity created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-identity created
serviceaccount/linkerd-identity created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-controller created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-controller created
serviceaccount/linkerd-controller created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-destination created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-destination created
serviceaccount/linkerd-destination created
role.rbac.authorization.k8s.io/linkerd-heartbeat created
rolebinding.rbac.authorization.k8s.io/linkerd-heartbeat created
serviceaccount/linkerd-heartbeat created
role.rbac.authorization.k8s.io/linkerd-web created
rolebinding.rbac.authorization.k8s.io/linkerd-web created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-web-check created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-web-check created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-web-admin created
serviceaccount/linkerd-web created
customresourcedefinition.apiextensions.k8s.io/serviceprofiles.linkerd.io created
customresourcedefinition.apiextensions.k8s.io/trafficsplits.split.smi-spec.io created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-prometheus created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-prometheus created
serviceaccount/linkerd-prometheus created
serviceaccount/linkerd-grafana created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-proxy-injector created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-proxy-injector created
serviceaccount/linkerd-proxy-injector created
secret/linkerd-proxy-injector-tls created
mutatingwebhookconfiguration.admissionregistration.k8s.io/linkerd-proxy-injector-webhook-config created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-sp-validator created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-sp-validator created
serviceaccount/linkerd-sp-validator created
secret/linkerd-sp-validator-tls created
validatingwebhookconfiguration.admissionregistration.k8s.io/linkerd-sp-validator-webhook-config created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-tap created
clusterrole.rbac.authorization.k8s.io/linkerd-linkerd-tap-admin created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-tap created
clusterrolebinding.rbac.authorization.k8s.io/linkerd-linkerd-tap-auth-delegator created
serviceaccount/linkerd-tap created
rolebinding.rbac.authorization.k8s.io/linkerd-linkerd-tap-auth-reader created
secret/linkerd-tap-tls created
apiservice.apiregistration.k8s.io/v1alpha1.tap.linkerd.io created
podsecuritypolicy.policy/linkerd-linkerd-control-plane created
role.rbac.authorization.k8s.io/linkerd-psp created
rolebinding.rbac.authorization.k8s.io/linkerd-psp created
configmap/linkerd-config created
secret/linkerd-identity-issuer created
service/linkerd-identity created
deployment.apps/linkerd-identity created
service/linkerd-controller-api created
deployment.apps/linkerd-controller created
service/linkerd-dst created
deployment.apps/linkerd-destination created
cronjob.batch/linkerd-heartbeat created
service/linkerd-web created
deployment.apps/linkerd-web created
configmap/linkerd-prometheus-config created
service/linkerd-prometheus created
deployment.apps/linkerd-prometheus created
configmap/linkerd-grafana-config created
service/linkerd-grafana created
deployment.apps/linkerd-grafana created
deployment.apps/linkerd-proxy-injector created
service/linkerd-proxy-injector created
service/linkerd-sp-validator created
deployment.apps/linkerd-sp-validator created
service/linkerd-tap created
deployment.apps/linkerd-tap created
Linkerd is starting

```



