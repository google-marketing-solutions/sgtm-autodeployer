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

project_id = ""
container_config = ""
domain_names = ["example.org"]
regions = ["europe-west1","us-central1"]

# Configuration Variables Help
# - project_id:
#   Represents the Google Cloud project you are going to use to deploy server
#   side tagging. You can get this information from the project dashboard at
#   https://console.cloud.google.com.
# - container_config:
#   the container ID at the top-right of the page. Click on Manually provision
#   tagging server to find the Container Config value.
# - domain_names:
#   The domain name (or list of domain names) you want to use with the server
#   side tagging container.
# - regions:
#   The region (or list of regions) where the server side tagging container
#   will be deployed.

