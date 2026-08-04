resource "aws_instance" "web" {
  ami                    = data.aws_ami.amazon_linux.id   
  instance_type          = "t3.micro"                    
  subnet_id              = aws_subnet.public.id          
  vpc_security_group_ids = [aws_security_group.web.id]   
  key_name               = aws_key_pair.main.key_name     

  tags = {
    Name = "web-server"
  }
}

resource "aws_instance" "backend" {
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private.id          
  vpc_security_group_ids = [aws_security_group.backend.id]
  key_name               = aws_key_pair.main.key_name

  tags = {
    Name = "backend-server"
  }
}
