# VPC Principal
resource "aws_vpc" "lms_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "lms-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.lms_vpc.id

  tags = {
    Name = "lms-igw"
  }
}


# Subnets Públicas (ALB, NAT Gateway)
resource "aws_subnet" "public_az1" {
  vpc_id                  = aws_vpc.lms_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.myregion}a"
  map_public_ip_on_launch = true

  tags = {
    Name = "lms-public-az1"
    Type = "Public"
  }
}

resource "aws_subnet" "public_az2" {
  vpc_id                  = aws_vpc.lms_vpc.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "${var.myregion}b"
  map_public_ip_on_launch = true

  tags = {
    Name = "lms-public-az2"
    Type = "Public"
  }
}


# Subnets Privadas (ECS Fargate, Aurora, ElastiCache)
resource "aws_subnet" "private_az1" {
  vpc_id            = aws_vpc.lms_vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.myregion}a"

  tags = {
    Name = "lms-private-az1"
    Type = "Private"
  }
}

resource "aws_subnet" "private_az2" {
  vpc_id            = aws_vpc.lms_vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "${var.myregion}b"

  tags = {
    Name = "lms-private-az2"
    Type = "Private"
  }
}

# NAT Gateway (para que subnets privadas accedan a internet)
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "lms-nat-eip"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_az1.id

  tags = {
    Name = "lms-nat-gateway"
  }

  depends_on = [aws_internet_gateway.igw]
}


# Route Tables

# Route Table Pública
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.lms_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "lms-public-rt"
  }
}

# Route Table Privada
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.lms_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "lms-private-rt"
  }
}

# Asociaciones Route Table - Subnets Públicas
resource "aws_route_table_association" "public_az1" {
  subnet_id      = aws_subnet.public_az1.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public_az2" {
  subnet_id      = aws_subnet.public_az2.id
  route_table_id = aws_route_table.public.id
}

# Asociaciones Route Table - Subnets Privadas
resource "aws_route_table_association" "private_az1" {
  subnet_id      = aws_subnet.private_az1.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private_az2" {
  subnet_id      = aws_subnet.private_az2.id
  route_table_id = aws_route_table.private.id
}