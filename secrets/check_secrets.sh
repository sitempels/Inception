#! /bin/bash
SCRIPT_NAME="${0##*/}"
LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -ne 1 ]; then
    echo "[$SCRIPT_NAME] Error: usage: $SCRIPT_NAME <secret_file_path>"
    exit 1
fi

if [ ! -f $1 ]; then
    echo "[$SCRIPT_NAME] Error: file $1 not found"
    exit 1
else
    SECRETS_FILE="$1"
fi	

echo "[$SCRIPT_NAME] checking secrets file"
missing=false
while IFS='=' read -r key value; do
    #Skip empty lines and comments
    [[ -z "${key// }" ]] && continue
    [[ "$key" =~ [[:space:]]*# ]] && continue

    #Trim IFS
    key=$(xargs <<<"$key")
    value=$(xargs <<<"$value")

    #Flag not set entries
    if [[ -z "$value" ]]; then
	echo "Missing value for ${key}"
	missing=true
    fi 
done < "$SECRETS_FILE"

if $missing; then
    echo "[$SCRIPT_NAME] One or more secrets value missing, please fill them"
    exit 1
else
    echo "[$SCRIPT_NAME] All secrets are set"
    exit 0
fi
