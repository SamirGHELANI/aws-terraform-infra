resource "aws_key_pair" "main" {
  key_name   = "terraform-key"
  public_key = file("~/.ssh/aws-terraform.pub")  
}
