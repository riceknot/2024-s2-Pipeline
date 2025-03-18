#!/bin/bash

set -e # Bail on first sign of trouble

echo "Testing AWS credentials"
aws sts get-caller-identity

public_SSH_KEY=${SSH_PUBLIC_KEY}
private_SSH_KEY=${SSH_PRIVATE_KEY}
user_IP=${USER_IP}

#------------------Terraform-------------------
cd infra-2

echo "Initialising Terraform..."
terraform init
echo "Validating Terraform configuration..."
terraform validate
echo "Running terraform apply 1st time"
terraform apply \
-var "my_ip_address=$user_IP" \
-var "path_to_ssh_public_key=$public_SSH_KEY" \
-auto-approve

echo "Waiting for Terraform to finish..."
sleep 30

# Taking all instances public IP addresses
app1_IP=$(terraform output -raw app_instance_1_public_ip)
app2_IP=$(terraform output -raw app_instance_2_public_ip)
db_IP=$(terraform output -raw db_instance_public_ip)

echo "Running terraform apply 2nd time (to set up security groups correctly)"
terraform apply \
-var "my_ip_address=$user_IP" \
-var "path_to_ssh_public_key=$public_SSH_KEY" \
-var "app_address_1=$app1_IP" \
-var "app_address_2=$app2_IP" \
-var "db_address=$db_IP" \
-auto-approve

echo "Waiting for Terraform to finish, again..."
sleep 30
#------------------Terraform-------------------

cd -

#-------------------Ansible--------------------
cd ansible-2

# Set SSH options to automatically add the host key (auto-approve ssh key during ansible configuration)
export ANSIBLE_SSH_ARGS='-o StrictHostKeyChecking=no'

echo "Configuring app and db with Ansible..."

# Overwrite the inventory-db.yml file with the db instance public ip.
cat <<EOL > inventory-db.yml
db_servers:
  hosts:
    db1:
      ansible_host: $db_IP
EOL

# Overwrite the inventory-app.yml file with the app instances public ip.
cat <<EOL > inventory-app.yml
app_servers:
  hosts:
    app1:
      ansible_host: $app1_IP
    app2:
      ansible_host: $app2_IP
EOL

# Overwrite the vars.yml file with db instance public ip.
cat <<EOL > vars.yml
db_ip: "$db_IP"
EOL

# Start configuring db instance first.
ansible-playbook db-playbook.yml -i inventory-db.yml --private-key "$private_SSH_KEY"

# Start configuring app instances after.
ansible-playbook app-playbook.yml -i inventory-app.yml --private-key "$private_SSH_KEY"

cd -

#-------------------Ansible--------------------

#----------------END-------------------