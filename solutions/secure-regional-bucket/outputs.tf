locals {
  bucket = module.cos.buckets[0]
}
##############################################################################
# Outputs
##############################################################################
output "buckets" {
  description = "List of buckets created"
  value       = module.cos.buckets
}


output "buckets" {
  description = "List of buckets created"
  value       = module.cos.buckets
}
