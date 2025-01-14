#!/bin/bash

function printhelp() {
        echo "Usage: $0 -d DOMAIN"
}

if [ $# -eq 0 ]; then
        printhelp
        exit 1
fi

while getopts "hd:" option; do
  case $option in
    d) # domain
      domain="$OPTARG"
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

format=xml

echo "Collecting realm info..."
realminfo=$(curl -s "https://login.microsoftonline.com/getuserrealm.srf?login=$domain&$format=1")
#echo "RealmInfo = $realminfo"
domainname=$(echo $realminfo | grep -oE '<DomainName>(.*)<\/DomainName>' | cut -d "><" -f 3)
echo "Domain Name = $domainname"
namespacetype=$(echo $realminfo | grep -oE '<NameSpaceType>(.*)<\/NameSpaceType>' | cut -d "><" -f 3)
echo "NameSpaceType = $namespacetype"
fedbrandname=$(echo $realminfo | grep -oE '<FederationBrandName>(.*)<\/FederationBrandName>' | cut -d "><" -f 3)
echo "Fed Brand Name = $fedbrandname"
if [ $namespacetype == "Federated" ]; then
        authurl=$(echo $realminfo | grep -oE '<AuthURL>(.*)<\/AuthURL>' | cut -d "><" -f 3)
        echo "Auth URL = $authurl"
        stsauthurl=$(echo $realminfo | grep -oE '<STSAuthURL>(.*)<\/STSAuthURL>' | cut -d "><" -f 3)
        echo "STS Auth URL = $stsauthurl"
fi

echo "Done."
