##### Terraform providers for rediscloud and aws
terraform {
 required_providers {
   rediscloud = {
     source = "RedisLabs/rediscloud"
     version = "1.0.1"
     }
   aws = {
      source  = "hashicorp/aws"
      version = ">= 3.0"
      }
  }
}

#### configure the AWS provider
#### AWS region and AWS key pair
provider "aws" {
  region     = "us-east-1"
  access_key = var.aws_creds[0]
  secret_key = var.aws_creds[1]
}


#### Configure the rediscloud provider:
#### go to your Redis Cloud Account >  Access Managment > API Keys > 
#### create new API Key (this gives you the secret key, the API_key is the API account key)
provider "rediscloud" {
    api_key = var.rediscloud_creds[0]
    secret_key = var.rediscloud_creds[1]
}


############################################### AWS VPC

#### Create the VPC
resource "aws_vpc" "vpc" {
  cidr_block = var.aws_customer_application_vpc_cidr
  enable_dns_support          = true
  enable_dns_hostnames        = true

  tags = {
    Name = format("%s-%s-vpc", var.prefix_name, "us-east-1"),
    Project = format("%s-%s", var.prefix_name, "us-east-1"),
    Owner = var.prefix_name
  }
}

#### Create the subnets
resource "aws_subnet" "subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = var.subnet_cidr_block
  availability_zone = "us-east-1a"
  tags = {
    Name = format("%s-subnet", var.prefix_name)
  }
}

#### network
#### Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = format("%s-igw", var.prefix_name),
    Project = format("%s-%s", var.prefix_name, "us-east-1"),
    Owner = var.prefix_name
    }
}

#### Create the default route table
resource "aws_default_route_table" "route_table" {
  default_route_table_id = aws_vpc.vpc.default_route_table_id
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = aws_internet_gateway.igw.id
    }

  tags = {
    Name = format("%s-rt", var.prefix_name),
    Project = format("%s-%s", var.prefix_name, "us-east-1"),
    Owner = var.prefix_name
  }
}

#### Associate the subnets with the default route table
resource "aws_route_table_association" "subnet_route_table_associations" {
  subnet_id = aws_subnet.subnet.id
  route_table_id = aws_default_route_table.route_table.id
}

### VPC Outputs
output "subnet-id" {
  value = aws_subnet.subnet.id
}

output "vpc-id" {
  value = aws_vpc.vpc.id
}

output "vpc-name" {
  description = "get all tags, get the Project Name tag for the VPC"
  value = aws_vpc.vpc.tags_all.Project
}

output "route-table-id" {
  description = "route table id"
  value = aws_default_route_table.route_table.id
}


############################################### Redis Cloud Account Information
######## Redis Cloud Account Information
data "rediscloud_cloud_account" "account" {
  exclude_internal_account = true
  provider_type = "AWS"
}

output "rc_cloud_account_id" {
  value = data.rediscloud_cloud_account.account.id
}

output "rc_cloud_account_provider_type" {
  value = data.rediscloud_cloud_account.account.provider_type
}

output "cloud_account_access_key_id" {
  value = data.rediscloud_cloud_account.account.access_key_id
}

############################################### Redis Cloud Subscription

data "rediscloud_payment_method" "card" {
  card_type = var.cc_type
  last_four_numbers = var.cc_last_4
}

resource "rediscloud_subscription" "example" {

  name = "redis-user-sub"
  payment_method = "credit-card"
  payment_method_id = data.rediscloud_payment_method.card.id
  memory_storage = "ram"

  cloud_provider {
    provider = "AWS"
    cloud_account_id = data.rediscloud_cloud_account.account.id
    region {
      region = "us-east-1"
      networking_deployment_cidr = var.rc_networking_deployment_cidr
      preferred_availability_zones = ["us-east-1a","us-east-1b","us-east-1c"]
      multiple_availability_zones  = true
    }
  }

  // This block needs to be defined for provisioning a new subscription.
  // This allows creating a well-optimised hardware specification for databases in the cluster
  creation_plan {
    average_item_size_in_bytes = 1
    memory_limit_in_gb = 25
    quantity = 1
    replication= true
    support_oss_cluster_api= false
    throughput_measurement_by = "operations-per-second"
    throughput_measurement_value = 12000
    modules = ["RedisJSON"]
  }
}

output "rediscloud_subscription_id" {
  value = rediscloud_subscription.example.id
}

############################################ Redis Cloud DB


// The primary database to provision
resource "rediscloud_subscription_database" "example" {
    subscription_id                       = rediscloud_subscription.example.id
    name                                  = "example-db"
    protocol                              = "redis"
    memory_limit_in_gb                    = 5
    data_persistence                      = "none"
    throughput_measurement_by             = "operations-per-second"
    throughput_measurement_value          = 1000
    support_oss_cluster_api               = "false"
    external_endpoint_for_oss_cluster_api = "false"
    replication                           = "true"
    average_item_size_in_bytes            = 0
    modules                               = [
                                        {
                                        "name": "RedisJSON"
                                        },
                                        {
                                        "name": "RedisBloom"
                                        }
                                    ]
    # alert {
    #   name = "dataset-size"
    #   value = 40
    # }

}


############################################  Redis Cloud Subscription peering

### Redis Cloud Subscription peering

resource "rediscloud_subscription_peering" "example" {
   subscription_id = rediscloud_subscription.example.id
   region = "us-east-1"
   aws_account_id = var.aws_customer_application_aws_account_id
   vpc_id = aws_vpc.vpc.id
   vpc_cidr = var.aws_customer_application_vpc_cidr

   depends_on = [
    rediscloud_subscription.example
    ]
}


resource "aws_vpc_peering_connection_accepter" "example-peering" {
  vpc_peering_connection_id = rediscloud_subscription_peering.example.aws_peering_id
  auto_accept               = true
}

### AWS Terrafrom to add route table in customer AWS environment
### ADD ROUTE TABLE ROUTE


# Declare the data source
data "aws_vpc_peering_connection" "pc" {
  peer_vpc_id = aws_vpc.vpc.id
  status = "active"
  depends_on = [aws_vpc_peering_connection_accepter.example-peering]
}

## output of the sub id
output "aws_vpc_peering_connection" {
  value = data.aws_vpc_peering_connection.pc.id
}

# Create a route
resource "aws_route" "r" {
  route_table_id            = aws_default_route_table.route_table.id
  destination_cidr_block    = var.rc_networking_deployment_cidr
  vpc_peering_connection_id = data.aws_vpc_peering_connection.pc.id
}