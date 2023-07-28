resource "aws_instance" "internal_target" {
  #count                  = 1
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = "t2.micro"
  key_name               = data.aws_key_pair.example.key_name
  vpc_security_group_ids = [aws_security_group.privatesg.id]
  subnet_id              = aws_subnet.private1.id

  user_data_replace_on_change = true
  user_data_base64            = data.cloudinit_config.ssh.rendered

  tags = {
    Name = "sshrecording-private-target"
  }
}


locals {
  cloud_config_config = <<-END
    #cloud-config
    ${jsonencode({
  write_files = [
    {
      path        = "/etc/ssh/ca-key.pub"
      permissions = "0644"
      owner       = "root:root"
      encoding    = "b64"
      content     = filebase64("vault_ca.pub")
    },
  ]
})}
  END
}

data "cloudinit_config" "ssh" {
  gzip          = false
  base64_encode = true
  part {
    content_type = "text/cloud-config"
    content      = local.cloud_config_config
  }
  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      sudo chown 1000:1000 /etc/ssh/ca-key.pub
      sudo chmod 644 /etc/ssh/ca-key.pub
      sudo echo TrustedUserCAKeys /etc/ssh/ca-key.pub >> /etc/ssh/sshd_config
      sudo echo PermitTTY yes >> /etc/ssh/sshd_config
      sudo sed -i 's/X11Forwarding no/X11Forwarding yes/' /etc/ssh/sshd_config
      sudo echo "X11UseLocalhost no" >> /etc/ssh/sshd_config
      sudo systemctl restart sshd

  EOF
  }
}



