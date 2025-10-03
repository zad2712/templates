# ElastiCache Module Variables
variable "cluster_id" {
  description = "Group identifier for the ElastiCache cluster"
  type        = string
  default     = "default-cache-cluster"
}

variable "engine" {
  description = "Name of the cache engine"
  type        = string
  default     = "redis"
}

variable "node_type" {
  description = "The instance class used"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes"
  type        = number
  default     = 1
}

variable "subnet_group_name" {
  description = "Name of the subnet group"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the cluster"
  type        = map(string)
  default     = {}
}
