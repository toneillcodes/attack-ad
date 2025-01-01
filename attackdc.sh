#!/bin/bash

export timestamp=`date +"%Y%m%d-%H%M%S"`

target=10.0.2.15

user="fcastle"
password="Password1"
domain=""

echo "[+] Executing attack script against target: $target @ $timestamp"

echo "[*] Collecting open ports (port-list.txt)"
# find open ports, store in port-list.txt
ports=$(nmap -p- --min-rate=1000 -T4 $target | grep ^[0-9] | cut -f1 -d '/' | tr '\n' ',' | sed s/,$//)
echo $ports > port-list.txt

echo "[*] Running NMAP Script and Version scans (port-recon.txt)"
# collect additional info about open ports, store in port-recon.txt
nmap -sC -sV -p$ports $target -oN port-recon.txt

echo "[*] Parsing port results and executing modules..."

# LDAP
if grep -q ",389," port-list.txt ; then
        echo "[*] Running LDAP module."		
		# Run ldapsearch
		## check domain details
		## check container details OU and DC info?
		ldapsearch -H ldap://$target -x -s base -b '' "(objectClass=*)" "*" > ldap-info.txt 
		echo -n "LDAP DNS Hostname:" >> ldap-recon.txt
		ldap_dns_hostname=$(grep dnsHostName ldap-info.txt | awk '{print $2}')
		echo $ldap_dns_hostname	>> ldap-recon.txt
		echo -n "LDAP Root Domain Naming Context:" >> ldap-recon.txt
		base_dn=$(grep rootDomainNamingContext ldap-info.txt | awk '{print $2}')
		echo $base_dn >> ldap-recon.txt
        if [ ! -z $user ] && [ ! -z $password ]; then
				## lockoutThreshold
				if [ ! -z $domain ]; then
					#ldapsearch -H <ldap_server> -D <bind_dn> -w <bind_password> -b "dc=example,dc=com" "(&(objectClass=user)(sAMAccountName=<username>)(lockoutTime>=0))"
					#(&(objectClass=user)(sAMAccountName=username)(badPwdCount>5))
					ldapsearch -D '$domain\$user' -w '$password' -h ldap://$target -b "$base_dn" -s sub "*" | grep lockoutThreshold
				fi
				# TODO: Run windapsearch -o windapsearch-recon.txt
				# Run NetExec
                echo "[*] Running nxc LDAP enum with credentials $user:****** (nxc-recon.txt)"
                # clear the file and output the scan timestamp
				echo "Scan timestamp: $timestamp" > nxc-recon.txt
				echo -n "NXC Domain SID:" >> nxc-recon.txt
				nxc ldap $target -u $user -p $password --get-sid >> nxc-recon.txt
				echo "NXC Users:" >> nxc-recon.txt
				nxc ldap $target -u $user -p $password --users >> nxc-recon.txt
				echo "NXC Groups:" >> nxc-recon.txt
				nxc ldap $target -u $user -p $password --groups >> nxc-recon.txt
				echo "NXC Password Not Required:" >> nxc-recon.txt
				nxc ldap $target -u $user -p $password--password-not-required >> nxc-recon.txt
				echo "NXC Domain Admins:" >> nxc-recon.txt
				nxc ldap $target -u $user -p $password -M group-mem -o GROUP="Domain Admins" >> nxc-recon.txt
				echo "NXC DnsAdmins:" >> nxc-recon.txt
				nxc ldap $target -u $user -p $password -M group-mem -o GROUP="DnsAdmins" >> nxc-recon.txt
        else
                #Run ldapsearch, Run windapsearch, Run NetExec	
                echo "Running unauthenticated LDAP enum"
        fi
        echo "[*] LDAP module complete."
fi

echo "[-] Done."
