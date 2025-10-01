# Config Layer - Local Variables

locals {
  common_tags = {
    Environment = var.environment
    Layer      = "config"
  }
}