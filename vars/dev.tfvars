vpc_cidr               = "10.0.0.0/16"
environment            =  "dev"
region                 =  "us-east-1"
availability_zones     = ["us-east-1a", "us-east-1b"]
public_subnets_cidr         = ["10.0.10.0/24", "10.0.20.0/24"]
private_subnets_cidr        = ["10.0.1.0/24", "10.0.2.0/24"]

# these are used for tags
app_name               = "node-js-app"
project                = "levva_test"

container_definitions_host_port = 80
container_definitions_container_port = 3000