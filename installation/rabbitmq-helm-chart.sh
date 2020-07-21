git clone https://github.com/bitnami/charts.git ..

cd ../charts/bitnami/rabbitmq/

echo "Open values.yaml and change 'cluster_formation.k8s.host = kubernetes.default.svc.{{ .Values.clusterDomain }}' to cluster_formation.k8s.host = kubernetes"

