data "aws_internet_gateway" "default" {
  filter {
    name   = "attachment.vpc-id"
    values = [data.terraform_remote_state.local_backend.outputs.vpc]
  }
}

# Deploy 2 Public Subnets
resource "aws_subnet" "public1" {
  vpc_id                  = data.terraform_remote_state.local_backend.outputs.vpc
  cidr_block              = "172.31.20.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "sshrecording-1public"
  }
}

resource "aws_subnet" "public2" {
  vpc_id                  = data.terraform_remote_state.local_backend.outputs.vpc
  cidr_block              = "172.31.21.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "sshrecording-2public"
  }
}

# Deploy 2 Private Subnets
resource "aws_subnet" "private1" {
  vpc_id                  = data.terraform_remote_state.local_backend.outputs.vpc
  cidr_block              = "172.31.22.0/24"
  availability_zone       = "eu-west-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "sshrecording-1private"
  }
}

resource "aws_subnet" "private2" {
  vpc_id                  = data.terraform_remote_state.local_backend.outputs.vpc
  cidr_block              = "172.31.23.0/24"
  availability_zone       = "eu-west-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "sshrecording-2private"
  }
}
# Deploy Route Table
resource "aws_route_table" "rt" {
  vpc_id = data.terraform_remote_state.local_backend.outputs.vpc

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = data.aws_internet_gateway.default.id
  }

  # Route traffic to the HVN peering connection
  route {
    cidr_block                = "172.25.16.0/20"
    vpc_peering_connection_id = data.terraform_remote_state.local_backend.outputs.peering_id
  }

  tags = {
    Name = "sshrecording-route-table-self-hvn"
  }
}

# Associate Subnets With Route Table
resource "aws_route_table_association" "route1" {
  subnet_id      = aws_subnet.public1.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_route_table_association" "route2" {
  subnet_id      = aws_subnet.public2.id
  route_table_id = aws_route_table.rt.id
}

# Deploy Security Groups
resource "aws_security_group" "publicsg" {
  name        = "sshrecording-upstream-worker"
  description = "SSH + Boundary port"
  vpc_id      = data.terraform_remote_state.local_backend.outputs.vpc

  # To allow direct connections from clients and downstream workers
  ingress {
    from_port   = 9202
    to_port     = 9202
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
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
}

resource "aws_security_group" "privatesg" {
  name        = "sshrecording-privatesg"
  description = "Allow traffic"
  vpc_id      = data.terraform_remote_state.local_backend.outputs.vpc

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    cidr_blocks     = ["10.0.0.0/16"]
    security_groups = [aws_security_group.publicsg.id]
  }
  ingress {
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
}
