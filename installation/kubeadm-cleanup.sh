echo "enter a node name to delete"
read nodename
echo "deleting $nodename"
kubectl drain $nodename --delete-local-data --force --ignore-daemonsets
kubectl delete node $nodename

echo "trigger a best-effort control pane clean up"
kubeadm reset

echo "reset iptables"
iptables -F && iptables -t nat -F && iptables -t mangle -F && iptables -X

echo "reset the IPVS tables"
ipvsadm -C

echo "remove config"
rm $HOME/.kube/config
