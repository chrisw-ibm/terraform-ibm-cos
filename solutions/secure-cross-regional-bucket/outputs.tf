##############################################################################
# Outputs
##############################################################################
output "buckets" {
  description = "List of buckets created"
  value       = module.cos.buckets
}

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

