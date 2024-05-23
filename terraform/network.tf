resource "oci_core_vcn" "z_vcn" {
  cidr_block     = var.vcn_cidr_block
  compartment_id = var.compartment_id

  display_name = "z_vcn"
}

resource "oci_core_subnet" "z_subnet" {
  compartment_id    = var.compartment_id
  vcn_id            = oci_core_vcn.z_vcn.id
  security_list_ids = [oci_core_security_list.z_security_list.id]
  route_table_id    = oci_core_route_table.z_rt.id
  cidr_block        = var.subnet_cidr_block

  display_name = "z_subnet"

}
resource "oci_core_internet_gateway" "z_gateway" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.z_vcn.id
  enabled        = true
  display_name   = "z_gateway"
}
resource "oci_core_route_table" "z_rt" {
  compartment_id = var.compartment_id
  vcn_id         = oci_core_vcn.z_vcn.id
  route_rules {
    destination       = "0.0.0.0/0"
    network_entity_id = oci_core_internet_gateway.z_gateway.id
  }
  display_name = "z_rt"
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
