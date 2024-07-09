#!/bin/bash

# Actualiza los paquetes e instala Apache
sudo yum update -y
sudo yum install -y httpd

# Inicia Apache y habilita para que inicie en cada reinicio del sistema
sudo systemctl start httpd
sudo systemctl enable httpd

