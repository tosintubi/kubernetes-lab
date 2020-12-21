#!/bin/bash


#gcloud projects create project-kubernetes-hard-way --name= "Kubernetes the Hard way Project"  --labels=type=k8-hard

REGION=europe-west3
ZONE=europe-west3-a


function create_network {
    #creates the network
    echo "Creating VPC Network ......."
    gcloud compute networks create kubernetes-the-hard-way --subnet-mode custom

    #Creates subnet  10.240.0.0/24 IP address range can host up to 254 compute instances.
    echo "Creating VPC Subnets ......."
    gcloud compute networks subnets create kubernetes \
    --network kubernetes-the-hard-way \
    --region ${REGION} \
    --range 10.240.0.0/24
 
    #Firewall ingress rules
    echo "Creating Firewall Ingress Rules ......."
    gcloud compute firewall-rules create kubernetes-the-hard-way-allow-internal \
    --allow tcp,udp,icmp \
    --network kubernetes-the-hard-way \
    --source-ranges 10.240.0.0/24,10.200.0.0/16

    #Firewall egress rules
    echo "Creating Firewall Egress Rules ......."
    gcloud compute firewall-rules create kubernetes-the-hard-way-allow-external \
    --allow tcp:22,tcp:6443,icmp \
    --network kubernetes-the-hard-way \
    --source-ranges 0.0.0.0/0

    #List the networks
    gcloud compute firewall-rules list --filter="network:kubernetes-the-hard-way"
}

function create_controllers {
    echo "Creating controllers ............. "
    for i in 0 1; do
        gcloud compute instances create controller-${i} \
            --async \
            --boot-disk-size 200GB \
            --can-ip-forward \
            --image-family ubuntu-2004-lts \
            --image-project ubuntu-os-cloud \
            --machine-type e2-standard-2 \
            --private-network-ip 10.240.0.1${i} \
            --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
            --subnet kubernetes \
            --zone ${ZONE} \
            --tags kubernetes-the-hard-way,controller
    done
}

function create_workers {
    echo "Creating workers  ............. "
    for i in 0 1; do
        gcloud compute instances create worker-${i} \
            --async \
            --boot-disk-size 200GB \
            --can-ip-forward \
            --image-family ubuntu-2004-lts \
            --image-project ubuntu-os-cloud \
            --machine-type e2-standard-2 \
            --metadata pod-cidr=10.200.${i}.0/24 \
            --private-network-ip 10.240.0.2${i} \
            --scopes compute-rw,storage-ro,service-management,service-control,logging-write,monitoring \
            --subnet kubernetes \
            --zone ${ZONE} \
            --tags kubernetes-the-hard-way,worker
    done
}


function create_static_ip {
    gcloud compute addresses create kubernetes-the-hard-way \
        --region ${REGION}
       # --region $(gcloud config get-value compute/{REGION})
}

function check_static_ip {
    gcloud compute addresses list --filter="name=('kubernetes-the-hard-way')"
}

create_network
create_controllers
create_workers
create_static_ip
check_static_ip