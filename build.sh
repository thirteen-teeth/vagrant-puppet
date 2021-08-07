#!/bin/bash

box_version='8.4.220'
box_out_file="ol8-opensearch-${box_version}.box"

find -type f -name "*.box" -exec rm -f {} +

vagrant up
vagrant package --output $box_out_file
