variable "vpc_cidr" {
    type = string
    default = "10.0.0.0/16" 
}

variable "public_subnets" {
    type = list(string)
}

variable "private_subnets" {
    type = list(string)
}

variable "name" {
    type = string
}

variable "availability_zone" {
    type = list(string)
}

variable "db_name" {
    type = string
  
}
variable "db_password" {
  description = "RDS root user password"
  type        = string
  sensitive   = true
}

variable "username" {
  description = "RDS root user name"
  type        = string
  sensitive   = true
}

variable "db_engine" {
  type = string
}

variable "db_engine_version" {
    type = string
}

variable "db_storage" {
    type = number  
}

variable "db_instance_type" {
    type = string
}

variable "publicly_accessible" {
  type = bool
}

variable "private_only" {
    type = bool
}

variable "skip_final_snapshot" {
    type = bool
}

variable "enable_db" {
    type = bool
}

variable "db_port" {
    type = string
}


variable "db_instance_count" {
    type = number
}

variable "repo_name" {
    type = string
  
}

variable "branch_name" {
    type = string
  
}

variable "load_balancer_certificate" {
    type = string
  
}

variable "account_id" {
    type = number
  
}

variable "aws_region" {
    type = string 
  
}