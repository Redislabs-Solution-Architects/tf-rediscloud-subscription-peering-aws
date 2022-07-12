

## if you want to see the output of the sub id
output "rediscloud_subscription" {
  value = data.rediscloud_subscription.example.id
}
# output "rediscloud_subscription_networking_deployment_cidr" {
#   value = data.rediscloud_subscription.example.cloud_provider[0].region
# }

## if you want to see the output of the sub id
output "aws_vpc_peering_connection" {
  value = data.aws_vpc_peering_connection.pc.id
}