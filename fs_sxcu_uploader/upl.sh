#!/bin/bash

COLLECTION=""
COLLECTION_TOKEN=""
TOKEN=""
DOMAIN=""
STORAGE="~/Pictures/flameshot" # SCREENSHOT STORAGE PATH

SCREENSHOT_FORMAT="$(grep -P -o '(?<=^saveAsFileExtension\=).+$' ~/.config/flameshot/flameshot.ini)"
if [ "${SCREENSHOT_FORMAT}" == "" ]; then
	SCREENSHOT_FORMAT="png"
fi

FILE="$(date +%F_%H.%M.%S)_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 10).${SCREENSHOT_FORMAT}"

# a little trick to expand tilde (~) to the actual path
STORAGE="$(eval echo "${STORAGE}")"
# make sure the local folder exists
mkdir --parents "${STORAGE}"

FLAMESHOT_STATUS=$(flameshot gui --path "${STORAGE}/${FILE}" 2>&1)

if [ "${FLAMESHOT_STATUS}" == "flameshot: info: Screenshot aborted." ]; then
	echo "The screenshot process was aborted"
	exit 0
fi

response=$(curl -X POST \
	-F "file=@${STORAGE}/${FILE}" \
	-F "token=${TOKEN}" \
	-F "collection=${COLLECTION}" \
	-F "collection_token=${COLLECTION_TOKEN}" \
	${DOMAIN}/api/files/create)

if [ $? -eq 0 ]; then
	error=$(echo "$response" | jq -r '.error')
	if [ "$error" != "null" ] && [ "$error" != "" ]; then
		echo "Error: $error" | tee -a output.log
		notify-send --icon terminal --category 'transfer.error' "Screenshot upload error" "$error"
	else
		image_url=$(echo "$response" | jq -r '.url')
		del_url=$(echo "$response" | jq -r '.del_url')
		echo "Image $FILE" | tee -a links.log
		echo "Image URL: $image_url" | tee -a links.log
		echo "Delete URL: $del_url" | tee -a links.log

		echo "$image_url" | xclip -selection clipboard
		notify-send --icon terminal --category 'transfer.success' \
			"Screenshot uploaded successfully" \
			"Link copied to clipboard"
	fi
else
	echo "Error: Request failed" | tee -a error.log
	notify-send --icon terminal --category 'transfer.error' "Screenshot upload error" "Request failed"
	exit 1
fi
