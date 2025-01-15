#!/bin/bash

function printhelp() {
        echo "Usage: $0 -d DOMAIN -u USERNAME"
}

if [ $# -eq 0 ]; then
        printhelp
        exit 1
fi

while getopts "hd:u:" option; do
  case $option in
    d) # domain
      domain="$OPTARG"
      ;;
  case $option in
    u) # domain
      username="$OPTARG"
      ;;
    h) # help
     printhelp
      ;;
    \?) # invalid option
      printhelp
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [ -z $domain ]; then
        echo "domain required"
        printhelp
        exit 1
fi

timestamp=`date +"%Y%m%d-%H%M%S"`
format=xml

echo "Collecting realm info..."
realminfo=$(curl -s "https://login.microsoftonline.com/getuserrealm.srf?login=$domain&$format=1")
touch az-recon-$domain-$timestamp.txt
echo $realminfo >> az-recon-$domain-$timestamp.txt
echo "Parsed realm info:" >> az-recon-$domain-$timestamp.txt
domainname=$(echo $realminfo | grep -oE '<DomainName>(.*)<\/DomainName>' | cut -d "><" -f 3)
echo "DomainName = $domainname"
echo "DomainName=$domainname" >> az-recon-$domain-$timestamp.txt
namespacetype=$(echo $realminfo | grep -oE '<NameSpaceType>(.*)<\/NameSpaceType>' | cut -d "><" -f 3)
echo "NameSpaceType = $namespacetype"
echo "NameSpaceType=$namespacetype" >> az-recon-$domain-$timestamp.txt
fedbrandname=$(echo $realminfo | grep -oE '<FederationBrandName>(.*)<\/FederationBrandName>' | cut -d "><" -f 3)
echo "FedBrandName = $fedbrandname"
echo "FedBrandName=$fedbrandname" >> az-recon-$domain-$timestamp.txt
if [ $namespacetype == "Federated" ]; then
        authurl=$(echo $realminfo | grep -oE '<AuthURL>(.*)<\/AuthURL>' | cut -d "><" -f 3)
        echo "AuthURL = $authurl"
        echo "AuthURL=$authurl" >> az-recon-$domain-$timestamp.txt
        stsauthurl=$(echo $realminfo | grep -oE '<STSAuthURL>(.*)<\/STSAuthURL>' | cut -d "><" -f 3)
        echo "STSAuthURL = $stsauthurl"
        echo "STSAuthURL=$stsauthurl" >> az-recon-$domain-$timestamp.txt
fi

echo "Collecting tenant info..."
tenantid=$(curl -s https://login.microsoftonline.com/$domain/v2.0/.well-known/openid-configuration | cut -d "\"" -f 4 | cut -d "/" -f 4)
echo "TenantID = $tenantid"
echo "TenantId=$tenantid" >> az-recon-$domain-$timestamp.txt

if [ -z $username ]; then
        echo "Username provided, checking $user@$domain"
        usercheck=$(curl -s -X POST "https://login.microsoftonline.com/common/GetCredentialType" --data "{\"Username\":\"$user@$domain\"}")
fi

echo "Done."
