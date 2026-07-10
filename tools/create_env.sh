#! /bin/bash
SCRIPT_NAME="${0##*/}"
LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

if [ $# -ne 1 ]; then
    echo "[$SCRIPT_NAME] Error: usage: $SCRIPT_NAME <env_file_absolute_path>"
    exit 1
fi

if [ ! -f $1 ]; then
    echo "[$SCRIPT_NAME] Error: file $1 not found"
    echo "[$SCRIPT_NAME] Error: usage: $SCRIPT_NAME <env_file_absolute_path>"
    exit 1
else
    ENV_FILE="$1"
fi	

echo "[$SCRIPT_NAME] creating env variables"
while IFS='=' read -r key value; do
    #Skip empty lines and comments
    [[ -z "${key// }" ]] && continue
    [[ "$key" =~ [[:space:]]*# ]] && continue
    [[ "$key" == S_* ]] && continue

    #Trim IFS
    key=$(xargs <<<"$key")
    value=$(xargs <<<"$value")

    #Skip not set entries
    [[ -z "${value// }" ]] && continue

    #Create env variable
    printf '%s := %s\n' "$key" "$value"

done < "$ENV_FILE"
echo "[$SCRIPT_NAME] env variables created"
