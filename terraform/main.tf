terraform {
  required_providers {
    oci = {
      source = "oracle/oci"
    }
  }
  cloud {

    organization = "wheelz"

    workspaces {
      name = "wheelz-prod"
    }
  }
}

data "oci_identity_availability_domains" "z_ads" {
  compartment_id = var.tenancy_ocid
}
