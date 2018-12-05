# GistBackupUtility

This Bash script backs up your public and private gists to a given directory as git repositories including the full revision history.
If the directories already exist, the gist repos will be updated.
The entire implementation is provided and ran as a simple Bash script.


#### Setup

The first fun of this script will prompt you for your GitHub Username and Password, in which the script
will authenticate, generate a Personal Access Token (Named GistBackupUtility), and store in the
Git configuration as `github.gist.oauth.token`.

Your account password is required here because v3 of the API is not accessible with your account token.

To remove the git configuration value, run

    $ git config --global --unset github.gist.oauth.token

You can revoke this token at any time by visiting <https://github.com/settings/applications>.


#### Usage

You can start backing up all your gists by simply executing the script:

    $ ./gist-backup-utility.sh

This will clone all gist repositories to the local folder `./backups`.

When you call the script again, it will simply update the repos (pull changes) if they exist already.
