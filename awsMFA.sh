#!/bin/bash
AWS_USERNAME="notafakeusername"
PERM_KEYID="REALKEYAKIASL2R5B2ZK"
PERM_SECRET="REALSECRETW/KT7aWXURz1YuZQiTmZaLJlG2AcWeYL"
AWS_ACCOUNT_ID="867530912340"
# an array of authorized roles as "<name> <ROLE URI>"
PROFILES=("profile1 arn:aws:iam::867530912341:role/ExternalRole1"\
  "profile2 arn:aws:iam::867530912342:role/ExternalRole2"\
  "profile3 arn:aws:iam::867530912343:role/ExternalRole3")
CRED_FILE="${HOME}/.aws/credentials"

unset AWS_PROFILE

function reset {
cat <<EOF1 > "${CRED_FILE}"
[nomfa]
aws_access_key_id = $PERM_KEYID
aws_secret_access_key = $PERM_SECRET
EOF1
}

function append {
NAME="$1"
echo "setting profile $NAME"
shift
KEYID=$(echo $1 | grep AccessKeyId | sed 's@.*AccessKeyId": "\([^"]*\)".*@\1@')
#echo AccessKeyId $KEYID
KEY=$(echo $1 | grep SecretAccessKey | sed 's@.*SecretAccessKey": "\([^"]*\)".*@\1@')
#echo SecretAccessKey $KEY
TOKEN=$(echo $1 | grep SessionToken | sed 's@.*SessionToken": "\([^"]*\)".*@\1@')
#echo SessionToken $TOKEN
cat <<EOF2 >> "${CRED_FILE}"

[$NAME]
aws_access_key_id = $KEYID
aws_secret_access_key = $KEY
aws_session_token = $TOKEN
EOF2
}

# deletes all the lines in the credentials after the first profile entry
function resetProfilesOnly {

    local search_string=($PROFILES)
    if [[ -z "$search_string" ]]; then
        echo "Error: no profiles defined"
        exit 1
    fi
    local tempfile=$(mktemp)
    local line_to_delete=$(grep -n "$search_string" "${CRED_FILE}" | cut -d: -f1 | head -1)

    if [[ -z "$line_to_delete" ]]; then
        echo "Error: No profiles configured"
        return 1
    fi

    head -n "$((line_to_delete - 1))" "${CRED_FILE}" > "$tempfile"
    mv "$tempfile" "${CRED_FILE}"
}

function updateProfiles {
    for profile in "${PROFILES[@]}"; do
        split=(${profile})
        # AWS limits assumend role sessions to a maximum of one hour (ugh) and this can't be changed
        # https://repost.aws/knowledge-center/iam-role-chaining-limit
        OUTPUT=$(aws sts assume-role --duration-seconds 3600 --role-arn "${split[1]}" --role-session-name AWSCLI-Session)
        if [ $? -eq 0 ]; then
            # worked
            append "${split[0]}" "$OUTPUT"
        fi
    done
}

case "$1" in
    '')
        # get tokens for profiles:
        resetProfilesOnly
        updateProfiles
        ;;

    'reset'|'default')
        echo "setting default"
        reset
        ;;

    *)
        OUTPUT=$(aws sts get-session-token --serial-number arn:aws:iam::$AWS_ACCOUNT_ID:mfa/$AWS_USERNAME --duration-seconds 21600 --profile nomfa --token-code "$1")
        if [ $? -eq 0 ]; then
            # worked
            reset
            append "default" "$OUTPUT"
            
            # get tokens for profiles:
            updateProfiles
        else
            # failed
            echo "error, not updating credentials"
            exit 0
        fi
        ;;

esac


