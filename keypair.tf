resource "aws_key_pair" "main" {
  key_name   = "terraform-key"
  public_key = var.ssh_public_key
}
