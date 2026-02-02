# NAT Module Variables

variable "public_subnet_ids" {
  description = "IDs of the public subnets (NAT Gateway will be placed in the first one)"
  type        = list(string)
}

variable "private_route_table_id" {
  description = "ID of the private route table"
  type        = string
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}
