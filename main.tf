provider "aws" {
  region = "us-east-1"  # Cambia esto a tu región preferida 
}

# Creación del tema SNS
resource "aws_sns_topic" "example" {
  name = "example-topic"
}

# Suscripción al tema SNS para invocar la Lambda
resource "aws_sns_topic_subscription" "lambda_subscription" {
  topic_arn = aws_sns_topic.example.arn
  protocol  = "lambda"
  endpoint  = aws_lambda_function.example_lambda.arn
}
 
# Suscripción al tema SNS para enviar correo electrónico
resource "aws_sns_topic_subscription" "email_subscription" {
  topic_arn = aws_sns_topic.example.arn
  protocol  = "email"
  endpoint  = "marcosvinicius.costa@tajamar365.com"
}

# variable "subscription_email" {
#   description = "Email for SNS subscription"
#   type        = string
# }

resource "aws_instance" "prueba" {
  ami           = "ami-01b799c439fd5516a"  # AMI de Amazon Linux 2
  instance_type = "t2.micro"
  key_name      = "vockey"  # Cambia esto al nombre de tu par de claves SSH
  iam_instance_profile = "LabInstanceProfile"
  
  tags = {
    Name = "WebServer"
  }
 
  # Define el Security Group para permitir tráfico HTTP y SSH
  vpc_security_group_ids = [aws_security_group.web_sg.id]
 
  provisioner "file" {
    source      = "install_apache.sh"
    destination = "/tmp/install_apache.sh"
  }
  
  provisioner "file" {
    source      = "install_php.sh"
    destination = "/tmp/install_php.sh"
  }
  
  provisioner "file" {
    source      = "index.html"
    destination = "/tmp/index.html"
  }
  provisioner "file" {
    source      = "submit.php"
    destination = "/tmp/submit.php"
  }
  
  # provisioner "remote-exec" {
  #   inline = [
  #     "chmod +x /tmp/install_apache.sh",
  #     "sudo /tmp/install_apache.sh"
  #   ]
  # }
  
  # provisioner "remotet-exec" {
  #   inline = [
  #     "chmod +x /tmp/install_php.sh",
  #     "sudo /tmp/install_php.sh"
  #   ]
  # }
  
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install_apache.sh",
      "sudo /tmp/install_apache.sh",
      "chmod +x /tmp/install_php.sh",
      "sudo /tmp/install_php.sh",
      "sudo mv /tmp/index.html /var/www/html/index.html",
      "sudo mv /tmp/submit.php /var/www/html/submit.php"
    ]
  }

provisioner "remote-exec" {
   inline = [ 
     "sudo sed -i 's|arn:aws:sns:us-east-1:XXXXXXX:test|${aws_sns_topic.example.arn}|' /var/www/html/submit.php" ]
  }
  provisioner "remote-exec" {
   inline = [ 
     "sudo sed -i '/AddType application\\/x-compress \\.Z/i AddType application\\/x-httpd-php \\.php' /etc/httpd/conf/httpd.conf" ]
  }
  
  connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("ssh.pem")  # Ruta a tu clave privada
    host        = self.public_ip
  }
}

// Security Groups

resource "aws_security_group" "web_sg" {
  name        = "web_sg"
  description = "Allow HTTP and SSH traffic"
 
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
 
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

provider "archive" {}

data "archive_file" "zip" {
  type        = "zip"
  source_file = "hello_lambda.py"
  output_path = "hello_lambda.zip"
}


resource "aws_lambda_function" "example_lambda" {
  function_name = "hello_lambda"

  filename         = data.archive_file.zip.output_path
  source_code_hash = data.archive_file.zip.output_base64sha256

  role    = "arn:aws:iam::958327387559:role/LabRole"
  handler = "hello_lambda.lambda_handler"
  runtime = "python3.12"

  timeout = 60
}

resource "aws_lambda_permission" "with_sns" {
  statement_id  = "AllowExecutionFromSNS"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.example_lambda.function_name
  principal     = "sns.amazonaws.com"
  source_arn    = aws_sns_topic.example.arn
}