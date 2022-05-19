## DEFINE YOUR VARIABLES
DOMAIN_NAME="INSERT_YOUR_DOMAIN_HERE" ## dev.acme.com ## The hosted zone you want to create
REQUEST_DOMAIN_NAME="YOUR_ACM_CERTIFICATE_DOMAIN" ## aws.dev.acme.com # the domain you want a cert for

## Create a public Hosted Zone in Route53
## CALL_REF is a unique epoch to identify the call to aws cli
CALL_REF=$(date +%s)
aws route53 create-hosted-zone --name $DOMAIN_NAME --caller-reference $CALL_REF

## Request for a certificate within the new hosted zone
## https://docs.aws.amazon.com/cli/latest/reference/acm/request-certificate.html
CERT_ARN=$(aws acm request-certificate --domain-name $REQUEST_DOMAIN_NAME --validation-method DNS | awk -F '""' '{ print $4 }')

## Gather DNS Record Details from certificate request to validate ownership
DOMAIN_NAME=$(aws acm describe-certificate --certificate-arn $CERT_ARN | grep ResourceRecord -A3 | grep Name | awk -F '"' '{ print $4 }')
DOMAIN_VALUE=$(aws acm describe-certificate --certificate-arn $CERT_ARN | grep ResourceRecord -A3 | grep Value | awk -F '"' '{ print $4 }')

## GET HOSTEDZONE ID
HOSTED_ZONE=$(aws route53 list-hosted-zones-by-name | grep -n1 $DOMAIN_NAME | grep hostedzone | awk -F '"' '{ print $4 }' | awk -F '/' '{print $3}')

## Replace batch reource template with actual values
cp ./batch-resource-template.json ./batch-resource.json
sed -i ".bak" "s/%DOMAIN_NAME/$DOMAIN_NAME/g" "batch-resource.json"
sed -i ".bak" "s/%DOMAIN_VALUE/$DOMAIN_VALUE/g" "batch-resource.json"

## Add DNS Entry to domain for certificate validation
aws route53 change-resource-record-sets --hosted-zone-id $HOSTED_ZONE --change-batch file://./batch-resource.json

## Clean Up
rm batch-resource.json
rm batch-resource.json.bak
