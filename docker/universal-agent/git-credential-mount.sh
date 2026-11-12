#!/bin/bash
if [ "$1" = "get" ]; then
    TOKEN=$(cat /home/agent/.config/github-app/current-token 2>/dev/null)
    if [ -n "$TOKEN" ]; then
        echo "username=x-access-token"
        echo "password=$TOKEN"
    fi
fi
