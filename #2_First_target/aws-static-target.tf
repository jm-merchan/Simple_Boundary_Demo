# Define the data source for the latest Ubuntu AMI
data "aws_ami" "ubuntu_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["099720109477"]  # Canonical account ID
}


resource "aws_subnet" "subnet1" {
    vpc_id = data.terraform_remote_state.local_backend.outputs.vpc
    cidr_block = "172.31.1.0/24"
    map_public_ip_on_launch = "true" //it makes this a public subnet
    availability_zone = "eu-west-2a"
    tags = {
        Name = "subnet1"
    }
}

resource "aws_internet_gateway" "prod-igw" {
    vpc_id = data.terraform_remote_state.local_backend.outputs.vpc
    tags = {
        Name = "prod-igw"
    }
}

resource "aws_route_table" "prod-public-crt" {
    vpc_id = data.terraform_remote_state.local_backend.outputs.vpc
    
    route {
        //associated subnet can reach everywhere
        cidr_block = "0.0.0.0/0" 
        //CRT uses this IGW to reach internet
        gateway_id = aws_internet_gateway.prod-igw.id
    }
    
    tags = {
        Name = "prod-public-crt"
    }
}



resource "aws_route_table_association" "prod-crta-public-subnet-1"{
    subnet_id = aws_subnet.subnet1.id
    route_table_id = aws_route_table.prod-public-crt.id
}

/*
# Data block to grab current IP and add into SG rules
data "http" "current" {
  url = "https://ifconfig.me/ip"
}
*/


resource "aws_security_group" "public_network_boundary_ssh" {
  name        = "public_ssh"
  description = "Allow SSH inbound traffic"
  vpc_id      = data.terraform_remote_state.local_backend.outputs.vpc

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #cidr_blocks = ["${data.http.current.response_body}/32"]
  }
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}



resource "aws_instance" "boundary_target" {
  #count                  = 1
  ami               = data.aws_ami.ubuntu_ami.id
  instance_type     = "t2.micro"
  key_name          = aws_key_pair.ec2_key.key_name
  depends_on = [  aws_key_pair.ec2_key ]
  vpc_security_group_ids = [aws_security_group.public_network_boundary_ssh.id]
  subnet_id = aws_subnet.subnet1.id

  tags = {
    Name = "Ubuntu Boundary Target"
  }
}

