# tf-rediscloud-subscription-peering-aws
Create a Redis Cloud on AWS Subscription and Database and VPC peer subscription to customer AWS VPC using the Redis Cloud Terraform Provider. ([link](https://registry.terraform.io/providers/RedisLabs/rediscloud/latest/docs))


# Overview

This repo will create a brand new Redis Enterprise Cloud on AWS subscription and deploy a Redis Enterprise Database in that subscription.
The repo will also create a brand new AWS VPC in the customer AWS account and use the Redis Cloud Terraform provider to initiate a VPC peering connection between the Redis Enterprise Cloud on AWS subscription and the customer AWS VPC.
AWS requires a route to be added to the customers AWS VPC Route table inside the customers AWS Account. The repo will use the AWS Terraform provider to add this route.

If you would like to use an existing AWS VPC you will need to comment out the AWS VPC resources and replace the variable values in the `Redis Cloud Subscription`.
A walk through can be found below. [Use Existing AWS VPC](#i-have-an-existing-aws-vpc-i-want-to-use)

The repo is made as simple as possible with all values hardcoded into the `main.tf` file.

# Getting Started: Create a Redis Cloud subscription from Terraform

#### Prerequisites
* aws account
* aws-cli (*aws access-key and secret-key*)
* redis cloud account ([link](https://redis.com/try-free/))
  * redis cloud API Key and Secret (*instructions below*) [API & Secret Key](#step-1-redis-cloud-account-steps)
* terraform installed on local machine
* VS Code

Once you have the prerequisties we can get started.

## Step 1: Redis Cloud Account Steps
1. Navigate to your Redis Cloud Account ([link](https://app.redislabs.com/))
2. Log in and click "Access Management"
3. Click API Keys

![Alt text](images/rc-accessmanagment-1.png?raw=true "Title")

4. Click the "+" icon and create a new API Key User.

![Alt text](images/rc-accessmanagment-2.png?raw=true "Title")

5. Save the API `Account Key` & the `Secret Key` information into the `main.tf` file

Example Below:
```
#### Configure the rediscloud provider:
#### go to your Redis Cloud Account >  Access Managment > API Keys > 
#### create new API Key (this gives you the secret key, the API_key is the API account key)
provider "rediscloud" {
    api_key = "myRedisAccesssKeyxjdklfdakf" #REDIS_CLOUD_ACCESS_KEY (USER INPUT ADJUSTMENT REQUIRED)
    secret_key = "MyRedisSecretKeyxkldkfhadjkfh" #REDIS_CLOUD_SECRET_KEY (USER INPUT ADJUSTMENT REQUIRED)
}
```

## Step 2: AWS Account Steps

1. Gather required AWS Account information
* AWS Account ID (12-digit account number)
  * can be found under account settings
* aws-cli (*aws access-key and secret-key*)

2. Save the API `Account Key` & the `Secret Key` information into the `main.tf` file

Example Below:
```
#### configure the AWS provider
#### AWS region and AWS key pair
provider "aws" {
  region     = "us-east-1"
  access_key = "myAWSAccesssKeyxjdklfdakf" #AWS_ACCESS_KEY (USER INPUT ADJUSTMENT REQUIRED)
  secret_key = "MyAWSSecretKeyxkldkfhadjkfh" #AWS_SECRET_KEY (USER INPUT ADJUSTMENT REQUIRED)
}
```

## Step 3: Update hardcoded values in `main.tf`

Many of the hardcoded values do not need to change. But feel free to update them as desired.
There are a few that much be updated. Please see below:

### rediscloud_payment_method
Update the the info in the resource block
```
############################################### Redis Cloud Subscription

data "rediscloud_payment_method" "card" {
  card_type = "Visa"
  last_four_numbers = "1234" #last 4 digits of cc (USER INPUT ADJUSTMENT REQUIRED)
}
```

### rediscloud_subscription_peering
Update the the info `aws_account_id` in this resource block
```
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
```

## Step 4: Run Terraform!

Now that you have replaced the required variable values
you can run terraform and create your Redis Cloud subscription, database, 
AWS VPC and VPC peer it to the Redis Cloud Subscription.

* Open a terminal in VS Code:
```bash
  terraform init
  terraform plan
  terraform apply
```

## Cleanup

Remove the resources that were created.

```bash
  terraform destroy
```

# Optional Steps:

## I have an existing AWS VPC I want to use

If you have an existing AWS VPC you would like to peer then you will need to make a few adjustments.

1. Comment out the AWS VPC resource blocks

Comment out the following in `main.tf`:
```
############################################### AWS VPC
###### The customer application VPC in the customers AWS account

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
```

Now terraform will not provision a new VPC.
Now you will need to update the variable values in the `Redis Cloud VPC Peering` section

Please update the values with the **#UPDATE WITH EXISTING AWS VPC ...**
```
############################################  Redis Cloud Subscription peering

### Redis Cloud Subscription peering

resource "rediscloud_subscription_peering" "example" {
   subscription_id = rediscloud_subscription.example.id
   region = "us-east-1" #UPDATE WITH EXISTING AWS VPC REGION
   aws_account_id = "123456789012" #Customer AWS Account ID (12 digits) (USER INPUT ADJUSTMENT REQUIRED)
   vpc_id = aws_vpc.vpc.id #UPDATE WITH EXISTING AWS VPC ID
   vpc_cidr = "10.0.0.0/16" #UPDATE WITH EXISTING AWS VPC CIDR

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
  peer_vpc_id = aws_vpc.vpc.id #UPDATE WITH EXISTING AWS VPC ID
  status = "active"
  depends_on = [aws_vpc_peering_connection_accepter.example-peering]
}
```

Now that everything is updated go ahead and run terraform.

## Run Terraform!

Now that you have replaced the required variable values
you can run terraform and create your Redis Cloud subscription, database, 
AWS VPC and VPC peer it to the Redis Cloud Subscription.

* Open a terminal in VS Code:
```bash
  terraform init
  terraform plan
  terraform apply
```

## Cleanup

Remove the resources that were created.

```bash
  terraform destroy
```