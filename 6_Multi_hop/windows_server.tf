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



resource "aws_instance" "windows-server" {
  ami                    = data.aws_ami.windows-2019.id
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.private1.id
  vpc_security_group_ids = [aws_security_group.privatesg.id]
  
  source_dest_check      = false
  key_name               = data.aws_key_pair.example.key_name
  get_password_data      = true
  user_data              = <<EOF
    <powershell>
    # Rename Machine
    Rename-Computer -NewName "Windows-private-subnet" -Force;
    # Install IIS
    Install-WindowsFeature -name Web-Server -IncludeManagementTools;
    # Restart machine
    shutdown -r -t 10;
    </powershell>
EOF

  tags = {
    Name = "windows-server-vm-internal"
  }
}
