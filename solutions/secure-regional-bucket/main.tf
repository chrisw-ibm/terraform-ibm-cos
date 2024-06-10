##############################################################################
# Secure Regional Bucket
##############################################################################

module "resource_group" {
  providers = {
    ibm = ibm.cos
  }
  source                       = "terraform-ibm-modules/resource-group/ibm"
  version                      = "1.1.5"
  resource_group_name          = var.existing_resource_group == false ? var.resource_group_name : null
  existing_resource_group_name = var.existing_resource_group == true ? var.resource_group_name : null
}

locals {
  kms_guid    = var.create_kms_instance && var.existing_kms_guid != null ? var.existing_kms_guid : module.kms.kms_guid
  kms_key_crn = var.existing_kms_key_crn != null ? var.existing_kms_key_crn : module.kms.keys[format("%s.%s", var.key_ring_name, var.key_name)].crn
  bucket_config = [{
    access_tags                   = var.bucket_access_tags
    bucket_name                   = var.bucket_name
    kms_encryption_enabled        = true
    add_bucket_name_suffix        = var.add_bucket_name_suffix
    kms_guid                      = local.kms_guid
    kms_key_crn                   = local.kms_key_crn
    skip_iam_authorization_policy = var.skip_iam_authorization_policy
    management_endpoint_type      = var.management_endpoint_type_for_bucket
    region_location               = var.region
    storage_class                 = var.bucket_storage_class
    force_delete                  = var.force_delete
    hard_quota                    = var.hard_quota
    object_locking_enabled        = var.object_locking_enabled
    object_lock_duration_days     = var.object_lock_duration_days
    object_lock_duration_years    = var.object_lock_duration_years

    activity_tracking = var.activity_tracker_crn != null ? {
      read_data_events     = true
      write_data_events    = true
      activity_tracker_crn = var.activity_tracker_crn
    } : null
    archive_rule = var.archive_days != null ? {
      enable = true
      days   = var.archive_days
      type   = var.archive_type
    } : null
    expire_rule = var.expire_days != null ? {
      enable = true
      days   = var.expire_days
    } : null
    metrics_monitoring = var.monitoring_crn != null ? {
      usage_metrics_enabled   = true
      request_metrics_enabled = true
      metrics_monitoring_crn  = var.monitoring_crn
    } : null
    object_versioning = {
      enable = var.object_versioning_enabled
    }
    retention_rule = var.retention_enabled ? {
      default   = var.retention_default
      maximum   = var.retention_maximum
      minimum   = var.retention_minimum
      permanent = var.retention_permanent
    } : null
  }]
}

#######################################################################################################################
# KMS Key
#######################################################################################################################

# KMS root key for COS cross region bucket
module "kms" {
  providers = {
    ibm = ibm.kms
  }
  source                      = "terraform-ibm-modules/kms-all-inclusive/ibm"
  version                     = "4.11.2"
  create_key_protect_instance = var.create_kms_instance
  existing_kms_instance_guid  = var.existing_kms_guid
  resource_group_id           = module.resource_group.resource_group_id
  region                      = var.kms_region
  key_ring_endpoint_type      = var.kms_endpoint_type
  key_endpoint_type           = var.kms_endpoint_type
  keys = [
    {
      key_ring_name         = var.key_ring_name
      existing_key_ring     = false
      force_delete_key_ring = true
      keys = [
        {
          key_name                 = var.key_name
          standard_key             = false
          rotation_interval_month  = 3
          dual_auth_delete_enabled = false
          force_delete             = true
        }
      ]
    }
  ]
}

#######################################################################################################################
# COS Bucket
#######################################################################################################################

module "cos" {
  providers = {
    ibm = ibm.cos
  }
  cos_instance_name        = var.cos_instance_name
  source                   = "../../modules/fscloud"
  create_cos_instance      = var.create_cos_instance
  existing_cos_instance_id = var.existing_cos_instance_id
  cos_plan                 = var.cos_plan
  cos_tags                 = var.cos_tags
  access_tags              = var.access_tags
  resource_group_id        = module.resource_group.resource_group_id
  bucket_configs           = local.bucket_config
}
locals {
  cos_resource_policy = [{
    service              = "cloud-object-storage"
    resource_type        = "bucket"
    resource_instance_id = module.cos.cos_instance_guid
    resource             = var.bucket_name
    resource_group_id    = module.resource_group.resource_group_id
  }]
  reader_service_id_name        = "cos-${var.bucket_name}-reader"
  writer_service_id_name        = "cos-${var.bucket_name}-writer"
  reader_service_id_description = "Managed by Terraform. DO NOT DELETE! This service Id is used for **reading** from the cos bucket (https://cloud.ibm.com/objectstorage/${urlencode(module.cos.cos_instance_crn)}?bucket=${var.bucket_name}&bucketRegion=${var.region})"
  writer_service_id_description = "Managed by Terraform. DO NOT DELETE! This service Id is used for **writing** to the cos bucket (https://cloud.ibm.com/objectstorage/${urlencode(module.cos.cos_instance_crn)}?bucket=${var.bucket_name}&bucketRegion=${var.region})"

  create_reader_service_id   = var.create_reader_service_id && !var.combine_service_id_roles
  create_writer_service_id   = var.create_writer_service_id && !var.combine_service_id_roles
  create_combined_service_id = var.combine_service_id_roles
}

module "reader_service_id" {
  count = local.create_reader_service_id ? 1 : 0
  providers = {
    ibm = ibm.cos
  }
  source  = "terraform-ibm-modules/iam-service-id/ibm"
  version = "1.1.2"
  # insert the 2 required variables here
  iam_service_id_name        = local.reader_service_id_name
  iam_service_id_tags        = []
  iam_service_id_description = local.reader_service_id_description
  iam_service_policies = {
    read_cos_objects = {
      roles     = ["Object Reader"]
      tags      = []
      resources = local.cos_resource_policy
    }
  }
}

module "writer_service_id" {
  count = local.create_writer_service_id ? 1 : 0
  providers = {
    ibm = ibm.cos
  }
  source                     = "terraform-ibm-modules/iam-service-id/ibm"
  version                    = "1.1.2"
  iam_service_id_name        = local.writer_service_id_name
  iam_service_id_tags        = []
  iam_service_id_description = local.writer_service_id_description
  iam_service_policies = {
    read_cos_objects = {
      roles     = ["Object Writer"]
      tags      = []
      resources = local.cos_resource_policy
    }
  }
}

module "read_write_service_id" {
  count = local.create_combined_service_id ? 1 : 0
  providers = {
    ibm = ibm.cos
  }
  source                     = "terraform-ibm-modules/iam-service-id/ibm"
  version                    = "1.1.2"
  iam_service_id_name        = local.writer_service_id_name
  iam_service_id_tags        = []
  iam_service_id_description = local.writer_service_id_description
  iam_service_policies = {
    readwrite_cos_objects = {
      roles     = ["Object Reader", "Object Writer"]
      tags      = []
      resources = local.cos_resource_policy
    }
  }
}
