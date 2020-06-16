echo "enter a node name to delete"
read nodename
echo "deleting $nodename"
kubectl drain $nodename --delete-local-data --force --ignore-daemonsets
kubectl delete node $nodename

