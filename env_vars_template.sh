##########
#**Global settings to change**
export CDP_LICENSE_FILE="<LOCATION_OF_PVC_LICENSE_FILE>"

export SSH_PUBLIC_KEY_FILE="<LOCATION_OF_PUBLIC_SSH_KEY_FILE>"
export SSH_PRIVATE_KEY_FILE="<LOCATION_OF_PRIVATE_SSH_KEY_FILE>"
# Openstack username, password and tenant
export OS_USERNAME="<username>@cloudera.com"
export OS_PASSWORD="<password>"
export OS_PROJECT_NAME="se"
##########
#**Static settings for P9 Openstack **
export OS_AUTH_URL=https://cloudera-iopscloud.platform9.net/keystone/v3
export OS_IDENTITY_API_VERSION=3
export OS_REGION_NAME="iopscloud"
export OS_PROJECT_DOMAIN_ID=${OS_PROJECT_DOMAIN_ID:-"default"}
export OS_USER_DOMAIN_ID=${OS_USER_DOMAIN_ID:-"default"}

#**Sidecar FreeIPA settings
export IPA_USER="admin"

export ANSIBLE_HOST_KEY_CHECKING="False"
# Required for MacOS
export OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES