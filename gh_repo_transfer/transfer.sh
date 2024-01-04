#!/bin/bash

SOURCE_USERNAME=""
DESTINATION_USERNAME=""
GH_TOKEN=""

function git_repo_transfer(){
    local response
    response=$(curl -s -o /dev/null -w "%{http_code}" \
        -X POST \
        -H "Accept: application/vnd.github+json" \
        -H "Authorization: Bearer $GH_TOKEN" \
        -H "X-GitHub-Api-Version: 2022-11-28" \
        "https://api.github.com/repos/$SOURCE_USERNAME/{$1}/transfer" \
        -d '{"new_owner":"'"$DESTINATION_USERNAME"'"}')

    if [ "$response" -eq 202 ]; then
        echo "Repository $1 transferred successfully."
    else
        echo "Error transferring repository $1. HTTP status code: $response"
    fi
}

function take_input(){
    read -rp "Enter your username: " SOURCE_USERNAME
    while [ -z "$SOURCE_USERNAME" ]; do
        echo "Input cannot be empty. Please try again."
        read -rp "Enter your username: " SOURCE_USERNAME
    done

    read -rp "Enter destination username (only where you have permission): " DESTINATION_USERNAME
    while [ -z "$DESTINATION_USERNAME" ]; do
        echo "Input cannot be empty. Please try again."
        read -rp "Enter destination username (only where you have permission): " DESTINATION_USERNAME
    done

    read -rp "Enter your token(Classic Token): " GH_TOKEN
    while [ -z "$SOURCE_USERNAME" ]; do
        echo "Input cannot be empty. Please try again."
        read -rp "Enter your token(Classic Token): " GH_TOKEN
    done

}

take_input  # Call the function to take input

repos=$(cat ./repos.txt)

for repo in $repos; do
    git_repo_transfer "$repo"
done
