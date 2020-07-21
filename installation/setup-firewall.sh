sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow from 149.165.156.57 #use.jetstream-cloud.org
sudo ufw allow from 149.165.157.209 #use-staging.jetstream-cloud.org
sudo ufw allow from 149.165.238.143 # web shell host
sudo ufw allow from 149.165.171.189 # worker node
sudo ufw allow from 149.165.171.191 # master
sudo ufw allow from 172.16.35.13 # kubernetes master
sudo ufw enable
