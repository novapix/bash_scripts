#!/bin/bash


API_KEY="" # vgy.me api key
STORAGE="" # Path where the screenshots are stored


# grab the file format that is defined by the user in the Flameshot config
SCREENSHOT_FORMAT="$(grep -P -o '(?<=^saveAsFileExtension\=).+$' ~/.config/flameshot/flameshot.ini)"
# if no format was specified
if [ "${SCREENSHOT_FORMAT}" == "" ]; then
    # fallback to png which is default of Flameshot
    SCREENSHOT_FORMAT="png"
fi

# construct the file name
FILE="$(date +%F_%H.%M.%S)_$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | head -c 10).${SCREENSHOT_FORMAT}"

# a little trick to expand tilde (~) to the actual path
STORAGE="$(eval echo "${STORAGE}")"
# make sure the local folder exists
mkdir --parents "${STORAGE}"

# take the screenshot and capture the output
FLAMESHOT_STATUS=$(flameshot gui --path "${STORAGE}/${FILE}" 2>&1)

# check if user aborted the screenshot
if [ "${FLAMESHOT_STATUS}" == "flameshot: info: Screenshot aborted." ]; then
    echo "The screenshot process was aborted"
    exit 0
fi

# inform the user
echo "${STORAGE}/${FILE} created!"

output=$(vgy "$API_KEY" "${STORAGE}/${FILE}")

# Check if the command encountered an error
if [ $? -ne 0 ]; then
    # If there was an error, display an error notification and log the error
    error_message="Error: Screenshot upload failed for $FILE to vgy"
    echo "$output" | tee -a output.log
    notify-send --icon terminal --category 'transfer.error' "Screenshot upload error" "$error_message"
else
    # If the command was successful, extract URL, copy it to clipboard, and display success notification
    echo "$output" | tee -a output.log | xclip -selection clipboard
    notify-send --icon terminal --category 'transfer.success' "Screenshot uploaded successfully" "Screenshot link copied to clipboard"
fi
