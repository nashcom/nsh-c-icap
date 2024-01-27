#!/bin/bash
############################################################################
# Copyright Nash!Com, Daniel Nashed 2024 - APACHE 2.0 see LICENSE
############################################################################


# --- Begin Helper functions ---

print_delim()
{
  echo "--------------------------------------------------------------------------------"
}

header()
{
  echo
  print_delim
  echo "$1"
  print_delim
  echo
}

# --- End Helper functions ---


header "Updating Linux via yum"
#/usr/bin/yum update -y


header "Install epel-release"
yum install -y epel-release


header "Install packages"
yum install -y procps-ng hostname gettext bind-utils findutils


header "Create c-icap user&group"

groupadd c-icap --gid 1000
useradd c-icap -m --gid 1000 --uid 1000


header "Install c-icap"
yum install -y c-icap


header "Configuration"

mkdir -p /var/log/c-icap
mkdir -p /run/c-icap 

mv /squidclamav.conf /etc/c-icap/squidclamav.conf

chown -R c-icap:c-icap /var/log/c-icap
chown -R c-icap:c-icap /run/c-icap 
chown  c-icap:c-icap /c-icap.conf

header "Cleanup"

/usr/bin/yum clean all >/dev/null
rm -fr /var/cache/yum
