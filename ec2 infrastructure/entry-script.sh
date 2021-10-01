#!/bin/bash
sudo yum update -y && sudo yum install -y docker # -y means yes
sudo systemctl start docker
sudo usermod -aG docker ec2-user # add ec2-user to docker group
docker run -p 8080:80 nginx