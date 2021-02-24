layout: page
title: "Installation Instructions"
permalink: /install/

# File Pipeline Setup

Broadly, this involves three steps: first set up a cluster of nodes on OpenStack, then set up a Kubernetes cluster on those nodes, and finally install the pipeline Helm chart.

## Openstack Cluster Setup

_based on: [https://github.com/jlf599/JetstreamAPITutorial](https://github.com/jlf599/JetstreamAPITutorial)_

### Security Group

#### Create Security Group
`openstack security group create --description "GeoEDF pipeline security group" geoedf-security-group`

#### Allow SSH from anywhere
`openstack security group rule create --protocol tcp --dst-port 22:22 --remote-ip 0.0.0.0/0 geoedf-security-group`

#### Allow ICMP and ping packets
`openstack security group rule create --proto icmp geoedf-security-group`

#### Allow communication between nodes in the cluster
`openstack security group rule create --proto udp --dst-port 1:65535 --remote-ip 10.0.0.0/24 geoedf-security-group`
`openstack security group rule create --proto tcp --dst-port 1:65535 --remote-ip 10.0.0.0/24 geoedf-security-group`

#### Allow HTTP and HTTPS _(should probably make this more restrictive)_
`openstack security group rule create --protocol tcp --dst-port 80:80 --remote-ip 0.0.0.0/0 geoedf-security-group`
`openstack security group rule create --protocol tcp --dst-port 443:443 --remote-ip 0.0.0.0/0 geoedf-security-group`

#### Allow connections to AMQP port _(should probably make this more restrictive)_
`openstack security group rule create --protocol tcp --dst-port 5672:5672 --remote-ip 0.0.0.0/0 geoedf-security-group`

### SSH key

#### Create SSH key to be used to connect to instances
`ssh-keygen -b 2048 -t rsa -f geoedf-api-key -P ""`

#### Upload to Openstack
`openstack keypair create --public-key geoedf-api-key.pub geoedf-api-key`

### Network

#### Create network
`openstack network create geoedf-api-net`

#### Create subnet attached to this network
`openstack subnet create --network geoedf-api-net --subnet-range 10.0.0.0/24 geoedf-api-subnet`

#### Create router
`openstack router create geoedf-api-router`

#### Attach subnet to router
`openstack router add subnet geoedf-api-router geoedf-api-subnet`

#### Attach router to “public” network
`openstack router set --external-gateway public geoedf-api-router`

### Servers

#### Create master and _two_ workers
`openstack server create geoedf-api-master --flavor m1.medium --image JS-API-Featured-Ubuntu18-Latest --key-name geoedf-api-key --security-group geoedf-security-group --nic net-id=geoedf-api-net --wait`
`openstack server create geoedf-api-worker1 --flavor m1.medium --image JS-API-Featured-Ubuntu18-Latest --key-name geoedf-api-key --security-group geoedf-security-group --nic net-id=geoedf-api-net --wait`
`openstack server create geoedf-api-worker2 --flavor m1.medium --image JS-API-Featured-Ubuntu18-Latest --key-name geoedf-api-key --security-group geoedf-security-group --nic net-id=geoedf-api-net --wait`

#### Create _public_ floating IPs _(as many nodes as you created, plus two more for an externally accessible IP assigned by LoadBalancer)_
`openstack floating ip create public` x 5

#### Attach floating IP to servers
`openstack server add floating ip geoedf-api-master <IP-address>`

#### Create ports (_private IPs_) that can be provided to the LoadBalancer _(as many as you have free floating IPs, although you only need as many as the LoadBalancer services you will be exposing)_
`openstack port create --network geoedf-api-net geoedf-svc1`
`openstack port create --network geoedf-api-net geoedf-svc2`

#### Attach free floating IPs to these newly created ports (i.e., bind public and private IPs)
`openstack floating ip set --port geoedf-svc1 <floating IP address>` x n times

#### MetalLB **magic** set the free ports as _allowed-addresses_ on the servers’ ports (i.e. fixed IPs); _this will ensure that when MetalLB uses these free ports/fixed IPs for the load balanced services, they are attached to an actual node where the pod is running; external access to these services is then through the public floating IPs_
`openstack port set --allowed-address ip-address=<port IP> <server's port ID>` x repeat for each server and free port combination

---- this completes the Openstack setup process

## Kubernetes Cluster Setup
Based on [https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)

### Master Setup
1. SSH into the master and run the steps at the link above to install kubeadm
2. Ensure docker is installed/running - _okay to have this only accessible by sudo_
3. First enable the Docker service: `systemctl enable docker.service`
4. Initialize the cluster `kubeadm init` as root
5. Copy the command to join worker nodes _(you can find the command later too by running `kubeadm token create --print-join-command`_
6. Allow kubernetes commands to be run by non-root user by setting up kubecube config for the non-root user
7. Install a network add-on, we will use Weave: [https://www.weave.works/docs/net/latest/kubernetes/kube-addon/#install](https://www.weave.works/docs/net/latest/kubernetes/kube-addon/#install)
8. Install Helm: [https://helm.sh/docs/intro/install/](https://helm.sh/docs/intro/install/)

### Worker Setup _(for each worker)_

#### Install kubeadm and join cluster
1. SSH into each worker and install kubeadm (as in master above) **do not do the init step**
2. Run the join command to join this worker

#### Verify that nodes have joined the cluster
Run `kubectl get nodes` on master to check that all nodes show up

#### Setup mounts/folders for service data files 
1. Create directories /data/rabbitmq and /srv/idata
2. Mount idata files (data.rcac.purdue.edu:/depot/ssg/geoedf) at /srv/idata using SSHFS
	1. Generate SSH key and add to c4e4user `authorized_keys`
	2. `sshfs -o allow_other,default_permissions,IdentityFile=~/.ssh/depot c4e4user@data.rcac.purdue.edu:/depot/ssg/geoedf /srv/idata`

---- this completes the Kubernetes cluster setup

## Pipeline Helm chart setup

### MetalLB setup

We will set up MetalLB separately since it requires updates to the _kube-proxy_ and a first time key

Follow instructions at: [https://metallb.universe.tf/installation/](https://metallb.universe.tf/installation/)

*the MetalLB config, providing the address space for LoadBalancer services will be set up as part of the Helm chart*

### Certificate setup

We will be using HTTPS to access services such as the RabbitMQ management console and the QGIS map server. This is especially important in the latter case since browsers will refuse to serve mixed content when maps are embedded in other web applications (e.g. file preview).

#### Certificate generation
Follow instructions at [https://certbot.eff.org/](https://certbot.eff.org/) to set up a certificate for your chosen domain (in our case, this is _www.pipeline.geoedf.org_). 

**Note: you need to have nginx running (temporarily) wherever you set this up. Our suggestion is to use the Kubernetes master node**

#### DNS records
We will use _www.pipeline.geoedf.org_ as the domain name for accessing the external services. We need to add DNS records (for e.g., in domains.google) to bind the **free** floating IPs to this domain. 

**the free ports will be assigned as LoadBalancer service IPs and externally accessible via the floating IPs bound to them, hence our strategy of creating a DNS record for these floating IPs**

### Updates to YAML files

Most of the updates will be in the _values.yaml_ file. However, some updates are needed in the deployment YAML files.

#### dep-charts/ingress/templates/metallb-config.yaml
We use the _layer2_ option in MetalLB. Update the address pool with the free port IPs that were created earlier. Since these are specific IP addresses, use the CIDR notation: _\<IP-address\>/32_

#### dep-charts/ingress/templates/geoedf-pipeline-tls.yaml
We use a TLS secret to inject the certificate that we previously created into the ingress resources and the NGINX config for the QGIS server. Paste in the base64 encoded contents of the certificate chain and the key into this secret file.

#### values.yaml
This is the values file for the top-level _idata-pipeline_ chart. Make sure to update the `hostname` and `rabbitmq_password` as needed. Also, ensure that the data paths correspond to the mounts created previously. `idata_path` needs to correspond to where the iData files will be available on the worker nodes; `persistence_path` needs to correspond to the directory under which a _rabbitmq_ directory was created in the mount step.

### Installation

#### Dependency Update
Before installation, we need to pull in the Bitnami RabbitMQ chart and ensure that the various dependencies for the pipeline are set up. To accomplish this, run: `helm dependency update .` first in the `dep-charts/rmq` folder and then in the top-level folder.

Certain files will be installed first since other resources are dependent on them. Specifically, the _ingress-nginx_ namespace and the _load-definition_ secret are created first by annotating them with a _pre-install_ hook. 

**Note: these resources may not be removed when the Helm release is deleted. You may need to delete them manually, if a subsequent Helm install complains about them already existing.**

Install the Helm chart as usual: `helm install geoedf .`

**Note: the /data/rabbitmq/ directory in the worker nodes may need to be emptied out when attempting a reinstall of the chart. It is not yet clear if this is always required or only in certain error conditions.**

---- this completes the Helm chart install
