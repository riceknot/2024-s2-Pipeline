# COSC2759 Assignment 2

## Student details

- Full Name: Louisa Christine Carbone
- Student ID: s3945892

- Full Name: Chu Khai Minh
- Student ID: s3864172

## Solution design

The expected outcome of this solution is to automate the deploy of the Foo app, a web application backed by a PostgreSQL database, onto AWS infrastructure using Terraform for infrasturctre provisioning and Ansible for configuration management.

### Infrastructure

The infrastructure setup includes:

- AWS EC2 instance running Ubuntu 22.04, provisioned via Terraform.
- Ensuring Docker is installed on the EC2 instance to manage the application and database containers.
Security groups are configured to:
- Allow inbound traffic on ports 22 (SSH) and 80 (HTTP).
- Allow outbound traffic on port 443 (HTTPS).

#### Key data flows

- User reqest flow: A user accesses the Foo app by navigating to the public IP address of the EC2 instance. The request reches the web server runing in the Foo app container via port 80 (HTTP).
- Database interaction: The Foo app interacts with a PostgreSQL database running in a Docker container, using port 5432. The database is pre-populated with production data loaded from a snapshot.

### Deployment process

#### Prerequisites

Before deployment, we must ensure the following prerequisites are met:
- AWS account: Access to AWS is require for provisioning the EC2 istance.
- SSH key pair: Ensure you have an existing key pair in your AWS region to connect to the EC2 instance  (In this scenario, we are connecting the us-east)
- Terraform: Terraform must be installed to provision infrastructure.
- Ansible: Ansible must be installed to configure the EC2 instance and deploy the app.
- Docker: Docker is installed via Ancible on the EC2 instance to run the containers.

#### Description of the GitHub Actions workflow

The Github Actions workflow will automate the deployment through the following actions (no pun intended):

#### Trigger:
- A push to the main branch triggers the workflow.

#### Terraform setup:
- Workflow initalises Terraform.
- Runs terraform apply to provision infrastructure, including EC2 instance and security group.

#### Ansible configuration:
- After provisioning, Ancible installs Docker on the EC2 instance.
- Docker runs the application and database containers.

#### Test deployment:
- Once deployment is complete, the public IP of the EC2 instance is retrieved.
- Workflow tests that the app is accessible via HTTP on port 80.

#### Validating that the app is working

Post deployment, you can validate the app by navigating to the EC2 instance's public IP in a web browser via:

http://${APP_IP_ADDRESS}/

Check the app loads and that you can access the /foos endpoint to confirm database connectibity.

## Contents of this repo

- /github/workflows/ci-pipeline.yml: The CI pipeline for Github Actions to deploy the infrastructure.

- ansible-1: Ansible files for Section A.

- ansible-2: Ansible files for Section B - D.

- app: Folder that contains files the application.

- img: Stores images, purely to be used for this README file.

- infra-1: Terraform files for Section A.

- infra-2: Terraform files for Section B - D.

- misc: store miscellaneous files, including an SQL file that is used to initialize the database with data.

- s3-bucket: Terraform files for Section C, to deploy an S3 Bucket.

- deploy_section_A.sh: Shell script to deploy infrastructure for Section A.

- deploy_section_D.sh: Shell script to deploy infrastructure for Section D, mainly used by the Github Actions pipeline.

# Section A:
<img src="/img/sectionA-diagram.drawio.png" style="height: 400px;"/>
Section A requires us to deploy 1 single instance that contains both the app and db. For this task, we decided to use Docker Compose to deploy 2 containers: 1 for app and 1 for db. Folders infra-1, ansible-1, file docker-compose.yml inside 'misc', and file deploy-section-A.sh have been created exclusively for this task.

## Instance deployment and configuration.
### Infra-1 (Terraform deployment)
#### you.auto.tfvars (variables)
<img src="/img/sectionA-variable.png" style="height: 80px;"/>
We create 3 variables:

 - path_to_ssh_public_key: defining path to ssh public key.
   
 - allow_all_ip_addresses: if set to true, it will uses cidr ["0.0.0.0/0"] to allow all ip addresses to access the instances.
   
 - my_ip_address: use to allow the user to SSH into the instances.

#### Creating instance (foo_instance)
<img src="/img/sectionA-instance.png" style="height: 150px;"/>
Using the AWS "aws_instance" resource block, we create an instance called 'foo_instance' with Ubuntu VM and uses the security group 'foo_group'.

#### Security group (foo_group)
<img src="/img/sectionA-sg.png" style="height: 300px;"/>
The security group block allows all IP address to access it through HTTP. However, it only allows certain IP addresses to SSH into the instance, such as the user's IP address. All IP addresses can SSH into the instance if the variable 'allow_all_ip_addresses' is set to true.

#### Output (foo_instanc_public_ip)
<img src="/img/sectionA-output.png" style="height: 50px;"/>
This block is to let Terraform produce the foo instance's public IP address as an output. This can later be used for the shell script to automatically configure the instance with Ansible.

### Ansible configuration (ansible-1)
#### Installing Docker and dependencies
<img src="/img/sectionA-docker.png" style="height: 300px;"/>
This entire section is for installing docker and the resources necessary for docker.

#### Installing Docker Compose
<img src="/img/sectionA-compose.png" style="height: 90px;"/>
Since we need to create 2 Docker containers inside a single instance, we decided to use Docker Compose. 

#### Uploading necessary files
<img src="/img/sectionA-upload.png" style="height: 300px;"/>
Since we are including both the app and db inside foo instance, we need to upload the necessary files for both. 

- This section first create a new directory in the instance called 'app' and upload all of the app's files into it.
  
- Then, it creates another directory called 'misc' upload the 'snapshot-prod-data.sql' into it.
  
- Finally, it uploads the 'docker-compose.yml' file into 'misc' directory, which will be explained later.
  

### Docker Compose (docker-compose.yml)
#### DB container
<img src="/img/sectionA-container-db.png" style="height: 200px;"/>
To set up the container for db, we first pull an 'postgres:14.7' image to get the necessary files to deploy a PostgreSQL database. 
Then, we set it up with its name 'foo', user as 'pete', and password as 'devops'.


For ports, we set it to PostgreSQL default port of 5432.
Finally, in 'volumes', we refer to the 'snapshot-prod-data.sql' and initialize the database by inserting data from the SQL file.

#### App container
<img src="/img/sectionA-container-app.png" style="height: 200px;"/>
To set up the app container, we first pull an image from 'mattcul/assignment2app:1.0.0' to get the necessary dependencies such as NodeJS and Express for the app to work.


For the environment, we set the port to 3001, so that the container can communicate with the URL 'mattcul/assignment2app:1.0.0'. Then, we can establish a connection between app and db with db_hostname, and correct username and password, with db_port being 5432.


## Section A shell script.
<img src="/img/sectionA-shell1.png" style="height: 150px;"/>
The shell script will first run the function 'get_user_input()' to prompt the user with 2 inputs, which are the paths to the user's public and private SSH keys.


<img src="/img/sectionA-shell2.png" style="height: 150px;"/>
The shell script then automatically takes the user's IP address (for Terraform to use later) and checks for the user's AWS CLI credentials.


<img src="/img/sectionA-shell3.png" style="height: 200px;"/>
To deploy the infrastructure, the shell script will access 'infra-1' folder, then initialize and deploy a single instance called 'foo', using the user's IP address and path to their public SSH key.



After the deployment is done, it will store the instance's public IP address in the variable 'FOO_INSTANCE_IP', which can be used later with Ansible.


<img src="/img/sectionA-shell4.png" style="height: 250px;"/>
Then, the shell script will modify the 'inventory-foo.yml' file with the instance's public IP address, then execute ansible-playbook command to configure the 'foo' instance.


<img src="/img/sectionA-shell5.png" style="height: 90px;"/>
Finally, the shell will SSH into the 'foo' instance and run the command: 'sudo docker-compose up -d' to deploy the containers 'app' and 'db' inside the instance.


## Section A Instructions:
### Using deploy-section-A.sh shell script
Simply run the deploy_section_A.sh script:

./deploy_section_A.sh

Once ran, fill in your SSH key paths as the input prompts.

# Section B:
<img src="/img/sectionB-diagram.drawio.png" style="height: 400px;"/>
This section requires us to deploy 3 instances: 2 apps and 1 db. A load balancer must be deployed for the 2 app instances, and a communication must be established between the 2 apps' containers and db container. Folders created exclusively for this section are infra-2 and ansible-2.


The diagram above is applicable from Section B all to Section D, as the infrastructure does not change much along the way.

### Infra-2 (Terraform deployment)
#### you.auto.tfvars (variables)
<img src="/img/sectionB-variable.png" style="height: 100px;"/>
We create 6 variables:

 - path_to_ssh_public_key: defining path to ssh public key.
   
 - allow_all_ip_addresses: if set to true, it will uses cidr ["0.0.0.0/0"] to allow all ip addresses to access the instances.
   
 - my_ip_address: use to allow the user to SSH into the instances.
   
 - app_address_1: app-1 public IP address.
   
 - app_address_2: app-2 public IP address.
  
 - db_address: db public IP address.


The three last variables are left empty on the first 'terraform apply'. After that, the IP addresses must be filled in, then run 'terraform apply' again.  

#### Creating Instances
<img src="/img/sectionB-instance.png" style="height: 400px;"/>
Using the AWS "aws_instance" resource block, we create 3 instances: app-1, app-2, and db. The 2 apps instance and db uses 2 different security groups.

#### Apps' security group
<img src="/img/sectionB-app-sg.png" style="height: 400px;"/>
With this security group, all IP addresses are allowed to access the instances through SSH, HTTP, and send HTTP requests. However, in order for the apps to communicate with db, an additional EGRESS rule is made with port 5432 and db's public IP as CIDR.

#### DB's security group
<img src="/img/sectionB-db-sg.png" style="height: 400px;"/>
Very similar to the app's security group. However, in order for the db to allow requests from the app instances, an additional INGRESS rule is made with port 5432 and apps' public IPs as CIDR.  

#### Load balancer (ELB)
<img src="/img/sectionB-lb.png" style="height: 300px;"/>
This section is to set up the load balancer for the 2 app instances. Since the load balancer is used to share traffic between the instances, we need to specify 2 different avaiability zones, and the 2 instances to deploy on (app-1 and app-2). The listener is for the load balancer to listen to requests (HTTP) from a specific port (80) and foward them to the app instances.

#### Load balancer security group
<img src="/img/sectionB-lb-sg.png" style="height: 300px;"/>
The load balancer also needs a security group. This group allows the load balancer to take any HTTP requests with port 80 (ingress). The egress rule allows the load balancer to send out traffic (to app instances) with absolute no restriction (protocal set to -1 means accepts all protocols).

#### Updating App security group with Load balancer security group
<img src="/img/sectionB-lb-sg-update.png" style="height: 150px;"/>
The section updates the app instances' security group with load balancer security group, which allows the instances and the load balancer to have a proper communication.

#### Output
<img src="/img/sectionB-output.png" style="height: 150px;"/>
Allows terraform to output all instances' public IP addresses. Later be used for other tasks, such as ansible and shell script.

### Ansible configuration (ansible-2)
#### Variable (vars.yml)
<img src="/img/sectionB-vars.png" style="height: 30px;"/>
A 'vars.yml' file is created purely to create and define variable 'db_ip' to be used later in ansible-playbook files. 'db_ip' needs to be filled in with the db instance public IP address.

#### DB Configuration (db-playbook)
<img src="/img/sectionB-db-playbook.png" style="height: 300px;"/>
The db must be set up first before the apps. The configuration is very similar to Section A, except a task that has been made to create a container speficially for db. The container is set up to have PostgreSQL image, and an environment with user and password. The container is also set at port 5432, which is PostgreSQL default port. Volumes refer to the file that is mounted onto container, which in this case is the SQL data file that is upload onto the db instance, used to initialize the db with data.

#### App Configuration (app-playbook)
<img src="/img/sectionB-app-playbook.png" style="height: 300px;"/>
The app-playbook.yml file will configure both app-1 and app-2 instances. The configuration is very similar to Section A, except a task that has been made to create containers speficially for both apps. It is set up with 'mattcul/assignment2app:1.0.0' URL image, with appropriate env to communicate with db, such DB_HOSTNAME with the db's public IP address, matching username and password, and internal port 3001. For published ports, it is set as '80:3001' so that it will allow users to access it through HTTP (port 80) and listen for any requests from the internal environment through port 3001.


# Section C:
This section require us to deploy an AWS S3 Bucket and copy our terraform state file (from section B) onto it. The assignment has provided us with with a terraform file called 'state-bucket-infra.tf' with all of the required resources for the task. We have put this file into a folder called 's3-bucket' for deployment.


By putting the terraform state file into the Bucket, deployment after the first initialization will let Terraform fetch the state file from the bucket to deploy the infrastructure.

#### S3-bucket file (state-bucket-infra.tf)
<img src="/img/sectionC-bucket.png" style="height: 300px;"/>
The 'aws_s3_bucket' resource block is used to deploy the S3 bucket itself.

- 'bucket': the name of the bucket.
  
- 'acl': to set the bucket public or private.
  
Since AWS S3 Bucket names has to be globally unqiue, it is necessary to modify the name of the bucket with both letters and numbers, which in this case 'foostatebucket-s2001'. 'acl' is set to private so that no one can access the bucket except the owner.


The 'aws_dynamodb_table' resource block is to create a AWS Dynamo database used for state locking to prevent multiple users from applying changes to the terraform state file at the same time.

#### Adjustment to Infra-2 main.tf
<img src="/img/sectionC-main.png" style="height: 300px;"/>
In order for our main terraform state file to be copied onto the S3 bucket, we need to make a small adjustment to infra-2 main.tf file.

A section is added into the beginning terraform block, called 'backend "s3"'. This section states the bucket (foostatebucket-s2001) and Dynamo database (foostatelock) to use, and the path to the terraform state file (key="terraform.tfstate").

#### Deployment

1. Access the infra-2 folder:  cd infra-2

2. Modify line 10 (or bucket) in 'main.tf' file with your bucket name of your choice.

3. Access the s3-bucket folder:  cd s3-bucket

4. Modify line 6 (bucket) in 'state-bucket-infra.tf' with your bucket name of your choice.

5. Make sure that the bucket name between 'main.tf' and 'state-bucket-infra.tf' MUST MATCH with each other.

7. While inside s3-bucket folder, initialize terraform: terraform init

8. Deploy the bucket: terraform apply


Once the bucket has been deployed, we can continue by deploying the instances in Infra-2 like normal.


# Section D
In this task, we are required to create a shell script to deploy section B terraform instances and ansible configuration, and uses Github Actions to execute and run that shell script.

The S3 Bucket must be deployed manually first before doing anything in this section.

## Task 1
### Github Secrets
<img src="/img/sectionD-secrets.png" style="height: 150px;"/>
Since Terraform and Ansible requires both AWS CLI credentials and SSH keys to work correctly, we need to put them in Github Secrets so the pipeline can them.

By using Secrets, the pipeline can later use them for deploying Terraform and Ansible correctly.


Before triggering the pipeline, the user MUST do these steps first:

1. In the Github Repo, click 'Settings'.

2. While in 'Settings', scroll down to 'Security' section, and click 'Secrets and variables', then click 'Actions' under it.

3. While in 'Secrets', in the 'Repository secrets' section, the user MUST create or modify 4 variables: 

  - AWS_CREDS: copy your AWS CLI credentials into it.

  - SSH_PRIVATE: copy the content of your SSH private key into it.

  - SSH_PUBLIC: copy the content of your SSH public key into it.

  - USER_IP: copy your IP address into it (ifconfig.co).


### CI-pipeline
The pipeline will run a shell script, which will execute the necessary commands to deploy Terraform and Ansible.


But before running the shell script, Github Actions must set up both the AWS CLI credentials and SSH keys:
<img src="/img/sectionD-pipeline1.png" style="height: 300px;"/>

These two tasks are needed to make 2 directories: '.aws' and '.ssh'. The first task will copy the AWS CLI credentials from Secrets into the 'credentials' file. And for the second task, it will copy both SSH public and private keys from Secrets into 'ssh_key.pub' and 'ssh_key' files, then set their permissions correctly.


<img src="/img/sectionD-pipeline2.png" style="height: 250px;"/>

Next, the pipeline must install both Terraform and Ansible in order for the shell script to work correctly.

Both Terraform and Ansible are installed following their documents and instructions.


<img src="/img/sectionD-pipeline3.png" style="height: 200px;"/>
Finally, the pipeline pass down 3 variables into the shell script's environment for use:
    
    - SSH_PRIVATE_KEY: path to the SSH private key.
    
    - SSH_PUBLIC_KEY: path to the SSH public key.

    - USER_IP: the user's IP address taken from Secrets.

Then, it will execute the shell script to do the rest of the deployment.


### Shell script (deploy_section_D.sh)
#### AWS credentials and SSH key paths.
<img src="/img/sectionD-shell1.png" style="height: 250px;"/>
Before executing all of the necessary tasks, the script first tests out the AWS CLI credentials, and create 3 variables that take the SSH private and public key paths, and the user's IP address that was passed down by the Github runner.


#### Terraform deployment
<img src="/img/sectionD-shell2.png" style="height: 350px;"/>
After accessing the infra-2 folder, the script will initialize and deploy the instances with only the user's IP and path to public ssh key for the first time.


After the initial deployment, the shell will store the 3 instances' public IP addresses into variables to be used later in the next Terraform deployment and Ansible.


The script has to deploy the instances again, this time includes the apps' instance and db instance public IPs. This is to let Terraform update their security groups correctly (refer to section B).


#### Ansible configuration
<img src="/img/sectionD-shell3.png" style="height: 300px;"/>
Before configuring the instances with Ansible, the shell has to modify 3 files (inventory-db.yml, inventory-app.yml, and vars.yml) with the correct instances' public IP addresses.


<img src="/img/sectionD-shell4.png" style="height: 100px;"/>
Then finally, the shell will execute ansible-playbook commands to start the configurations. The shell configures the db instance BEFORE configuring the app instances.

## Task 2
For this sub task, we need to adjust the pipeline file so that it can be triggered with REST API and when there's a change to the 'main' branch.

#### Adjustment to pipeline
<img src="/img/sectionD-trigger.png" style="height: 100px;"/>
The image above shows the adjustment we need to make the pipeline for this task. 

Since the task asks to run the pipeline everytime the there's a change on the 'main' branch, we decided to make the pipeline only run when there's a 'push' on 'main' branch.


The 'workflow_dispatch:' is also added, which is essential for allowing the pipeline to be triggered through REST API.

#### REST API Command (manually triggers pipeline)
The following command is used to trigger the pipeline manually:

curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer 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" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/rmit-sdo-2024-s2/s3945892-s3864172-assignment2/actions/workflows/ci-pipeline.yml/dispatches \
  -d '{"ref":"main"}'


## Task 3
After running the pipeline multiple times, it has given no errors. Therefore, this task is completed.


## Section D Instruction:
Assuming that the S3 Bucket has been deployed (please refer to section C), the instruction for Section D is as follows:


1. Go to the repo's Secrets and create or modify 4 variables:
   
  - AWS_CREDS: copy your AWS CLI credentials into it.

  - SSH_PRIVATE: copy the content of your SSH private key into it.

  - SSH_PUBLIC: copy the content of your SSH public key into it.

  - USER_IP: copy your IP address into it (ifconfig.co).


2. Run the REST API command to trigger the pipeline for deployment:
   
curl -L \
  -X POST \
  -H "Accept: application/vnd.github+json" \
  -H "Authorization: Bearer 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" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  https://api.github.com/repos/rmit-sdo-2024-s2/s3945892-s3864172-assignment2/actions/workflows/ci-pipeline.yml/dispatches \
  -d '{"ref":"main"}'
