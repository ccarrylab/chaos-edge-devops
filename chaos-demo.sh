#!/bin/bash
cd terraform && terraform init && terraform apply -auto-approve
CF=$(terraform output -raw cloudfront_domain)
echo "✅ https://$CF/chaos/latency"
