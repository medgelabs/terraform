terraform {
  backend "s3" {
    bucket = "medgelabs-tf-states"
    key = "eks"
    region = "us-east-1"
  }
}

locals {
  cluster_name = "medgelabs"
}

# Get default VPC and subnets automatically
data "aws_vpc" "selected" {
  tags = {
    Name = "default"
  }
}
data "aws_subnet_ids" "target_subnets" {
  vpc_id = data.aws_vpc.selected.id
}
data "aws_subnet" "target_subnet" {
  count = length(data.aws_subnet_ids.target_subnets.ids)
  id    = element(tolist(sort(data.aws_subnet_ids.target_subnets.ids)), count.index)
}

module "eks" {
  source      = "git::https://github.com/terraform-aws-modules/terraform-aws-eks.git?ref=v12.2.0"

  cluster_name = local.cluster_name
  cluster_version = "1.17"
  vpc_id       = data.aws_vpc.selected.id
  subnets      = [data.aws_subnet.target_subnet[0].id,data.aws_subnet.target_subnet[1].id,data.aws_subnet.target_subnet[2].id]

  node_groups = {
    eks_nodes = {
      desired_capacity = 1
      max_capacity     = 3
      min_capaicty     = 1

      instance_type = "t3.small"
    }
  }

  manage_aws_auth = false
}
