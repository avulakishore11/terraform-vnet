# ── Tag Enforcement Policies ─────────────────────────────────────────────────
# Assigns built-in Azure "Require a tag" policies at the subscription scope.
# Effect is Deny — resources and resource groups missing any required tag will
# be blocked by ARM at creation/update time.
#
# Required RBAC: the deployment principal needs Owner or Policy Contributor
# at the subscription scope to create policy assignments.

data "azurerm_subscription" "current" {}

locals {
  required_tags = toset(["CreatedBy", "Owner", "Department", "Environment"])

  # Built-in policy definition IDs (immutable Azure platform GUIDs)
  policy_require_tag_on_resources       = "/providers/Microsoft.Authorization/policyDefinitions/871b6d14-10aa-478d-b590-94f262ecfa99"
  policy_require_tag_on_resource_groups = "/providers/Microsoft.Authorization/policyDefinitions/96670d01-0a4d-4649-9c89-2d3abc0a5025"
}

# Enforce required tags on every resource
resource "azurerm_subscription_policy_assignment" "require_tag_resources" {
  for_each = local.required_tags

  name                 = "require-tag-${lower(each.key)}-res"
  display_name         = "Require ${each.key} tag on resources"
  policy_definition_id = local.policy_require_tag_on_resources
  subscription_id      = data.azurerm_subscription.current.id

  parameters = jsonencode({
    tagName = { value = each.key }
  })
}

# Enforce required tags on every resource group
resource "azurerm_subscription_policy_assignment" "require_tag_resource_groups" {
  for_each = local.required_tags

  name                 = "require-tag-${lower(each.key)}-rg"
  display_name         = "Require ${each.key} tag on resource groups"
  policy_definition_id = local.policy_require_tag_on_resource_groups
  subscription_id      = data.azurerm_subscription.current.id

  parameters = jsonencode({
    tagName = { value = each.key }
  })
}
