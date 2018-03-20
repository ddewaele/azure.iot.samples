#!/usr/bin/env bash

OUTPUTFOLDER=./certs/

RESOURCE_GROUP=rg-iothub
LOCATION=westeurope
IOTHUB_NAME=ixortalkiothub
DPS_NAME=ixortalkdps

ROOTCA_CERT_NAME=root-cacert2
INTERMEDIATE_CERT_NAME=intermediate-cacert2
VERIFICATION_CERT_NAME=verification-cert2

ROOTCA_CERT_SUBJECT="/C=BE/ST=Mechelen/L=Mechelen/O=IxorTalk/OU=Platform/CN=ROOT CA2"
INTERMEDIA_CERT_SUBJECT="/C=BE/ST=Mechelen/L=Mechelen/O=IxorTalk/OU=Platform/CN=INTERMEDIATE CA2"

ENROLLMENT_GROUP_NAME=devicegroup1
DEVICENAME=device1
