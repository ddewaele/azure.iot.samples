#!/usr/bin/env bash

source config.sh

mkdir -p $OUTPUTFOLDER

echo " -- Generate the root CA (this will get uploaded to DSP as a certificate)"
openssl genrsa -out $OUTPUTFOLDER/$ROOTCA_CERT_NAME.key 2048
openssl req -x509 -new -nodes -key $OUTPUTFOLDER/$ROOTCA_CERT_NAME.key -sha256 -days 365 -subj "$ROOTCA_CERT_SUBJECT" -out $OUTPUTFOLDER/$ROOTCA_CERT_NAME.pem

echo " -- Generate an intermediary CA (signed by our root ca, this will be uploded to DPS when creating an enrollment)"
openssl genrsa -out $OUTPUTFOLDER/$INTERMEDIATE_CERT_NAME.key 2048
openssl req -new -key $OUTPUTFOLDER/$INTERMEDIATE_CERT_NAME.key -subj "$INTERMEDIA_CERT_SUBJECT" -out $OUTPUTFOLDER/$INTERMEDIATE_CERT_NAME.csr
openssl x509 -req -in $OUTPUTFOLDER/$INTERMEDIATE_CERT_NAME.csr -extfile v3_intermediate_ca.ext -CA $OUTPUTFOLDER/$ROOTCA_CERT_NAME.pem -CAkey $OUTPUTFOLDER/$ROOTCA_CERT_NAME.key -CAcreateserial -out $OUTPUTFOLDER/$INTERMEDIATE_CERT_NAME.crt -days 365 -sha256
openssl x509 -in $OUTPUTFOLDER/$INTERMEDIATE_CERT_NAME.crt -out $OUTPUTFOLDER/$INTERMEDIATE_CERT_NAME.pem -outform PEM

echo " -- Upload the root CA cert to DSP"
az iot dps certificate create --certificate-name ${ROOTCA_CERT_NAME} --dps-name $DPS_NAME --resource-group $RESOURCE_GROUP --path=$OUTPUTFOLDER/$ROOTCA_CERT_NAME.pem

echo " -- Generate and capture the verification code. Needed for the Proof-of-ownership flow"
ETAG=$(az iot dps certificate show --name ${ROOTCA_CERT_NAME} --dps-name $DPS_NAME --resource-group $RESOURCE_GROUP | jq --raw-output .etag)
VERIFICATION_CODE=$(az iot dps certificate generate-verification-code --certificate-name ${ROOTCA_CERT_NAME} --etag $ETAG --dps-name $DPS_NAME --resource-group $RESOURCE_GROUP | jq --raw-output .properties.verificationCode)
echo " -- found verification : $VERIFICATION_CODE"

echo " -- Proof-of-ownership flow via verification cert for the cloud (signed by our root ca)"
openssl genrsa -out $OUTPUTFOLDER/$VERIFICATION_CERT_NAME.key 2048
openssl req -new -key $OUTPUTFOLDER/$VERIFICATION_CERT_NAME.key -subj "/CN=${VERIFICATION_CODE}" -out $OUTPUTFOLDER/$VERIFICATION_CERT_NAME.csr
openssl x509 -req -in $OUTPUTFOLDER/$VERIFICATION_CERT_NAME.csr -CA $OUTPUTFOLDER/$ROOTCA_CERT_NAME.pem -CAkey $OUTPUTFOLDER/$ROOTCA_CERT_NAME.key -CAcreateserial -out $OUTPUTFOLDER/$VERIFICATION_CERT_NAME.crt -days 365 -sha256
openssl x509 -in $OUTPUTFOLDER/$VERIFICATION_CERT_NAME.crt -out $OUTPUTFOLDER/$VERIFICATION_CERT_NAME.pem -outform PEM

echo " -- Verify the root CA cert in DSP. Fetch the etag of the root ca and verify it with the verification cert."
ETAG=$(az iot dps certificate show --name ${ROOTCA_CERT_NAME} --dps-name $DPS_NAME --resource-group $RESOURCE_GROUP | jq --raw-output .etag)
az iot dps certificate verify --name ${ROOTCA_CERT_NAME} --dps-name $DPS_NAME --resource-group $RESOURCE_GROUP  --path $OUTPUTFOLDER/${VERIFICATION_CERT_NAME}.pem --etag $ETAG

echo " -- Create a device cert signed by intermediate ca"
DEVICENAME=device1

openssl genrsa -out $OUTPUTFOLDER/${DEVICENAME}.key 2048
openssl req -new -key $OUTPUTFOLDER/${DEVICENAME}.key -subj "/C=BE/ST=Mechelen/L=Mechelen/O=IxorTalk/OU=PassThrough/CN=${DEVICENAME}" -out $OUTPUTFOLDER/${DEVICENAME}.csr
openssl x509 -req -in $OUTPUTFOLDER/${DEVICENAME}.csr -CA $OUTPUTFOLDER/$INTERMEDIATE_CERT_NAME.pem -CAkey $OUTPUTFOLDER/$INTERMEDIATE_CERT_NAME.key -CAcreateserial -out $OUTPUTFOLDER/${DEVICENAME}.crt -days 365 -sha256
openssl x509 -in $OUTPUTFOLDER/$DEVICENAME.crt -out $OUTPUTFOLDER/$DEVICENAME.pem -outform PEM
cat $OUTPUTFOLDER/$DEVICENAME.pem $OUTPUTFOLDER/$INTERMEDIATE_CERT_NAME.pem $OUTPUTFOLDER/$ROOTCA_CERT_NAME.pem > $OUTPUTFOLDER/$DEVICENAME-chain.pem

echo " -- Create enrollments"
ENROLLMENT_GROUP_NAME=devicegroup1
az iot dps enrollment-group create --dps-name $DPS_NAME --resource-group $RESOURCE_GROUP --enrollment-id ${ENROLLMENT_GROUP_NAME} --provisioning-status enabled --certificate-path $OUTPUTFOLDER/$INTERMEDIATE_CERT_NAME.pem


