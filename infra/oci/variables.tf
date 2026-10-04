variable "tenancy_ocid" {
  description = "OCI tenancy OCID"
  type        = string
}

variable "compartment_ocid" {
  description = "Compartment OCID where the lab will be created"
  type        = string
}

variable "region" {
  description = "OCI home region; Always Free compute must be created there"
  type        = string
  default     = "sa-saopaulo-1"

  validation {
    condition     = var.region == "sa-saopaulo-1"
    error_message = "This project is locked to the tenancy home region sa-saopaulo-1 to preserve Always Free eligibility."
  }
}

variable "oci_profile" {
  description = "Profile name in ~/.oci/config"
  type        = string
  default     = "DEFAULT"
}

variable "project_name" {
  description = "Name used for OCI resources"
  type        = string
  default     = "sre-platform-lab"
}

variable "kubernetes_version" {
  description = "OKE Kubernetes version, including the v prefix"
  type        = string
}

variable "node_image_ocid" {
  description = "OKE-compatible ARM64 Oracle Linux image OCID for the selected region and Kubernetes version"
  type        = string
}

variable "ssh_public_key" {
  description = "Public SSH key installed on worker nodes"
  type        = string
}

variable "api_allowed_cidr" {
  description = "Public CIDR allowed to reach the Kubernetes API, normally your public IP with /32"
  type        = string

  validation {
    condition     = var.api_allowed_cidr != "0.0.0.0/0"
    error_message = "Use a specific trusted CIDR; exposing the Kubernetes API to the whole internet is intentionally blocked."
  }
}

variable "node_count" {
  description = "Number of Ampere A1 worker nodes"
  type        = number
  default     = 1

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 2
    error_message = "This lab allows one or two nodes to remain within the documented Always Free design."
  }
}

variable "remaining_free_a1_ocpus" {
  description = "Unused Always Free Ampere A1 OCPUs after inventorying all existing instances in the home region"
  type        = number

  validation {
    condition     = var.remaining_free_a1_ocpus >= 0 && var.remaining_free_a1_ocpus <= 2
    error_message = "Use a value from 0 to 2 based on the current conservative Always Free allowance."
  }
}

variable "remaining_free_a1_memory_gb" {
  description = "Unused Always Free Ampere A1 memory after inventorying all existing instances in the home region"
  type        = number

  validation {
    condition     = var.remaining_free_a1_memory_gb >= 0 && var.remaining_free_a1_memory_gb <= 12
    error_message = "Use a value from 0 to 12 GB based on the current conservative Always Free allowance."
  }
}

variable "remaining_free_block_storage_gb" {
  description = "Unused Always Free Block Volume capacity after counting all boot and block volumes in the home region"
  type        = number

  validation {
    condition     = var.remaining_free_block_storage_gb >= 0 && var.remaining_free_block_storage_gb <= 200
    error_message = "Use a value from 0 to 200 GB after inventorying existing boot and block volumes."
  }
}

variable "node_ocpus" {
  description = "OCPUs per Ampere A1 worker"
  type        = number
  default     = 1
}

variable "node_memory_gb" {
  description = "Memory in GB per Ampere A1 worker"
  type        = number
  default     = 6
}
