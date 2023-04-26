#!/bin/bash
#
# This script deploys sGTM using custom settings.
#
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

set -e

CWD="$(dirname "$(realpath "$0")")"
source "${CWD}/config.conf"

function gcloud_ext() {
  if [ -n "${OPT_DEBUG}" ]
  then
    echo "Skipped command as we are running in debug mode: "
    echo gcloud $@
  else
    gcloud $@
  fi
}

function gcloud_int() {
  if [ -n "${OPT_DEBUG}" ]
  then
    echo gcloud $@
  else
    gcloud
  fi
}

function print_usage() {
  echo "Server Side GTM Autodeployer."
  echo "Usage: deploy.sh [-d] [-p project-id]"
  echo ""
  echo "Options:"
  echo "-d:                    Execute a dry run (no changes will be made)."
  echo "-p project-id:         Id of the GCP project where sGTM will be deployed."
}

function enable_apis() {
  # Enable required APIs
  echo -e "\n--> Enabling required APIs..."
  gcloud_ext services enable \
    compute.googleapis.com \
    run.googleapis.com \
    --project="${GOOGLE_CLOUD_PROJECT}"
}

function create_load_balancer() {
  # Create a load balancer
  echo -e "\n--> Creating a load balancer..."
  # projects/sgtm-by-gps/global/addresses/service-ip
  gcloud_ext compute addresses create --global ${SERVICE_IP}
}

function create_backend_service() {
  # Create the backend service
  echo -e "\n--> Creating the backend service..."
  # https://www.googleapis.com/compute/v1/projects/sgtm-by-gps/global/backendServices/server-side-backend
  gcloud_ext compute backend-services create --global ${BACKEND_NAME}
}

function create_url_map() {
  # Create a URL map
  echo -e "\n--> Creating a URL map..."
  # https://www.googleapis.com/compute/v1/projects/sgtm-by-gps/global/urlMaps/url-map
  gcloud_ext compute url-maps create ${URLMAP_NAME} --default-service=${BACKEND_NAME}
}

function create_tls_certificate() {
  # Create a managed TLS Certificate
  echo -e "\n--> Creating a managed TLS Certificate..."
  # https://www.googleapis.com/compute/v1/projects/sgtm-by-gps/global/sslCertificates/cert-name]
  gcloud_ext compute ssl-certificates create ${CERT_NAME} \
  --domains=${DOMAIN_NAME}
}

function create_target_https_proxy() {
  # Create a target HTTPS Proxy
  echo -e "\n--> Create a target HTTPS Proxy..."
  # https://www.googleapis.com/compute/v1/projects/sgtm-by-gps/global/targetHttpsProxies/proxy-https
  gcloud_ext compute target-https-proxies create ${HTTPS_PROXY_NAME} \
    --ssl-certificates=${CERT_NAME} \
    --url-map=${URLMAP_NAME}
}

function create_forwarding_rule() {
  # Create a forwarding rule
  echo -e "\n--> Create a forwarding rule..."
  # (This fails within google)
  # https://www.googleapis.com/compute/v1/projects/sgtm-by-gps/global/forwardingRules/forwarding-lb
  gcloud_ext compute forwarding-rules create --global ${FORWARDING_RULE_NAME} \
    --target-https-proxy=${HTTPS_PROXY_NAME} \
    --address=${SERVICE_IP} \
    --ports=443
}

function deploy_cloud_run() {
  # Deploy the sGTM application
  echo -e "\n--> Deploy the sGTM preview application..."
  gcloud_ext run deploy "${SERVICE_NAME}-preview" \
  --region ${REGION} \
  --image gcr.io/cloud-tagging-10302018/gtm-cloud-image:2.1.0 \
  --min-instances 0 \
  --max-instances 1 \
  --timeout 60 \
  --allow-unauthenticated \
  --no-cpu-throttling \
  --update-env-vars \
  RUN_AS_PREVIEW_SERVER=true,CONTAINER_CONFIG="${CONTAINER_CONFIG}"

  echo -e "\n--> Deploy the sGTM application..."
  gcloud_ext run deploy "${SERVICE_NAME}" \
  --region ${REGION} \
  --image gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable \
  --platform managed \
  --ingress all \
  --min-instances ${MIN_INSTANCES} \
  --max-instances ${MAX_INSTANCES} \
  --timeout 60 \
  --allow-unauthenticated \
  --no-cpu-throttling \
  --update-env-vars PREVIEW_SERVER_URL="$(
    gcloud_int run services describe ${SERVICE_NAME}-preview --region "${REGION}" \
    --format="value(status.url)")",CONTAINER_CONFIG="${CONTAINER_CONFIG}"
}

function main() {
    # Process optional arugments.
    while getopts 'dp:h' arg; do
        case "${arg}" in
            d) OPT_DEBUG="true";;
            p) PROJECT_ID="${OPTARG}";;
            h) print_usage; exit 0;;
            *) cli_errors; exit 1;;
        esac
    done
    shift "$((OPTIND-1))"
    
    if [ -n "${PROJECT_ID}"]
    then
      gcloud_ext config set project ${PROJECT_ID}
      export GOOGLE_CLOUD_PROJECT=${PROJECT_ID}
    elif [ -n "${GOOGLE_CLOUD_PROJECT}" ]
    then
      gcloud_ext config set project ${GOOGLE_CLOUD_PROJECT}
    else
      GOOGLE_CLOUD_PROJECT=$(gcloud config get project)
      if [ -z "${GOOGLE_CLOUD_PROJECT}" ]
      then
        echo "Google Cloud Project not defined."
        echo "Please run 'gcloud config set project <PROJECT_ID>' and try again."
        exit 1
      fi
    fi

    echo "Installing sGTM in ${GOOGLE_CLOUD_PROJECT}:"

    enable_apis
    create_load_balancer
    create_backend_service
    create_url_map
    create_tls_certificate
    create_target_https_proxy
    create_forwarding_rule
    deploy_cloud_run
}

main "$@"