resource "oci_core_vcn" "z_vcn" {
  cidr_block     = var.vcn_cidr
  compartment_id = var.compartment_id
  display_name   = "z_vcn"
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

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "all"
    source   = "0.0.0.0/0"
  }
}

resource "oci_core_subnet" "z_subnet" {
  cidr_block        = var.subnet_cidr
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.z_vcn.id
  route_table_id    = oci_core_route_table.z_route_table.id
  security_list_ids = [oci_core_security_list.z_security_list.id]
  display_name      = "z_subnet"
}
