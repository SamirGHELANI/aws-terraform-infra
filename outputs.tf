output "web_public_ip" {
  description = "IP publique du serveur web"
  value       = aws_instance.web.public_ip
}

# L'IP privée du backend (interne)
output "backend_private_ip" {
  description = "IP privee du backend"
  value       = aws_instance.backend.private_ip
}

# La commande SSH toute prête pour se connecter
output "ssh_command" {
  description = "Commande pour se connecter au serveur web"
  value       = "ssh -i ~/.ssh/aws-terraform ec2-user@${aws_instance.web.public_ip}"
}
