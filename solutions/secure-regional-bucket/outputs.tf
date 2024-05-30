locals {
  bucket = module.cos.buckets[local.bucket_config[0].bucket_name]
}

output "kms_guid" {
  description = "KMS GUID"
  value       = local.kms_guid
}

output "resource_group_name" {
  description = "Resource group name"
  value       = module.resource_group.resource_group_name
}

output "resource_group_id" {
  description = "Resource group ID"
  value       = module.resource_group.resource_group_id
}


output "cos_instance_id" {
  description = "COS instance id"
  value       = module.cos.cos_instance_id
}

output "cos_instance_guid" {
  description = "COS instance guid"
  value       = module.cos.cos_instance_guid
}

output "cos_instance_name" {
  description = "COS instance name"
  value       = module.cos.cos_instance_name
}

output "cos_instance_crn" {
  description = "COS instance crn"
  value       = module.cos.cos_instance_crn
}

##############################################################################
# Outputs
##############################################################################
output "s3_endpoint_private"  {
  description = "private s3 endpoint of the bucket"
  value = local.bucket.s3_endpoint_private
}
output "s3_endpoint_public"   {
  description = "public s3 endpoint of the bucket"
  value = local.bucket.s3_endpoint_public
}
output "s3_endpoint_direct"   {
  description = "direct s3 endpoint of the bucket"
  value = local.bucket.s3_endpoint_direct
}
output "bucket_id"            {
  description = "id of the bucket"
  value = local.bucket.bucket_id
}
output "bucket_crn"           {
  description = "crn of the bucket"
  value = local.bucket.bucket_crn
}
output "bucket_name"          {
  description = "name of the bucket"
  value = local.bucket.bucket_name
}
output "bucket_storage_class" {
  description = "bucket storage class"
  value = local.bucket.bucket_storage_class
}
output "kms_key_crn"          {
  description = "kms key crn used to encrypt the bucket"
  value = local.bucket.kms_key_crn
}
