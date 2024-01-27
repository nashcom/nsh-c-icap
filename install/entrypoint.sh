#!/bin/bash

############################################################################
# Copyright Nash!Com, Daniel Nashed 2024 - APACHE 2.0 see LICENSE
############################################################################

# This script is the main entry point for the c-icap container.
# The entry point is invoked by the container run-time to start c-icap.

# Set more paranoid umask to ensure files can be only read by user
umask 0077

# Create log directory with owner nginx
mkdir /tmp/c-icap

# Dump environment
set > /tmp/c-icap/env.log

if [ -e /cert.pem ] && [ -e /key.pem ]; then

  if [ -z "$TLS_PORT" ]; then
    TLS_PORT=11344
  fi

  echo "TlsPort $TLS_PORT cert=/cert.pem key=/key.pem" >> /c-icap.conf

  echo "TLS enabled on port $TLS_PORT"
fi


LINUX_PRETTY_NAME=$(cat /etc/os-release | grep "PRETTY_NAME="| cut -d= -f2 | xargs)

if [ "$CICAP_LOG_LEVEL" = "debug" ]; then
  echo
  echo Environment
  echo ------------------------------------------------------------
  set
  echo ------------------------------------------------------------
  echo
  echo Configuration
  echo ------------------------------------------------------------
  cat -n /c-icap.conf 
  echo ------------------------------------------------------------
  echo
fi

echo
echo $LINUX_PRETTY_NAME
echo ------------------------------------------------------------
echo
echo c-icap Server $(c-icap -V)
echo ------------------------------------------------------------

if [ "$CICAP_LOG_LEVEL" = "debug" ]; then
  c-icap -VV
  echo ------------------------------------------------------------
fi

echo

c-icap -f /c-icap.conf -N -D -d 3

exit 0

