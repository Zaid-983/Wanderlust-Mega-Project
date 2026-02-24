#!/bin/bash
set -e

# Update packages
sudo apt-get update -y


mkdir -p /home/ubuntu/.ssh
echo '${tls_private_key.jenkins_key.private_key_pem}' > /home/ubuntu/.ssh/id_rsa
chmod 600 /home/ubuntu/.ssh/id_rsa
chown ubuntu:ubuntu /home/ubuntu/.ssh/id_rsa





# =============================
# Install & Configure Docker
# =============================
sudo apt-get install -y docker.io
sudo systemctl enable docker
sudo systemctl start docker
sudo usermod -aG docker ubuntu && newgrp docker

# =============================
# Install Java (Required for Jenkins)
# =============================
sudo apt-get install fontconfig openjdk-17-jre -y

# =============================
# Install Jenkins
# =============================
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" | \
sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y jenkins

# Start & Enable Jenkins
sudo systemctl enable jenkins
sudo systemctl start jenkins

