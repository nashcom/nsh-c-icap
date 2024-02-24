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

remove_package()
{
  if [ -x /usr/bin/zypper ]; then
    /usr/bin/zypper rm -y "$@"

  elif [ -x /usr/bin/dnf ]; then
    /usr/bin/dnf remove -y "$@"

  elif [ -x /usr/bin/tdnf ]; then
    /usr/bin/tdnf remove -y "$@"

  elif [ -x /usr/bin/microdnf ]; then
    /usr/bin/microdnf remove -y "$@"

  elif [ -x /usr/bin/yum ]; then
    /usr/bin/yum remove -y "$@"

  elif [ -x /usr/bin/apt-get ]; then
    /usr/bin/apt-get remove -y "$@"

  elif [ -x /usr/bin/pacman ]; then
    /usr/bin/pacman --noconfirm -R "$@"

  elif [ -x /sbin/apk ]; then
      /sbin/apk del "$@"
  fi
}

remove_packages()
{
  local PACKAGE=
  for PACKAGE in $*; do
    remove_package $PACKAGE
  done
}

clean_linux_repo_cache()
{
  if [ -x /usr/bin/zypper ]; then

    header "Cleaning zypper cache"
    /usr/bin/zypper clean --all >/dev/null
    rm -fr /var/cache

  elif [ -x /usr/bin/dnf ]; then

    header "Cleaning dnf cache"
    /usr/bin/dnf clean all >/dev/null

  elif [ -x /usr/bin/tdnf ]; then

    header "Cleaning tdnf cache"
    /usr/bin/tdnf clean all >/dev/null

  elif [ -x /usr/bin/microdnf ]; then

    header "Cleaning microdnf cache"
    /usr/bin/microdnf clean all >/dev/null

  elif [ -x /usr/bin/yum ]; then

    header "Cleaning yum cache"
    /usr/bin/yum clean all >/dev/null
    rm -fr /var/cache/yum

  elif [ -x /usr/bin/apt-get ]; then

    header "Cleaning apt cache"
    /usr/bin/apt-get clean

  elif [ -x /usr/bin/pacman ]; then
     header "Cleaning pacman cache"
     pacman --noconfirm -Sc

  elif [ -x /sbin/apk ]; then
     echo "No cleanup for Alpine"

  else
    log_error "Warning: No packet manager to clear repo cache!"
  fi
}


if [ "$LINUX_UPDATE" = "yes" ]; then
  check_linux_update
else
  log_space "Warning: Not updating Linux"
fi


header "Install packages"
install_packages procps-ng hostname gettext bind-utils findutils libatomic openssl shadow-utils


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

mkdir -p /usr/local/etc
cp /squidclamav.conf /usr/local/etc/squidclamav.conf
#cp /squidclamav.conf /etc/c-icap/squidclamav.conf
rm -f /squidclamav.conf

cp /c-icap.conf /etc/c-icap/c-icap.conf
rm -f /c-icap.conf

chown -R c-icap:c-icap /var/log/c-icap
chown -R c-icap:c-icap /run/c-icap
chown -R c-icap:c-icap /certs
chown -R c-icap:c-icap /etc/c-icap

header "Cleanup"

remove_package shadow-utils
clean_linux_repo_cache
