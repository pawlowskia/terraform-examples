#!/bin/bash
apt-get update
apt-get install -y docker docker-compose-v2
systemctl start docker
systemctl enable docker
usermod -aG docker ubuntu
cd /home/ubuntu
git clone https://github.com/pwr-cloudprogramming/a5-pawlowskia.git
cd a5-pawlowskia
chmod 755 ipfinder.sh
./ipfinder.sh
docker compose up --build
