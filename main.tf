# Create VPC
resource "aws_vpc" "my-vpc" {
  cidr_block           = "10.0.0.0/26"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "My-VPC"
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.my-vpc.id

  tags = {
    Name = "My-IGW"
  }
}

# Create Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.my-vpc.id
  cidr_block              = "10.0.0.0/28"
  availability_zone       = "us-east-1a" # Change to your desired AZ
  map_public_ip_on_launch = true

  tags = {
    Name = "Public-Subnet"
  }
}

# Create Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.my-vpc.id
  cidr_block        = "10.0.0.32/28"
  availability_zone = "us-east-1b" # Change to your desired AZ

  tags = {
    Name = "Private-Subnet"
  }
}

# Create Security Groups
resource "aws_security_group" "public_sg" {
  vpc_id = aws_vpc.my-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private_sg" {
  vpc_id = aws_vpc.my-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Network ACLs
resource "aws_network_acl" "public_acl" {
  vpc_id = aws_vpc.my-vpc.id
}

resource "aws_network_acl" "private_acl" {
  vpc_id = aws_vpc.my-vpc.id
}

# Associate Subnets with ACLs
resource "aws_network_acl_association" "public_association" {
  subnet_id      = aws_subnet.public.id
  network_acl_id = aws_network_acl.public_acl.id
}

resource "aws_network_acl_association" "private_association" {
  subnet_id      = aws_subnet.private.id
  network_acl_id = aws_network_acl.private_acl.id
}

# Create Instances
resource "aws_instance" "public_instance" {
  ami                         = "ami-0e731c8a588258d0d" # Amazon Linux 2 AMI ID
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public.id
  security_groups             = [aws_security_group.public_sg.id]
  key_name                    = "ajam-key" # Change to your key pair name
  associate_public_ip_address = true

  tags = {
    Name = "PublicInstance"
  }
}

resource "aws_instance" "private_instance" {
  ami             = "ami-0e731c8a588258d0d" # Amazon Linux 2 AMI ID
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.private.id
  security_groups = [aws_security_group.private_sg.id]
  key_name        = "ajam-key" # Change to your key pair name

  tags = {
    Name = "PrivateInstance"
  }
}

resource "aws_eip_association" "eip_assoc" {
  instance_id   = aws_instance.public_instance.id
  allocation_id = aws_eip.public_instance.id
}


# Create NAT Gateway
resource "aws_nat_gateway" "main" {
  # allocation_id = aws_instance.public_instance.network_interface # Assuming the public instance has a single network interface
  allocation_id = aws_eip_association.eip_assoc.id
  subnet_id = aws_subnet.public.id

  tags = {
    Name = "MyNAT"
  }
}


# Configure Security Group Rules
resource "aws_security_group_rule" "public_sg_ingress" {
  security_group_id = aws_security_group.public_sg.id
  type              = "ingress"
  from_port         = 22
  to_port           = 22
  protocol          = "tcp"
  cidr_blocks       = ["93.107.90.239/32"] # Change to your public IP
}

resource "aws_security_group_rule" "private_sg_ingress" {
  security_group_id        = aws_security_group.private_sg.id
  type                     = "ingress"
  from_port                = 22
  to_port                  = 22
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.public_sg.id
}

#===========================================================================================
# Define VPC
# resource "aws_vpc" "my_vpc" {
#   cidr_block = "10.0.0.0/26"
# }

# # Define Public Subnet
# resource "aws_subnet" "public_subnet1" {
#   vpc_id                  = aws_vpc.my_vpc.id
#   cidr_block              = "10.0.0.0/28"
#   availability_zone       = "us-east-1a" # Specify the availability zone
#   map_public_ip_on_launch = true
# }
# resource "aws_subnet" "public_subnet2" {
#   vpc_id                  = aws_vpc.my_vpc.id
#   cidr_block              = "10.0.0.16/28"
#   availability_zone       = "us-east-1b" # Specify the availability zone
#   map_public_ip_on_launch = true
# }
# # Define Private Subnet
# resource "aws_subnet" "private_subnet1" {
#   vpc_id            = aws_vpc.my_vpc.id
#   cidr_block        = "10.0.0.32/28"
#   availability_zone = "us-east-1a" # Specify the availability zone
# }
# resource "aws_subnet" "private_subnet2" {
#   vpc_id            = aws_vpc.my_vpc.id
#   cidr_block        = "10.0.0.48/28"
#   availability_zone = "us-east-1b" # Specify the availability zone
# }

# # Define Security Groups
# resource "aws_security_group" "public_sg" {
#   vpc_id = aws_vpc.my_vpc.id

#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

# resource "aws_security_group" "private_sg" {
#   vpc_id = aws_vpc.my_vpc.id
# }

# # Define Security Group Rules
# resource "aws_security_group_rule" "public_sg_ingress" {
#   security_group_id = aws_security_group.public_sg.id
#   type              = "ingress"
#   from_port         = 22 # SSH Port
#   to_port           = 22
#   protocol          = "tcp"
#   cidr_blocks       = ["your_public_ip/32"]
# }

# resource "aws_security_group_rule" "private_sg_ingress" {
#   security_group_id        = aws_security_group.private_sg.id
#   type                     = "ingress"
#   from_port                = 22 # SSH Port
#   to_port                  = 22
#   protocol                 = "tcp"
#   source_security_group_id = aws_security_group.public_sg.id
# }

# # Define EC2 Instances
# resource "aws_instance" "public_instance" {
#   ami                = "your_public_ami"
#   instance_type      = "t2.micro"
#   subnet_id          = aws_subnet.public_subnet.id
#   security_group_ids = [aws_security_group.public_sg.id]
# }

# resource "aws_instance" "private_instance" {
#   ami                = "your_private_ami"
#   instance_type      = "t2.micro"
#   subnet_id          = aws_subnet.private_subnet.id
#   security_group_ids = [aws_security_group.private_sg.id]
# }

# # Output the public IP of the public instance
# output "public_instance_ip" {
#   value = aws_instance.public_instance.public_ip
# }

# # Output the private IP of the private instance
# output "private_instance_ip" {
#   value = aws_instance.private_instance.private_ip
# }
