# Lambda Module Variables
variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "default-function"
}

variable "runtime" {
  description = "Runtime for the Lambda function"
  type        = string
  default     = "python3.9"
}

variable "handler" {
  description = "Function entrypoint in your code"
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "filename" {
  description = "Path to the function's deployment package"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the function"
  type        = map(string)
  default     = {}
}
