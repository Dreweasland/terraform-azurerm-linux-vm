resource "azurerm_public_ip" "public_ip" {
  count = var.public_ip_sku == null ? 0 : 1

  name                = coalesce(var.custom_public_ip_name, "${local.vm_name}-pubip")
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  domain_name_label   = coalesce(var.custom_dns_label, local.vm_name)
  sku                 = var.public_ip_sku

  tags = merge(local.default_tags, var.extra_tags)
}

resource "azurerm_network_interface" "nic" {
  name                = coalesce(var.custom_nic_name, "${local.vm_name}-nic")
  location            = var.location
  resource_group_name = var.resource_group_name

  enable_accelerated_networking = var.nic_enable_accelerated_networking

  network_security_group_id = var.nic_nsg_id

  ip_configuration {
    name                          = coalesce(var.custom_ipconfig_name, "${local.vm_name}-nic-ipconfig")
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = var.public_ip_sku == null ? null : join("", azurerm_public_ip.public_ip.*.id)
  }

  tags = merge(local.default_tags, var.extra_tags)
}

resource "azurerm_network_interface_backend_address_pool_association" "lb_pool_association" {
  count = var.attach_load_balancer ? 1 : 0

  backend_address_pool_id = var.load_balancer_backend_pool_id
  ip_configuration_name   = local.ip_configuration_name
  network_interface_id    = azurerm_network_interface.nic.id
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "appgw_pool_association" {
  count = var.attach_application_gateway ? 1 : 0

  backend_address_pool_id = var.application_gateway_backend_pool_id
  ip_configuration_name   = local.ip_configuration_name
  network_interface_id    = azurerm_network_interface.nic.id
}
