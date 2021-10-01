provider "aws" {
    region = "us-east-1"
}

variable cidr_blocks {}
variable subnet_cidr_block {}
variable avail_zone {}
variable env_prefix {}
variable my_ip{}
variable instance_type{}
variable public_key_location{}
variable private_key_location {}
# create a new vpc
resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.cidr_blocks
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

# create a new subnet
resource "aws_subnet" "myapp-subnet-1" {
    vpc_id = aws_vpc.myapp-vpc.id
    cidr_block = var.subnet_cidr_block
    availability_zone = var.avail_zone
    tags = {
        Name: "${var.env_prefix}-subnet-1"
    }
}

# create a new route table
resource "aws_route_table" "myapp-route-table" {
    vpc_id = aws_vpc.myapp-vpc.id

    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.myapp-igw.id
    }

    tags = {
        Name: "${var.env_prefix}-rtb"
    }
}

# create a internet gateway for the VPC
resource "aws_internet_gateway" "myapp-igw" {
    vpc_id = aws_vpc.myapp-vpc.id
    tags = {
        Name: "${var.env_prefix}-rtb"
    }
}

# associate the aws route table with the subnet that just got created
resource "aws_route_table_association" "a-rtb-subnet" {
    subnet_id = aws_subnet.myapp-subnet-1.id
    route_table_id = aws_route_table.myapp-route-table.id
}

# configure the security group
# open port 22 and 8080 as inbound rule for ssh and web app
# open port for all as outbound rule for the instance to have access to internet
resource "aws_security_group" "myapp-sg" {
    name = "myapp-sg"
    vpc_id = aws_vpc.myapp-vpc.id

    ingress {
        from_port = 22
        to_port = 22 # a range, from 22 to 22
        protocol = "tcp"
        cidr_blocks = [var.my_ip] # list of IP address allowed to access the server
    }

    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        prefix_list_ids = []
    }
    tags = {
        Name: "${var.env_prefix}-sg"
    }
}

# get the image you expected
data "aws_ami" "latest-amazon-linux-image"{
    most_recent = true
    owners = ["amazon"]
    filter {
        name = "name"
        values = ["amzn2-ami-hvm-*-x86_64-gp2"]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}
# output the image id
output "aws_ami_id" {
    value = data.aws_ami.latest-amazon-linux-image.id
}

resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = "${file(var.public_key_location)}"
}
resource "aws_instance" "myapp-server"{
    ami = data.aws_ami.latest-amazon-linux-image.id
    # create the instance
    instance_type = var.instance_type
    subnet_id = aws_subnet.myapp-subnet-1.id
    vpc_security_group_ids = [aws_security_group.myapp-sg.id]
    availability_zone = var.avail_zone
    associate_public_ip_address = true # asscociate public ip to the server so that we could ssh to it

    #key_name = "demo tutorial" # use pem file to ssh to the server
    key_name = aws_key_pair.ssh-key.key_name # now you don't have to ssh with a pem file

    # run nginx docker container in the ec2-user
    # user_data = file("entry-script.sh")
    # user_data = <<EOF
    #                 #!/bin/bash
    #                 sudo yum update -y && sudo yum install -y docker # -y means yes
    #                 sudo systemctl start docker
    #                 sudo usermod -aG docker ec2-user # add ec2-user to docker group
    #                 docker run -p 8080:80 nginx
    #             EOF
    connection {
        type = "ssh"
        host = self.public_ip
        user = "ec2-user"
        private_key = file(var.private_key_location)
    }

    provisioner "file" {
        source = "entry-script.sh"
        destination = "/home/ec2-user/entry-script.sh"
    }
    # provisioner "remote-exec" {
    #     inline = [
    #         "export ENV=dev",
    #         "mkdir newdir",
    #     ]
    # }

    # you can send a file to another server as well using following command
    # provisioner "file" {
    #     source = "entry-script.sh"
    #     destination = "/home/ec2-user/entry-script.sh"

    #     connection {
    #     type = "ssh"
    #     host = someotherserver.public_ip
    #     user = "ec2-user"
    #     private_key = file(var.private_key_location)
    #     }
    # }

    provisioner "remote-exec" {
        script = file("/home/ec2-user/entry-script.sh")
    }
    tags = {
        Name: "${var.env_prefix}-server"
    }

    # run command on your local laptop
    provisioner "local-exec" {
        command = "echo ${self.public_ip} > ~/Desktop/output.txt"
    }
}

output "ec2_public_ip" {
    value = aws_instance.myapp-server.public_ip
}