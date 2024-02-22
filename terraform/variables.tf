variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "public_key_path" {}
variable "region" {
  default = "eu-paris-1"
}
variable "compartment_id" {}
variable "availability_domain" {}
variable "vcn_cidr_block" {
  default = "10.0.0.0/16"
}
variable "subnet_cidr_block" {
  default = "10.0.1.0/24"
}
variable "instance_shape" {
  default = "VM.Standard.A1.Flex"
}
variable "instance_image_ocid" {}
