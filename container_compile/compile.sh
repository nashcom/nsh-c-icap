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


install_package()
{
  if [ -x /usr/bin/zypper ]; then
    /usr/bin/zypper install -y "$@"

  elif [ -x /usr/bin/dnf ]; then
    /usr/bin/dnf install -y "$@"

  elif [ -x /usr/bin/tdnf ]; then
    /usr/bin/tdnf install -y "$@"

  elif [ -x /usr/bin/microdnf ]; then
    /usr/bin/microdnf install -y "$@"

  elif [ -x /usr/bin/yum ]; then
    /usr/bin/yum install -y "$@"

  elif [ -x /usr/bin/apt-get ]; then
    /usr/bin/apt-get install -y "$@"

  elif [ -x /usr/bin/pacman ]; then
    /usr/bin/pacman --noconfirm -Sy "$@"

  elif [ -x /sbin/apk ]; then
    /sbin/apk add "$@"

  else
    log_error "No package manager found!"
    exit 1
  fi
}


install_packages()
{
  local PACKAGE=
  for PACKAGE in $*; do
    install_package $PACKAGE
  done
}


check_linux_update()
{

  # On Ubuntu and Debian update the cache in any case to be able to install additional packages
  if [ -x /usr/bin/apt-get ]; then
    header "Refreshing packet list via apt-get"
    /usr/bin/apt-get update -y
  fi

  if [ -x /usr/bin/pacman ]; then
    header "Refreshing packet list via pacman"
    pacman --noconfirm -Sy
  fi

  # Install Linux updates if requested
  if [ ! "$LinuxYumUpdate" = "yes" ]; then
    return 0
  fi

  if [ -x /usr/bin/zypper ]; then

    header "Updating Linux via zypper"
    /usr/bin/zypper refresh
    /usr/bin/zypper update -y

  elif [ -x /usr/bin/dnf ]; then

    header "Updating Linux via dnf"
    /usr/bin/dnf update -y

  elif [ -x /usr/bin/tdnf ]; then

    header "Updating Linux via tdnf"
    /usr/bin/tdnf update -y

  elif [ -x /usr/bin/microdnf ]; then

    header "Updating Linux via microdnf"
    /usr/bin/microdnf update -y

  elif [ -x /usr/bin/yum ]; then

    header "Updating Linux via yum"
    /usr/bin/yum update -y

  elif [ -x /usr/bin/apt-get ]; then

    header "Updating Linux via apt"
    echo 'debconf debconf/frontend select Noninteractive' | debconf-set-selections

    /usr/bin/apt-get update -y

    # Needed by Astra Linux, Ubuntu and Debian. Should be installed before updating Linux but after updating the repo!
    if [ -x /usr/bin/apt-get ]; then
      install_package apt-utils
    fi

    /usr/bin/apt-get upgrade -y

  elif [ -x /usr/bin/pacman ]; then
    header "Updating Linux via pacman"
    pacman --noconfirm -Syu

  elif [ -x /sbin/apk ]; then
    header "Updating Linux via apk"
    /sbin/apk update

  else
    log_error "No packet manager to update Linux"
  fi
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
  check_linux_update
else
  log_space "Warning: Not updating Linux"
fi


header "Install required packages"
install_packages git g++ make openssl openssl-devel autoconf diffutils libtool libatomic automake


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


# Reaplace HTTP 1.0 with HTTP 1.1
sed -i 's/HTTP\/1.0/HTTP\/1.1/g' utils/c-icap-client.c
sed -i 's/HTTP\/1.0/HTTP\/1.1/g' icap_send_file.c
sed -i 's/HTTP\/1.0/HTTP\/1.1/g' info.c


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

# Reaplace HTTP 1.0 with HTTP 1.1
sed -i 's/HTTP\/1.0/HTTP\/1.1/g' src/squidclamav.c


header "Compile squidclamav"

make

cp src/.libs/squidclamav.so /

if [ ! -e "/squidclamav.so" ]; then
  log_error "Cannot find /squidclamav.so"
  exit 1
fi

