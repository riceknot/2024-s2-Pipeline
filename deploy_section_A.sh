#!/bin/bash

# Function to get the user's path to ssh private key
get_user_input() {
    read -p "Enter the path to your PRIVATE SSH key: " private_SSH_KEY
    read -p "Enter the path to your PUBLIC SSH key: " public_SSH_KEY
}

set -e # Bail on first sign of trouble

get_user_input # Get user input for ip address and ssh key path

# Automatically takes the user's ip address.
USER_IP=$(curl -s ifconfig.co)
echo "Your IP address is: $USER_IP"

echo "Testing AWS credentials"
aws sts get-caller-identity

cd infra-1

echo "Initialising Terraform..."
terraform init
echo "Validating Terraform configuration..."
terraform validate
echo "Running terraform apply"
terraform apply -var "my_ip_address=$USER_IP" -var "path_to_ssh_public_key=$public_SSH_KEY" -auto-approve

echo "Waiting for Terraform to finish..."
sleep 30

# Take foo's instance public IP address for ansible configuration.
FOO_INSTANCE_IP=$(terraform output -raw foo_instance_public_ip)

cd -
cd ansible-1

echo "Configuring foo instance..."

# Overwrite the inventory-foo.yml file with the foo instance public ip.
cat <<EOL > inventory-foo.yml
foo_servers:
  hosts:
    foo:
      ansible_host: $FOO_INSTANCE_IP
EOL

# Set SSH options to automatically add the host key (auto-approve ssh key during ansible configuration)
export ANSIBLE_SSH_ARGS='-o StrictHostKeyChecking=no'

# Start configuring foo instance.
ansible-playbook foo-playbook.yml -i inventory-foo.yml --private-key "$private_SSH_KEY"

cd -

echo "Running commands on the remote EC2 instance..."
ssh ubuntu@"$FOO_INSTANCE_IP" -i "$private_SSH_KEY" -o StrictHostKeyChecking=no << 'EOF'
    echo "Running docker-compose..."
    sudo docker-compose up -d
EOF