#!/bin/bash

# Get user Hostname, OS and relative Bash Config location
function get_host_details() {
    if [[ "`uname -a`" == *"Darwin"* ]]; then
        OS="MacOS"
        BASH_CONFIG=~/.bash_profile
    elif [[ "`uname -a`" == *"Linus"* ]]; then
        OS="Linux"
        BASH_CONFIG=~/.bash_rc
    fi
    HOSTNAME=`hostname`
}

# Retrieve Web Token linked to the provided Email
function retrieve_token_url() {
    tokenresponse=$(curl -s -X POST https://canarytokens.org/generate -d "email=$EMAIL" -d "memo='$1'" -d"type=web" -d"webhook=")
    TOKEN=$(echo ${tokenresponse} | awk -F'Url' '{ print $3 }' | awk -F'"' '{ print $3 }')
    echo "$TOKEN"
}

# Add an alias for the ping command that will trigger a Web Token
function create_ping_alias() {
    PINGMEMO="Ping run on ${HOSTNAME}"
    PINGTOKEN=`retrieve_token_url '${PINGMEMO}'`
    echo "alias ping='curl -s ${PINGTOKEN} && ping '" >> $BASH_CONFIG

}

# Download a tokened Word Doc
function download_word() {
    WORDMEMO="Word file open on ${HOSTNAME}"
    wordresponse=$(curl -s -X POST https://canarytokens.org/generate -d "email=$EMAIL" -d "memo='${WORDMEMO}'" -d "type=ms_word" -d"webhook=")
    wordtoken=$(echo ${wordresponse} | awk -F'Token' '{ print $2 }' | awk -F'"' '{ print $3 }')
    wordauth=$(echo ${wordresponse} | awk -F'Auth' '{ print $2 }' | awk -F'"' '{ print $3 }')
    # Actually download file
    curl -s -o passwords.docx "https://canarytokens.org/download?fmt=msword&token=${wordtoken}&auth=${wordauth}"
}

# Download a tokened PDF Doc
function download_pdf() {
    PDFMEMO="PDF file open on ${HOSTNAME}"
    pdfresponse=$(curl -s -X POST https://canarytokens.org/generate -d "email=$EMAIL" -d "memo='${PDFMEMO}'" -d "type=adobe_pdf" -d"webhook=")
    pdftoken=$(echo ${pdfresponse} | awk -F'Token' '{ print $2 }' | awk -F'"' '{ print $3 }')
    pdfauth=$(echo ${pdfresponse} | awk -F'Auth' '{ print $2 }' | awk -F'"' '{ print $3 }')
    # actually download file
    curl -s -o bankstatement.pdf "https://canarytokens.org/download?fmt=msword&token=${pdftoken}&auth=${pdfauth}"
}

# Download tokened AWS Credentials and add/append to the .aws/credentials directory
function download_awscreds() {
    AWSMEMO="AWS credentials run on ${HOSTNAME}"
    awsresponse=$(curl -s -X POST https://canarytokens.org/generate -d "email=$EMAIL" -d "memo='${AWSMEMO}'" -d "type=aws_keys" -d"webhook=")
    aws_access_key_id=$(echo $awsresponse | awk -F"aws_access_key_id" '{ print $2 }' | awk -F'"' '{ print $3 }')
    aws_secret_access_key=$(echo $awsresponse | awk -F"aws_secret_access_key" '{ print $2 }' | awk -F'"' '{ print $3 }')
    mkdir .aws
    cat >> .aws/credentials <<EOF

[default]
aws_access_key = '${aws_access_key_id}'
aws_secret_access_key = '${aws_secret_access_key}'
output = json
region = us-east-2
EOF

}

usage()
{
    echo 'token_me.sh [-h]'
    echo 'Usage: ./token_me.sh -e <user_email>'
    echo -e "\t-h \t-\t Show this help"
    echo -e "\t-e \t-\t Email flag"
}

while getopts "he:" opt; do
    case $opt in
        h)
            usage
            exit
            ;;
        e)
            EMAIL="$OPTARG"
	        ;;
        \?)
            echo "Invalid options: $OPTARG" >&2
     esac
done

echo "Getting host details..."
get_host_details
echo "Done"
echo "Hostname is: " ${HOSTNAME}
echo "OS is: " ${OS}
echo "Bash config location is: ${BASH_CONFIG}"
echo "Creating ping alias..."
create_ping_alias
echo "Done"
echo "Downloading tokened MS Word doc..."
download_word
echo "Done"
echo "Downloading tokened PDF doc..."
download_pdf
echo "Done"
echo "Downloading AWS Credentials..."
download_awscreds
echo "Done"
echo "Tokening process complete!"