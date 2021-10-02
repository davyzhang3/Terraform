provider "aws" {
    region = "us-east-1"
}

resource "aws_vpc" "myapp-vpc" {
    cidr_block = var.cidr_blocks
    tags = {
        Name: "${var.env_prefix}-vpc"
    }
}

# create a new subnet
# The variable in the following module takes values form terraform.tfvars from root directory
# Then it pass the value to the variables.tf in modules/subnets
module "myapp-subnet" {
    source = "./modules/subnet"
    subnet_cidr_block = var.subnet_cidr_block
    avail_zone = var.avail_zone
    env_prefix = var.env_prefix
    vpc_id = aws_vpc.myapp-vpc.id
}

module "myapp-server" {
    source = "./modules/webserver"
    vpc_id = aws_vpc.myapp-vpc.id
    my_ip = var.my_ip
    env_prefix = var.env_prefix
    image_name = var.image_name
    instance_type = var.instance_type
    public_key_location = var.public_key_location
    subnet_id = module.myapp-subnet.subnet.id #myapp-subnet is the module name, subnet is the output of that module
    avail_zone = var.avail_zone
}