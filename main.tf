# Copyright 2023 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

provider "google" {
  project = var.project_id
}

# Enable APIs
resource "google_project_service" "cloudresourcemanager" {
  disable_on_destroy = false
  service            = "cloudresourcemanager.googleapis.com"
}

resource "google_project_service" "compute" {
  disable_on_destroy = false
  service            = "compute.googleapis.com"
}

resource "google_project_service" "run" {
  disable_on_destroy = false
  service            = "run.googleapis.com"
}

resource "google_project_service" "runapps" {
  disable_on_destroy = false
  service            = "runapps.googleapis.com"
}

data "google_iam_policy" "noauth" {
  binding {
    role = "roles/run.invoker"
    members = [
      "allUsers",
    ]
  }
}

resource "google_cloud_run_service" "server-side-tagging-preview" {
  name     = "server-side-tagging-preview"
  location = var.regions[0]

  template {
    spec {
      containers {
        image = "gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable"
        env {
          name  = "RUN_AS_PREVIEW_SERVER"
          value = "true"
        }
        env {
          name  = "CONTAINER_CONFIG"
          value = var.container_config
        }
      }
      timeout_seconds = 60
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"  = 1
        "autoscaling.knative.dev/minScale"  = 0
        "run.googleapis.com/client-name"    = "terraform"
        "run.googleapis.com/cpu-throttling" = false
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [
    google_project_service.run,
    google_project_service.runapps
  ]
}

resource "google_cloud_run_service_iam_policy" "server-side-tagging-preview" {
  location = google_cloud_run_service.server-side-tagging-preview.location
  project  = google_cloud_run_service.server-side-tagging-preview.project
  service  = google_cloud_run_service.server-side-tagging-preview.name

  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_cloud_run_service" "server-side-tagging" {
  name = "server-side-tagging"

  for_each = toset(var.regions)
  location = each.key

  template {
    spec {
      containers {
        image = "gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable"
        env {
          name = "PREVIEW_SERVER_URL"
          value = google_cloud_run_service.server-side-tagging-preview.status[0].url
        }
        env {
          name  = "CONTAINER_CONFIG"
          value = var.container_config
        }
      }
      timeout_seconds = 60
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale"  = var.max_instances
        "autoscaling.knative.dev/minScale"  = var.min_instances
        "run.googleapis.com/client-name"    = "terraform"
        "run.googleapis.com/cpu-throttling" = false
      }
    }
  }
  traffic {
    percent         = 100
    latest_revision = true
  }
  depends_on = [
    google_project_service.run,
    google_project_service.runapps
  ]
}

resource "google_cloud_run_service_iam_policy" "server-side-tagging" {
  for_each = toset(var.regions)

  location = google_cloud_run_service.server-side-tagging[each.value].location
  project  = google_cloud_run_service.server-side-tagging[each.value].project
  service  = google_cloud_run_service.server-side-tagging[each.value].name

  policy_data = data.google_iam_policy.noauth.policy_data
}

resource "google_compute_global_address" "server-side-tagging-ip" {
  name = "server-side-tagging-ip"
  depends_on = [
    google_project_service.compute
  ]
}

resource "google_compute_url_map" "server-side-tagging-urlmap" {
  name            = "server-side-tagging-urlmap"
  default_service = google_compute_backend_service.server-side-tagging-backend-main.id

  host_rule {
    hosts        = ["*"]
    path_matcher = "allpaths"
  }

  path_matcher {
    name            = "allpaths"
    default_service = google_compute_backend_service.server-side-tagging-backend-main.id

    path_rule {
      paths   = ["/gtm.js"]
      service = google_compute_backend_service.server-side-tagging-backend-scripts.id
    }
    path_rule {
      paths   = ["/gtag/*"]
      service = google_compute_backend_service.server-side-tagging-backend-scripts.id
    }
  }
}

resource "google_compute_managed_ssl_certificate" "server-side-tagging-cert" {
  name = "server-side-tagging-cert"

  managed {
    domains = var.domain_names
  }
}

resource "google_compute_target_https_proxy" "server-side-tagging-https-proxy" {
  name             = "server-side-tagging-https-proxy"
  url_map          = google_compute_url_map.server-side-tagging-urlmap.id
  ssl_certificates = [google_compute_managed_ssl_certificate.server-side-tagging-cert.id]
}

resource "google_compute_global_forwarding_rule" "server-side-tagging-forwarding" {
  name       = "server-side-tagging-forwarding"
  target     = google_compute_target_https_proxy.server-side-tagging-https-proxy.id
  port_range = "443"
  ip_address = google_compute_global_address.server-side-tagging-ip.id
}

resource "google_compute_region_network_endpoint_group" "server-side-tagging-neg" {
  for_each = toset(var.regions)
  name                  = "server-side-tagging-neg"
  network_endpoint_type = "SERVERLESS"
  region                = google_cloud_run_service.server-side-tagging[each.value].location
  cloud_run {
    service = google_cloud_run_service.server-side-tagging[each.value].name
  }
}

resource "google_compute_backend_service" "server-side-tagging-backend-main" {
  name = "server-side-tagging-backend-main"

  dynamic "backend" {
    for_each = google_compute_region_network_endpoint_group.server-side-tagging-neg
    content {
      group = backend.value.id
    }
  }
}

resource "google_compute_backend_service" "server-side-tagging-backend-scripts" {
  name                   = "server-side-tagging-backend-scripts"
  custom_request_headers = ["X-Gclb-Country:{client_region}", "X-Gclb-Region:{client_region_subdivision}"]

  dynamic "backend" {
    for_each = google_compute_region_network_endpoint_group.server-side-tagging-neg
    content {
      group = backend.value.id
    }
  }
}

resource "google_logging_project_exclusion" "server-side-tagging-run-server" {
  count       =  var.full_logging_enabled ? 0 : 1
  name        = "server-side-tagging-run-server"
  description = "Exclude Cloud Run logs below ERROR"
  filter      = "LOG_ID(\"run.googleapis.com/requests\") AND severity<=ERROR"
}

resource "google_logging_project_exclusion" "server-side-tagging-balancer" {
  count       =  var.full_logging_enabled ? 0 : 1
  name        = "server-side-tagging-balancer"
  description = "Exclude Load Balancing logs below ERROR"
  filter      = "LOG_ID(\"requests\") AND severity<=ERROR"
}

output "server-side-tagging-public-ip" {
  description = "Public IP of the tagging server"
  value       = google_compute_global_address.server-side-tagging-ip.address
}