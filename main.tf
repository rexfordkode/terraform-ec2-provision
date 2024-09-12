provider "aws" {
    region = "us-eest-1"
}

# VPC
resource "aws_vpc" "main_vpc" {
    cidr_block = "10.0.0.1/16"
    tags = {
        Name = "main_vpc"
    }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "public_subnet"
    }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"
    tags = {
        Name = "private_subnet"
    }
}

# Internet Gateway
resource "aws_internet_gateway" "main_igw" {
    vpc_id = aws_vpc.main_vpc.id
    tags = {
        Name = "main_igw"
    }
}

# Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main_vpc.id

    route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.main_igw.id
    }
    tags = {
        Name = "public-route-table"
    }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_rt_assoc" {
    subnet_id      = aws_subnet.public_subnet.id
    route_table_id = aws_route_table.public_rt.id
}

# Security Group for EC Instance
resource "aws_security_group" "ec2_sg" {
    vpc_id = aws_vpc.main_vpc.id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    ingress = {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress = {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/-"]
    }
    tags = {
      Name = "ec2-sg"
    }
}
# Security Group for RDS Instance
resource "aws_security_group" "rds_sg" {
    vpc_id = aws_vpc.main_vpc.id
    ingress {
        from_port = 5432
        to_port = 5432
        protocol = "tcp"
        cidr_blocks = [""]
        security_groups = [aws_security_group.ec2_sg.id]
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    tags = {
      Name = "rds-sg"
    }
}
# EC2 Instance
resource "aws_instance" "web_server" {
    ami = "ami-0c55b159cbfafe1f0"
    instance_type = "t2.micro"
    key_name = "mykey"
    subnet_id = aws_subnet.public_subnet.id
    security_groups = [aws_security_group.ec2_sg.name]
    tags = {
        Name = "web-server"
    }
}

# RDS PostgreSQL Instance
resource "aws_db_instance" "postgres_db" {
    allocated_storage = 20
    storage_type = "gp2"
    engine = "postgres"
    engine_version = "12.5"
    instance_class = "db.t2.micro"
    db_name = "mydb"
    username = "postgres_user"
    password = "postgres_password"
    db_subnet_group_name = aws_db_subnet_group.rds.name

    vpc_security_group_ids = [aws_security_group.rds_sg.id]

    skip_final_snapshot = true
    tags = {
        Name = "postgres-db"
    }
}
# DB Subnet Group (Private Subnet)
resource "aws_db_subnet_group" "rds" {
    name = "rds-subnet-group"
    subnet_ids = [aws_subnet.private_subnet.id]
    tags = {
        Name = "rds-subnet-group"
    }
}

