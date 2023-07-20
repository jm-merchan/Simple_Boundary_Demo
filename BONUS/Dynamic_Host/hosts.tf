# Configure the AWS VM hosts
variable "instances" {
  default = [
    "boundary-1-dev",
    "boundary-2-dev",
    "boundary-3-production",
    "boundary-4-production"
  ]
}

variable "vm_tags" {
  default = [
    { "Name" : "boundary-1-dev", "service-type" : "database", "application" : "dev" },
    { "Name" : "boundary-2-dev", "service-type" : "database", "application" : "dev" },
    { "Name" : "boundary-3-production", "service-type" : "database", "application" : "production" },
    { "Name" : "boundary-4-production", "service-type" : "database", "application" : "production" }
  ]
}

resource "aws_security_group" "boundary-ssh" {
  name        = "boundary_allow_ssh"
  description = "Allow SSH inbound traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh"
  }
}

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
  owners = ["099720109477"] # Canonical account ID
}


data "aws_key_pair" "example" {
  key_name           = "ec2-key"
  include_public_key = true
}



resource "aws_instance" "boundary-instance" {
  count                  = length(var.instances)
  key_name               = data.aws_key_pair.example.key_name
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = "t3.micro"
  security_groups        = ["boundary_allow_ssh"]
  vpc_security_group_ids = ["${aws_security_group.boundary-ssh.id}"]
  tags                   = var.vm_tags[count.index]
}
