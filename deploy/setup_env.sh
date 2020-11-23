#!/bin/bash
###############################################################################
# SPDX-License-Identifier: Apache-2.0
# Source this file to setup terraform environment.
###############################################################################

# TF_VAR_github_private_key_path
# Set the variable to the path of a private key that the instance can use to
# git clone the stbotolphs repo of interest
export TF_VAR_github_private_key_path="~/.ssh/id_ed25519"

# TF_VAR_aws_instance_ssh_private_key_path
# Set the variable to the path of a private key that the instance can use to
# use for the instance SSH connection for provider configuration.
export TF_VAR_instance_ssh_private_key_path="~/.ssh/kalambos_github_simon_derek_hughes_gmail_com_id_rsa"

# TF_VAR_aws_instance_ssh_public_key_path
# Set the variable to the path of a public key that the instance can use to
# use for the instance SSH connection for provider configuration.
export TF_VAR_instance_ssh_public_key_path="~/.ssh/kalambos_github_simon_derek_hughes_gmail_com_id_rsa.pub"

