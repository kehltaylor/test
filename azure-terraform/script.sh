# terraform plan -var tenant_id="016ad98b-1345-4ac9-bba1-08456f0b06fc" -var subscription_id="c6f4a1c2-5a4d-4fb4-be37-9583ea4eefc1" -var client_id="a6879f88-707d-43e5-a096-c588ad7eb3a4" -var client_secret="/RDfHB]ARE95Vh?ZhLRmVFQK-bhkIC21"

TENANT_ID=${1}
SUB_ID=${2}
CLIENT_ID=${3}
CLIENT_SECRET=${4}
APP_GIT=${5}

terraform init .
terraform plan -var tenant_id=${TENANT_ID} -var subscription_id=${SUB_ID} -var client_id=${CLIENT_ID} -var client_secret=${CLIENT_SECRET} -var github_address_fonction_app=${APP_GIT}
terraform apply -var tenant_id=${TENANT_ID} -var subscription_id=${SUB_ID} -var client_id=${CLIENT_ID} -var client_secret=${CLIENT_SECRET} -var github_address_fonction_app=${APP_GIT}
