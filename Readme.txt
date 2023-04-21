1. The following services must be created in AWS in order to run this sample.
    1. VPC
    2. RDS
    3. ECS
    4. ALB
    5. IAM

2. Clone the application repository into local machine and build the docker image ad push it into ECR repository. 

2. Once it's done, Please clone this terraform repository onto your local computer and go to the dev folder to create the infrastructure.

3. A few parameters in the main.tf file, including the username, password, aws account number, and region, need to be updated.

Once you're done, enter the following command within the dev folder to deploy the infrastructure to AWS.
 1. terraform init -- this will install the necessary terraform plugins.
 2. Terraform plan --- with this, we can see the list of services that Terraform will be deployed.
 3. Terraform apply --- This will build the infrastructure on AWS Cloud

 ###### Run the application locally #######
 1. Clone the application repository onto your local computer in order to execute the application locally.
 2. Update the MYSQL_USER and MYSQL_PASS values in the docker-compose.yml file. 
 3. Change the corsOptions Origin in the server.js file to http://localhost:8080 
 4. Update the database HOST, USER, and PASS in the app/config/db-config.js file.
 4. To deploy the programme locally, please run the following command once it has finished.
     1. docker-compose up -d --- This will set up and run the Docker container on your local machine.
     2. docker ps --- To see the list of running containers.