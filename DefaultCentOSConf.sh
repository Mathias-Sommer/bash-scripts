#!/bin/sh

green='\033[0;32m'
red='\033[0;31m'
cWhite='\033[01;37m'
clear='\033[0m'
username=pingu
password=Passw0rd

clear

#Tjekker efter opdateringer og opdatere bagefter
dnf check-update && dnf upgrade -y

sleep 2

#Ændre hostname til full qualified domain name FQDN
hostnamectl hostname storage.sommer.local
set +x
#Tilføjer brugeren pingu
useradd pingu

#Sæt kode til brugeren
sudo echo -e "$password\n$password" | sudo passwd $username

#Giv sudo / wheel gruppen
usermod -aG wheel $username

clear
echo "###################"
echo "User created!"
echo ""
printf "${green}Username:${clear} ${cWhite}$username ${clear}\n" 
printf "${green}Password:${clear} ${cWhite}$password${clear}\n"
printf "${cWhite}$username${clear} granted ${red}sudo${clear} permissions!\n"
printf "${white}${username}${clear} allowed ${green}SSH${clear} authentication!\n"
echo "###################"
echo ""
echo ""
echo ""

#Skift SELinux til permissive
sed -i 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

#Disable root til at logge på via ssh
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/g' /etc/ssh/sshd_config

#Tilføj pingu til ssh authentication
sed -i 's/# Authentication:/# Authentication:\nAllowUsers pingu/g' /etc/ssh/sshd_config

#Tilføj lan-netkort til zonen internal
firewall-cmd --zone=internal --add-interface=enp1s0 --permanent

#Fjerner services MDNS, Samba-client og dhcpv6-client
firewall-cmd --zone=internal --remove-service=MDNS --permanent
firewall-cmd --zone=internal --remove-service=samba-client --permanent
firewall-cmd --zone=internal --remove-service=dhcpv6-client --permanent
firewall-cmd --reload

#øvelse 5.1 modificer scriptet - opret flere zoner
firewall-cmd --new-zone=secure --permanent
firewall-cmd --zone=secure --add-service=ssh --permanent

#tilføjer jumphost som source
firewall-cmd --zone=secure --add-source=192.168.100.50 --permanent

#fjern ssh fra internal zonen
firewall-cmd --zone=internal --remove-service=ssh --permanent

echo "Genstarter!"
sleep 3
reboot
