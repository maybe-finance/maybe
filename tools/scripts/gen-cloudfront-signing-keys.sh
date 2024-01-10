#!/usr/bin/env bash

# Script for documentation purposes
# Further instructions here:
# https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/private-content-trusted-signers.html#private-content-creating-cloudfront-key-pairs

# REMOVE FROM SOURCE CONTROL!
# Store in secrets manager
openssl genrsa -out private_key.pem 2048

# Store in param store 
openssl rsa -pubout -in private_key.pem -out public_key.pem