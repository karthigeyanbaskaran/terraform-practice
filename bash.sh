#!/bin/bash
sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo useradd -aG docker ec2-user
sudo docker run -p 8080:80 nginx