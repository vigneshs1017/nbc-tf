 resource "aws_vpc" "nbc_vpc" {         
   cidr_block       = var.vpc_cidr    
   instance_tenancy = "default"
   enable_dns_hostnames = "true"
   enable_dns_support = "true"
   tags = {
    Name = "${var.name}-vpc"
  }
 }
 
 resource "aws_internet_gateway" "IGW" {   
    vpc_id =  aws_vpc.nbc_vpc.id  
    tags = {
      Name = "${var.name}-IGW"
  }             
 }

 resource "aws_subnet" "publicsubnets" {  
   count = length(var.public_subnets)  
   vpc_id =  aws_vpc.nbc_vpc.id
   availability_zone = var.availability_zone[count.index]
   map_public_ip_on_launch = true
   cidr_block = var.public_subnets[count.index]
   tags = {
    Name = "${var.name}-public-sub-${count.index+1}"
  }
 }
                
 resource "aws_subnet" "privatesubnets" {
   count = length(var.private_subnets)
   vpc_id =  aws_vpc.nbc_vpc.id
   availability_zone = var.availability_zone[count.index]
   cidr_block = var.private_subnets[count.index]         
   tags = {
    Name = "${var.name}-private-sub-${count.index+1}"
  }
 }
 
 resource "aws_route_table" "PublicRT" {    
    vpc_id =  aws_vpc.nbc_vpc.id
    route {
    cidr_block = "0.0.0.0/0"              
    gateway_id = aws_internet_gateway.IGW.id
     }
    tags = {
     Name = "${var.name}-public-RT"
  }
    
 }

 resource "aws_route_table" "PrivateRT" {  
   vpc_id = aws_vpc.nbc_vpc.id
   route {
    cidr_block = "0.0.0.0/0"             
    nat_gateway_id = aws_nat_gateway.NATgw.id
   }
   tags = {
     Name = "${var.name}-private-RT"
  }
 }

 resource "aws_route_table_association" "PublicRTassociation" {
    count = length(var.public_subnets)
    subnet_id = aws_subnet.publicsubnets[count.index].id
    route_table_id = aws_route_table.PublicRT.id
 }

 resource "aws_route_table_association" "PrivateRTassociation" {
    count = length(var.private_subnets)
    subnet_id = aws_subnet.privatesubnets[count.index].id
    route_table_id = aws_route_table.PrivateRT.id
 }
 resource "aws_eip" "nateIP" {
   vpc   = true
   tags = {
     Name = "${var.name}"
  }
 }
 
 resource "aws_nat_gateway" "NATgw" {
   allocation_id = aws_eip.nateIP.id
   subnet_id = aws_subnet.publicsubnets[0].id
   tags = {
     Name = "${var.name}"
  }
 }