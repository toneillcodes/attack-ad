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
    u) # username
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
        echo "No username provided"
        echo "No username provided" >> az-recon-$domain-$timestamp.txt
else
        echo "Username provided, checking $username@$domain"
        echo "Username provided, checking $username@$domain" >> az-recon-$domain-$timestamp.txt
        usercheck=$(curl -s -X POST "https://login.microsoftonline.com/common/GetCredentialType" --data "{\"Username\":\"$username@$domain\"}")
        echo "GetCredentialType:" >> az-recon-$domain-$timestamp.txt
        echo $usercheck >> az-recon-$domain-$timestamp.txt
        ifuserexists=$(echo $usercheck | grep -oE "IfExistsResult\":[0-9]," | cut -d ":," -f 2)
        echo "IfUserExists=$ifuserexists"
        echo "IfUserExists=$ifuserexists" >> az-recon-$domain-$timestamp.txt
        # The following may not be accurate for federated domains
        # 1 - Does not exist in tenant
        # 0 - Exists in tenant, auth via Azure
        if [ $ifuserexists -eq 0 ]; then
                echo "User $username exists in $domain ($tenantid)"
                echo "User $username exists in $domain ($tenantid)" >> az-recon-$domain-$timestamp.txt
        elif [ $ifuserexists -eq 1 ]; then
                echo "User $username does NOT exist in $domain ($tenantid)"
                echo "User $username does NOT exist in $domain ($tenantid)" >> az-recon-$domain-$timestamp.txt
        else
                echo "Unmapped result: $ifuserexists; User $username might not exist in $domain ($tenantid)"
                echo "Unmapped result: $ifuserexists; User $username might not exist in $domain ($tenantid)" >> az-recon-$domain-$timestamp.txt
        fi
fi

echo "Done."
