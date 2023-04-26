# Server Side GTM Autodeployer

## Setup

Welcome to the guided deployment of server side GTM (sGTM). This would help you
deploy sGTM as a Cloud Run service, customized for your particular environment.

## Cloud Project

To start we need to select the Google Cloud Project to deploy sGTM in.

We'll be using a script to deploy sGTM on Google Cloud, this uses the Google Cloud
SDK that should be available directly from your Cloud Shell environment.

<walkthrough-project-setup></walkthrough-project-setup>

Click the Cloud Shell icon below to copy the command to your shell, and then run
it from the shell by pressing Enter/Return. The tool will pick up the project
name from the environment variable.

```bash
export GOOGLE_CLOUD_PROJECT=<walkthrough-project-id/>
```

## Customize the environment

To deploy sGTM using the best settings for your environment, we need
to gather some information from your environment.

Open <walkthrough-editor-open-file filePath="./config.conf">
config.conf</walkthrough-editor-open-file>

Each variable modifies a specific behaviour in the deployment script.
Make sure you provide the appropiate values and save the file before
continuing.

You can find a summary of each value below.

Variable                         | Description
-------------------------------: | :-------------------------------------------------------- |
CONTAINER_CONFIG                 | Add the configuration string for the server container.
USE_MULTIREGION                  | `"YES"` if you need multiregion support.
REGIONS                          | Specify the regions to deploy sGTM, separated by commas.
USE_CUSTOM_DOMAIN                | `"YES"` if you plan to use custom domains.
USE_1P_SCRIPT_SERVING            | `"YES"` if you want to use First Party Script Serving.
ENABLE_LOGGING                   | `"YES"` if you want to enable logging.

After that, let's get the deployment started.

## Deploy it

The script `deploy.sh` will read the configuration you prepared in the previous
step and take care of everything needed for sGTM. You can execute the commands
by clicking the Cloud Shell icon next to them to copy the command to your shell,
and then run it from the shell by pressing Enter/Return.

### Dry Run (Optional)

If you want to preview all the commands that will be executed before
doing any modifications to the system, you can run the script
in *dry run* mode using this command:

```bash
bash deploy.sh -d
```

### Deployment

You can execute the script by using this command  (make sure to follow the
output in case any errors occur):

```bash
bash deploy.sh
```
