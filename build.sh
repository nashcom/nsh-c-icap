#!/bin/bash
############################################################################
# Copyright Nash!Com, Daniel Nashed 2024 - APACHE 2.0 see LICENSE
############################################################################

BASE_IMAGE=quay.io/centos/centos:stream9

export BUILDKIT_PROGRESS=plain

docker build --no-cache -t nashcom/c-icap --build-arg BASE_IMAGE=$BASE_IMAGE .
#docker build -t nashcom/c-icap --build-arg BASE_IMAGE=$BASE_IMAGE .

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

