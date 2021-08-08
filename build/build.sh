#!/bin/bash
set -x

box_name='opensearch'
opensearch_version='1.0.0'
box_full_name="$box_name-$opensearch_version"

#clean up old files
vagrant destroy --force
vagrant box remove --force --all $box_full_name
find . -type f -name "*.box" -delete

vagrant up || exit 1
vagrant package --output $box_full_name.box || exit 1
vagrant box add --name $box_full_name ${box_full_name}.box || exit 1