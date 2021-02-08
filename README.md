# GistBackupUtility

This Bash script backs up your public and private gists to a given directory as git repositories 
including the full revision history.  If the directories already exist, the gist repos will be 
updated.  The entire implementation is provided and ran as a simple Bash script.


#### Setup

This script originally self-provisioned an authentication token using the GitHub API, however
GitHub has since removed this endpoint for public use.  Personal Access Tokens must now be created
manually.  You can do so by visiting <https://github.com/settings/tokens> or by navigating from the main
site to **Settings -> Developer Settings -> Personal Access Tokens**

I suggest the name **GistBackupUtility**, but it's not a requirement.  The token is the only piece used
from the script side.

Once the Personal Access Token is generated,  store in the Git configuration as `github.gist.oauth.token`.
You can do so by replacing ACCESS_TOKEN with the provided GitHub value in the command below.

    $ git config --global github.gist.oauth.token ACCESS_TOKEN

To remove the git configuration value, run

    $ git config --global --unset github.gist.oauth.token

You can revoke this token at any time by visiting <https://github.com/settings/tokens>.


#### Usage

You can start backing up all your gists by simply executing the script:

    $ ./gist-backup-utility.sh

This will clone all gist repositories to a local folder, for example `./backups`.  This value will be
stored in `./config.ini` for later use.  Remove this file if you'd like to change directories.

When you call the script again, it will simply update the repos (pull changes) if they exist already.


#### Usage

* Dated backup folders
