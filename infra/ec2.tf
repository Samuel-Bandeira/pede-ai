resource "aws_instance" "pedeai" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.pedeai.id]
  key_name               = var.key_name

  user_data = file("${path.module}/cloud-init.sh")

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name    = "pedeai-server"
    Project = "pedeai"
  }
}

resource "aws_eip" "pedeai" {
  instance = aws_instance.pedeai.id
  domain   = "vpc"

  tags = {
    Name    = "pedeai-eip"
    Project = "pedeai"
  }
}
