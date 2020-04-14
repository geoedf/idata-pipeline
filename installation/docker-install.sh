#Install Docker CE
## Set up the repository:
### Install packages to allow apt to use a repository over HTTPS
sudo apt-get update && sudo apt-get install -y \
      apt-transport-https ca-certificates curl gnupg-agent software-properties-common

### Add Docker’s official GPG key
curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -

### Add Docker apt repository.
add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
        $(lsb_release -cs) \
          stable"

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

## Install Docker CE.
sudo apt-get update && sudo apt-get install docker-ce containerd.io

# Setup daemon.
cat > /etc/docker/daemon.json <<EOF
{
    "exec-opts": ["native.cgroupdriver=systemd"],
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "100m"
    },
    "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker
