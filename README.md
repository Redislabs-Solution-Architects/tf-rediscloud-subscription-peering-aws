# tf-rediscloud-subscription-peering-aws
Terraform to VPC peer a Redis Cloud subscription to your AWS VPC and add a route to the AWS VPC route table.

# Download Terraform: (Mac OS)
Download Terraform

# VPC peer a RedisCloud subscription to your AWS Environment VPC from Terraform
Now that we have terraform installed and working with VS code we can get started.

* Head to your Redis Enterprise Cloud account:
* Get your Cloud API Access Key and Secret Key.
* Get your Redis Cloud Subscription Name and Deployment CIDR
* Place these keys in the terraform.tfvars file.

Do the same with your AWS Credentials:
* Access key and Secret key for aws account
* Get your AWS application Account ID
* Get your AWS VPC ID
* Get your AWS VPC CIDR
* Get your AWS VPC main route table ID
* Place these keys in the terraform.tfvars file.

Copy the variables template. or rename it 'terraform.tfvars'
```bash
  cp terraform.tfvars.example terraform.tfvars
```
Update terraform.tfvars with your [secrets](#secrets)

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