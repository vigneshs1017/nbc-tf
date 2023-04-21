locals {
  project = "nbc"
  env = "dev"
}

module "nbc_aws" {
    source = "../aws"
    ##### AWS Account ID ######
    account_id = 919490798061
    aws_region = "ca-central-1"
    ##### AWS Account ID ######

    #### VPC ######
    vpc_cidr = "10.0.0.0/16"
    public_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
    private_subnets = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
    name = "${local.project}-${local.env}"
    availability_zone = ["ca-central-1a", "ca-central-1d", "ca-central-1b"]
    #### VPC ######

    #### RDS ######
    enable_db = true
    private_only = true
    publicly_accessible = false
    db_password = "MJGCfy9GkhZurLJG"
    username = "nbcdev"
    db_name = "nbcapp"
    db_engine = "mysql"
    db_engine_version = "5.7" 
    db_port = "3306"
    db_storage = 20
    db_instance_type = "db.t2.micro"
    db_instance_count = 1
    skip_final_snapshot = true
    #### RDS ######

    ##### ECS ######
    repo_name = "nbcdemoapp"
    branch_name = "master"
    load_balancer_certificate = "arn:aws:acm:ca-central-1:919490798061:certificate/e2b8c3d2-998d-4b8b-847e-753489d09b75"
    ##### ECS ######


}