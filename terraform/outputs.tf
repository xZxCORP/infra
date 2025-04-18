output "master_public_ip" {
  description = "Public IP address of the master instance."
  value       = oci_core_instance.z_master.public_ip
}
output "runner_public_ip" {
  description = "Public IP address of the runner instance."
  value       = oci_core_instance.z_runner.public_ip
}

output "worker_public_ips" {
  description = "Public IP addresses of the worker instances."
  value       = oci_core_instance.z_worker[*].public_ip
}

output "ansible_inventory" {
  value = templatefile("${path.module}/inventory.tftpl", {
    master_ip  = oci_core_instance.z_master.public_ip,
    runner_ip  = oci_core_instance.z_runner.public_ip,
    worker_ips = oci_core_instance.z_worker[*].public_ip
  })
}
