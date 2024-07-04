provider "aws" {
  region                   = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "my_vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.101.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.102.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private_subnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    name = "my_igw"
  }
}

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

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "server_sg" {
  name        = "server_security"
  description = "allow ssh, http traffic"
  vpc_id      = aws_vpc.my_vpc.id


  ingress {
    description = "HTTP Backend"
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP Frontend"
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
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sg"
  }
}

resource "aws_elastic_beanstalk_application" "app" {
  name        = "ttc-pawlowski"
  description = "Tic Tac Toe app using Elastic Beanstalk"
}

resource "aws_elastic_beanstalk_environment" "env" {
  name                = "ttc-env"
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = "64bit Amazon Linux 2023 v4.3.2 running Docker"
  version_label       = aws_elastic_beanstalk_application_version.version.name
  cname_prefix        = "pawlowski-ttc"

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.my_vpc.id
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "LabInstanceProfile"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = join(",", [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id])
  }

  setting {
    namespace = "aws:ec2:vpc"
    name = "AssociatePublicIpAddress"
    value = "true"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "SecurityGroups"
    value     = aws_security_group.server_sg.id
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "EnvironmentType"
    value     = "LoadBalanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name = "ServiceRole"
    value = "arn:aws:iam::654654145459:role/LabRole"
  }

  setting {
    namespace = "aws:ec2:instances"
    name = "SupportedArchitectures"
    value = "x86_64"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name = "InstanceType"
    value = "t2.small"
  }
}


resource "aws_s3_bucket" "app_bucket" {
  bucket = "pawlowski-ttc"
}


resource "aws_s3_object" "app_s3o" {
  bucket = aws_s3_bucket.app_bucket.bucket
  key = "appcompose.zip"
  source = "appcompose.zip"
}

resource "aws_elastic_beanstalk_application_version" "version" {
  name        = "v1"
  application = aws_elastic_beanstalk_application.app.name
  description = "Initial version"

  bucket = aws_s3_bucket.app_bucket.bucket
  key    = aws_s3_object.app_s3o.key
}
