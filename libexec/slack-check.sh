#!/bin/bash

function error_msg {
    echo "Slack check failed!"
    echo
    echo "No SLACK_TOKEN provided."
    echo "Export the variable in the VM to allow package updates to be published to the openflight Slack channel"
    exit 1
}

# Check for token
echo "Checking Slack access..."
if [ "$SLACK_TOKEN" ]; then
    # Check that token is valid
    TEAM=$(echo '' |curl -s --data @- -X POST -H "Authorization: Bearer $SLACK_TOKEN" -H 'Content-Type: application/json' https://slack.com/api/auth.test |sed 's/.*"team":"//g;s/","user".*//g')
    if [[ $TEAM != "Alces Flight" ]] ; then
        error_msg
    else
        echo "Slack check successful!"
    fi
else
    error_msg
fi
