# Configure the AWS Provider
#Authentiaction

provider "aws" {
  region     = "ap-south-1"
  access_key = ""
  secret_key = ""
}

# Let AZs be shuffled when more than 1 AZ is needed.
resource "random_shuffle" "az" {
  input = var.availability_zones
  result_count = length(var.availability_zones)
}


############# Network Creation ###############################

#create new vpc with 10.0.0.0/16  cidr block

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Demo VPC"
  }
}

# DB Subnet.
resource "aws_subnet" "db_subnet" {  
  count = 2
  cidr_block = var.subnet_cidr_blocks.db[count.index] 
  vpc_id = aws_vpc.main.id 
  availability_zone = random_shuffle.az.result[count.index % length( random_shuffle.az.result)]
   tags = {
    Name = "DB-Subnet"
  }
  
}

# App Subnet  w/ NAT Gateway.
resource "aws_subnet" "app_subnet" {  
  count = 2
  cidr_block = var.subnet_cidr_blocks.app[count.index] 
  vpc_id = aws_vpc.main.id  
  availability_zone = random_shuffle.az.result[count.index % length( random_shuffle.az.result)]
  tags = {
    Name = "App-Subnet"
  }  
}

# NAT Gatway w/ EIP.
resource "aws_eip" "nat_eip" {
  vpc = true
  tags = {
    Name = "nat-eip"
  } 
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id = aws_subnet.app_subnet[0].id
  
}

# IGW w
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "Internate-Gateway"
  } 
}

resource "aws_route_table" "igw_private_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "public-route-table"
  } 
}

# Route table for NAT.
resource "aws_route_table" "nat_private_route_table" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "private-route-table"
  } 
}



########### route creation ####################
resource "aws_route" "route_to_internet" {
  route_table_id = aws_route_table.igw_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}

resource "aws_route" "route_to_nat" {
  route_table_id = aws_route_table.nat_private_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.nat.id
}
######################################




# Add routing associations to subnet
resource "aws_route_table_association" "association_for_route_to_igw" { 
  count = 2
  route_table_id = aws_route_table.igw_private_route_table.id
  subnet_id = aws_subnet.app_subnet[count.index].id
}

resource "aws_route_table_association" "association_for_route_to_nat" {  
  count = 2
  route_table_id = aws_route_table.nat_private_route_table.id
  subnet_id = aws_subnet.db_subnet[count.index].id
}




################# creating security group ###########

resource "aws_security_group" "app_sg" {
  name        = "web-app-sg"
  description = "allow app"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "web-app-sg"
  }
 }


resource "aws_security_group_rule" "r1" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_sg.id
}

resource "aws_security_group_rule" "r2" {
  type              = "ingress"
  from_port         = 465
  to_port           = 465
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_sg.id
}

resource "aws_security_group_rule" "r3" {
  type              = "ingress"
  from_port         = 587
  to_port           = 587
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_sg.id
}

resource "aws_security_group_rule" "r4" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.app_sg.id
}

resource "aws_security_group_rule" "r5" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = aws_security_group.db_sg.id
  security_group_id = aws_security_group.app_sg.id
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "db security group"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "db-sg"
  }
}

resource "aws_security_group_rule" "db_r1" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  source_security_group_id = aws_security_group.app_sg.id
  security_group_id = aws_security_group.db_sg.id
}

resource "aws_security_group_rule" "db_r2" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.db_sg.id
}
#################################################################################




####################### Opswork Creation ##########################################

resource "aws_opsworks_stack" "demo" {
  name                         = "LSEG_Demo2"
  region                       = "ap-south-1"
  service_role_arn             = "arn:aws:iam::886038311436:role/aws-opsworks-service-role"
  default_instance_profile_arn = "arn:aws:iam::886038311436:instance-profile/aws-opsworks-ec2-role"
  configuration_manager_version = "12"
  default_os = "Amazon Linux 2018.03"
  use_custom_cookbooks = true
  default_root_device_type= "ebs"
  vpc_id =  aws_vpc.main.id
  default_subnet_id = aws_subnet.app_subnet[0].id

  custom_cookbooks_source{
    type = "git"
    url = "https://github.com/sdr077/Opswork_Demo.git"
    #ssh_key= ""


  }

}

resource "aws_opsworks_custom_layer" "application" {
  name       = "Application Layer"
  short_name = "app"
  stack_id   = aws_opsworks_stack.demo.id
  custom_security_group_ids = [aws_security_group.app_sg.id]
  custom_setup_recipes = ["configuration::configFile"]
  auto_assign_public_ips = true


}

resource "aws_opsworks_instance" "app1" {
  stack_id = aws_opsworks_stack.demo.id

  layer_ids = [
    aws_opsworks_custom_layer.application.id,
  ]

  instance_type = "t3.micro"
  os            = "Amazon Linux 2018.03"
  state         = "running"
}




resource "aws_opsworks_custom_layer" "db" {
  name       = "DB Layer"
  short_name = "db"
  stack_id   = aws_opsworks_stack.demo.id
  custom_security_group_ids = [aws_security_group.db_sg.id]
  custom_setup_recipes = ["configuration::mysql_conf"]
  auto_assign_public_ips = true
}

resource "aws_opsworks_instance" "db1" {
  stack_id = aws_opsworks_stack.demo.id

  layer_ids = [
    aws_opsworks_custom_layer.db.id,
  ]

  instance_type = "t3.micro"
  os            = "Amazon Linux 2018.03"
  state         = "running"
  subnet_id = aws_subnet.db_subnet[0].id
}


###################################################################