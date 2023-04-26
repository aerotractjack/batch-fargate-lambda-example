########################
# NETWORKING RESOURCES #
########################

# public subnet #2, same reason as #1
# serves as a duplicate for fault-tolerance
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "aerotract-main-vpc"
  }
}

# public subet #1, allows VPC to communicate with internet
# we need this to access ECR
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-1a"
  tags = {
    Name = "${local.name}-public-sn-a"
  }
}

# public subnet #2, same reason as #1
# serves as a duplicate for fault-tolerance
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-1b"
  tags = {
    Name = "${local.name}-public-sn-b"
  }
}

# public internet gateway for VPC
resource "aws_internet_gateway" "public_igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.name}-public-igw"
  }
}

# public route table to route IGW through subnets
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.public_igw.id
  }
  depends_on = [
    aws_internet_gateway.public_igw
  ]
  tags = {
    Name = "${local.name}-public-rt"
  }
}

# associate the IGW with our public #1 subnet
resource "aws_route_table_association" "public_rt_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public_rt.id
}

# associate the IGW with our public #2 subnet
resource "aws_route_table_association" "public_rt_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public_rt.id
}

# private subnet #1, allows Batch to communicate with services
# we use this for S3
resource "aws_subnet" "private_a" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone = "us-west-1a"
  tags = {
    Name = "${local.name}-private-sn-a"
  }
}

# private subnet #2, same reason as #1
# serves as a duplicate for fault-tolerance
resource "aws_subnet" "private_b" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = false
  availability_zone = "us-west-1b"
  tags = {
    Name = "${local.name}-private-sn-b"
  }
}

# vpc endpoint to access S3 service
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = aws_vpc.main.id
  service_name = "com.amazonaws.us-west-1.s3"
  route_table_ids = [aws_route_table.private_rt.id]
  tags = {
    Name = "${local.name}-s3-endpoint"
  }
}

# private route table to route traffic for AWS services used by batch
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "${local.name}-private-rt"
  }
}

# associate the private route table with our private #1 subnet
resource "aws_route_table_association" "private_rt_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private_rt.id
}

# associate the private route table with our private #2 subnet
resource "aws_route_table_association" "private_rt_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private_rt.id
}