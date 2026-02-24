# Generate SSH key pair for Jenkins Master ↔ Agent communication
resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# Save private key locally so Jenkins master can use it
resource "local_sensitive_file" "private_key" {
  content         = tls_private_key.jenkins_key.private_key_pem
  filename        = "${path.module}/jenkins-master-key.pem"
  file_permission = "0400"
  
  }



resource "aws_key_pair" "deployer" {
  key_name   = "terra-automate-key"
  public_key = file("/Users/dawoodsiddique/Downloads/jen-key.pub")
}
resource "aws_default_vpc" "default" {

}

resource "aws_security_group" "allow_user_to_connect" {
  name        = "allow TLS"
  description = "Allow user to connect"
  vpc_id      = aws_default_vpc.default.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SonarQube"
    from_port   = 9000
    to_port     = 9000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outgoing traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysecurity"
  }
}

# =========================
# Jenkins Master Node
# =========================
resource "aws_instance" "jenkins_master" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.allow_user_to_connect.name]
  user_data       = file("userdata-master.sh")

  tags = {
    Name = "Jenkins-Master"
  }

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }
}

# =========================
# Jenkins Agent Node
# =========================
resource "aws_instance" "jenkins_agent" {
  ami             = var.ami_id
  instance_type   = var.instance_type
  key_name        = aws_key_pair.deployer.key_name
  security_groups = [aws_security_group.allow_user_to_connect.name]
  user_data       = file("userdata-agent.sh")

  tags = {
    Name = "Jenkins-Agent"
  }

  root_block_device {
    volume_size = 12
    volume_type = "gp3"
  }
}
