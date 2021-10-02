
# configure the security group
# open port 22 and 8080 as inbound rule for ssh and web app
# open port for all as outbound rule for the instance to have access to internet
resource "aws_security_group" "myapp-sg" {
    name = "myapp-sg"
    vpc_id = var.vpc_id

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
        values = [var.image_name]
    }
    filter {
        name = "virtualization-type"
        values = ["hvm"]
    }
}

resource "aws_key_pair" "ssh-key" {
    key_name = "server-key"
    public_key = "${file(var.public_key_location)}"
}
resource "aws_instance" "myapp-server"{
    ami = data.aws_ami.latest-amazon-linux-image.id
    # create the instance
    instance_type = var.instance_type
    subnet_id = var.subnet_id
    vpc_security_group_ids = [aws_security_group.myapp-sg.id]
    availability_zone = var.avail_zone
    associate_public_ip_address = true # asscociate public ip to the server so that we could ssh to it

    #key_name = "demo tutorial" # use pem file to ssh to the server
    key_name = aws_key_pair.ssh-key.key_name # now you don't have to ssh with a pem file

    # run nginx docker container in the ec2-user
    user_data = file("entry-script.sh")
    tags = {
        Name: "${var.env_prefix}-server"
    }
}
