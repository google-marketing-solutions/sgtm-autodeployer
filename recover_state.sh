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

PROJECT_ID=$(echo "var.project_id" | terraform console | sed 's/"//g')
REGIONS=$(echo "join(\",\",var.regions)" | terraform console | sed 's/"//g')
IFS=',' read -ra REGIONS_LIST <<< ${REGIONS}

function delete_state_files() {
  echo -e "\n--> Deleting current terraform state files..."
  rm terraform.tfstate*
}

function import_elements() {
  echo -e "\n--> Importing elements..."
  terraform import google_project_service.cloudresourcemanager ${PROJECT_ID}/cloudresourcemanager.googleapis.com
  terraform import google_project_service.compute ${PROJECT_ID}/compute.googleapis.com
  terraform import google_project_service.run ${PROJECT_ID}/run.googleapis.com
  terraform import google_project_service.runapps ${PROJECT_ID}/runapps.googleapis.com

  terraform import google_cloud_run_service.server-side-tagging-preview ${REGIONS_LIST[0]}/${PROJECT_ID}/server-side-tagging-preview
  terraform import google_cloud_run_service_iam_policy.server-side-tagging-preview projects/${PROJECT_ID}/locations/${REGIONS_LIST[0]}/services/server-side-tagging-preview

  for REGION in ${REGIONS_LIST[@]}
  do
    terraform import "google_cloud_run_service.server-side-tagging[\"${REGION}\"]" ${REGION}/${PROJECT_ID}/server-side-tagging
    terraform import "google_cloud_run_service_iam_policy.server-side-tagging[\"${REGION}\"]" projects/${PROJECT_ID}/locations/${REGION}/services/server-side-tagging
    terraform import "google_compute_region_network_endpoint_group.server-side-tagging-neg[\"${REGION}\"]" ${PROJECT_ID}/${REGION}/server-side-tagging-neg
  done

  terraform import google_compute_global_address.server-side-tagging-ip ${PROJECT_ID}/server-side-tagging-ip
  terraform import google_compute_backend_service.server-side-tagging-backend-main ${PROJECT_ID}/server-side-tagging-backend-main
  terraform import google_compute_backend_service.server-side-tagging-backend-scripts ${PROJECT_ID}/server-side-tagging-backend-scripts
  terraform import google_compute_url_map.server-side-tagging-urlmap ${PROJECT_ID}/server-side-tagging-urlmap
  terraform import google_compute_managed_ssl_certificate.server-side-tagging-cert ${PROJECT_ID}/server-side-tagging-cert
  terraform import google_compute_target_https_proxy.server-side-tagging-https-proxy ${PROJECT_ID}/server-side-tagging-https-proxy
  terraform import google_compute_global_forwarding_rule.server-side-tagging-forwarding ${PROJECT_ID}/server-side-tagging-forwarding

  terraform import google_logging_project_exclusion.server-side-tagging-balancer[0] projects/${PROJECT_ID}/exclusions/server-side-tagging-balancer
  terraform import google_logging_project_exclusion.server-side-tagging-run-server[0] projects/${PROJECT_ID}/exclusions/server-side-tagging-run-server
}

function main() {
  read -r -p "This will reset your local terraform state. Do you want to continue? [y/N] " response
  response=${response,,}
  if [[ "$response" =~ ^(yes|y)$ ]]
  then
    delete_state_files
    import_elements
  fi
}

main "$@"
