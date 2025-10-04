locals {
  normalized_location = replace(var.location, " ", "")
  base_name           = lower(join("-", compact([var.org_code, var.environment, local.normalized_location, var.workload_name])))

  default_tags = merge({
    "environment" = var.environment,
    "workload"    = var.workload_name,
    "managed-by"  = "terraform"
  }, var.tags)
}
