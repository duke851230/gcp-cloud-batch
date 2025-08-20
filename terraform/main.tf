provider "google" {
  project = var.project_id
  region  = var.region
}

locals {
  image_uri = "${var.region}-docker.pkg.dev/${var.project_id}/${var.artifact_repo_id}/${var.image_name}"
}

# Artifact Registry (Docker)
resource "google_artifact_registry_repository" "repo" {
  location      = var.region
  repository_id = var.artifact_repo_id
  description   = "Repo for Batch job images"
  format        = "DOCKER"
}

# 服務帳號：Batch 執行時使用
resource "google_service_account" "batch_runner" {
  account_id   = "batch-runner-sa"
  display_name = "Batch Runner Service Account"
}

# 服務帳號：Workflows（用來建立 Batch Job）
resource "google_service_account" "workflows" {
  account_id   = "workflows-batch-sa"
  display_name = "Workflows to Batch Service Account"
}

# 服務帳號：Scheduler（呼叫 Workflows 執行 API）
resource "google_service_account" "scheduler" {
  account_id   = "scheduler-invoker-sa"
  display_name = "Scheduler Invoker Service Account"
}

# IAM：Batch Runner 需要讀取 Artifact Registry 與寫入 Logs
resource "google_project_iam_member" "batch_runner_ar_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.batch_runner.email}"
}

resource "google_project_iam_member" "batch_runner_logs" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.batch_runner.email}"
}

# IAM：Workflows 需要操作 Batch，且可代替 batch_runner SA 執行
resource "google_project_iam_member" "workflows_batch_admin" {
  project = var.project_id
  role    = "roles/batch.admin"
  member  = "serviceAccount:${google_service_account.workflows.email}"
}

resource "google_service_account_iam_member" "workflows_impersonate_batch_runner" {
  service_account_id = google_service_account.batch_runner.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.workflows.email}"
}

# Workflows：建立 Batch Job 的流程
resource "google_workflows_workflow" "batch_trigger" {
  name        = "create-batch-job"
  description = "Creates a one-off Cloud Batch job to run the provided container image"
  region      = var.region
  service_account = google_service_account.workflows.email
  deletion_protection = false

  source_contents = <<-YAML
    # Workflows source
    main:
      steps:
        - set_vars:
            assign:
              - project: "${var.project_id}"
              - region: "${var.region}"
              - image: "${local.image_uri}"
              - batch_sa: "${google_service_account.batch_runner.email}"
              - job_id: $${"py-" + string(int(sys.now()))}
        - create_job:
            call: http.post
            args:
              url: $${"https://batch.googleapis.com/v1/projects/" + project + "/locations/" + region + "/jobs?jobId=" + job_id}
              auth:
                type: OAuth2
              body:
                taskGroups:
                  - taskSpec:
                      computeResource:
                        cpuMilli: ${var.task_cpu_milli}
                        memoryMib: ${var.task_memory_mib}
                      runnables:
                        - container:
                            imageUri: $${image}
                            # 若要覆寫容器命令，可加入：
                            # entrypoint: ""
                            # commands: ["python", "/app/main.py"]
                    taskCount: 1
                allocationPolicy:
                  serviceAccount:
                    email: $${batch_sa}
                  instances:
                    - policy:
                        machineType: "${var.machine_type}"
                logsPolicy:
                  destination: CLOUD_LOGGING
                labels:
                  workload: "python"
                  source:   "workflows"
            result: resp
        - the_end:
            return: $${resp.body}
  YAML
}

# 允許 Scheduler SA 觸發這個 Workflow（Executions API）
resource "google_project_iam_member" "workflow_invoker" {
  project = var.project_id
  role    = "roles/workflows.invoker"
  member  = "serviceAccount:${google_service_account.scheduler.email}"
}

# Cloud Scheduler Job：用 OAuth token 直接呼叫 Workflows Executions API
resource "google_cloud_scheduler_job" "run_batch" {
  name     = "schedule-python-batch"
  region   = var.scheduler_location
  schedule = var.scheduler_cron
  time_zone = var.timezone

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/workflows/${google_workflows_workflow.batch_trigger.name}/executions"

    oauth_token {
      service_account_email = google_service_account.scheduler.email
    }

    headers = {
      "Content-Type" = "application/json"
    }

    # 無需傳參，空 JSON 即可 - 需要 base64 編碼
    body = base64encode(jsonencode({}))
  }
}


# IAM：Batch Runner 需要 Batch 服務代理權限
resource "google_project_iam_member" "batch_runner_service_agent" {
  project = var.project_id
  role    = "roles/batch.serviceAgent"
  member  = "serviceAccount:${google_service_account.batch_runner.email}"
}

# IAM：Batch Runner 需要 Batch 代理報告權限
resource "google_project_iam_member" "batch_runner_agent_reporter" {
  project = var.project_id
  role    = "roles/batch.agentReporter"
  member  = "serviceAccount:${google_service_account.batch_runner.email}"
}