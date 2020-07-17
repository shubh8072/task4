provider "aws" {
  region     = "ap-south-1"
  profile = "shubhgupta94"
}
data "aws_availability_zones" "available" {
  state = "available"
}
resource "aws_vpc" "sh_vpc" {
  cidr_block       = "192.162.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "sh_vpc"
  }
}
resource "aws_subnet" "sh_subnet1a" {
  vpc_id     = "${aws_vpc.sh_vpc.id}"
  cidr_block = "192.162.0.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "sh_subnet1a"
  }
}
resource "aws_subnet" "sh_subnet1b" {
  vpc_id     = "${aws_vpc.sh_vpc.id}"
  cidr_block = "192.162.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "sh_subnet1b"
  }
}
resource "aws_internet_gateway" "sh_gw" {
  vpc_id = "${aws_vpc.sh_vpc.id}"

  tags = {
    Name = "sh_gw"
  }
}
resource "aws_route_table" "sh_r" {
  vpc_id = "${aws_vpc.sh_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.sh_gw.id}"
  }
  tags = {
    Name = "sh_r"
  }
}
resource "aws_route_table_association" "sh_a" {
  subnet_id      = aws_subnet.sh_subnet1a.id
  route_table_id = aws_route_table.sh_r.id
}

resource "aws_security_group" "sh_sg1a" {
  vpc_id      = "${aws_vpc.sh_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "ICMP"
    cidr_blocks = ["0.0.0.0/0"]
  }
   ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "sh_sg1a"
  }
}
resource "aws_security_group" "sh_sg1b" {
  vpc_id      = "${aws_vpc.sh_vpc.id}"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "TCP"
    cidr_blocks = ["192.168.0.0/24"]
  }
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "TCP"
    cidr_blocks = ["192.168.0.0/24"]
  }

  tags = {
    Name = "sh_sg1b"
  }
}
resource "aws_instance" "web" {
  ami           = "ami-07a8c73a650069cf3"
  key_name = "shubham09"
  subnet_id = "${aws_subnet.sh_subnet1a.id}"
  vpc_security_group_ids = ["${aws_security_group.sh_sg1a.id}"]
  instance_type = "t2.micro"
  associate_public_ip_address = true
  

  tags = {
    Name = "webserver"
  }
}
resource "aws_instance" "database" {
  ami           = "ami-07a8c73a650069cf3"
  key_name = "shubham09"
  subnet_id = "${aws_subnet.sh_subnet1b.id}"
  vpc_security_group_ids = ["${aws_security_group.sh_sg1b.id}"]
  instance_type = "t2.micro"

  tags = {
    Name = "database"
  }
}
resource "aws_eip" "lb" {
  instance = "${aws_instance.database.id}"
  vpc      = true
}
resource "aws_nat_gateway" "gw" {
  allocation_id = "${aws_eip.lb.id}"
  subnet_id     = "${aws_subnet.sh_subnet1b.id}"
}