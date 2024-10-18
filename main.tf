# 0. Declare the client_secret variable
variable "client_secret" {
  type      = string
  sensitive = true  # Mark the variable as sensitive
}

# 1. Configure the Azure provider
provider "azurerm" {
  features {}

  subscription_id = " "
  client_id       = "    "
  client_secret   = var.client_secret  # Use the declared variable
  tenant_id       = " "
}

# 2. Create Resource Group
resource "azurerm_resource_group" "bankwork" {
  name     = "bankwork"
  location = "West Europe"
}

# 3. Create Virtual Network and Subnet
resource "azurerm_virtual_network" "main" {
  name                = "main-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.bankwork.location
  resource_group_name = azurerm_resource_group.bankwork.name
}

resource "azurerm_subnet" "main" {
  name                 = "main-subnet"
  resource_group_name  = azurerm_resource_group.bankwork.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/24"]  # /24 Subnet
}

# 4. Create Network Security Group (NSG) and define security rules
resource "azurerm_network_security_group" "nsg" {
  name                = "main-nsg"
  location            = azurerm_resource_group.bankwork.location
  resource_group_name = azurerm_resource_group.bankwork.name
}

# Inbound Rule: Allow SSH traffic (port 22) from trusted IP ranges
resource "azurerm_network_security_rule" "allow_ssh" {
  name                        = "allow-ssh"
  priority                    = 1001
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "203.0.113.0/24"  # Trusted IP range
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
  resource_group_name         = azurerm_resource_group.bankwork.name
}

# Inbound Rule: Allow HTTP traffic (port 80)
resource "azurerm_network_security_rule" "allow_http" {
  name                        = "allow-http"
  priority                    = 1002
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
  resource_group_name         = azurerm_resource_group.bankwork.name
}

# Outbound Rule: Allow internet access for web server
# Allow outbound internet traffic on port 80 (HTTP)
resource "azurerm_network_security_rule" "allow_outbound_http" {
  name                        = "allow-outbound-http"
  priority                    = 1001
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "80"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
  resource_group_name         = azurerm_resource_group.bankwork.name
}

# Allow outbound internet traffic on port 443 (HTTPS)
resource "azurerm_network_security_rule" "allow_outbound_https" {
  name                        = "allow-outbound-https"
  priority                    = 1002
  direction                   = "Outbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_range      = "443"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
  resource_group_name         = azurerm_resource_group.bankwork.name
}

# Inbound Rule: Deny all other inbound traffic (default deny)
resource "azurerm_network_security_rule" "deny_all_inbound" {
  name                        = "deny-all-inbound"
  priority                    = 2000
  direction                   = "Inbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
  resource_group_name         = azurerm_resource_group.bankwork.name
}

# Outbound Rule: Deny all other outbound traffic (default deny)
resource "azurerm_network_security_rule" "deny_all_outbound" {
  name                        = "deny-all-outbound"
  priority                    = 3000
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "*"
  network_security_group_name = azurerm_network_security_group.nsg.name
  resource_group_name         = azurerm_resource_group.bankwork.name
}

# 5. Associate NSG with Subnet
resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.main.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

# 6. Public IP for Virtual Machine
resource "azurerm_public_ip" "main" {
  name                = "main-public-ip"
  location            = azurerm_resource_group.bankwork.location
  resource_group_name = azurerm_resource_group.bankwork.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# 7. Network Interface for Virtual Machine
resource "azurerm_network_interface" "main" {
  name                = "main-nic"
  location            = azurerm_resource_group.bankwork.location
  resource_group_name = azurerm_resource_group.bankwork.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.main.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.main.id
  }
}

# 8. Linux Virtual Machine with Docker and Nginx
resource "azurerm_linux_virtual_machine" "main" {
  name                = "nginx-vm"
  location            = azurerm_resource_group.bankwork.location
  resource_group_name = azurerm_resource_group.bankwork.name
  size                = "Standard_B1ms"
  admin_username      = "azureuser"
  network_interface_ids = [azurerm_network_interface.main.id]

  disable_password_authentication = true

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  custom_data = filebase64("user_data.sh")
}

# 9. Output Public IP and Access URL
output "public_ip" {
  value = azurerm_public_ip.main.ip_address
}

output "nginx_url" {
  value = "http://${azurerm_public_ip.main.ip_address}"
}
