#!/bin/bash

VERSION_FILE="sha.txt"


DOCKERHUB_USERRNAME=""
DOCKERHUB_REPO=""
TAG="" # eg: lastest, edge, nightly


update_version_file() {
    echo "Updating version file with the latest version: $1"
    echo "$1" > "$VERSION_FILE"
    # optionally send Notification
    # curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" -F chat_id="$CHAT_ID" -F message_thread_id="$TOPIC_ID" \
    #                   -F text="New Image update with Hash $1 "> /dev/null
}

commit_update(){
    git config --local user.name "Github Action"
    git config --local user.email "action@github.com"
    git add --all
    git commit -m "Commit hash: $1"
    git push
}

current_sha=$(<"$VERSION_FILE")

json_response=$(curl "https://hub.docker.com/v2/namespaces/$DOCKERHUB_USERRNAME/repositories/$DOCKERHUB_REPO/tags/$TAG")

api_sha=$(echo "$json_response" | jq -r '.digest')

# Compare commit hash
if [ "$api_sha" != "$current_sha" ]; then
    update_version_file "$api_sha"
    commit_update "$api_sha"
fi
