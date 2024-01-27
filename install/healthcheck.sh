#!/bin/bash

# Health check script to test if ICAP responds to the OPTIONS command for ClamAV


ICAP_STATUS=$(c-icap-client -s clamav 2>&1 | grep "ICAP/1.0 200 OK" | xargs)

echo "ICAP_STATUS: [$ICAP_STATUS]"

if [ -z "$ICAP_STATUS" ]; then
  exit 1
else
  exit 0
fi
