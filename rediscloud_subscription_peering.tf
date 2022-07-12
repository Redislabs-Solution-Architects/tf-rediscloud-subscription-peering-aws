## Access a Redis Cloud subcription by its name
## initiate a VPC peering request to AWS and auto accept

## enter customers existing subscription name here
data "rediscloud_subscription" "example" {
  name = var.rediscloud_subscription_name
}

resource "rediscloud_subscription_peering" "example" {
   subscription_id = data.rediscloud_subscription.example.id
   region = var.aws_customer_application_vpc_region
   aws_account_id = var.aws_customer_application_aws_account_id
   vpc_id = var.aws_customer_application_vpc_id
   vpc_cidr = var.aws_customer_application_vpc_cidr
}


resource "aws_vpc_peering_connection_accepter" "example-peering" {
  vpc_peering_connection_id = rediscloud_subscription_peering.example.aws_peering_id
  auto_accept               = true
}