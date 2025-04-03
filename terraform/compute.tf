locals {
  ssh_public_key  = file(var.ssh_public_key_path)
  ssh_private_key = file(var.ssh_private_key_path)
}

resource "oci_core_instance" "z_master" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  shape               = var.instance_shape
  shape_config {
    memory_in_gbs = 6
    ocpus         = 1
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.z_subnet.id
    assign_public_ip = true
  }
  metadata = {
    ssh_authorized_keys = local.ssh_public_key
  }
  source_details {
    source_type = "image"
    source_id   = var.arm_instance_image_ocid
  }

  display_name = "z_master"
}
resource "oci_core_instance" "z_runner" {
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  shape               = var.instance_shape
  shape_config {
    memory_in_gbs = 6
    ocpus         = 1
  }
  create_vnic_details {
    subnet_id        = oci_core_subnet.z_subnet.id
    assign_public_ip = true
  }
  metadata = {
    ssh_authorized_keys = local.ssh_public_key
  }
  source_details {
    source_type = "image"
    source_id   = var.arm_instance_image_ocid
  }

  display_name = "z_runner"
}

resource "oci_core_instance" "z_worker" {
  count               = 2
  availability_domain = var.availability_domain
  compartment_id      = var.compartment_id
  shape               = var.instance_shape
  shape_config {
    memory_in_gbs = 6
    ocpus         = 1
  }

  create_vnic_details {
    subnet_id        = oci_core_subnet.z_subnet.id
    assign_public_ip = true

  }

  source_details {
    source_type = "image"
    source_id   = var.arm_instance_image_ocid

  }
  metadata = {
    ssh_authorized_keys = local.ssh_public_key
  }

  display_name = "z_worker_${count.index}"
}
