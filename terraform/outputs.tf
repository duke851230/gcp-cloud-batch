output "artifact_image_uri" {
  value = local.image_uri
}

output "workflow_name" {
  value = google_workflows_workflow.batch_trigger.name
}

output "scheduler_job_name" {
  value = google_cloud_scheduler_job.run_batch.name
}