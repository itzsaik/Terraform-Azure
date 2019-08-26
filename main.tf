// Azurerm Variables
    variable "subscription_id" {}
    variable "client_id" {}
    variable "client_secret" {}
    variable "tenant_id" {}

//Azure Resource group variables
    variable "web_server_location" {}
    variable "web_server_rg" {}

// Azure vnet variables
    variable "resource_prefix" {}
    variable "web_server_address_space" {}

// Azure subnet variables
    variable "web_server_address_prefix" {}
variable "web_server_name" {}

variable "environment" {}

variable "web_server_count" {}

provider "azurerm" {
  version         = "1.27"
  tenant_id       = "${var.tenant_id}"
  subscription_id = "${var.subscription_id}"
  client_id       = "${var.client_id}"
  client_secret   = "${var.client_secret}"
}

locals {
    web_server_name = "${var.environment == "production" ? "${var.web_server_name}-prd"  : "${var.web_server_name}-dev"}"
}


resource "azurerm_resource_group" "web_server_rg" {
  name     = "${var.web_server_rg}"
  location = "${var.web_server_location}"
}

resource "azurerm_virtual_network" "web_server_vnet" {
  name                = "${var.resource_prefix}-vnet"
  location            = "${var.web_server_location}"
  resource_group_name = "${azurerm_resource_group.web_server_rg.name}"
  address_space       = ["${var.web_server_address_space}"]
}

resource "azurerm_subnet" "web_server_subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = "${azurerm_resource_group.web_server_rg.name}"
  virtual_network_name = "${azurerm_virtual_network.web_server_vnet.name}"
  address_prefix       = "${var.web_server_address_prefix}"
  network_security_group_id = "${azurerm_network_security_group.web_server_nsg.id}"
}

  // resource "azurerm_network_interface" "web_server_nic" {
  //    name                      = "${var.web_server_name}-${format("%02d",count.index)}-nic"
  //    location                  = "${var.web_server_location}"
  //    resource_group_name       = "${azurerm_resource_group.web_server_rg.name}"
  //    count                     = "${var.web_server_count}"

  //    ip_configuration {
  //      name                          = "${var.web_server_name}-${format("%02d",count.index)}-ip"
  //      subnet_id                     = "${azurerm_subnet.web_server_subnet.id}"
  //      private_ip_address_allocation = "dynamic"
  //      public_ip_address_id          = "${azurerm_public_ip.web_server_public_ip.*.id[count.index]}"
  //    }
   // }

    resource "azurerm_public_ip" "web_server_public_ip" {
      name                         = "${var.resource_prefix}-public-ip"
      location                     = "${var.web_server_location}"
      resource_group_name          = "${azurerm_resource_group.web_server_rg.name}"
      allocation_method            = "Static"
      
    }

    resource "azurerm_network_security_group" "web_server_nsg" {
      name                = "${var.resource_prefix}-nsg"
      location            = "${var.web_server_location}"
      resource_group_name = "${azurerm_resource_group.web_server_rg.name}" 
    }

    resource "azurerm_network_security_rule" "web_server_nsg_rule_rdp" {
      name                        = "RDP Inbound"
      priority                    = 100
      direction                   = "Inbound"
      access                      = "Allow"
      protocol                    = "Tcp"
      source_port_range           = "*"
      destination_port_range      = "3389"
      source_address_prefix       = "*"
      destination_address_prefix  = "*"
      resource_group_name         = "${azurerm_resource_group.web_server_rg.name}" 
      network_security_group_name = "${azurerm_network_security_group.web_server_nsg.name}" 
    }

//  resource "azurerm_availability_set" "webserver_availability_set" {
//    name                         = "${var.resource_prefix}-availability-set"
//    location                     = "${var.web_server_location}"
//    resource_group_name          = "${azurerm_resource_group.web_server_rg.name}"
//    managed                      = true
//    platform_fault_domain_count  = 2

//}

resource "azurerm_virtual_machine_scale_set" "web_server" {
    name                         = "${local.web_server_name}-scale-set"
    location                     = "${var.web_server_location}"
    resource_group_name          = "${azurerm_resource_group.web_server_rg.name}"  
    upgrade_policy_mode          = "manual"

    sku {
     name                        = "Standard_F2s_v2"
     tier                        = "Standard"
     capacity                    = "${var.web_server_count}" 
    }


    storage_profile_image_reference {
      publisher = "MicrosoftWindowsServer"
      offer     = "WindowsServer"
      sku       = "2016-Datacenter-Server-Core-smalldisk"
      version   = "latest"
    }

    storage_profile_os_disk {
      name              = ""
      caching           = "ReadWrite"
      create_option     = "FromImage"
      managed_disk_type = "Standard_LRS"
    }
    
    os_profile {
      computer_name_prefix      = "${local.web_server_name}" 
      admin_username     = "webserver"
      admin_password     = "Passw0rd1234"
    }

    os_profile_windows_config {
    }

    network_profile{
      name  ="web_server_network_profile"
      primary = true

    ip_configuration{
      name =  "${local.web_server_name}"
      primary = true
      subnet_id = "${azurerm_subnet.web_server_subnet.*.id[0]}"
    }
    }
}

