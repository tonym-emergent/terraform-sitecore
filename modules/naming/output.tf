#client-application-project-env-location
output "resource_group_prefixes" {
  value = [lower(var.client), lower(local.project_safe), var.environment, local.location_safe]
  description = "Resource group name prefixes for CAF module."
}

output "resource_prefixes" {
  value = [lower(var.client), lower(local.project_safe), var.environment, local.location_safe]
    description = "Resource name prefixes for CAF module."
}