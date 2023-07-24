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

resource "aws_security_group" "public_network_ssh_postgres" {
  name        = "public_ssh_postgres"
  description = "Allow SSH and Postgres inbound traffic"
  vpc_id      = data.terraform_remote_state.local_backend.outputs.vpc

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #cidr_blocks = ["${data.http.current.response_body}/32"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = ["172.25.16.0/20"] # HCP Network only - connecting via peering
    #cidr_blocks = ["${data.http.current.response_body}/32"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_ssh_postgres"
  }
}

# Retrieve information about subnet1 created previously
data "aws_subnet" "example_subnet" {
  filter {
    name   = "cidr-block"
    values = ["172.31.1.0/24"]
  }

  filter {
    name   = "vpc-id"
    values = [data.terraform_remote_state.local_backend.outputs.vpc]
  }
}


data "aws_key_pair" "example" {
  key_name           = "ec2-key"
  include_public_key = true
}

resource "aws_instance" "postgres_target" {
  #count                  = 1
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = "t2.micro"
  key_name               = data.aws_key_pair.example.key_name
  vpc_security_group_ids = [aws_security_group.public_network_ssh_postgres.id]
  subnet_id              = data.aws_subnet.example_subnet.id

  user_data_replace_on_change = true
  user_data_base64            = data.cloudinit_config.postgres.rendered

  tags = {
    Name = "Postgres Boundary Target"
  }
}

/* Configuring postgress Database as per 
https://developer.hashicorp.com/boundary/tutorials/credential-management/hcp-vault-cred-brokering-quickstart#setup-postgresql-northwind-demo-database
*/
data "cloudinit_config" "postgres" {
  gzip          = false
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      sudo apt-get install wget ca-certificates net-tools -y
      wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | sudo apt-key add -
      sudo sh -c 'echo "deb http://apt.postgresql.org/pub/repos/apt/ `lsb_release -cs`-pgdg main" >> /etc/apt/sources.list.d/pgdg.list'
      sudo apt-get update
      sudo apt-get install postgresql postgresql-contrib git postgresql-client-common -y

      sudo sed -ibak "s/#listen_addresses\ \=\ 'localhost'/listen_addresses = '*'/g" /etc/postgresql/15/main/postgresql.conf
      sudo sed -ibak 's/127.0.0.1\/32/0.0.0.0\/0/g' /etc/postgresql/15/main/pg_hba.conf
      sudo echo "host    all             all             0.0.0.0/0                 md5" >> /etc/postgresql/15/main/pg_hba.conf
      sudo echo "host    all             all             ::/0                      md5" >> /etc/postgresql/15/main/pg_hba.conf

      sudo systemctl daemon-reload
      sudo systemctl restart postgresql.service
      sudo systemctl enable postgresql.service
      
      git clone https://github.com/hashicorp/learn-boundary-vault-quickstart
      
      sudo -i -u postgres createdb northwind
      sudo -i -u postgres psql -d northwind -f /learn-boundary-vault-quickstart/northwind-database.sql --quiet
      sudo -i -u postgres psql -d northwind -f /learn-boundary-vault-quickstart/northwind-roles.sql --quiet
      sudo -i -u postgres psql -U postgres -d postgres -c "alter user postgres with password '${var.postgres_password}';"

      curl 'https://api.ipify.org?format=txt' > /tmp/ip
      cat /tmp/ip
  EOF
  }
}



