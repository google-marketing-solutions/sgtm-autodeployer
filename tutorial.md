# Tagging server auto-deployment guide

## Setup

This deployment guide helps you:

-   Deploy a new Cloud Run server
-   Install the Tag Manager server container
-   Customize the server to meet your needs

## Select your cloud project

To prepare, you need to select the Google Cloud Project to deploy the tagging
server in.

To deploy the tagging server on Cloud Run, you need to use a script that uses
the Google Cloud SDK which is available in your Cloud Shell environment.

<walkthrough-project-setup></walkthrough-project-setup>

Click the Cloud Shell icon below to copy the command to your shell. Paste the
command into your shell and run it by pressing Enter or Return.

The tool will pick up the project name from the environment variable.

```bash
export GOOGLE_CLOUD_PROJECT=<walkthrough-project-id/>
```

## Customize the environment

Provide some information about your environment to deploy a tagging server that
meets your needs.

Open <walkthrough-editor-open-file filePath="./config.conf">
config.conf</walkthrough-editor-open-file>

Each variable modifies a specific behavior in the deployment script.

Click next to start the review process for each of them.

## Container config string

The first item you need to provide is the the configuration string for the
server container. In Tag Manager, navigate to your server container workspace
and click on the container ID at the top-right of the page. Click on **Manually
provision** tagging server to find the **container config** value.

Then, copy this value into the
<walkthrough-editor-select-regex filePath="./config.conf" regex='CONTAINER_CONFIG=".*"'>
`CONTAINER_CONFIG`</walkthrough-editor-select-regex> variable.

Example:

```js
CONTAINER_CONFIG="WW91IGFyZSB0b28gc21hcnQgZm9yIHRoZSB0dXRvcmlhbCwgZ28gZm9yIHRoZSBzY3JpcHQhIDsp"
```

## Deployment regions

The tagging server can be deployed on any region supporting Cloud Run. For this
deployment, you can specify one or more regions where the tagging server will be
deployed. You can find the list
[here](https://cloud.google.com/run/docs/locations).

To define the regions to be used, please add them separated by commas (without
spaces) in the
<walkthrough-editor-select-regex filePath="./config.conf" regex='REGIONS=".*"'>
`REGIONS`</walkthrough-editor-select-regex> variable.

Example:

```js
REGIONS="europe-west1,europe-west2"
```

## Domain name

Next one is the domain name you want to use with the tagging server. Please
specify the domain name in the
<walkthrough-editor-select-regex filePath="./config.conf" regex='DOMAIN_NAME=".*"'>
`DOMAIN_NAME`</walkthrough-editor-select-regex> variable.

Example:

```js
DOMAIN_NAME="metrics.example.com"
```

## Set maximum number of instances

The `MAX_INSTANCES` field establishes a maximum boundary of how many Cloud Run
instances can be created automatically. Cloud Run only scales up to the maximum
number if required.

Autoscaling 2-10 servers will handle 35-350 requests per second, though the
performance will vary with the number of tags, and what those tags do. If you
expect to handle more than 350 per second at a given time, we recommend
increasing the number above 10.

Specify the maximum number of instances each Cloud Run deployment can scale to
in the
<walkthrough-editor-select-regex filePath="./config.conf" regex='MAX_INSTANCES=".*"'>
`MAX_INSTANCES`</walkthrough-editor-select-regex> variable.

Example:

```js
MAX_INSTANCES=10
```

## Optional: Set the logging level

By default, logging levels are not modified. If your tagging server handles a
lot of requests per month (e.g. greater than 1 million), those log messages may
incur significant logging charges.

There are two options available to alleviate this issue:

-   `DISABLE`: Disable the logging of requests.
-   `ERROR_ONLY` Log only ERROR level messages.

Set the appropriate value in the
<walkthrough-editor-select-regex filePath="./config.conf" regex='LOGGING=".*"'>
`LOGGING`</walkthrough-editor-select-regex> variable.

Example:

```js
LOGGING="DISABLE"
```

## Deploy it

The script `deploy.sh` will read the configuration you prepared in the previous
step and take care of everything needed for deploying the tagging server. You
can execute the commands by clicking the Cloud Shell icon next to them to copy
the command to your shell, and then run it from the shell by pressing
Enter/Return.

### Dry run (optional)

If you want to preview all the commands that will be executed before doing any
modifications to the system, you can run the script in *test* mode (without
doing any modifications) using this command:

```bash
bash deploy.sh -d
```

### Deployment

You can execute the script by using this command (make sure to follow the output
in case any errors occur):

```bash
bash deploy.sh
```

## Update DNS records at your domain registrar

Now that the server has been deployed, you need to update the DNS records of the
domain to point to your load balancer IP.

To get the IP you need to use, you can run the following command:

```bash
bash deploy.sh -m show_address
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

This configuration requires using custom headers when serving the scripts. As
this implies a cost per 1M requests, you'll deploy a supplemental backend
service with the headers configuration, while keeping the original Tag Manager
backend service without them.
[Learn how to set up custom request headers](https://developers.google.com/tag-platform/tag-manager/server-side/enable-region-specific-settings#step_1_set_up_the_request_header_).

To deploy the supplemental backend to handle script requests, you need to
execute the following command:

```sh
bash deploy.sh -m script_serving
```

After running the command,
[set up request headers in GTM](https://developers.google.com/tag-platform/tag-manager/server-side/enable-region-specific-settings).

## Deployment finished

<walkthrough-conclusion-trophy></walkthrough-conclusion-trophy>

Congratulations! You have successfully deployed a tagging server in your own GCP
project.

### Next steps

-   [How to send data to server-side Tag Manager](https://developers.google.com/tag-platform/tag-manager/server-side/send-data)
-   [Server-side tagging fundamentals](https://developers.google.com/tag-platform/learn/sst-fundamentals)
-   [Troubleshooting](https://developers.google.com/tag-platform/tag-manager/server-side/debug)
