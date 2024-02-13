packer {
  required_plugins {
    amazon = {
      version = ">= 1.2.8"
      source  = "github.com/hashicorp/amazon"
    }
  }
}

source "amazon-ebs" "ubuntu" {
  ami_name      = "ubuntu-20.04-confidence"
  instance_type = "t2.micro"
  region        = "us-east-1"
  tags = {
          "Name": "ubuntu-20.04-confidence"
  }  
  
  source_ami_filter {
    filters = {
      name                = "ubuntu/images/*ubuntu-focal-20.04-amd64-server-*"
      root-device-type    = "ebs"
      virtualization-type = "hvm"
    }
    most_recent = true
    owners      = ["099720109477"]
  }
  
  ssh_username = "ubuntu"
}

build {
  name = "ubuntu-20.04-confidence"

  sources = [
    "source.amazon-ebs.ubuntu"
  ]
  
  provisioner "file" {
    source      = "script.sh"
    destination = "/tmp/script.sh"
  }

  provisioner "shell" {
    inline = [
      "sudo chmod +x /tmp/script.sh",
      "sudo bash /tmp/script.sh"
    ]
  }
}    
