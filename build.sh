#!/bin/bash
############################################################################
# Copyright Nash!Com, Daniel Nashed 2024 - APACHE 2.0 see LICENSE
############################################################################

BASE_IMAGE=quay.io/centos/centos:stream9

export BUILDKIT_PROGRESS=plain

#docker build --no-cache -t nashcom/c-icap --build-arg BASE_IMAGE=$BASE_IMAGE .
docker build -t nashcom/c-icap --build-arg BASE_IMAGE=$BASE_IMAGE .
