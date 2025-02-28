# Server-side Tag Manager Autodeployer

This tool enables you to deploy server-side Tag Manager easily in your own
Google Cloud environment, allowing you to customize the regions to use, scaling
capabilities and custom domain to use.

The deployment is based on the
[Cloud Run setup guide](https://developers.google.com/tag-platform/tag-manager/server-side/cloud-run-setup-guide?provisioning=cli)
and is meant to simplify the process for new users of server-side tagging.

*Before installing the tool, we strongly recommend you to join the
[sGTM Autodeployer users group](https://groups.google.com/g/sgtm-autodeployer).
In there you will be able ask questions and provide feedback about the
solution.*

## Quick start

Click the *Open in Cloud Shell* button to open this repository in Google Cloud
Shell and follow a guided tutorial to deploy server-side Tag Manager.

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Fgoogle%2Fsgtm-autodeployer&cloudshell_git_branch=main&cloudshell_workspace=.&cloudshell_tutorial=tutorial.md)

## Advance usage

### Initial Environment Setup

1. If you don't use Cloud Shell, export environment variables and set the default project.
   Typically, there is a single project to install the solution. If you chose to use multiple projects - use the one
   designated for the data processing.

    ```bash
    export PROJECT_ID="[your Google Cloud project id]"
    gcloud config set project $PROJECT_ID
    ```

1. Authenticate with additional OAuth 2.0 scopes needed to interact with Google Cloud APIs:
   ```shell
   gcloud auth login
   gcloud auth application-default login --quiet --scopes="openid,https://www.googleapis.com/auth/userinfo.email,https://www.googleapis.com/auth/cloud-platform,https://www.googleapis.com/auth/sqlservice.login,https://www.googleapis.com/auth/accounts.reauth"
   gcloud auth application-default set-quota-project $PROJECT_ID
   export GOOGLE_APPLICATION_CREDENTIALS=/Users/<USER_NAME>/.config/gcloud/application_default_credentials.json
   ```

    **Note:** You may receive an error message informing the Cloud Resource Manager API has not been used/enabled for your project, similar to the following: 
    
    ERROR: (gcloud.auth.application-default.login) User [<ldap>@<company>.com] does not have permission to access projects instance [<gcp_project_ID>:testIamPermissions] (or it may not exist): Cloud Resource Manager API has not been used in project <gcp_project_id> before or it is disabled. Enable it by visiting https://console.developers.google.com/apis/api/cloudresourcemanager.googleapis.com/overview?project=<gcp_project_id> then retry. If you enabled this API recently, wait a few minutes for the action to propagate to our systems and retry.

    On the next step, the Cloud Resource Manager API will be enabled and, then, your credentials will finally work.

1. Review your Terraform version

    Make sure you have installed terraform version is 1.9.7. We recommend you to use [tfenv](https://github.com/tfutils/tfenv) to manage your terraform version.
   `Tfenv` is a version manager inspired by rbenv, a Ruby programming language version manager.

    To install `tfenv`, run the following commands:

    ```shell
    # Install via Homebrew or via Arch User Repository (AUR)
    # Follow instructions on https://github.com/tfutils/tfenv

    # Now, install the recommended terraform version 
    tfenv install 1.9.7
    tfenv use 1.9.7
    terraform --version
    ```

    **Note:** If you have a Apple Silicon Macbook, you should install terraform by setting the `TFENV_ARCH` environment variable:
    ```shell
    TFENV_ARCH=amd64 tfenv install 1.9.7
    tfenv use 1.9.7
    terraform --version
    ```
    If not properly terraform version for your architecture is installed, `terraform .. init` will fail.

    For instance, the output on MacOS should be like:
    ```shell
    Terraform v1.9.7
    on darwin_amd64
    ```

1. Create the Terraform variables file by making a copy from the template and set the Terraform variables.
   If you want to use the tool without the guided tutorial, make sure to edit the
   `terraform.tfvars` file first, and provide all the needed parameters there
   (there are detailed instructions for each variable in the bottom of the file).


    ```bash
    cp terraform-sample.tfvars terraform.tfvars
   ```

   Edit the variables file. If using Vim:
   ```shell
    vim terraform.tfvars
    ```

1. Run Terraform to initialize your environment, and validate if your configurations and variables are set as expected:

    ```bash
    terraform init
    terraform plan
    terraform validate
    ```

    If you run into errors, review and edit the `terraform.tfvars` file. However, if there are still configuration errors, open a new [github issue](https://github.com/google-marketing-solutions/sgtm-autodeployer/issues/).

    If you have already deployed the tagging server in the target Google Cloud
    project, recover the terraform state using the command below, otherwise you can
    skip this step.

    ```bash
    bash recover_state.sh
    ```

1. To start the deployment, use the command below and follow the prompts to confirm
the operation (you need to enter `yes` when prompted if you agree with the
changes, otherwise the script will exit).

    ```bash
    terraform apply
    ```

## Disclaimers

**This is not an officially supported Google product.**

*Copyright 2023 Google LLC. This solution, including any related sample code or
data, is made available on an “as is,” “as available,” and “with all faults”
basis, solely for illustrative purposes, and without warranty or representation
of any kind. This solution is experimental, unsupported and provided solely for
your convenience. Your use of it is subject to your agreements with Google, as
applicable, and may constitute a beta feature as defined under those agreements.
To the extent that you make any data available to Google in connection with your
use of the solution, you represent and warrant that you have all necessary and
appropriate rights, consents and permissions to permit Google to use and process
that data. By using any portion of this solution, you acknowledge, assume and
accept all risks, known and unknown, associated with its usage, including with
respect to your deployment of any portion of this solution in your systems, or
usage in connection with your business, if at all.*
