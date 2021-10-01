provider "aws" {
    region = "us-east-1"
}

variable "vpc_cidr_block" {
    description = "vpc cidr block"
}

resource "aws_vpc" "development-vpc"{
    cidr_block = var.vpc_cidr_block
    tags = {
        Name: "development"
    }
}

variable "subnet_cider_block" {
    description = "subnet cidr block"
    default = "10.0.10.0/24"
    type = string # type can also be numbers, list, obj,etc
}

resource "aws_subnet" "dev-subnet-1"{
    vpc_id = aws_vpc.development-vpc.id
    cidr_block = var.subnet_cider_block
    availability_zone = "us-east-1a"
    tags = {
        Name: "development"
    }
}

data "aws_vpc" "existing_vpc" {
    default = true
}



resource "aws_subnet" "dev-subnet-2"{
    vpc_id = data.aws_vpc.existing_vpc.id
    cidr_block = "172.31.128.0/20"
    availability_zone = "us-east-1a"
    tags = {
        Name: "development2"
    }
}

output "dev-vpc-id" {
    value = aws_vpc.development-vpc.id
}