# tf-rediscloud-subscription-peering-aws
Create a Redis Cloud on AWS Subscription and Database and VPC peer subscription to customer AWS VPC.


# Overview

This repo will create a brand new AWS VPC and VPC peer it to the Redis Cloud Subscription VPC. It will add the Redis Cloud Subscription VPC CIDR to the AWS Route Table.

If you would like to use an existing AWS VPC you will need to comment out the AWS VPC resources and replace the variable values.

The repo is made as simple as possible with most of the variables hardcoded in.


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

5. Save the API `Account Key` & the `Secret Key` information
  * This info will be saved into the `terraform.tfvars` file.

## Step 2: AWS Account Steps

1. Gather required AWS Account information
* AWS Account ID (12-digit account number)
  * can be found under account settings
* aws-cli (*aws access-key and secret-key*)

## Step 3: Terraform.tfvars

Fill in the `terraform.tfvars` file with variable information to 
create the Redis Cloud subscription, create a brand new VPC and VPC peer it to your Redis Cloud subscription.
And create a new database in your Redis Cloud subscription.

1. Step 1, utilize the `terraform.tfvars.example` file and replace/fill in the variable values

Copy the `terraform.tfvars.example` and rename it 'terraform.tfvars'
```bash
  cp terraform.tfvars.example terraform.tfvars
```
Update terraform.tfvars with your variable entries.


## Step 4: Run Terraform!

Now that you have filled in all the variable values
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