
provider "aws" {
  region = "ap-south-1"

}

variable "vpc_cidr" {}
variable "env" {}
variable "open" {}
variable "availability_zone" {}
variable "key_name" {}
variable "key" {}

resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr
  tags = {
    Name = "${var.env}-vpc"
  }

}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = var.availability_zone
  tags = {
    Name = "${var.env}-subnet"
  }

}

resource "aws_internet_gateway" "my_gateway" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "${var.env}-gateway"
  }

}
resource "aws_route_table" "my_route" {
  vpc_id = aws_vpc.my_vpc.id
  route {
    cidr_block = var.open
    gateway_id = aws_internet_gateway.my_gateway.id
  }

}

resource "aws_route_table_association" "my_association" {
  subnet_id      = aws_subnet.my_subnet.id
  route_table_id = aws_route_table.my_route.id

}

resource "aws_security_group" "my_security" {
  name   = "karthik-sg"
  vpc_id = aws_vpc.my_vpc.id

  ingress {
    from_port   = 0
    to_port     = 65000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = -1
    cidr_blocks     = ["0.0.0.0/0"]
    prefix_list_ids = []
  }

}

data "aws_ami" "choose-ami" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_key_pair" "my-key" {
  key_name   = var.key_name
  public_key = file(var.key)

}
resource "aws_instance" "my_instance" {
  ami                         = data.aws_ami.choose-ami.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.my_subnet.id
  vpc_security_group_ids      = [aws_security_group.my_security.id]
  key_name                    = aws_key_pair.my-key.key_name
  associate_public_ip_address = true

  #user_data = file("bash.sh")
  connection {
    type        = "ssh"
    host        = self.public_ip
    user        = "ec2-user"
    private_key = file("~/.ssh/id_rsa")
  }

  provisioner "file" {
    source      = "bash.sh"
    destination = "/home/ec2-user/bash.sh"

  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/ec2-user/bash.sh",
      "/home/ec2-user/bash.sh"
    ]
    # inline = [
    #   "mkdir hello"
    # ]

  }

  provisioner "local-exec" {
    command = "echo ${aws_instance.my_instance.public_ip} >> public.txt"
  }
}




output "public_ip" {
  value = aws_instance.my_instance.public_ip

}
