resource "oci_core_instance" "master" {
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
    ssh_authorized_keys = file(var.public_key_path)
  }
  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }

  display_name = "master"
}
resource "oci_core_instance" "runner" {
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
    ssh_authorized_keys = file(var.public_key_path)
  }
  source_details {
    source_type = "image"
    source_id   = var.instance_image_ocid
  }

  display_name = "runner"
}

resource "oci_core_instance" "worker" {
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
    source_id   = var.instance_image_ocid

  }
  metadata = {
    ssh_authorized_keys = file(var.public_key_path)
  }

  display_name = "worker-${count.index}"
}
