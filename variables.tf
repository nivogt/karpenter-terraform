variable "cluster_name" {
  type    = string
  default = "karpenter-demo"
}

variable "azs" {
type = list(string)
default = ["eu-west-3a", "eu-west-3b", "eu-west-3c"]
}
