# Sitecore Solr Module
Terraform Module for setting up Solr on Azure VM for Sitecore. 

This Terraform module takes care of complete automation for Solr Setup for Sitecore by:
  - Creating a Public IP assigned Azure Windows VM
  - Installing Solr
  - Create Sitecore Cores
  - Create xConnect(xDB) Cores
  - Firewall updates for Solr to be accessed externally

## Sitecore Solr Support
This module supports setup of Solr for Sitecore 9.0.0 to 10.3.0

Sitecore Solr Compatibility Table: https://support.sitecore.com/kb?id=kb_article_view&sysparm_article=KB0227897 

## End Architecture
![End Architecture](https://github.com/codeblitzmaster/terraform-azurerm-sitecoresolr/blob/main/End_Sitecore_Solr_Architecture.png?raw=true)

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_azurecaf"></a> [azurecaf](#requirement\_azurecaf) | 2.0.0-preview3 |
| <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) | 3.50.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.4.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_azurecaf"></a> [azurecaf](#provider\_azurecaf) | 2.0.0-preview3 |
| <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) | 3.50.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.4.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_scsolr_naming"></a> [scsolr\_naming](#module\_scsolr\_naming) | ./modules/naming | n/a |

## Resources

| Name | Type |
|------|------|
| [azurecaf_name.this](https://registry.terraform.io/providers/aztfmod/azurecaf/2.0.0-preview3/docs/resources/name) | resource |
| [azurerm_network_interface.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.50.0/docs/resources/network_interface) | resource |
| [azurerm_network_interface_security_group_association.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.50.0/docs/resources/network_interface_security_group_association) | resource |
| [azurerm_network_security_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.50.0/docs/resources/network_security_group) | resource |
| [azurerm_public_ip.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.50.0/docs/resources/public_ip) | resource |
| [azurerm_subnet.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.50.0/docs/resources/subnet) | resource |
| [azurerm_virtual_machine_extension.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.50.0/docs/resources/virtual_machine_extension) | resource |
| [azurerm_virtual_network.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.50.0/docs/resources/virtual_network) | resource |
| [azurerm_windows_virtual_machine.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.50.0/docs/resources/windows_virtual_machine) | resource |
| [random_string.admin_password](https://registry.terraform.io/providers/hashicorp/random/3.4.3/docs/resources/string) | resource |
| [azurerm_resource_group.this](https://registry.terraform.io/providers/hashicorp/azurerm/3.50.0/docs/data-sources/resource_group) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_admin_username"></a> [admin\_username](#input\_admin\_username) | VM Admin Username [Note: Password would be auto generated] | `string` | `"adminuser"` | no |
| <a name="input_client"></a> [client](#input\_client) | Code name of the client. Must have 3 alphanumeric chars. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment code (LAB, DEV, TST, STG, PROD, DR). | `string` | `"DEV"` | no |
| <a name="input_location"></a> [location](#input\_location) | Azure region to use for deployment. | `string` | n/a | yes |
| <a name="input_project"></a> [project](#input\_project) | Code name of the subproject. Must have 4 digits. | `string` | n/a | yes |
| <a name="input_resource_group_name"></a> [resource\_group\_name](#input\_resource\_group\_name) | Resource group name for deployment. | `string` | n/a | yes |
| <a name="input_sitecore_version"></a> [sitecore\_version](#input\_sitecore\_version) | Supports Sitecore Version 9.0.0 to 10.3.0 | `string` | `"10.3.0"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The tags to associate with your resources. | `map` | <pre>{<br>  "company": "Acme Corp.",<br>  "environment": "DEV"<br>}</pre> | no |
| <a name="input_windows_vm_size"></a> [windows\_vm\_size](#input\_windows\_vm\_size) | Azure Windows Virtual Machine Size | `string` | `"Standard_B2ms"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_admin_password"></a> [admin\_password](#output\_admin\_password) | Admin Password |
| <a name="output_admin_username"></a> [admin\_username](#output\_admin\_username) | Admin Username |
| <a name="output_vm_ip"></a> [vm\_ip](#output\_vm\_ip) | Virtual Machine Public IP |
<!-- END_TF_DOCS -->