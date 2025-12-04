#!/bin/bash
# This script can be used in EC2 User Data or run manually to setup the server

# Update system
yum update -y

# Install Docker
yum install -y docker

# Start Docker service
service docker start

# Add ec2-user to docker group so sudo isn't needed
usermod -a -G docker ec2-user

# Enable Docker to start on boot
chkconfig docker on

# Install AWS CLI v2 (if not present on AMI)
if ! command -v aws &> /dev/null
then
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install
fi

echo "EC2 Setup Complete. Please logout and login again for group changes to take effect."
