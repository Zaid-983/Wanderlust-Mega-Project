#!/bin/bash
set -e


mkdir -p /home/ubuntu/.ssh
echo '${tls_private_key.jenkins_key.public_key_openssh}' >> /home/ubuntu/.ssh/authorized_keys
chmod 600 /home/ubuntu/.ssh/authorized_keys
chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
              
# Update packages
sudo apt-get update -y

sudo apt install fontconfig openjdk-17-jre -y