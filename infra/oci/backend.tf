terraform {
  backend "oci" {
    bucket    = "sre-platform-lab-tfstate"
    namespace = "grsadtmyypgu"
    key       = "sre-platform-lab/terraform.tfstate"
    region    = "sa-saopaulo-1"
  }
}
