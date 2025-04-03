terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
}

data "oci_identity_availability_domains" "z_ads" {
  compartment_id = var.tenancy_ocid
}