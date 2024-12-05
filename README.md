# Cloudera AI Compute Only Cluster with sidecar FreeIPA

> Constructs Cloudera on Premise Base and ECS clusters with sidecar FreeIPA to enable provisioning of a Cloudera AI Compute Only Cluster. Note that the sidecar FreeIPA is the DNS server, access to the nodes via URL needs to go via FreeIPA (e.g. using a SOCKS5 proxy).

A summary of the infrastructure and cluster configuration is given below.

| Item                           | |
| ------------------------------ | ------ |
| _**PvC Base Version**_         | 7.1.9 SP1 |
| _**Cloudera Manager Version**_ | 7.11.3 |
| _**ECS Version**_              | 1.5.4 |
| _**DNS & Directory Service**_  | FreeIPA server deployed as part of automation |
| _**Infrastructure Platform**_  | OpenStack |
| _**Num Nodes Created**_        | 4 |
| _FreeIPA & Cloudera Manager Server Nodes_         | 1 |
| _Base Nodes_            | 1 |
| _ECS Master Nodes_             | 1 |
| _ECS Worker Nodes_             | 3 |

## Requirements

This example requires an execution environment with dependencies to run the automation; and a set of configuration variables.

We provide instructions for using a Docker container based execution environment.

### Execution Environment Setup

> **_NOTE 1:_** These steps need to be run using Python version 3.9 or greater.

> **_NOTE 2:_** A container engine is required to be run. The instructions here are for Docker.

0. Ensure you have a version of Python >= 3.9 and have docker running.

    ```bash
    python --version

    docker info
    ```

1. Create and activate a new `virtualenv` and install `ansible-core` and `ansible-navigator`

    ```bash
    python -m venv ~/cdp-navigator; 

    source ~/cdp-navigator/bin/activate; 

    pip install ansible-core==2.12.10 ansible-navigator==3.4.0
    ```

1. Clone this repository.

    ```bash
    git clone https://github.infra.cloudera.com/jenright/pvc-ai-compute-cluster.git; 
    ```

1. Change your working directory to this project.

    ```bash
    cd pvc-ai-compute-cluster
    ```

#### Environment Variables

* A `env_vars_template.sh` exists shows the required variables. This can be edited and can be edited and sourced to set the desired values.

```bash
cp env_vars_template.sh env_vars.sh

# edit env_vars.sh as needed

source ./env_vars.sh
```

* A description of the environment variables are below.
    
    | Variable | Description | Status |
    |----------|-------------|--------|
    | `SSH_PUBLIC_KEY_FILE` | File path to the SSH public key that will be uploaded to the cloud provider (using the `name_prefix` variable as the key label). E.g. `/Users/example/.ssh/id_rsa.pub` | Mandatory |
    | `SSH_PRIVATE_KEY_FILE` | File path to the SSH private key. E.g. `/Users/example/.ssh/demo_ops` | Mandatory |
    | `CDP_LICENSE_FILE` | File path to a CDP Private Cloud Base license. E.g. `/Users/example/Documents/cloudera_license.txt` | Mandatory |
    | `OS_*` | The OpenStack credentials enviroment varariables set by the openrc.sh file. | Mandatory |

* For OSX, set the following: `export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` to allow some modules to function.

#### Configuration file variables

Create a `config.yml` file with user-facing configuration for your deployment. The `config_template.yml` shows the required vars to set.

*NOTE:* `name_prefix` should be 4-8 characters and is the "primary key" for the deployment.

```yaml
name_prefix:       "< short_id_for_deployment >" # Unique identifier for the deployment 
owner_email:       "<email>@cloudera.com"  # Owner email
infra_az:          "CLOUD" # P9 IOPSCloud SE
domain:            "{{ owner_prefix }}.cldr.example"   # The private, adhoc subdomain (name_prefix.owner_prefix.cldr.demo)
realm:             "CLDR.EXAMPLE"                      # The Kerberos realm
common_password:   "Example776"                   
admin_password:    "Example776"               
deployment_tags:
  email: "{{ owner_email }}"
  deployment: "{{ name_prefix }}"
  deploy-tool: cloudera-deploy
```

## Execution

NOTE: If you need to debug any of the following Ansible playbooks, include the `verbose` flags, i.e. `-vvv`, or for full connection debugging, `-vvvvv`.

### (Optional) Infrastructure setup Playbook

This playbook includes tasks to provision the infrastructure resources. It is an optional and can be used when the infrastructure is required to be created.

Run the following command for the infra_setup.yml playbook:

```bash
ansible-navigator run infra_setup.yml \
-e @config.yml \
-e @definition.yml
```

> **_NOTE:_** If the infrastructure resources already exist then an inventory file can be populated with this details. See the next section for details on this.

> **_NOTE:_** On the Platform 9 IOPSCloud intermittent failures in VM instance creation may occur due to timeouts during image upload to the boot volume. When this happens the pre_setup.yml will fail at the `Provision infrastructure resources` play. The pre_setup.yml Playbook can be rerun until all instances are created successfully.

### Creating an Inventory file for pre-existing Playbooks

TODO:

### Platform Playbooks

These playbooks configure and deploy PVC Base and ECS.

Tasks include:
* System/host configuration
* Cloudera Manager server and agent installation and configuration
* Cluster template imports

Run the following:

```bash
# Run the 'external' system configuration
ansible-navigator run external_setup.yml \
-e @config.yml \
-e @definition.yml
```

```bash
# Run the 'internal' Cloudera installations and configurations
ansible-navigator run internal_setup.yml \
-e @config.yml \
-e @definition.yml
```

```bash
# Run the Cloudera cluster configuration and imports
ansible-navigator run base_setup.yml \
-e @config.yml \
-e @definition.yml
```

## Deployment Summary Playbook & Cluster Access

Use the `summary.yml` playbook to generate a summary document of the deployment. This outputs files of the form `<NAME_PREFIX>-DEPLOYMENT.md` and `<NAME_PREFIX>-DEPLOYMENT.html` which give details about the deployed hosts and how to access the cluster.


```bash
ansible-navigator run summary.yml \
-e @config.yml \
-e @definition.yml
```

### Cluster Access (generic instructions)

> **NOTE:** Generic instructions on how to access the cluster are below; details specific to the deployment name prefix will be written to the summary document.

You can access all of the UIs within, including the FreeIPA sidecar, via a SSH tunnel:

```bash
ssh -D 8157 -q -C -N centos@<IP address of FreeIPA server instance>
```

Use a SOCKS5 proxy switcher in your browser (an example is the SwitchyOmega browser extension).

In the SOCKS5 proxy configuration, set _Protocol_ to `SOCKS5`, _Server_ to `localhost`, and _Port_ to `8157`. Ensure the SOCKS5 proxy is active when clicking on the CDP UI that you wish to access.

> [!CAUTION]
> You will get a SSL warning for the self-signed certificate; this is expected given this particular definition as the local FreeIPA server has no upstream certificates. However, you can install this CA certificate to remove this notification.

In addition, you can log into the jump host via SSH and get to any of the servers within the cluster. Remember to forward your SSH key!

```bash
ssh -A -C -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null centos@<IP address of FreeIPA server instance>
```

## Teardown

Run the following: 

```bash
ansible-navigator run pre_teardown.yml \
    -e @config.yml \
    -e @definition.yml
```

You can also run `terraform destroy` within the `tf_deployment` directory.

## Execution Environment

If you need to construct a local Execution Environment image, first set up a Python virtual environment with the latest `ansible-core` and `ansible-builder`:

```bash
python -m venv ~/location/of/venv; source ~/location/of/venv/bin/activate; pip install ansible-builder
```

> [!NOTE]
> If you have already set up `ansible-navigator`, then you have `ansible-builder`!

Then run:

```bash
ansible-builder build --prune-images --no-cache --squash all --tag <your image> 
```

You may want to update the `execution-environment.yml` configuration file to use this image. You can make this change in the following section of the configuration file:

```yaml
images:
  base_image:
    name: <your image>
```

The resulting image defined by the `--tag` parameter will now be loaded into your local image cache.

## Docker Registry

If you need to publish the images to the [internal Docker registry](https://cloudera.atlassian.net/wiki/spaces/ENG/pages/170557921/Image+Registries+promotion+process+and+Image+categories#Repositories), first tag the image appropriately, if needed, and then push.

```bash
docker login docker-sandbox.infra.cloudera.com
<Enter AD username and password>
docker tag <your image> docker-sandbox.infra.cloudera.com/goes/pvc-ecs-freeipa-sidecar:<image tag>
docker push docker-sandbox.infra.cloudera.com/goes/pvc-ecs-freeipa-sidecar:<image tag>
```

You can then reference this image via the tag pushed into the Docker registry.

## Troubleshooting

### Confirm SSH Connectivity

Run the following command:

```bash
ansible-navigator exec -- ansible -m ansible.builtin.ping -i inventory.yml all
```

This will check to see if the inventory file is well constructed, etc.
