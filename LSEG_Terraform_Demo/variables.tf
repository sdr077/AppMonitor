variable "availability_zones" {
  type = list
  default = [
    "ap-south-1a","ap-south-1b","ap-south-1c"]
  description = "Availability zones that the subnets should be distributed across"
}

variable "subnet_cidr_blocks" {
  type = map
  default = {
    db = [
      "10.0.1.0/24","10.0.2.0/24"]
    app = [
      "10.0.3.0/24","10.0.4.0/24"]
  }
  description = "CIDR block for the subnet"
}