module "az-microk8s" {
    source = "git::https://github.com/balchua/az-microk8s"
    region = "southeastasia"
    cluster_name = "cetacean"
    host_cidr = "10.0.0.0/16" 
    controller_type = "Standard_DS2_v2"
    worker_type = "Standard_DS2_v2"
    worker_count = "1"

    microk8s_channel = "edge"
    cluster_token = "PoiuyTrewQasdfghjklMnbvcxz123409"
    cluster_token_ttl_seconds = 3600    

}