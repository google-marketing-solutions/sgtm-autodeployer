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

variable "project_id" {
  type        = string
  description = "Google Cloud Project ID"
}
variable "container_config" {
  type        = string
  description = "GTM server container config"
}
variable "domain_names" {
  type        = list(string)
  description = "Domain names"
}
variable "regions" {
  type        = list(string)
  description = "Regions used for the deployment"
}
variable "min_instances" {
  type        = string
  description = "Minimum number of Cloud Run instances to scale"
  default = 1
}
variable "max_instances" {
  type        = string
  description = "Maximum number of Cloud Run instances to scale"
  default = 20
}
variable "full_logging_enabled" {
  type  = bool
  description = "Enable full logging"
  default = false
}