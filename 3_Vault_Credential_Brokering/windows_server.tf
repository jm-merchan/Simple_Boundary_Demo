/*
https://gmusumeci.medium.com/how-to-deploy-a-windows-server-ec2-instance-in-aws-using-terraform-dd86a5dbf731
*/

# Define the data source for the Windows Server
data "aws_ami" "windows-2019" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["Windows_Server-2019-English-Full-Base*"]
  }
}


resource "aws_security_group" "public_network_http_rdp" {
  name        = "public_http_rdp"
  description = "Allow HTTP and RDP inbound traffic"
  vpc_id      = data.terraform_remote_state.local_backend.outputs.vpc

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    #cidr_blocks = ["${data.http.current.response_body}/32"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow ldap from HCP Vault
  ingress {
    from_port   = 389
    to_port     = 389
    protocol    = "tcp"
    cidr_blocks = ["172.25.16.0/20"]
  }
  # Allow ldaps from HCP Vault
  ingress {
    from_port   = 636
    to_port     = 636
    protocol    = "tcp"
    cidr_blocks = ["172.25.16.0/20"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "allow_http_rdp_ldap"
  }
}


resource "aws_instance" "windows-server" {
  ami                    = data.aws_ami.windows-2019.id
  instance_type          = "t3.medium"
  subnet_id              = data.aws_subnet.example_subnet.id
  vpc_security_group_ids = [aws_security_group.public_network_http_rdp.id]
  source_dest_check      = false
  key_name               = data.aws_key_pair.example.key_name
  get_password_data      = true
  user_data              = <<EOF
    <powershell>
    # Rename Machine
    Rename-Computer -NewName "${var.windows_instance_name}" -Force;
    # Install IIS
    Install-WindowsFeature -name Web-Server -IncludeManagementTools;
    # Restart machine
    shutdown -r -t 10;
    </powershell>
EOF

  tags = {
    Name = "windows-server-vm"
  }
}
/*
# Create Elastic IP for the EC2 instance
resource "aws_eip" "windows-eip" {
  vpc  = true
  tags = {
    Name = "windows-eip"
  }
}
# Associate Elastic IP to Windows Server
resource "aws_eip_association" "windows-eip-association" {
  instance_id   = aws_instance.windows-server.id
  allocation_id = aws_eip.windows-eip.id
}
*/
