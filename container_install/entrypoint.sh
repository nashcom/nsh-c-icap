#!/bin/bash

############################################################################
# Copyright Nash!Com, Daniel Nashed 2024 - APACHE 2.0 see LICENSE
############################################################################

# This script is the main entry point for the c-icap container.
# The entry point is invoked by the container run-time to start c-icap.

# Helper functions

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


log_debug()
{
  if [ -z "$DEBUG" ]; then
    return 0
  fi

  echo "DEBUG - $@"
}


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


dump_file()
{

  if [ -z "$2"]; then
    return 0
  fi

  header "$1"

  if [ -e "$2" ]; then
    cat "$2"
    print_delim
  else
    echo "No file: $2"
  fi

  echo
}


remove_file()
{
  if [ -z "$1" ]; then
    return 1
  fi

  if [ ! -e "$1" ]; then
    return 2
  fi

  rm -f "$1" >/dev/null 2>/dev/null

  if [ -e "$1" ]; then
    echo "Info: File not deleted [$1]"
  fi

  return 0
}


create_local_ca_cert()
{
  log_space "Creating new certificate for $HOSTNAME"

  # Create CA key and cert if not present

  if [ ! -e "$CA_KEY" ]; then
    openssl ecparam -name prime256v1 -genkey -noout -out $CA_KEY
  fi

  if [ ! -e "$CA_CERT" ]; then
    openssl req -new -x509 -days 3650 -key $CA_KEY -out $CA_CERT -subj "/O=$ORG_NAME/CN=$CA_NAME"
  fi

  # Create server key
  if [ ! -e "$SERVER_KEY" ]; then
    openssl ecparam -name prime256v1 -genkey -noout -out $SERVER_KEY
  fi

  # Create server cert
  openssl req -new -key $SERVER_KEY -out $SERVER_CSR -subj "/O=$ORG_NAME/CN=$HOSTNAME" -addext "subjectAltName = DNS:$HOSTNAME" -addext extendedKeyUsage="serverAuth,clientAuth"

  # OpenSSL 3.0 supports new flags to simplify operations. Create a certificate for 1 year
  openssl x509 -req -days 365 -in $SERVER_CSR -CA $CA_CERT -CAkey $CA_KEY -out $SERVER_CERT -CAcreateserial -CAserial $CA_SEQ -copy_extensions copy # Copying extensions can be dangerous! Requests should be checked

  # Add the CA root
  cat "$CA_CERT" >> "$SERVER_CERT"

  remove_file "$SERVER_CSR"
}


show_cert()
{
  if [ -z "$1" ]; then
    return 0
  fi

  if [ ! -e "$1" ]; then
    return 0
  fi

  local SAN=$(openssl x509 -in "$1" -noout -ext subjectAltName | grep "DNS:" | xargs )
  local SUBJECT=$(openssl x509 -in "$1" -noout -subject | cut -d '=' -f 2- )
  local ISSUER=$(openssl x509 -in "$1" -noout -issuer | cut -d '=' -f 2- )
  local EXPIRATION=$(openssl x509 -in "$1" -noout -enddate | cut -d '=' -f 2- )
  local FINGERPRINT=$(openssl x509 -in "$1" -noout -fingerprint | cut -d '=' -f 2- )
  local SERIAL=$(openssl x509 -in "$1" -noout -serial | cut -d '=' -f 2- )

  echo
  echo "SAN         : $SAN"
  echo "Subject     : $SUBJECT"
  echo "Issuer      : $ISSUER"
  echo "Expiration  : $EXPIRATION"
  echo "Fingerprint : $FINGERPRINT"
  echo "Serial      : $SERIAL"
  echo
}


# Configuration

if [ -z "$ORG_NAME" ]; then
  ORG_NAME=c-icap-server
fi

if [ -z "$CA_NAME" ]; then
  CA_NAME=c-icap-ca
fi

CERT_DIR=/certs
IMPORT_KEY=$CERT_DIR/key.pem
IMPORT_CERT=$CERT_DIR/cert.pem

CA_KEY=$CERT_DIR/ca_key.pem
CA_CERT=$CERT_DIR/ca_cert.pem
CA_SEQ=$CERT_DIR/ca.seq

SERVER_KEY=$CERT_DIR/server_key.pem
SERVER_CERT=$CERT_DIR/server_cert.pem
SERVER_CSR=$CERT_DIR/csr.pem

CICAP_CFG=/c-icap.conf


if [ -z "$CICAP_LOG_LEVEL" ]; then
  CICAP_LOG_LEVEL=3
fi


# Set more paranoid umask to ensure files can be only read by user
umask 0077

# Dump environment
set > /var/log/c-icap/env.log


HOSTNAME=$(hostname -f)

if [ -e "$IMPORT_KEY" ] && [ -e "$IMPORT_CERT" ]; then
  SERVER_KEY="$IMPORT_KEY"
  SERVER_CERT="$IMPORT_CERT"

else
  create_local_ca_cert
fi


LINUX_PRETTY_NAME=$(cat /etc/os-release | grep "PRETTY_NAME="| cut -d= -f2 | xargs)


if [ "$LOG_LEVEL" -ge "2" ]; then
  dump_file "CA Root Certificate" /certs/ca_cert.pem
  dump_file "Server Certificate" /certs/server_cert.pem
fi


if [ "$LOG_LEVEL" -ge "2" ]; then
  echo
  echo Environment
  print_delim
  set
  print_delim
  echo
  echo Configuration
  print_delim
  cat -n "$CICAP_CFG"
  print_delim
  echo
fi


if [ "$LOG_LEVEL" -ge "2" ]; then
  echo
  echo c-icap Details
  print_delim
  c-icap -VV
  print_delim
  echo
fi


echo
echo $LINUX_PRETTY_NAME
print_delim
echo
echo c-icap Server $(c-icap -V)
print_delim

echo
echo Certificate
print_delim
show_cert "$SERVER_CERT"
print_delim
echo
echo

c-icap -f "$CICAP_CFG" -N -D -d "$CICAP_LOG_LEVEL"

exit 0
