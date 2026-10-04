data "oci_identity_availability_domains" "available" {
  compartment_id = var.tenancy_ocid
}

locals {
  tags = {
    Project   = var.project_name
    ManagedBy = "Terraform"
    Tier      = "AlwaysFree"
  }
}

resource "oci_core_vcn" "lab" {
  compartment_id = var.compartment_ocid
  cidr_blocks    = ["10.42.0.0/16"]
  display_name   = "${var.project_name}-vcn"
  dns_label      = "sreplatform"
  freeform_tags  = local.tags
}

resource "oci_core_internet_gateway" "lab" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.lab.id
  display_name   = "${var.project_name}-internet-gateway"
  enabled        = true
  freeform_tags  = local.tags
}

resource "oci_core_route_table" "public" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.lab.id
  display_name   = "${var.project_name}-public-routes"
  freeform_tags  = local.tags

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = oci_core_internet_gateway.lab.id
  }
}

resource "oci_core_security_list" "oke" {
  compartment_id = var.compartment_ocid
  vcn_id         = oci_core_vcn.lab.id
  display_name   = "${var.project_name}-oke-security"
  freeform_tags  = local.tags

  egress_security_rules {
    protocol    = "all"
    destination = "0.0.0.0/0"
  }

  ingress_security_rules {
    protocol = "all"
    source   = "10.42.0.0/16"
  }

  ingress_security_rules {
    protocol = "6"
    source   = var.api_allowed_cidr

    tcp_options {
      min = 6443
      max = 6443
    }
  }
  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    description = "HTTP para Traefik (hostPort)"

    tcp_options {
      min = 80
      max = 80
    }
  }

  ingress_security_rules {
    protocol    = "6"
    source      = "0.0.0.0/0"
    description = "HTTPS para Traefik (hostPort)"

    tcp_options {
      min = 443
      max = 443
    }
  }
}

resource "oci_core_subnet" "public" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.lab.id
  cidr_block                 = "10.42.10.0/24"
  display_name               = "${var.project_name}-public-subnet"
  dns_label                  = "public"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.oke.id]
  freeform_tags              = local.tags
}
resource "oci_core_subnet" "workers" {
  compartment_id             = var.compartment_ocid
  vcn_id                     = oci_core_vcn.lab.id
  cidr_block                 = "10.42.20.0/24"
  display_name               = "${var.project_name}-workers-subnet"
  dns_label                  = "workers"
  prohibit_public_ip_on_vnic = false
  route_table_id             = oci_core_route_table.public.id
  security_list_ids          = [oci_core_security_list.oke.id]
  freeform_tags              = local.tags
}


resource "oci_containerengine_cluster" "lab" {
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = "${var.project_name}-oke"
  type               = "BASIC_CLUSTER"
  vcn_id             = oci_core_vcn.lab.id
  freeform_tags      = local.tags

  cluster_pod_network_options {
    cni_type = "FLANNEL_OVERLAY"
  }

  endpoint_config {
    is_public_ip_enabled = true
    subnet_id            = oci_core_subnet.public.id
  }

  options {
    service_lb_subnet_ids = [oci_core_subnet.public.id]

    service_lb_config {
      backend_nsg_ids = []
    }
  }
}

resource "oci_containerengine_node_pool" "ampere" {
  cluster_id         = oci_containerengine_cluster.lab.id
  compartment_id     = var.compartment_ocid
  kubernetes_version = var.kubernetes_version
  name               = "${var.project_name}-ampere"
  node_shape         = "VM.Standard.A1.Flex"
  ssh_public_key     = var.ssh_public_key
  freeform_tags      = local.tags

  node_shape_config {
    ocpus         = var.node_ocpus
    memory_in_gbs = var.node_memory_gb
  }

  node_source_details {
    image_id                = var.node_image_ocid
    source_type             = "IMAGE"
    boot_volume_size_in_gbs = 50
  }


  node_config_details {
    size = var.node_count

    placement_configs {
      availability_domain = data.oci_identity_availability_domains.available.availability_domains[0].name
      subnet_id           = oci_core_subnet.workers.id
    }

    node_pool_pod_network_option_details {
      cni_type = "FLANNEL_OVERLAY"
    }
  }

  initial_node_labels {
    key   = "workload"
    value = "platform-lab"
  }

  lifecycle {
    precondition {
      condition     = var.node_count * var.node_ocpus <= 2
      error_message = "Requested workers exceed the current 2-OCPU Always Free design."
    }

    precondition {
      condition     = var.node_count * var.node_memory_gb <= 12
      error_message = "Requested workers exceed the current 12-GB Always Free design."
    }

    precondition {
      condition     = var.node_count * var.node_ocpus <= var.remaining_free_a1_ocpus
      error_message = "Requested workers exceed the declared remaining Always Free Ampere OCPU capacity. Inventory existing instances first."
    }

    precondition {
      condition     = var.node_count * var.node_memory_gb <= var.remaining_free_a1_memory_gb
      error_message = "Requested workers exceed the declared remaining Always Free Ampere memory capacity. Inventory existing instances first."
    }

    precondition {
      condition     = var.node_count * 50 <= var.remaining_free_block_storage_gb
      error_message = "Requested boot volumes exceed the declared remaining Always Free Block Volume capacity. Inventory existing volumes first."
    }
  }
}
