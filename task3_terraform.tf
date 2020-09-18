provider "aws" {
  region  = "ap-south-1"
  profile = "shivi"
}
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.1.0.0/16"
  enable_dns_support= true
  enable_dns_hostnames= true
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public-subnet" {
  vpc_id     = "${aws_vpc.my_vpc.id}"
  cidr_block = "10.1.0.0/24"
  map_public_ip_on_launch= true
  availability_zone = "ap-south-1a"
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_subnet" "private-subnet" {
  vpc_id     = "${aws_vpc.my_vpc.id}"
  cidr_block = "10.1.1.0/24"
  map_public_ip_on_launch= true
  availability_zone = "ap-south-1a"
  tags = {
    Name = "private-subnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.my_vpc.id}"
  tags = {
    Name = "NATgateway"
  }
}

resource "aws_route_table" "route-table" {
  vpc_id = "${aws_vpc.my_vpc.id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
  tags = {
    Name = "rtable"
  }
}
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.route-table.id
}

resource "aws_security_group" "wp-security" {
  name        = "allow_http"
  description = "Allow http inbound traffic"
  vpc_id      = "${aws_vpc.my_vpc.id}"

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

resource "aws_security_group" "mysql-security" {
  name        = "mysql_sg"
  description = "mysql security group"
  vpc_id      = "${aws_vpc.my_vpc.id}"

  ingress {
    description = "mysql server"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mysql_sg"
  }
}

resource "aws_instance" "wordpress" {
  ami           = "ami-000cbce3e1b899ebd"
  instance_type = "t2.micro"
  key_name      = "SecKey"
  subnet_id     = "${aws_subnet.public-subnet.id}"
  security_groups = [ "${aws_security_group.wp-security.id}" ]
  availability_zone = "ap-south-1a"
  tags = {
    Name = "ec2 wordpress"
  }
  depends_on = [aws_instance.mysql]
}

resource "aws_instance" "mysql" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name      = "SecKey"
  subnet_id     = "${aws_subnet.private-subnet.id}"
  security_groups = [ "${aws_security_group.wp-security.id}" ]
  availability_zone = "ap-south-1a"
  tags = {
    Name = "ec2 mysql"
  }
}



