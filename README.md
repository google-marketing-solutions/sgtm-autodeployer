# Server-side Tag Manager Autodeployer

This tool enables you to deploy server-side Tag Manager easily in your own
Google Cloud environment, allowing you to customize the regions to use, scaling
capabilities and custom domain to use.

The deployment is based on the
[Cloud Run setup guide](https://developers.google.com/tag-platform/tag-manager/server-side/cloud-run-setup-guide?provisioning=cli)
and is meant to simplify the process for new users of server-side tagging.

## Quick start

Click the *Open in Cloud Shell* button to open this repository in Google Cloud
Shell and follow a guided tutorial to deploy server-side Tag Manager.

[![Open in Cloud Shell](https://gstatic.com/cloudssh/images/open-btn.svg)](https://shell.cloud.google.com/cloudshell/editor?cloudshell_git_repo=https%3A%2F%2Fgithub.com%2Fgoogle%2Fsgtm-autodeployer&cloudshell_git_branch=main&cloudshell_workspace=.&cloudshell_tutorial=tutorial.md)

## Advance usage

If you want to use the script directly without the guided tutorial, you can see
all the available options by executing the following command:

```sh
bash deploy.sh -h
```

Before going forward with the execution, make sure to edit the `config.conf`
file, and provide all the needed parameters there (there are detailed
instructions above each available variable).

The script also provides a `dry-run` mode that allows you to verify the commands
that will be executed without doing any changes to the system.

## Disclaimers

__This is not an officially supported Google product.__

_Copyright 2023 Google LLC. This solution, including any related sample code or
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
usage in connection with your business, if at all._