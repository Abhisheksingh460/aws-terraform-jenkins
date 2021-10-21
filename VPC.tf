provider "aws" {
  profile = "Abhishek"
  region  = "ap-south-1"
}

resource "aws_vpc" "newvpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = "true"
  enable_dns_support   = "true"
}

resource "aws_subnet" "publicsubnet" {
  vpc_id                  = aws_vpc.newvpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = "true"
}

resource "aws_subnet" "privatesubnet" {
  vpc_id            = aws_vpc.newvpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1b"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.newvpc.id
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.newvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

}

resource "aws_route_table_association" "routeasc" {
  subnet_id      = aws_subnet.publicsubnet.id
  route_table_id = aws_route_table.r.id
}

resource "aws_security_group" "sg_wp" {
  name   = "sg_wordpress"
  vpc_id = aws_vpc.newvpc.id
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }


  ingress {
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
    cidr_blocks = ["0.0.0.0/0"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Environment = "SGforWP"
    Name        = "security_group1"
  }

}

resource "aws_security_group" "sg_mysql" {
  name        = "sg_MYSQL"
  description = "managed by terrafrom for mysql servers"
  vpc_id      = aws_vpc.newvpc.id
  ingress {
    protocol        = "tcp"
    from_port       = 3306
    to_port         = 3306
    security_groups = ["${aws_security_group.sg_wp.id}"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "wordpress" {
  ami                    = "ami-06a0b4e3b7eb7a300"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.publicsubnet.id
  vpc_security_group_ids = ["${aws_security_group.sg_wp.id}"]
  key_name               = "mytfkey"
  
  tags = {
    Name = "word-Webserver"
  }
}

resource "aws_instance" "sqldatabase" {
  ami                    = "ami-06a0b4e3b7eb7a300"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.privatesubnet.id
  vpc_security_group_ids = ["${aws_security_group.sg_mysql.id}"]
  key_name               = "mytfkey"
  
  tags = {
    Name = "my-SQL"
  }
}
