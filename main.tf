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
  access_key = "myAWSAccesssKeyxjdklfdakf" #AWS_ACCESS_KEY (USER INPUT ADJUSTMENT REQUIRED)
  secret_key = "MyAWSSecretKeyxkldkfhadjkfh" #AWS_SECRET_KEY (USER INPUT ADJUSTMENT REQUIRED)
}


#### Configure the rediscloud provider:
#### go to your Redis Cloud Account >  Access Managment > API Keys > 
#### create new API Key (this gives you the secret key, the API_key is the API account key)
provider "rediscloud" {
    api_key = "myRedisAccesssKeyxjdklfdakf" #REDIS_CLOUD_ACCESS_KEY (USER INPUT ADJUSTMENT REQUIRED)
    secret_key = "MyRedisSecretKeyxkldkfhadjkfh" #REDIS_CLOUD_SECRET_KEY (USER INPUT ADJUSTMENT REQUIRED)
}


############################################### AWS VPC
###### The customer application VPC in the customers AWS account
#### COMMENT SECTION OUT IF YOU WANT TO USE EXISTING AWS VPC (START)

#### Create the VPC
resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16" #AWS VPC CIDR
  enable_dns_support          = true
  enable_dns_hostnames        = true

  tags = {
    Name = "my-app-vpc-us-east-1",
    Owner = "redisuser@redis.com"
  }
}

#### Create the subnets
resource "aws_subnet" "subnet" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "my-app-vpc-subnet"
  }
}

#### network
#### Create Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags = {
    Name = "my-app-vpc-igw",
    Owner = "redisuser@redis.com"
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
    Name = "my-app-vpc-rt",
    Owner = "redisuser@redis.com"
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

output "route-table-id" {
  description = "route table id"
  value = aws_default_route_table.route_table.id
}
#### COMMENT SECTION OUT IF YOU WANT TO USE EXISTING AWS VPC (END)


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
  card_type = "Visa"
  last_four_numbers = "1234" #last 4 digits of cc (USER INPUT ADJUSTMENT REQUIRED)
}

resource "rediscloud_subscription" "example" {

  name = "redis-user-sub1"
  payment_method = "credit-card"
  payment_method_id = data.rediscloud_payment_method.card.id
  memory_storage = "ram"

  cloud_provider {
    provider = "AWS"
    cloud_account_id = data.rediscloud_cloud_account.account.id
    region {
      region = "us-east-1"
      networking_deployment_cidr = "10.1.0.0/24" #Redis Cloud Subscription CIDR (Must not overlap with customer AWS VPC CIDR!)
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
   aws_account_id = "123456789012" #Customer AWS Account ID (12 digits) (USER INPUT ADJUSTMENT REQUIRED)
   vpc_id = aws_vpc.vpc.id
   vpc_cidr = "10.0.0.0/16" #Customer AWS VPC CIDR (matches the AWS VPC Resource VPC CIDR)

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
  destination_cidr_block    = "10.1.0.0/24" # Redis Cloud Subscription CIDR
  vpc_peering_connection_id = data.aws_vpc_peering_connection.pc.id
}