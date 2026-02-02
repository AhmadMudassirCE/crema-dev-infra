# NAT Module Variables

variable "public_subnet_id" {
  description = "ID of the public subnet for NAT Gateway"
  type        = string
}

variable "private_route_table_id" {
  description = "ID of the private route table"
  type        = string
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}
