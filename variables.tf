variable "cluster_name" {
  type    = string
  default = "karpenter-demo"
}

variable "cluster_version" {
  type    = string
  default = "1.21"
}

variable "cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "private_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  type    = list(string)
  default = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "azs" {
  type    = list(string)
  default = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
}
