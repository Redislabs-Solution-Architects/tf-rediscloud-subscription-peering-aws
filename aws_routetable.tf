## Add a AWS Route to the customer AWS VPC Route Table

# Declare the data source
data "aws_vpc_peering_connection" "pc" {
  peer_vpc_id = var.aws_customer_application_vpc_id
  status = "active"
  depends_on = [aws_vpc_peering_connection_accepter.example-peering]
}

## if you want to see the output of the sub id
output "aws_vpc_peering_connection" {
  value = data.aws_vpc_peering_connection.pc.id
}

# Create a route
resource "aws_route" "r" {
  route_table_id            = var.aws_vpc_route_table_id
  ##destination_cidr_block    = data.aws_vpc_peering_connection.pc.peer_cidr_block
  destination_cidr_block = var.rediscloud_networking_deployment_cidr
  vpc_peering_connection_id = data.aws_vpc_peering_connection.pc.id
}