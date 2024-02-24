#!/bin/bash
############################################################################
# Copyright Nash!Com, Daniel Nashed 2024 - APACHE 2.0 see LICENSE
############################################################################

CONTAINER_IMAGE_VERSION=0.9.1
C_ICAP_VERSION=0.6.2
SQUIDCLAM_VERSION=7.3

CONTAINER_IMAGE=nashcom/c-icap
CONTAINER_FILE=dockerfile
BASE_IMAGE=registry.access.redhat.com/ubi9/ubi-minimal
#BASE_IMAGE=quay.io/centos/centos:stream9

CONTAINER_NAME="Nash!Com c-icap container"
CONTAINER_DESCRIPTION="Nash!Com c-icap container with ClamAV support"
CONTAINER_MAINTAINER="daniel.nashed@nashcom.de"
CONTAINER_VENDOR="Nash!Com"

CONTAINER_OPENSHIFT_EXPOSED_SERVICES="1344:icap 11344:icaps"
CONTAINER_ARCHITECTURE=$(uname -m)
CONTAINER_OPENSHIFT_MIN_MEMORY="2Gi"
CONTAINER_OPENSHIFT_MIN_CPU=1

CONTAINER_OPTIONS=
CONTAINER_PULL_OPTION=
LINUX_UPDATE=yes

BUILDTIME=$(date -Iseconds)


detect_container_environment()
{

  if [ -n "$CONTAINER_CMD" ]; then
    return 0
  fi

  if [ -n "$USE_DOCKER" ]; then
     CONTAINER_CMD=docker
     return 0
  fi

  CONTAINER_RUNTIME_VERSION_STR=$(podman -v 2> /dev/null | head -1)
  if [ -n "$CONTAINER_RUNTIME_VERSION_STR" ]; then
    CONTAINER_CMD=podman
    return 0
  fi

  CONTAINER_RUNTIME_VERSION_STR=$(nerdctl -v 2> /dev/null | head -1)
  if [ -n "$CONTAINER_RUNTIME_VERSION_STR" ]; then
    CONTAINER_CMD=nerdctl
    return 0
  fi

  CONTAINER_RUNTIME_VERSION_STR=$(docker -v 2> /dev/null | head -1)
  if [ -n "$CONTAINER_RUNTIME_VERSION_STR" ]; then
    CONTAINER_CMD=docker
    return 0
  fi

  if [ -z "$CONTAINER_CMD" ]; then
    log "No container environment detected!"
    exit 1
  fi

  return 0
}

detect_container_environment


if [ -z "$CONTAINER_NETWORK" ]; then
  if [ -n "$CONTAINER_NETWORK_NAME" ]; then
    CONTAINER_NETWORK_CMD="--network=$CONTAINER_NETWORK_NAME"
  fi
fi


if [ -z "$BUILDAH_FORMAT" ]; then
  BUILDAH_FORMAT=docker
fi


export BUILDAH_FORMAT
export BUILDKIT_PROGRESS=plain


# Build the multi stage image

$CONTAINER_CMD build --no-cache $CONTAINER_OPTIONS $CONTAINER_PULL_OPTION \
  $CONTAINER_NETWORK_CMD \
  -t $CONTAINER_IMAGE \
  -f $CONTAINER_FILE \
  --label maintainer="$CONTAINER_MAINTAINER" \
  --label name="$CONTAINER_NAME" \
  --label vendor="$CONTAINER_VENDOR" \
  --label description="$CONTAINER_DESCRIPTION" \
  --label summary="$CONTAINER_NAME" \
  --label version="$CONTAINER_IMAGE_VERSION" \
  --label buildtime="$BUILDTIME" \
  --label release="$BUILDTIME" \
  --label architecture="$CONTAINER_ARCHITECTURE" \
  --label io.k8s.description="$CONTAINER_DESCRIPTION" \
  --label io.k8s.display-name="$CONTAINER_NAME" \
  --label io.openshift.tags="c-icap" \
  --label io.openshift.expose-services="$CONTAINER_OPENSHIFT_EXPOSED_SERVICES" \
  --label io.openshift.non-scalable=true \
  --label io.openshift.min-memory="$CONTAINER_OPENSHIFT_MIN_MEMORY" \
  --label io.openshift.min-cpu="$CONTAINER_OPENSHIFT_MIN_CPU" \
  --build-arg CONTAINER_IMAGE_VERSION="$CONTAINER_IMAGE_VERSION" \
  --build-arg C_ICAP_VERSION="$C_ICAP_VERSION" \
  --build-arg SQUIDCLAM_VERSION="$SQUIDCLAM_VERSION" \
  --build-arg LINUX_UPDATE="$LINUX_UPDATE" \
  --build-arg BASE_IMAGE=$BASE_IMAGE \
  --build-arg SPECIAL_CURL_ARGS="$SPECIAL_CURL_ARGS" .

echo

# Print run-time
hours=$((SECONDS / 3600))
seconds=$((SECONDS % 3600))
minutes=$((seconds / 60))
seconds=$((seconds % 60))

h=""; m=""; s=""
if [ ! $hours = "1" ] ; then h="s"; fi
if [ ! $minutes = "1" ] ; then m="s"; fi
if [ ! $seconds = "1" ] ; then s="s"; fi
if [ ! $hours = 0 ] ; then echo "Completed in $hours hour$h, $minutes minute$m and $seconds second$s"
elif [ ! $minutes = 0 ] ; then echo "Completed in $minutes minute$m and $seconds second$s"
else echo "Completed in $seconds second$s"; fi
echo


