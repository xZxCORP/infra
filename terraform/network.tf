resource "oci_core_vcn" "z_vcn" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_id
  display_name   = "z_vcn"
}

resource "oci_core_subnet" "z_subnet" {
  cidr_block        = var.subnet_cidr
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.z_vcn.id
  route_table_id    = oci_core_route_table.z_route_table.id
  security_list_ids = [oci_core_security_list.z_security_list.id]
  display_name      = "z_subnet"

}
resource "oci_core_internet_gateway" "z_internet_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.z_vcn.id
  display_name   = "z_internet_gateway"
}
resource "oci_core_route_table" "z_route_table" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.z_vcn.id
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.z_internet_gateway.id
  }
  display_name = "z_route_table"

}
resource "oci_core_security_list" "z_security_list" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.z_vcn.id
  display_name   = "z_security_list"

  # Rule for allowing all outgoing traffic from the subnet to the Internet
  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  # Rule for allowing all traffic within the cluster node subnet
  ingress_security_rules {
    protocol = "all"
    source   = var.subnet_cidr
  }

  # Rule for external SSH access
  ingress_security_rules {
    protocol = "6"
    source   = "0.0.0.0/0"

    tcp_options {
      min = 22
      max = 22
    }
  }

}
