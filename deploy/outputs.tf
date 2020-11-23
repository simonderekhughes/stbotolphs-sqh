/******************************************************************************
 * SPDX-License-Identifier: Apache-2.0
 *****************************************************************************/

output "public_ip" {
    description = "The public IP address assigned to the server."
    value = aws_instance.cms_instance.public_ip
}

output "public_dns" {
    description = "The public dns name  assigned to the server."
    value = aws_instance.cms_instance.public_dns
}

output "private_ip" {
    description = "The private IP address assigned to the server."
    value = aws_instance.cms_instance.private_ip
}
