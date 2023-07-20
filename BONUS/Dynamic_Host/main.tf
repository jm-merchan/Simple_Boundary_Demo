# Configure the AWS provider
terraform {
  required_providers {
    boundary = {
      source  = "hashicorp/boundary"
      version = "1.1.9"
    }

    aws = {
      source  = "hashicorp/aws"
      version = "4.46.0"
    }
  }
}
/*
output "boundary_access_key_id" {
    value = aws_iam_access_key.boundary.id
}

output "boundary_secret_access_key" {
  value = aws_iam_access_key.boundary.secret
  sensitive = true
}



resource "aws_iam_user" "boundary" {
  name = "boundary"
  path = "/"
}

resource "aws_iam_access_key" "boundary" {
  user = aws_iam_user.boundary.name
}

resource "aws_iam_user_policy" "BoundaryDescribeInstances" {
  name = "BoundaryDescribeInstances"
  user = aws_iam_user.boundary.name
  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "ec2:DescribeInstances"
      ],
      "Effect": "Allow",
      "Resource": "*"
    }
  ]
}
EOF
}
*/



