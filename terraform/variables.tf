variable "project_id" {
  description = "GCP project ID"
  type        = string
}

variable "region" {
  description = "Primary region for resources (Batch / Workflows / AR)"
  type        = string
  default     = "asia-east1"
}

variable "scheduler_location" {
  description = "Cloud Scheduler location (建議與 region 一致)"
  type        = string
  default     = "asia-east1"
}

variable "timezone" {
  description = "Scheduler cron timezone"
  type        = string
  default     = "Asia/Taipei"
}

variable "scheduler_cron" {
  description = "Cron 表達式（預設每小時）"
  type        = string
}

variable "artifact_repo_id" {
  description = "Artifact Registry repository id"
  type        = string
  default     = "batch-jobs"
}

variable "image_name" {
  description = "Container image name:tag"
  type        = string
  default     = "python-job:latest"
}

variable "machine_type" {
  description = "Batch VM machine type"
  type        = string
  default     = "e2-small"
}

variable "task_cpu_milli" {
  description = "CPU milli for Batch task (1000 = 1 vCPU)"
  type        = number
  default     = 1000
}

variable "task_memory_mib" {
  description = "Memory MiB for Batch task"
  type        = number
  default     = 512
}