#!/usr/bin/env bash

source config.sh

ETAG=$(az iot dps certificate show --name ${ROOTCA_CERT_NAME} --dps-name $DPS_NAME --resource-group $RESOURCE_GROUP | jq --raw-output .etag)
az iot dps certificate delete --certificate-name ${ROOTCA_CERT_NAME} --dps-name $DPS_NAME --resource-group $RESOURCE_GROUP --etag $ETAG
az iot dps enrollment-group delete --dps-name $DPS_NAME --resource-group $RESOURCE_GROUP --enrollment-id ${ENROLLMENT_GROUP_NAME}
