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
sudo usermod -aG docker ubuntu && newgrp docker
sudo systemctl enable docker
sudo systemctl start docker


# # =============================
# # Install Java (Required for Jenkins)
# # =============================

# # sudo apt-get install fontconfig openjdk-17-jre -y

# # # =============================
# # # Install Jenkins
# # # =============================
# # sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
# #   https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

# # echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] \
# # https://pkg.jenkins.io/debian-stable binary/" | \
# # sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null

# # sudo apt-get update -y
# # sudo apt-get install -y jenkins

# # # Start & Enable Jenkins
# # sudo systemctl enable jenkins
# # sudo systemctl start jenkins


# # =============================
# # AWS cli installing 
# # =============================

# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# sudo apt install unzip
# unzip awscliv2.zip
# sudo ./aws/install

# # =============================
# # Kubectl installing 
# # =============================

# curl -o kubectl https://amazon-eks.s3.us-west-2.amazonaws.com/1.19.6/2021-01-05/bin/linux/amd64/kubectl
# chmod +x ./kubectl
# sudo mv ./kubectl /usr/local/bin
# kubectl version --short --client


# # =============================
# # eksctl installing 
# # =============================

# curl --silent --location "https://github.com/weaveworks/eksctl/releases/latest/download/eksctl_$(uname -s)_amd64.tar.gz" | tar xz -C /tmp
# sudo mv /tmp/eksctl /usr/local/bin
# eksctl version


# # =============================
# # Verifying installations 
# # =============================

# echo "Verifying installations..."
# kubectl version --client
# eksctl version
# aws --version


# # =============================
# # Sonar installation  
# # =============================

# docker run -itd --name SonarQube-Server -p 9000:9000 sonarqube:lts-community

# # =============================
# # trivy  installations 
# # =============================

# sudo apt-get install wget apt-transport-https gnupg lsb-release -y
# wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | sudo apt-key add -
# echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | sudo tee -a /etc/apt/sources.list.d/trivy.list
# sudo apt-get update -y
# sudo apt-get install trivy -y


# echo "All tools installed successfully!"