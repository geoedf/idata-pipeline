echo "kubeadmin init"
sudo kubeadm init

echo "export config"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown 1000:1000 $HOME/.kube/config
export KUBECONFIG=$HOME/.kube/config

# configure networking for single node
#kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml

echo "install weavenet (pod network)"
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

# Install Weave Net (pod network)
#sudo sysctl net.bridge.bridge-nf-call-iptables=1
#kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n')"

#wait 12s
echo "verify coreDNS pod is running"
kubectl get pods --all-namespaces

