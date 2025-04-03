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
