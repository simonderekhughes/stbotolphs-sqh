###############################################################################
# SPDX-License-Identifier: Apache-2.0
# Input variables
###############################################################################

variable "github_private_key_path" {
  description = "The private key used by the instance to git clone the stbotolphs repo for building."
  type = string
  default = "~/.ssh/github_private_key_path"
}

variable "instance_ssh_private_key_path" {
  description = "The private key used for the instance SSH connection."
  type = string
  default = "~/.ssh/instance_private_key_path"
}

variable "instance_ssh_public_key_path" {
  description = "The public key used for the instance SSH connection."
  type = string
  default = "~/.ssh/instance_ssh_public_key_path"
}

variable "server_port" {
  description = "The port the server will use for HTTP requests."
  type = number
  default = 8000
}
