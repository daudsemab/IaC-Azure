#!/bin/bash

RESOURCE_GROUP_NAME=1-96ecf2f8-playground-sandbox
STORAGE_ACCOUNT_NAME=tfstatebackendstorage25
CONTAINER_NAME=tfstate-container

#Login
az login

# Create storage account
az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

# Create blob container
az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME