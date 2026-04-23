# #!/bin/bash
# set -e


# mkdir -p /home/ubuntu/.ssh
# echo '${tls_private_key.jenkins_key.public_key_openssh}' >> /home/ubuntu/.ssh/authorized_keys
# chmod 600 /home/ubuntu/.ssh/authorized_keys
# chown ubuntu:ubuntu /home/ubuntu/.ssh/authorized_keys
              
# # Update packages
# sudo apt-get update -y

# sudo apt install fontconfig openjdk-17-jre -y

# # =========================
# # Jenkins Master Node
# # =========================
# resource "aws_instance" "jenkins_agent" {
#   ami             = var.ami_id
#   instance_type   = var.instance_type
#   key_name        = aws_key_pair.deployer.key_name
#   security_groups = [aws_security_group.allow_user_to_connect.name]
#   user_data       = file("userdata-agent.sh")

#   tags = {
#     Name = "Jenkins-Agent"
#   }

#   root_block_device {
#     volume_size = 30
#     volume_type = "gp3"
#   }
# }