output "cluster_id" {
  description = "OKE cluster OCID"
  value       = oci_containerengine_cluster.lab.id
}

output "cluster_name" {
  description = "OKE cluster name"
  value       = oci_containerengine_cluster.lab.name
}

output "configure_kubectl" {
  description = "OCI CLI command that writes the kubeconfig"
  value       = "oci ce cluster create-kubeconfig --cluster-id ${oci_containerengine_cluster.lab.id} --file $HOME/.kube/config --region ${var.region} --token-version 2.0.0 --kube-endpoint PUBLIC_ENDPOINT"
}

output "worker_shape" {
  description = "Worker shape and total requested capacity"
  value       = "${var.node_count} x VM.Standard.A1.Flex (${var.node_ocpus} OCPU / ${var.node_memory_gb} GB each)"
}
