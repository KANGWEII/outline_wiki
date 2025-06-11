#!/bin/bash
# Generate config and secrets required to host outline server
set -e
shopt -s expand_aliases

function env_add {
    key=$1
    val=$2
    filename=$3
    echo "${key}=${val}" >> $filename
}

function env_replace {
    key=$1
    val=$2
    filename=$3
    sed "s|${key}=.*|${key}=${val}|" -i $filename
}

function env_delete {
    key=$1
    filename=$2
    sed "/${key}/d" -i $filename
}

function create_slack_env {
    set -o allexport; source env/env.outline; set +o allexport
    echo "=> Open https://api.slack.com/apps and Create New App"
    echo "=> After creating, navigate to 'Features' -> 'OAuth & Permissions'"
    echo "=> '${URL}/auth/slack.callback'"
    read -p "Copy the above to Redirect URLs. Press Enter to continue..."

    echo "=> Save, navigate to 'Settings' -> 'Basic Information'"

    if test -f env/env.slack; then
        set -o allexport; source env/env.slack; set +o allexport
    fi

    read -p "Enter App ID [$SLACK_APP_ID] : " SLACK_APP_ID_INP
    read -p "Enter Client ID [$SLACK_KEY] : " SLACK_KEY_INP
    read -p "Enter Client Secret [$SLACK_SECRET]: " SLACK_SECRET_INP
    read -p "Enter Verification Token (*not* Signing Secret) [$SLACK_VERIFICATION_TOKEN]: " SLACK_VERIFICATION_TOKEN_INP

    touch env/env.slack
    env_add SLACK_APP_ID ${SLACK_APP_ID_INP:-SLACK_APP_ID} env/env.slack
    env_add SLACK_KEY ${SLACK_KEY_INP:-SLACK_KEY} env/env.slack
    env_add SLACK_SECRET ${SLACK_SECRET_INP:-SLACK_SECRET} env/env.slack
    env_add SLACK_VERIFICATION_TOKEN ${SLACK_VERIFICATION_TOKEN_INP:-SLACK_VERIFICATION_TOKEN} env/env.slack
}

function create_env_files {
    read -p "Enter hostname [localhost]: " HOST
    HOST=${HOST:-localhost}

    read -p "Enter bucket name to store images [outline-bucket]: " BUCKET_NAME
    BUCKET_NAME=${BUCKET_NAME:-outline-bucket}

    # Download sample env for outline
    wget --quiet https://raw.githubusercontent.com/outline/outline/develop/.env.sample -O env/env.outline

    echo "" >> env/env.outline

    env_add HOST $HOST env/env.outline

    SECRET_KEY=`openssl rand -hex 32`
    UTILS_SECRET=`openssl rand -hex 32`

    env_replace SECRET_KEY $SECRET_KEY env/env.outline
    env_replace UTILS_SECRET $UTILS_SECRET env/env.outline

    env_delete DATABASE_URL env/env.outline
    env_delete REDIS_URL env/env.outline

    env_replace PORT 3000 env/env.outline
    
    env_add PGSSLMODE disable env/env.outline

    # Setup datastore
    sed "s|outline-bucket|${BUCKET_NAME}|" -i data/nginx/default.conf
    MINIO_ACCESS_KEY=`openssl rand -hex 8`
    MINIO_SECRET_KEY=`openssl rand -hex 32`

    rm -f env/env.minio
    env_add MINIO_ACCESS_KEY $MINIO_ACCESS_KEY env/env.minio
    env_add MINIO_SECRET_KEY $MINIO_SECRET_KEY env/env.minio
    env_add MINIO_BROWSER off env/env.minio

    env_replace AWS_ACCESS_KEY_ID $MINIO_ACCESS_KEY env/env.outline
    env_replace AWS_SECRET_ACCESS_KEY $MINIO_SECRET_KEY env/env.outline
    env_replace AWS_S3_UPLOAD_BUCKET_NAME $BUCKET_NAME env/env.outline
}

function generate_https_conf {
    echo "Generating HTTPS configuration"
    # https://letsencrypt.org/docs/certificates-for-localhost/
    openssl req -x509 -out data/certs/public.crt -keyout data/certs/private.key \
        -newkey rsa:2048 -nodes -sha256 \
        -subj '/CN=localhost' -extensions EXT -config <( \
        printf "[dn]\nCN=localhost\n[req]\ndistinguished_name = dn\n[EXT]\nsubjectAltName=DNS:localhost\nkeyUsage=digitalSignature\nextendedKeyUsage=serverAuth")

    set -o allexport; source env/env.outline; set +o allexport
    read -p "Enter https port number [443]: " HTTPS_PORT
    HTTPS_PORT=${HTTPS_PORT:-443}

    if [ $HTTPS_PORT == 443 ]
    then
        URL="https://${HOST}"
    else
        URL="https://${HOST}:${HTTPS_PORT}"
    fi

    env_add HTTPS_PORT $HTTPS_PORT env/env.outline
    env_replace URL $URL env/env.outline
    env_replace AWS_S3_UPLOAD_BUCKET_URL $URL env/env.outline

    touch data/certs/private.key data/certs/public.crt

    create_slack_env
}

function delete_env {
    printf "Delete all certs, env files, and MinIO metadata? (y or n) "
    while true; do
        stty -echo
        read -n 1 confirm
        stty echo

        case "$confirm" in
            [yY])
                echo
                rm -rfv data/certs env/env.*
                rm -rf data/minio_root/.minio.sys/
                break
                ;;
            [nN])
                echo
                echo "Aborted."
                break
                ;;
        esac
    done
}

function delete_data {
    printf "Do you want to delete your database and images? (y or n) "
    while true; do
        stty -echo
        read -n 1 confirm
        stty echo

        case "$confirm" in
            [yY])
                echo
                rm -rfv data/pgdata data/minio_root
                break
                ;;
            [nN])
                echo
                echo "Aborted."
                break
                ;;
        esac
    done
}

function init_data_dirs {
    set -o allexport; source env/env.outline; set +o allexport
    mkdir -p data/minio_root/${AWS_S3_UPLOAD_BUCKET_NAME} data/pgdata
}

$*