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


header "Install required packages"
yum install -y gcc procps-ng diffutils make git g++ redhat-rpm-config openssl openssl-devel c-icap-devel


header "Clone squidclamav GitHub project"

mkdir -p /local/github
cd /local/github

git clone https://github.com/darold/squidclamav.git


header "Configure squidclamav build"

cd squidclamav
./configure

sed -i 's/HTTP\/1.0/HTTP\/1.1/g' src/squidclamav.c


header "Compile squidclamav"

make


header "Copy image -> /squidclamav.so"

cp src/.libs/squidclamav.so /
