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


header "Install required packages"
microdnf -y install git g++ make openssl openssl-devel autoconf diffutils libtool libatomic

mkdir -p /local/github

header "Clone c-icap project"

cd /local/github

git clone https://github.com/c-icap/c-icap-server.git


header "Configure c-icap build"

cd c-icap-server
git checkout "C_ICAP_$C_ICAP_VERSION"

chmod +x RECONF
./RECONF

automake
./configure


header "Compile c-icap"

make

cp .libs/libicapapi.so /
cp .libs/c-icap /
cp services/echo/.libs/srv_echo.so /
cp utils/.libs/c-icap-client /


if [ ! -e  "/libicapapi.so" ]; then
  log_error "Cannot find libicapapi.so"
  exit 1
fi

if [ ! -e "/c-icap" ]; then
  log_error "Cannot find c-icap"
  exit 1
fi

if [ ! -e "/c-icap-client" ]; then
  log_error "Cannot find icap-client"
  exit 1
fi

if [ ! -e "/srv_echo.so" ]; then
  log_error "Cannot find srv_echo.so"
  exit 1
fi


header "Install c-icap"

make install


header "Clone squidclamav GitHub project"

cd /local/github

git clone https://github.com/darold/squidclamav.git


header "Configure squidclamav build"

cd squidclamav
git checkout "v$SQUIDCLAM_VERSION"

./configure

sed -i 's/HTTP\/1.0/HTTP\/1.1/g' src/squidclamav.c


header "Compile squidclamav"

make

cp src/.libs/squidclamav.so /

if [ ! -e "/squidclamav.so" ]; then
  log_error "Cannot find /squidclamav.so"
  exit 1
fi

