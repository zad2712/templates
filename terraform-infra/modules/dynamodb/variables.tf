# DynamoDB Module Variables
variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
  default     = "default-table"
}

variable "billing_mode" {
  description = "Controls how you are billed for read/write throughput"
  type        = string
  default     = "PAY_PER_REQUEST"
}

variable "hash_key" {
  description = "The attribute to use as the hash (partition) key"
  type        = string
  default     = "id"
}

variable "range_key" {
  description = "The attribute to use as the range (sort) key"
  type        = string
  default     = null
}

variable "attributes" {
  description = "List of nested attribute definitions"
  type        = list(map(string))
  default     = [
    {
      name = "id"
      type = "S"
    }
  ]
}

variable "tags" {
  description = "Tags to apply to the table"
  type        = map(string)
  default     = {}
}
