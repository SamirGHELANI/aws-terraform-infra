resource "aws_security_group" "web" {
  name        = "web-sg"
  description = "Autorise SSH, HTTP, HTTPS depuis internet"
  vpc_id      = aws_vpc.main.id

  # SSH (port 22) - pour se connecter au serveur
  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]      # SOURCE : de n'importe où (à restreindre en prod)
  }

  # HTTP (port 80) - le site web
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS (port 443)
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Sortie : tout autorisé (le serveur peut aller vers internet)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"               # -1 = tous les protocoles
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg"
  }
}

resource "aws_security_group" "backend" {
  name        = "backend-sg"
  description = "Autorise seulement le trafic venant du SG web"
  vpc_id      = aws_vpc.main.id

  ingress {
    description     = "From web tier"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.web.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "backend-sg"
  }
}
