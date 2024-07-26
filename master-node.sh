#!/bin/bash

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Update packages and install necessary dependencies
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common


# Add Docker GPG key and repository
sudo apt update
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce

#add current user to docker group
sudo usermod -aG docker ${USER}
newgrp docker



# Add Kubernetes GPG key and repository
# apt-transport-https may be a dummy package; if so, you can skip that package

sudo apt install -y curl gnupg2 software-properties-common apt-transport-https ca-certificates gpg

# If the directory `/etc/apt/keyrings` does not exist, it should be created before the curl command, read the note below.
# sudo mkdir -p -m 755 /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

# This overwrites any existing configuration in /etc/apt/sources.list.d/kubernetes.list
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

#Configure containerd so that it starts using systemd as cgroup.
sudo curl -fsSL https://download.docker.com/linux/ubu... | sudo gpg --dearmour -o /etc/apt/trusted.gpg.d/docker.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

#Now, install containerd

sudo apt update && sudo apt install -y runc containerd.io 

containerd config default | sudo tee /etc/containerd/config.toml 
sudo sed -i 's/SystemdCgroup \= false/SystemdCgroup \= true/g' /etc/containerd/config.toml

sudo systemctl restart containerd && sudo systemctl enable containerd

# Install kubelet, kubeadm, and kubectl

sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl




# Initialize Kubernetes cluster
sudo kubeadm init --pod-network-cidr=10.244.0.0/16

# Copy kubeconfig to user's home directory
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Install Calico network plugin
kubectl apply -f https://docs.projectcalico.org/v3.11/manifests/calico.yaml

# Print join command for worker nodes
echo "Master node setup complete. Use the following command to join worker nodes to the cluster:"
kubeadm token create --print-join-command
