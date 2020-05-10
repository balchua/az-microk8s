# Azure Terraform Microk8s

**This currently works for `edge` channel, as the token generation is not yet merged with the latest stable Microk8s version.**

Bootstrap a multi node Microk8s in digitalocean with Terraform.

For example to bootstrap 1 controller and 1 worker.

```hcl

module "az-microk8s" {
    source = "git::https://github.com/balchua/az-microk8s"
    region = "southeastasia"
    cluster_name = "cetacean"
    host_cidr = "10.0.0.0/16" 
    controller_type = "Standard_DS1_v2"
    worker_type = "Standard_DS1_v2"
    worker_count = "2"

    microk8s_channel = "edge"
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

Simply run the `terraform plan` and then `terraform apply`

Once terraform completes, you should be able to see the cluster.

Login to the `master` node using `ssh root@masterip`, then issue the command below.

```shell

root@microk8s-controller-cetacean:~# microk8s.kubectl get no
NAME                           STATUS   ROLES    AGE     VERSION
10.130.111.105                 Ready    <none>   2m30s   v1.18.2-41+afcc98bc789924
10.130.82.34                   Ready    <none>   2m20s   v1.18.2-41+afcc98bc789924
microk8s-controller-cetacean   Ready    <none>   2m39s   v1.18.2-41+afcc98bc789924

```

## Downloading Kube config file

The module automatically downloads the kubeconfig file to your local machine in `/tmp/client.config`
In order to access the Kubernetes cluster from your local machine.
Change the API server IP to the one exposed by Digitalocean droplet.

For example, you control plane machine IP is `167.71.207.166`

Then you can do this from the command line.

`sed -i 's/127.0.0.1/167.71.207.166/g' /tmp/client.config`
