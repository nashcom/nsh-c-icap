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

log_space()
{
  echo
  echo "$@"
  echo
}


log_error()
{
  echo
  echo "ERROR - $@"
  echo
}


# --- End Helper functions ---


if [ -z "$C_ICAP_VERSION" ]; then
  log_error "c-icap version not defined"
  exit 1
fi

if [ -z "$SQUIDCLAM_VERSION" ]; then
  log_error "SquidClam version not defined"
  exit 1
fi


if [ "$LINUX_UPDATE" = "yes" ]; then
  header "Updating Linux"
  microdnf -y update
else
  log_space "Warning: Not updating Linux"
fi


header "Install packages"
microdnf install -y procps-ng hostname gettext bind-utils findutils libatomic openssl shadow-utils


header "Create c-icap user&group"

groupadd c-icap --gid 1000
useradd c-icap -m --gid 1000 --uid 1000


header "Configuration"

mkdir -p /var/log/c-icap
mkdir -p /run/c-icap 
mkdir -p /etc/c-icap
mkdir -p /certs
mkdir -p /usr/lib64/c_icap

if [ ! -e "/usr/lib64/libicapapi.so" ]; then
  log_error "Cannot find /usr/lib64/libicapapi.so"
  exit 1
fi

ln -s /usr/lib64/libicapapi.so /usr/lib64/libicapapi.so.0


#cp /squidclamav.conf /etc/c-icap/squidclamav.conf
cp /squidclamav.conf /usr/local/etc/squidclamav.conf

chown c-icap:c-icap /var/log/c-icap
chown c-icap:c-icap /run/c-icap
chown c-icap:c-icap /certs
chown c-icap:c-icap /etc/c-icap
chown c-icap:c-icap /c-icap.conf

header "Cleanup"

microdnf remove -y shadow-utils
usr/bin/microdnf clean all >/dev/null

