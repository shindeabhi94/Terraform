
variable "access_key" {
  default = ""
}

variable "secret_key" {
  default = ""
}

variable "region" {
  default = "ap-south-1"
}

variable "key_name" {
  description = "Name of my AWS key pair"
  default = "test-key"
}

variable "public_key_path" {
  description = "Path to my public key"
  default = "/home/ec2-user/.ssh/authorized_keys" 
}

variable "amis" {
  type = "map"
  default = {
    ap-south-1 = "ami-f9daac96"
    us-east-1 = "ami-13be557e"
    us-west-2 = "ami-06b94666"
  }
}
