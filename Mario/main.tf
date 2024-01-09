provider "aws" {
  region     = "ap-south-1"
  access_key = ""
  secret_key = ""

}

resource "aws_security_group" "mario_sg" {
  name        = "mario_sg"
  description = "Security group allowing SSH, HTTP, and HTTPS traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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

resource "aws_iam_role" "mario_role" {
  name = "mario_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "mario_attachment_1" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  role       = aws_iam_role.mario_role.name
}

resource "aws_iam_policy" "mario_policy" {
  name        = "mario_policy"
  description = "IAM policy for mario_role"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "iam:CreateRole",
          "iam:AttachRolePolicy",
          "iam:PutRolePolicy", 
          "iam:GetRole",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:PassRole",
          "iam:DetachRolePolicy",
          "iam:ListInstanceProfilesForRole",
          "iam:DeleteRole"
        ],
        Resource = "*"
      },
      {
        Effect = "Allow",
        Action = [
            "eks:*",
        #   "eks:CreateCluster",
        #   "eks:DescribeCluster",
        #   "eks:ListClusters",
        #   "eks:CreateNodegroup",
        #   "eks:UpdateNodegroupConfig",
        #   "eks:DeleteNodegroup",
        #   "eks:DescribeNodegroup"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "mario_attachment" {
  policy_arn = aws_iam_policy.mario_policy.arn
  role       = aws_iam_role.mario_role.name
}

resource "aws_iam_instance_profile" "mario_instance_profile" {
  name = "mario_instance_profile"
  role = aws_iam_role.mario_role.name
}

resource "aws_instance" "mario_ec2" {
  ami                    = "ami-0d3f444bc76de0a79" # Amazon Linux 2023 AMI ID
  instance_type          = "t2.micro"
  key_name               = "devtest" # Replace with your SSH key pair name
  vpc_security_group_ids = [aws_security_group.mario_sg.id]
  iam_instance_profile   = aws_iam_instance_profile.mario_instance_profile.name # Update with your instance profile name

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install git -y
              git clone https://github.com/Mrunmay1312/k8s-mario.git
              cd k8s-mario
              sudo chmod +x script.sh
              ./script.sh

              yum install -y aws-cli

              # Configure AWS CLI with your credentials and region
              cat <<EOFAWS > /home/ec2-user/.aws/config
              [default]
              region = ap-south-1  # Set your desired AWS region
              EOFAWS

              cat <<EOFAWS > /home/ec2-user/.aws/credentials
              [default]
              aws_access_key_id = 
              aws_secret_access_key = 
              EOFAWS

              chown -R ec2-user:ec2-user /home/ec2-user/.aws
              chmod 600 /home/ec2-user/.aws/credentials
              chmod 644 /home/ec2-user/.aws/config
              EOF

  tags = {
    Name = "mario-instance"
  }
}
