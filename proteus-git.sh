#!/bin/bash
PATH="/bin:/usr/bin:/sbin:/usr/sbin:/home/$USER/bin"
echo 

HOME=/home/aetherinox
PATH_BACKUP=/server/proteus

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   @author :           aetherinox
#   @script :           Proteus Apt Git
#   @when   :           2024-06-15 19:50:31
#   @url    :           https://github.com/Aetherinox/proteus-git
#
#   requires chmod +x proteus_git.sh
#
#   This requires you to have the following files in your home directory:
#       ~/secrets/.pat_github       Not required if using Gitlab
#       ~/secrets/.pat_gitlab       Not required if using Github
#       ~/secrets/.passwd
#
#   LastVersion requires that two env variables be exported when running
#   that app, otherwise you will be rate-limited by Github and Gitlab.
#       export GITHUB_API_TOKEN=${CSI_PAT_GITHUB}
#       export GITLAB_PA_TOKEN=${CSI_PAT_GITLAB}
#
#   DO NOT change the name of the above env variables otherwise it will
#   not work.
#       - GITHUB_API_TOKEN
#       - GITLAB_PA_TOKEN
#
#   This script requires a minimum Reprepro version or it will cause
#   database errors:
#       - v5.4.2
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   Deprecated: This method is being deprecated in favor of clevis encrypted
#   secrets.
#
#   load secrets file to handle Github rate limiting via a PAF.
#   managed via https://github.com/settings/tokens?type=beta
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [ -f ${PATH_BACKUP}/secrets.sh ]; then
source ${PATH_BACKUP}/secrets.sh
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   vars > colors
#
#   tput setab  [1-7]       – Set a background color using ANSI escape
#   tput setb   [1-7]       – Set a background color
#   tput setaf  [1-7]       – Set a foreground color using ANSI escape
#   tput setf   [1-7]       – Set a foreground color
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [[ $- == *i* ]]
    BLACK="\e[1;30m"
    RED="\e[1;91m"
    ORANGE="\e[33m"
    GREEN="\e[1;92m"
    YELLOW="\e[1;93m"
    LIME_YELLOW="\e[1;93m"
    POWDER_BLUE="\e[1;34m"
    BLUE="\e[1;34m"
    MAGENTA="\e[1;34m"
    CYAN="\e[1;96m"
    WHITE="\e[97m"
    GREYL="\e[1;30m"
    DEV="\e[1;34m"
    DEVGREY="\e[37m"
    FUCHSIA="\e[1;35m"
    PINK="\e[1;34m"
    BOLD="\e[1m"
    NORMAL="\e[0m"
    BLINK="\e[5m"
    REVERSE="\e[7m"
    UNDERLINE="\e[4m"
then
    BLACK=$(tput setaf 0)
    RED=$(tput setaf 1)
    ORANGE=$(tput setaf 208)
    GREEN=$(tput setaf 2)
    YELLOW=$(tput setaf 156)
    LIME_YELLOW=$(tput setaf 190)
    POWDER_BLUE=$(tput setaf 153)
    BLUE=$(tput setaf 4)
    MAGENTA=$(tput setaf 5)
    CYAN=$(tput setaf 6)
    WHITE=$(tput setaf 7)
    GREYL=$(tput setaf 242)
    DEV=$(tput setaf 157)
    DEVGREY=$(tput setaf 243)
    FUCHSIA=$(tput setaf 198)
    PINK=$(tput setaf 200)
    BOLD=$(tput bold)
    NORMAL=$(tput sgr0)
    BLINK=$(tput blink)
    REVERSE=$(tput smso)
    UNDERLINE=$(tput smul)
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   vars > status messages
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

STATUS_MISS="${BOLD}${GREYL} MISS ${NORMAL}"
STATUS_SKIP="${BOLD}${GREYL} SKIP ${NORMAL}"
STATUS_OK="${BOLD}${GREEN}  OK  ${NORMAL}"
STATUS_FAIL="${BOLD}${RED} FAIL ${NORMAL}"
STATUS_HALT="${BOLD}${YELLOW} HALT ${NORMAL}"

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   load secrets through Clevis
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if [ -f ${HOME}/.secrets/.pat_github ]; then
    CSI_PAT_GITHUB=$(cat ${HOME}/.secrets/.pat_github | clevis decrypt 2>/dev/null)
    export GITHUB_API_TOKEN=${CSI_PAT_GITHUB}
else
    echo -e "  ${ORANGE}${BLINK}NOTICE  ${NORMAL} ......... ~/.secrets/.pat_github missing${WHITE}"
fi

if [ -f ${HOME}/.secrets/.pat_gitlab ]; then
    CSI_PAT_GITLAB=$(cat ${HOME}/.secrets/.pat_gitlab | clevis decrypt 2>/dev/null)
    export GITLAB_PA_TOKEN=${CSI_PAT_GITLAB}
else
    echo -e "  ${ORANGE}${BLINK}NOTICE  ${NORMAL} ......... ~/.secrets/.pat_gitlab missing${WHITE}"
fi

if [ -f ${HOME}/.secrets/.passwd ]; then
    CSI_SUDO_PASSWD=$(cat ${HOME}/.secrets/.passwd | clevis decrypt 2>/dev/null)
else
    echo -e "  ${ORANGE}${BLINK}NOTICE  ${NORMAL} ......... ~/.secrets/.passwd missing${WHITE}"
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   vars > app
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

sys_arch=$(dpkg --print-architecture)
sys_code=$(lsb_release -cs)
app_dir_home="$HOME/bin"
app_file_this=$(basename "$0")
app_file_proteus="${app_dir_home}/proteus-git"
app_repo_author="Aetherinox"
app_title="Proteus Apt Git"
app_about="Internal system to Proteus App Manager which grabs debian packages."
app_ver=("1" "1" "0" "0")
app_repo="proteus-git"
app_repo_branch="main"
app_repo_user=$( git config --global --get-all user.name )
app_repo_email=$( git config --global --get-all user.email )
app_repo_apt="proteus-apt-repo"
app_repo_apt_pkg="aetherinox-${app_repo_apt}-archive"
app_repo_url="https://github.com/${app_repo_author}/${app_repo}"
app_mnfst="https://raw.githubusercontent.com/${app_repo_author}/${app_repo}/${app_repo_branch}/manifest.json"
app_script="https://raw.githubusercontent.com/${app_repo_author}/${app_repo}/BRANCH/setup.sh"
app_dir=/server/proteus
app_dir_wd=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
app_dir_repo="incoming/proteus-git/${sys_code}"
app_dir_storage="$app_dir/incoming/proteus-git/${sys_code}"
app_pid_spin=0
app_pid=$BASHPID
app_queue_url=()
app_i=0

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   exports
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

export DATE=$(date '+%d%m%Y')
export DATE_TS=$(date +%s)
export YEAR=$(date +'%Y')
export TIME=$(date '+%H:%M:%S')
export NOW=$(date '+%m.%d.%Y %H:%M:%S')
export ARGS=$1
export LOGS_DIR="$app_dir/logs"
export LOGS_FILE="$LOGS_DIR/proteus-git-${DATE}.log"
export SECONDS=0

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   lists > github repos
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

lst_github=(
    'makedeb/makedeb'
)

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   list > packages
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

lst_packages=(
    'adduser'
)

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   list > architectures
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

lst_arch=(
    'all'
    'amd64'
    'arm64'
)

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   distro
#
#   returns distro information.
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

# freedesktop.org and systemd
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    OS_VER=$VERSION_ID

# linuxbase.org
elif type lsb_release >/dev/null 2>&1; then
    OS=$(lsb_release -si)
    OS_VER=$(lsb_release -sr)

# versions of Debian/Ubuntu without lsb_release cmd
elif [ -f /etc/lsb-release ]; then
    . /etc/lsb-release
    OS=$DISTRIB_ID
    OS_VER=$DISTRIB_RELEASE

# older Debian/Ubuntu/etc distros
elif [ -f /etc/debian_version ]; then
    OS=Debian
    OS_VER=$(cat /etc/debian_version)

# fallback: uname, e.g. "Linux <version>", also works for BSD
else
    OS=$(uname -s)
    OS_VER=$(uname -r)
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   clevis required to decrypt tokens
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if ! [ -x "$(command -v clevis)" ]; then
    echo -e "  ${GREYL}Installing package ${MAGENTA}Clevis${WHITE}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install clevis clevis-dracut clevis-udisks2 clevis-tpm2 -y -qq >/dev/null 2>&1
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   requite packages before anything begins
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

if ! [ -x "$(command -v git)" ]; then
    echo -e "  ${GREYL}Installing package ${MAGENTA}Git${WHITE}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install git -y -qq >/dev/null 2>&1

    echo -e "  ${GREYL}Installing package ${MAGENTA}GPG${WHITE}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install gpg -y -qq >/dev/null 2>&1
fi

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   vars > active repo branch
#   typically "main"
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

app_repo_branch_sel=$( [[ -n "$OPT_BRANCH" ]] && echo "$OPT_BRANCH" || echo "$app_repo_branch"  )

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#   distribution
#   jammy, lunar, focal, noble, etc
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

app_repo_dist_sel=$( [[ -n "$OPT_DISTRIBUTION" ]] && echo "$OPT_DISTRIBUTION" || echo "$sys_code"  )

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    #   .app folder
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    echo ${app_dir}

    manifest_dir=${app_dir}/.app
    mkdir -p            ${manifest_dir}

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    #   duration elapsed
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

    duration=$SECONDS
    elapsed="$(($duration / 60))m $(( $duration % 60 ))s"

    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
    #   .app folder > create .json
    # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

echo ${manifest_dir}/${app_repo_dist_sel}.json

sudo tee ${manifest_dir}/${app_repo_dist_sel}.json << EOF
{
    "name":             "${app_title}",
    "version":          "$(get_version)",
    "author":           "${app_repo_author}",
    "description":      "${app_about}",
    "distrib":          "${app_repo_dist_sel}",
    "url":              "${app_repo_url}",
    "last_duration":    "${elapsed}",
    "last_update":      "${NOW}",
    "last_update_ts":   "${DATE_TS}"
}
EOF

    cd "/server/proteus/"

    echo -e "Branch ${app_repo_branch}"
    git branch -m $app_repo_branch
    git add --all
    git add -u

    sleep 1

    app_repo_commit="[S] auto-update [ $app_repo_dist_sel ] @ $NOW"

    echo -e "  ${WHITE}Starting commit ${FUCHSIA}${app_repo_commit}${WHITE}${NORMAL}"

    echo -e "git commit ${app_repo_commit}"
    git commit -S -m "$app_repo_commit"

    sleep 1

    echo -e "  ${WHITE}Starting push ${FUCHSIA}${app_repo_branch}${WHITE}${NORMAL}"
    git push https://${CSI_PAT_GITHUB}@github.com/${GITHUB_NAME}/${app_repo_apt}
    echo -e "git push https://${CSI_PAT_GITHUB}@github.com/${GITHUB_NAME}/${app_repo_apt}"
