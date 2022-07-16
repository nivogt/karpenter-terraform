data "aws_partition" "current" {}

locals {

  # Used to determine correct partition (i.e. - `aws`, `aws-gov`, `aws-cn`, etc.)
  partition = data.aws_partition.current.partition
}


module "vpc" {
  # https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/latest
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.12.0"

  name = var.cluster_name
  cidr = "10.0.0.0/16"

  azs             = var.azs
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway     = true
  single_nat_gateway     = true
  one_nat_gateway_per_az = false

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    # Tags subnets for Karpenter auto-discovery
    "karpenter.sh/discovery" = var.cluster_name
  }
}

module "eks" {
  # https://registry.terraform.io/modules/terraform-aws-modules/eks/aws/latest
  source  = "terraform-aws-modules/eks/aws"
  version = "18.17.0"

  cluster_name    = var.cluster_name
  cluster_version = "1.21"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # Required for Karpenter role below
  enable_irsa = true

  # We will rely only on the cluster security group created by the EKS service
  # See note below for `tags`
  create_cluster_security_group = false
  create_node_security_group    = false

  # Only need one node to get Karpenter up and running.
  # This ensures core services such as VPC CNI, CoreDNS, etc. are up and running
  # so that Karpetner can be deployed and start managing compute capacity as required
  eks_managed_node_groups = {
    initial = {
      instance_types = ["t3.medium"]
      # We don't need the node security group since we are using the
      # cluster-created security group, which Karpenter will also use
      create_security_group                 = false
      attach_cluster_primary_security_group = true

      min_size     = 1
      max_size     = 1
      desired_size = 1

      iam_role_additional_policies = [
        # Required by Karpenter
        "arn:${local.partition}:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
    }
  }

  tags = {
    # Tag node group resources for Karpenter auto-discovery
    # NOTE - if creating multiple security groups with this module, only tag the
    # security group that Karpenter should utilize with the following tag
    "karpenter.sh/discovery" = var.cluster_name
  }
}
