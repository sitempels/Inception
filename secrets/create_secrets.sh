#! /bin/bash
SCRIPT_NAME="${0##*/}"
LOCATION="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SECRETS_DIR=${LOCATION}

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

echo "[$SCRIPT_NAME] creating secrets files"
while IFS='=' read -r key value; do
    #Skip empty lines and comments
    [[ -z "${key// }" ]] && continue
    [[ "$key" =~ [[:space:]]*# ]] && continue

    #Trim IFS
    key=$(xargs <<<"$key")
    value=$(xargs <<<"$value")

    #Skip not set entries
    [[ -z "${value// }" ]] && continue

    secret_file="${SECRETS_DIR}/${key,,}.secrets"
    #Create secrets
    if [ ! -f $secret_file ]; then
	printf '%s\n' "${value}" > "$secret_file"
    else
	echo "[$SCRIPT_NAME] secret file already exist: $secret_file"
    fi
done < "$SECRETS_FILE"
echo "[$SCRIPT_NAME] secrets files created"
