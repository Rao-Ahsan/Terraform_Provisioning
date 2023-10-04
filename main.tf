# CREATING AWS VPC
resource "aws_vpc" "practice-vpc" {
  cidr_block = "10.0.0.0/16"
 tags = {
    Name = "Practice-VPC"
  }

}


# PUBLIC SUBNET
resource "aws_subnet" "public-subnet" {
  vpc_id     = aws_vpc.practice-vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public Subnet"
  }
}
# PRIVATE SUBNET
resource "aws_subnet" "private-subnet" {
  vpc_id     = aws_vpc.practice-vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private Subnet"
  }

}

# INTERNET SECURITY GROUP

resource "aws_security_group" "terraform-practice-sg" {
  name        = "Terraform-Practice-SG"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.practice-vpc.id

  ingress {
    description      = "TLS from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

 ingress {
    description      = "TLS from VPC"
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }

  tags = {
    Name = "Terraform-Practice-SG"
  }

}

# INTERNET GATEWAY
resource "aws_internet_gateway" "terraform-practice-igw" {
  vpc_id = aws_vpc.practice-vpc.id

  tags = {
    Name = "Terraform-Practice-IGW"
  }
}

#CREATING AWS ROUTE TABLE
resource "aws_route_table" "public-rt" {
  vpc_id = aws_vpc.practice-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terraform-practice-igw.id
 }

  tags = {
    Name = "Public RT"
  }
}

resource "aws_route_table_association" "public-rt-asso" {
  subnet_id      = aws_subnet.public-subnet.id
  route_table_id = aws_route_table.public-rt.id
}

#CREATING A WEBSERVER


resource "aws_instance" "web-server" {
  ami           = "ami-067d1e60475437da2"  # Replace with your desired AMI ID
  instance_type = "t2.micro"              # Choose an appropriate instance type
  key_name      = "terra-key"         # Specify your key pair name
  subnet_id              = aws_subnet.public-subnet.id  # Replace with your subnet ID
  security_groups        = [aws_security_group.terraform-practice-sg.id]    # Replace with your security group ID
  

   connection {
    type        = "ssh"  # The type of connection (e.g., SSH or WinRM)
    user        = "ec2-user"  # The username to use for the connection
    private_key = file("./terra-key.pem")  # Path to your private key file
    host        = self.public_ip  # Connect to the instance's public IP
  }
  

  tags = {
    Name = "Web Server"
  }
}

# ELASTIC IP 
resource "aws_eip" "terraform-practice-eip" {
  instance = aws_instance.web-server.id
  domain   = "vpc"
}




resource "aws_instance" "db-server" {
  ami           = "ami-067d1e60475437da2"  # Replace with your desired AMI ID
  instance_type = "t2.micro"              # Choose an appropriate instance type
  key_name      = "terra-key"         # Specify your key pair name
  subnet_id              = aws_subnet.private-subnet.id  # Replace with your subnet ID
  security_groups        = [aws_security_group.terraform-practice-sg.id]    # Replace with your security group ID


   connection {
    type        = "ssh"  # The type of connection (e.g., SSH or WinRM)
    user        = "ec2-user"  # The username to use for the connection
    private_key = file("./terra-key.pem")  # Path to your private key file
    host        = self.public_ip  # Connect to the instance's public IP
  }


  tags = {
    Name = "DATABASE SERVER"
  }
}

# ELASTIC IP
resource "aws_eip" "terraform-practice-aws-ngw-id" {
  
  #nstance = aws_instance.web-server.id
  domain   = "vpc"
}

#CREATING NETGATEWAY
resource "aws_nat_gateway" "aws-ngw" {
  
  subnet_id     = aws_subnet.public-subnet.id
  allocation_id = aws_eip.terraform-practice-aws-ngw-id.id
  tags = {
    Name = "NAT Gateway"
  }

}

#CREATING A PRIVATE ROUTE TABLE
resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.practice-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.aws-ngw.id
  }

  

  tags = {
    Name = "Private RT"
  }
}

# AWS ROUTE TABLE ASSOCIATION


resource "aws_route_table_association" "private-rt-asso" {
  subnet_id      = aws_subnet.private-subnet.id
  route_table_id = aws_route_table.private-rt.id
}




