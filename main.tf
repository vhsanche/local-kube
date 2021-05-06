variable "registry1_username" {
  type = string
}

variable "registry1_password" {
  type = string
}

module "big_bang" {
  source = "git::https://repo1.dso.mil/platform-one/big-bang/terraform-modules/big-bang-terraform-launcher.git"

  big_bang_manifest_file = "bigbang/start.yaml"
  registry_credentials = [{
    registry = "registry1.dso.mil"
    username = var.registry1_username
    password = var.registry1_password
  }]
}
