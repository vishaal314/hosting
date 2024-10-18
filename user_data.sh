#!/bin/bash
# user_data.sh

# Update system packages
apt-get update -y

# Install Docker
apt-get install docker.io -y

# Start Docker service
systemctl start docker
systemctl enable docker

# Pull and run the Nginx container
docker run -d -p 80:80 nginx
