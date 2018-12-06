#!/bin/bash

# GistBackupUtility
#
# Backs up all your public and private gists
# to the given directory.
#
# Example:
#
#   ./path/gist-backup-utility.sh
#
# In addition to your own gists you can also backup your starred gists
# or (public) gists of a defined user by changing the gist url in the 
# environment variable.
#
# Example:
#
#   GITHUB_GIST_URL=https://api.github.com/gists/starred gist-backup ~/gist-backups/starred
#   GITHUB_GIST_URL=https://api.github.com/users/lukeawyatt/gists gist-backup ~/gist-backups/aprescott
#

########################################
########### TOKEN MANAGEMENT ###########
########################################

# INITIALIZATION
GITHUB_AUTH_URL="https://api.github.com/authorizations"
GITHUB_GIST_URL=${GIST_URL:-https://api.github.com/gists}


echo "########################################"
echo "########## GistBackupUtility ###########"
echo "########################################"
echo
echo "This utility will self-authenticate and backup"
echo "gists from GitHub.  First run will be guided."
echo "In the instance your Personal Access Token is"
echo "set, yet corrupt or deleted from GitHub, run"
echo "the following command:"
echo
echo "git config --global --unset github.gist.oauth.token"
echo
echo "Lets get started..."
echo

TOKEN=$(git config --get github.gist.oauth.token)

BACKUP_PATH=""
if [ -f config.ini ]; then
    BACKUP_PATH=$(<config.ini)
	echo "BACKUP PATH: $BACKUP_PATH"
	echo 
fi

if [ -z "$BACKUP_PATH" ]; then
	echo -n "Backup Path: " 
	read BACKUP_PATH
	echo "$BACKUP_PATH" > "./config.ini"
fi

function jsonval {
  temp=`echo $JSON | sed 's/\\\\\//\//g' | sed 's/[{}]//g' | awk -v k="text" '{n=split($0,a,","); for (i=1; i<=n; i++) print a[i]}' | sed 's/\"\:\"/\|/g' | sed 's/[\,]/ /g' | sed 's/\"//g' | grep -w $PROP`
  echo ${temp##*|}
}

if [ -z "$TOKEN" ]; then
  echo "Existing token not found, creating one instead..."
  echo 
  
  echo -n "GitHub Username: " 
  read GITHUB_USER

  read -s -p "GitHub Password: " GITHUB_PASSWORD
  
  CURL_OUTPUT=$(curl -u $GITHUB_USER:$GITHUB_PASSWORD \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"scopes":["gist"], "note": "GistBackupUtility"}' \
    $GITHUB_AUTH_URL)

  echo "GITHUB OUTPUT: $CURL_OUTPUT"
  echo 
    
  JSON=$CURL_OUTPUT
  PROP='token'
  TOKEN=`jsonval`
  TOKEN=$(echo "$TOKEN" | grep -oP "^token: \K.*")
fi

echo "TOKEN: $TOKEN"

if [ -z "$TOKEN" ]; then
  echo "Authorization is invalid or the Personal Access Token already exists."
  echo "Please try again. If the token exists and needs to be reset,"
  echo "log into GitHub and delete the token for the GistBackupUtility."
  echo "Then run 'git config --global --unset github.gist.oauth.token' to unset the"
  echo "token in the git configuration."
  echo 
  exit 1
else
  git config --global github.gist.oauth.token $TOKEN
fi


########################################
######### GIST BACKUP PROCESS ##########
########################################

if [ -z $TOKEN ]
then
  echo "No OAuth token found in github.gist.oauth.token git config."
  exit 1
fi

if [ -z "$BACKUP_PATH" ]
then
  echo "No backup directory set."
  usage
  exit 1
fi

# IF THE GIVEN DIRECTORY DOESN'T EXIST, CREATE IT
if [ ! -e "$BACKUP_PATH" ]
then
  mkdir -p $BACKUP_PATH
fi

# GO INTO THE GIVEN BACKUP DIRECTORY
cd $BACKUP_PATH

# IF WE FAILED TO CD FOR SOME REASON, ABORT
if [ $? -gt 0 ]
then
  exit 1
fi

# TAKE'S A GIT REMOTE URI AND CLONES IT INTO
# THE BACKUP DIRECTORY. IF THAT DIRECTORY
# EXISTS ALREADY, CD'S INTO IT AND DOES A
# GIT PULL.
backup() {
  echo "Backing up $1"
  local dir=$(echo "$1" | cut -d / -f 4 | cut -d . -f 1)

  if [ -e $dir ]
  then
    echo "  Already cloned at $PWD/$dir. Pulling."
    cd $dir
    git pull -q
    cd $OLDPWD
  else
    git clone -q $1
  fi
}

PAGE=1
RETRIES=0
MAX_RETRIES=3
while [ $RETRIES -lt $MAX_RETRIES ]
do
  echo "Requesting Gist page: $PAGE from $GITHUB_GIST_URL"
  
  gists=$(
  curl -s -H "Authorization: token $TOKEN" -d "page=$PAGE" -G $GITHUB_GIST_URL |
  sed -n 's/.*git_pull_url": "\(.*\)",/\1/p'
  )
  
  if [ -z "$gists" ]
  then
    echo "No gists found on this page. Trying again."
    RETRIES=$(( RETRIES + 1 ))
    continue
  fi

  for gist in $gists
  do
  echo $gist
    backup $gist
  done

  PAGE=$(( PAGE + 1 ))
  RETRIES=0
done

echo "No gists found (anymore). Not trying again."
exit 0
