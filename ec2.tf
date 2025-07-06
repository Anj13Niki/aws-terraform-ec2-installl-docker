
module "vpc" {
  source = "./module/vpc"

}


resource "aws_key_pair" "ec2-terra-key" {
  key_name = "terraform-key-ec2"
  public_key = file("ec2keys.pub")
}

resource "aws_security_group" "docker-sg" {    
    name="docker-sg"
    vpc_id = module.vpc.vpc_id

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}


resource "aws_instance" "ec2_docker" {
  key_name = aws_key_pair.ec2-terra-key.key_name
  ami = var.ami_ec2
  instance_type = var.type_ec2
  subnet_id = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.docker-sg.id]
  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y apt-transport-https ca-certificates curl software-properties-common
              curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
              add-apt-repository \
                "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
                $(lsb_release -cs) \
                stable"
              apt-get update -y
              apt-get install -y docker-ce
              systemctl start docker
              sudo usermod -aG docker ubuntu
              docker --version

              docker run -d -p 80:80 nginx
             EOF

  tags = {
    Name="docker-ec2-instance"
  }
}



