# variables.tf
# Extra variables can go here.
# region and cluster_name are defined in main.tf.

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    Project = "chaos-edge-devops"
    Owner   = "ccarrylab"
  }
}
