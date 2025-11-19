#!/bin/bash
# Check for deps
echo "Checking GChat requirements..."
if ! which jq &> /dev/null ; then
    echo "Sending to Google Chat requires 'jq'"
    exit 1
fi
