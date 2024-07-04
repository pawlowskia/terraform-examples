provider "aws" {
  region = "us-east-1"
}

# vpc creation
resource "aws_vpc" "my_vpc" {
	cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
	
	tags = {
		Name = "my_vpc"
	}
}

# vpc subnets
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.101.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"
  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id = aws_vpc.my_vpc.id
  cidr_block = "10.0.102.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private_subnet"
  }
}

# internet gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    name = "my_igw"
  }
}

# route table
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_route_table"
  }
}

# route table assotiation with public subnet
resource "aws_route_table_association" "public" {
  subnet_id = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# security groups
resource "aws_security_group" "ttc" {
  name        = "ttc_security"
  description = "allow ssh, http traffic"
  vpc_id      =  aws_vpc.my_vpc.id

  ingress {
    description = "HTTP"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks =  ["0.0.0.0/0"]
  }
  
  tags = {
    Name = "sg"
  }
}

# ec2 instances
resource "aws_instance" "ttc" {
  ami                         = "ami-080e1f13689e07408"
  instance_type               = "t2.micro"
  key_name                    = "vockey"
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = "true"
  vpc_security_group_ids      = [aws_security_group.ttc.id]
  user_data_replace_on_change = true
  user_data = file("user_data.sh")
  tags = {
    Name = "TicTacToe"
  }
}

output "ttc_public_ip" {
  value = aws_instance.ttc.public_ip
}
