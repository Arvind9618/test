/* create vpc, create 2 subnets, create 2 routetables and
attach one with one subnet and igw and another with another subnet
and attach it to private nat */

variable "vpc1_cidr" {
   default = "10.0.0.0/24"
}

  
variable "sn_cidr" {
   type = list
   default = ["10.0.0.0/25","10.0.0.128/25"]
}

variable "v_sn_azs" {
   type = list(any)
   default = ["eu-west-2a","eu-west-2b"]
}

resource "aws_vpc" "vpc1" {
    cidr_block = var.vpc1_cidr
	
	tags = {
    Name = "vpc"
  }
}

resource "aws_subnet" "sn" {
    count = length(var.v_sn_azs)
	vpc_id = aws_vpc.vpc1.id
	cidr_block = var.sn_cidr[count.index]
	tags = {
    Name = "sn"
  }
}
  
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc1.id

  tags = {
    Name = "main"
  }
}

resource "aws_route_table" "rt1" {
  vpc_id = aws_vpc.vpc1.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "rt1"
  }
}
resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.sn[0].id
  route_table_id = aws_route_table.rt1.id
}

resource "aws_route_table" "rt2" {
  vpc_id = aws_vpc.vpc1.id
  
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "rt2"
  }
}

resource "aws_nat_gateway" "nat" {
  connectivity_type = "private"
  subnet_id     = aws_subnet.sn[1].id

  tags = {
    Name = "gw NAT"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw]
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.sn[1].id
  route_table_id = aws_route_table.rt2.id

}