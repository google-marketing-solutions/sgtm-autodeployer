# Tagging server auto-deployment guide

## Setup

This deployment guide helps you:

-   Deploy a new Cloud Run server
-   Install the Tag Manager server container
-   Customize the server to meet your needs

## Select your cloud project

To prepare, you need to select the Google Cloud Project to deploy the tagging
server in.

<walkthrough-project-setup></walkthrough-project-setup>

## Customize the environment

Provide some information about your environment to deploy a tagging server that
meets your needs.

Open <walkthrough-editor-open-file filePath="./terraform-sample.tfvars">
terraform-sample.tfvars</walkthrough-editor-open-file>

Provide the correct value for each variable:

-   <walkthrough-editor-select-regex filePath="./terraform-sample.tfvars" regex='project_id = .*'>**project_id**</walkthrough-editor-select-regex>:
    Copy and paste `<walkthrough-project-id/>` as the project id.
-   <walkthrough-editor-select-regex filePath="./terraform-sample.tfvars" regex='container_config = .*'>**container_config**</walkthrough-editor-select-regex>:
    In Tag Manager, navigate to your server container workspace and click on the
    container ID at the top-right of the page. Click on **Manually provision**
    tagging server to find the **container config** value.
-   <walkthrough-editor-select-regex filePath="./terraform-sample.tfvars" regex='domain_names = .*'>**domain_names**</walkthrough-editor-select-regex>:
    One or more domain names to be use with the tagging server, using the list
    syntax. For example: `["tagging.example.org", "tagging.example.com"]`.
-   <walkthrough-editor-select-regex filePath="./terraform-sample.tfvars" regex='regions = .*'>**regions**</walkthrough-editor-select-regex>:
    One or more regions where the tagging server will be deployed, using the
    list syntax. You can find the list
    [here](https://cloud.google.com/run/docs/locations).

Finally save it as `terraform.tfvars`.

## Deploy the tagging server

### Prepare

Terraform will be used to deploy the tagging server. To initialize the terraform
environment, click the Cloud Shell icon below to copy the command to your shell.
Paste the command into your shell and run it by pressing Enter or Return.

```bash
terraform init
```

If you have already deployed the tagging server in this project, you need to
recover the terraform state using the command below, otherwise you can skip this
step.

```bash
bash recover_state.sh
```

### Deploy

To start the deployment, use the command below and follow the prompts to confirm
the operation (you need to enter `yes` when prompted if you agree with the
changes, otherwise the script will exit).

```bash
terraform apply
```

## Update DNS records at your domain registrar

Now that the server has been deployed, you need to update the DNS records of the
domain to point to your load balancer IP.

To get the IP you need to use, you can run the following command:

```bash
terraform output
```

Next, log in to your account at your domain registrar and open the DNS
configuration page.

Locate the host records section of your domain’s configuration page and add
create or update a **A** record with the following information:

-   Record name: Enter the enter only the subdomain part from the custom domain
    you defined in previous steps. For example, enter “metrics” to map
    metrics.example.com.

-   Data: Enter the IP address you got from the previous command.

Save your changes in the DNS configuration page of your domain’s account. In
most cases, it takes only a few minutes for these changes to take effect, but in
some cases it can take several hours.

## Optional: First-party script serving

By default, Tag Manager or the Google tag (gtag.js) load their dependencies from
Google-owned servers, such as www.googletagmanager.com.

To establish a first-party context between your web container and your tagging
server, Google scripts must be loaded through your server.

[Learn how to load dependencies through your own server](https://developers.google.com/tag-platform/tag-manager/server-side/dependency-serving?tag=gtm#before_you_begin).

### Region-specific settings

When the previous steps are ready, the only part missing is setting up
region-specific tag behavior for even more control (this is specially important
if using consent mode).

To enable this feature,
[set up request headers in GTM](https://developers.google.com/tag-platform/tag-manager/server-side/enable-region-specific-settings).

## Deployment finished

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

Congratulations! You have successfully deployed a tagging server in your own GCP
project.

### Next steps

-   [How to send data to server-side Tag Manager](https://developers.google.com/tag-platform/tag-manager/server-side/send-data)
-   [Server-side tagging fundamentals](https://developers.google.com/tag-platform/learn/sst-fundamentals)
-   [Troubleshooting](https://developers.google.com/tag-platform/tag-manager/server-side/debug)
