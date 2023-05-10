#!/bin/bash
#
# This script deploys the tagging server using custom settings.
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

IMAGE="gcr.io/cloud-tagging-10302018/gtm-cloud-image:stable"
MIN_INSTANCES=2

function gcloud_ext() {
  if [ -n "${OPT_DEBUG}" ]
  then
    echo "Skipped command as we are running in debug mode: "
    echo gcloud "$@"
  else
    gcloud "$@"
  fi
}

function gcloud_int() {
  if [ -n "${OPT_DEBUG}" ]
  then
    echo gcloud "$@"
  else
    gcloud "$@"
  fi
}

function cli_errors() {
  echo "Error parsing arguments" 1>&2
  print_usage
  exit 1
}

function enable_apis() {
  echo -e "\n--> Enabling required APIs..."
  gcloud_ext services enable \
    compute.googleapis.com \
    run.googleapis.com \
    runapps.googleapis.com \
    --project="${GOOGLE_CLOUD_PROJECT}"
}

function create_load_balancer() {
  create_address
  create_backend_service
  create_url_map
  create_tls_certificate
  create_target_https_proxy
  create_forwarding_rule
}

function delete_load_balancer() {
  delete_forwarding_rule
  delete_target_https_proxy
  delete_tls_certificate
  delete_url_map
  delete_backend_service
  delete_address
}

function create_address() {
  echo -e "\n--> Creating an IP address..."
  gcloud_ext compute addresses create --global ${SERVICE_IP}
}

function describe_address() {
  echo -e "This is the IP associated with your load balancer:"
  gcloud_ext compute addresses describe --global ${SERVICE_IP} --format='value(address)'
}

function delete_address() {
  echo -e "\n--> Deleting the IP address..."
  gcloud_ext compute addresses delete --global ${SERVICE_IP} ${FORCE} || :
}

function create_backend_service() {
  echo -e "\n--> Creating the backend service..."
  gcloud_ext compute backend-services create --global ${BACKEND_NAME}
}

function delete_backend_service() {
  echo -e "\n--> Deleting the backend service..."
  gcloud_ext compute backend-services delete --global ${BACKEND_NAME} ${FORCE} || :
}

function create_script_serving_backend_service() {
  echo -e "\n--> Creating the backend service for script serving..."
  gcloud_ext compute backend-services create ${SCRIPT_SERVING_BACKEND_NAME} --global \
  --custom-request-header "X-Gclb-Country: {client_region}" \
  --custom-request-header "X-Gclb-Region: {client_region_subdivision}"

  for REGION in ${REGIONS_LIST[@]}
  do
    gcloud_ext compute backend-services add-backend ${SCRIPT_SERVING_BACKEND_NAME} \
    --network-endpoint-group=server-side-tagging-neg --global \
    --network-endpoint-group-region="${REGION}"
  done

  gcloud_ext compute url-maps add-path-matcher ${URLMAP_NAME} \
  --path-matcher-name="${SCRIPT_SERVING_BACKEND_NAME}" \
  --path-rules="/gtm.js=${SCRIPT_SERVING_BACKEND_NAME},/gtags/*=${SCRIPT_SERVING_BACKEND_NAME}" \
  --default-service="${BACKEND_NAME}"
}

function delete_script_serving_backend_service() {
  echo -e "\n--> Deleting the backend service for script serving..."
  gcloud_ext compute url-maps remove-path-matcher ${URLMAP_NAME} \
  --path-matcher-name="${SCRIPT_SERVING_BACKEND_NAME}" || :
  gcloud_ext compute backend-services delete ${SCRIPT_SERVING_BACKEND_NAME} --global ${FORCE} || :
}

function create_url_map() {
  echo -e "\n--> Creating a URL map..."
  gcloud_ext compute url-maps create ${URLMAP_NAME} --default-service=${BACKEND_NAME}
}

function delete_url_map() {
  echo -e "\n--> Deleting the URL map..."
  gcloud_ext compute url-maps delete ${URLMAP_NAME} ${FORCE} || :
}

function create_tls_certificate() {
  echo -e "\n--> Creating a managed TLS Certificate..."
  gcloud_ext compute ssl-certificates create ${CERT_NAME} \
  --domains=${DOMAIN_NAME}
}

function delete_tls_certificate() {
  echo -e "\n--> Deleting the managed TLS Certificate..."
  gcloud_ext compute ssl-certificates delete ${CERT_NAME} ${FORCE} || :
}


function create_target_https_proxy() {
  echo -e "\n--> Create a target HTTPS Proxy..."
  gcloud_ext compute target-https-proxies create ${HTTPS_PROXY_NAME} \
    --ssl-certificates=${CERT_NAME} \
    --url-map=${URLMAP_NAME}
}
function delete_target_https_proxy() {
  echo -e "\n--> Delete the target HTTPS Proxy..."
  gcloud_ext compute target-https-proxies delete ${HTTPS_PROXY_NAME} ${FORCE} || :
}

function create_forwarding_rule() {
  echo -e "\n--> Create a forwarding rule..."
  gcloud_ext compute forwarding-rules create --global ${FORWARDING_RULE_NAME} \
    --target-https-proxy=${HTTPS_PROXY_NAME} \
    --address=${SERVICE_IP} \
    --ports=443
}

function delete_forwarding_rule() {
  echo -e "\n--> Delete the forwarding rule..."
  gcloud_ext compute forwarding-rules delete --global ${FORWARDING_RULE_NAME} ${FORCE} || :
}

function deploy_cloud_run() {
  # Deploy the tagging server preview application only once
  echo -e "\n--> Deploy the tagging server preview application in ${REGIONS_LIST[0]}..."
  gcloud_ext run deploy "${SERVICE_NAME}-preview" \
  --region ${REGIONS_LIST[0]} \
  --image ${IMAGE} \
  --min-instances 0 \
  --max-instances 1 \
  --timeout 60 \
  --allow-unauthenticated \
  --no-cpu-throttling \
  --update-env-vars \
  RUN_AS_PREVIEW_SERVER=true,CONTAINER_CONFIG="${CONTAINER_CONFIG}"

  if [[ "${MODE}" != "deploy_testing" ]]
  then
    PREVIEW_SERVER_URL=$(
        gcloud_int run services describe ${SERVICE_NAME}-preview --region "${REGIONS_LIST[0]}" \
        --format="value(status.url)")
    for REGION in ${REGIONS_LIST[@]}
    do
      # Deploy the tagging server
      echo -e "\n--> Deploy the tagging server in ${REGION}..."
      gcloud_ext run deploy "${SERVICE_NAME}" \
      --region ${REGION} \
      --image ${IMAGE} \
      --platform managed \
      --ingress all \
      --min-instances ${MIN_INSTANCES} \
      --max-instances ${MAX_INSTANCES} \
      --timeout 60 \
      --allow-unauthenticated \
      --no-cpu-throttling \
      --update-env-vars PREVIEW_SERVER_URL="${PREVIEW_SERVER_URL}",CONTAINER_CONFIG="${CONTAINER_CONFIG}"
    done
  fi
}

function delete_cloud_run() {
  echo -e "\n--> Deleting the tagging server preview in ${REGIONS_LIST[0]}..."
  gcloud_ext run services delete "${SERVICE_NAME}-preview" ${FORCE} --region ${REGIONS_LIST[0]} || :

  if [[ "${MODE}" != "remove_testing" ]]
  then
    for REGION in ${REGIONS_LIST[@]}
    do
      echo -e "\n--> Deleting the tagging server in ${REGION}..."
      gcloud_ext run services delete "${SERVICE_NAME}" ${FORCE} --region ${REGION} || :
    done
  fi
}

function create_network_endpoint_groups() {
  for REGION in ${REGIONS_LIST[@]}
  do
    echo -e "\n--> Create a network endpoint group for ${REGION}..."
    gcloud_ext compute network-endpoint-groups create ${SERVICE_NAME}-neg \
      --region=${REGION} \
      --network-endpoint-type=SERVERLESS \
      --cloud-run-service="${SERVICE_NAME}"
    gcloud_ext compute backend-services add-backend --global "${BACKEND_NAME}" \
    --network-endpoint-group-region=${REGION} \
    --network-endpoint-group="${SERVICE_NAME}-neg"
  done
}

function delete_network_endpoint_groups() {
  for REGION in ${REGIONS_LIST[@]}
  do
    echo -e "\n--> Deleting the network endpoint group for ${REGION}..."
    gcloud_ext compute backend-services remove-backend ${FORCE} --global "${BACKEND_NAME}" \
    --network-endpoint-group-region=${REGION} \
    --network-endpoint-group="${SERVICE_NAME}-neg" || :
    gcloud_ext compute network-endpoint-groups delete ${SERVICE_NAME}-neg ${FORCE} --region=${REGION} || :
  done
}

function create_log_filters() {
  if [ -n "${LOGGING}" ]
  then
    echo -e "\n--> Create the log filters..."
    if [[ "${LOGGING}" == "DISABLE" ]]
    then
      gcloud_ext logging sinks update _Default \
      --add-exclusion='name=run-server,filter=LOG_ID("run.googleapis.com/requests")'
      gcloud_ext logging sinks update _Default \
      --add-exclusion='name=balancer-server,filter=LOG_ID("requests")'
    elif [[ "${LOGGING}" == "ERROR_ONLY" ]]
    then
      gcloud_ext logging sinks update _Default \
      --add-exclusion='name=run-server,filter=LOG_ID("run.googleapis.com/requests") AND severity<=ERROR'
      gcloud_ext logging sinks update _Default \
      --add-exclusion='name=balancer-server,filter=LOG_ID("requests") AND severity<=ERROR'
    fi
  fi
}

function delete_log_filters() {
  echo -e "\n--> Deleting the log filters..."
  gcloud_ext logging sinks update _Default --remove-exclusions='run-filter' || :
  gcloud_ext logging sinks update _Default --remove-exclusions='balancer-filter' || :
}

function validate_values() {
  IFS=',' read -ra REGIONS_LIST <<< ${REGIONS}

  if [ -n "${PROJECT_ID}" ]
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
      echo "Aborting execution: prerequisites have not been met."
      echo "- Google Cloud Project not defined."
      echo "  Please run 'gcloud config set project <PROJECT_ID>' and try again."
      exit 1
    fi
  fi

  if [ -z "${CONTAINER_CONFIG}" ]
  then
    echo "Aborting execution: prerequisites have not been met."
    echo "- CONTAINER_CONFIG is required."
    echo "  In Tag Manager, navigate to your server container workspace and click on"
    echo "  the container ID at the top-right of the page. Click on "
    echo "  'Manually provision tagging server' to find the Container Config value."
    exit 1
  fi

  if [[ "${MODE}" == "deploy" && -z "${DOMAIN_NAME}" ]]
  then
    echo "Aborting execution: prerequisites have not been met."
    echo "- DOMAIN_NAME is required for production deployments. Please fix and try again."
    exit 1
  fi

  if [[ "${MODE}" == "deploy_testing" && ${#REGIONS_LIST[*]} -gt 1 ]]
  then
    echo "Aborting execution: prerequisites have not been met."
    echo "- Multiple deployment regions is not supported for testing environments. Please fix and try again."
    exit 1
  fi

}

function print_usage() {
  echo "Server Side GTM Autodeployer."
  echo "Usage: deploy.sh [-m deploy|show_address|deploy_testing|delete] [-t] [-p project-id]"
  echo ""
  echo "Options:"
  echo "-m                      Defines the operation to perform. Available options are:"
  echo "   deploy                -> Default option, deploys the tagging server in production mode."
  echo "   show_address          -> Displays the IP address that needs to be added to DNS record."
  echo "   remove                -> Deletes the components (if any) associated with this deployment."
  echo "   deploy_testing        -> Deploys the tagging server in testing mode (without load balancer)."
  echo "   remove_testing        -> Deletes the testing mode components (if any) associated with this deployment."
  echo "   script_serving        -> Deploys a specific backend service for first party script serving."
  echo "   remove_script_serving -> Deletes the backend service used for first party script serving."
  echo "-d                      Dry run mode (no changes will be made)."
  echo "-p project-id           Id of the GCP project where the tagging server will be deployed."
}

function main() {
    MODE="deploy"
    while getopts 'dm:p:fh' arg; do
        case "${arg}" in
            d) OPT_DEBUG="true";;
            m) MODE="${OPTARG}";;
            p) PROJECT_ID="${OPTARG}";;
            f) FORCE="--quiet";;
            h) print_usage; exit 0;;
            *) cli_errors; exit 1;;
        esac
    done
    shift "$((OPTIND-1))"

    validate_values

    if [ "${MODE}" == "remove" ]
    then
      echo "Deleting the tagging server from ${GOOGLE_CLOUD_PROJECT}:"
      delete_log_filters
      if [ -n "${DOMAIN_NAME}" ]
      then
        delete_network_endpoint_groups
        delete_load_balancer
      fi
      delete_cloud_run
    elif [ "${MODE}" == "show_address" ]
    then
      describe_address
    elif [ "${MODE}" == "deploy_testing" ]
    then
      echo "Installing the tagging server in testing mode in ${GOOGLE_CLOUD_PROJECT}:"
      enable_apis
      deploy_cloud_run
      create_log_filters
    elif [ "${MODE}" == "remove_testing" ]
    then
      echo "Deleting the tagging server in testing mode from ${GOOGLE_CLOUD_PROJECT}:"
      delete_log_filters
      delete_cloud_run
    elif [ "${MODE}" == "script_serving" ]
    then
      echo "Creating a specific backend service for first party script serving in ${GOOGLE_CLOUD_PROJECT}:"
      create_script_serving_backend_service
    elif [ "${MODE}" == "remove_script_serving" ]
    then
      echo "Deleting the backend service used for first party script serving from ${GOOGLE_CLOUD_PROJECT}:"
      delete_script_serving_backend_service
    elif [ "${MODE}" == "deploy" ]
    then
      echo "Installing the tagging server in ${GOOGLE_CLOUD_PROJECT}:"
      enable_apis
      deploy_cloud_run
      create_load_balancer
      create_network_endpoint_groups
      create_log_filters
    else
      print_usage
    fi
}

main "$@"
