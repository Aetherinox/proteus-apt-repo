#!/bin/bash
PATH="/bin:/usr/bin:/sbin:/usr/sbin:/home/$USER/bin"
echo 

##--------------------------------------------------------------------------
#   @author :           aetherinox
#   @script :           Proteus Apt Git
#   @when   :           2024-02-20 18:33:03
#   @url    :           https://github.com/Aetherinox/proteus-git
#
#   requires chmod +x proteus_git.sh
#
##--------------------------------------------------------------------------

##--------------------------------------------------------------------------
#   load secrets file to handle Github rate limiting via a PAF.
#   managed via https://github.com/settings/tokens?type=beta
##--------------------------------------------------------------------------

if [ -f secrets.sh ]; then
. ./secrets.sh
fi

##--------------------------------------------------------------------------
#   requite git
##--------------------------------------------------------------------------

# require git
if ! [ -x "$(command -v git)" ]; then
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install git -y -qq >/dev/null 2>&1
fi

##--------------------------------------------------------------------------
#   ensure we dont have any hanging applications
##--------------------------------------------------------------------------

# sudo pkill -f -9 apt-move
# sudo pkill -f -9 apt-url

##--------------------------------------------------------------------------
#   vars > colors
#
#   tput setab  [1-7]       – Set a background color using ANSI escape
#   tput setb   [1-7]       – Set a background color
#   tput setaf  [1-7]       – Set a foreground color using ANSI escape
#   tput setf   [1-7]       – Set a foreground color
##--------------------------------------------------------------------------

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

##--------------------------------------------------------------------------
#   vars > status messages
##--------------------------------------------------------------------------

STATUS_MISS="${BOLD}${GREYL} MISS ${NORMAL}"
STATUS_SKIP="${BOLD}${GREYL} SKIP ${NORMAL}"
STATUS_OK="${BOLD}${GREEN}  OK  ${NORMAL}"
STATUS_FAIL="${BOLD}${RED} FAIL ${NORMAL}"
STATUS_HALT="${BOLD}${YELLOW} HALT ${NORMAL}"

##--------------------------------------------------------------------------
#   vars > app
##--------------------------------------------------------------------------

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
app_dir=$PWD
app_dir_wd=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
app_dir_repo="incoming/proteus-git/${sys_code}"
app_dir_storage="$app_dir/incoming/proteus-git/${sys_code}"
app_pid_spin=0
app_pid=$BASHPID
app_queue_url=()
app_i=0

##--------------------------------------------------------------------------
#   exports
##--------------------------------------------------------------------------

export DATE=$(date '+%d%m%Y')
export DATE_TS=$(date +%s)
export YEAR=$(date +'%Y')
export TIME=$(date '+%H:%M:%S')
export NOW=$(date '+%m.%d.%Y %H:%M:%S')
export ARGS=$1
export LOGS_DIR="$app_dir/logs"
export LOGS_FILE="$LOGS_DIR/proteus-git-${DATE}.log"
export SECONDS=0

##--------------------------------------------------------------------------
#   lists > github repos
##--------------------------------------------------------------------------

lst_github=(
    'obsidianmd/obsidian-releases'
    'AppOutlet/AppOutlet'
    'bitwarden/clients'
    'shiftkey/desktop'
    'FreeTubeApp/FreeTube'
    'makedeb/makedeb'
)

##--------------------------------------------------------------------------
#   list > packages
##--------------------------------------------------------------------------

lst_packages=(
    'adduser'
    'argon2'
    'apt-move'
    'apt-utils'
    'dialog'
    'firefox'
    'flatpak'
    'gnome-keyring'
    'gnome-keysign'
    'gnome-shell-extension-manager'
    'gpg'
    'gpgconf'
    'gpgv'
    'keyutils'
    'kgpg'
    'libnginx-mod-http-auth-pam'
    'libnginx-mod-http-cache-purge'
    'libnginx-mod-http-dav-ext'
    'libnginx-mod-http-echo'
    'libnginx-mod-http-fancyindex'
    'libnginx-mod-http-geoip'
    'libnginx-mod-http-headers-more-filter'
    'libnginx-mod-http-ndk'
    'libnginx-mod-http-perl'
    'libnginx-mod-http-subs-filter'
    'libnginx-mod-http-uploadprogress'
    'libnginx-mod-http-upstream-fair'
    'libnginx-mod-nchan'
    'libnginx-mod-rtmp'
    'libnginx-mod-stream-geoip'
    'lsb-base'
    'lz4'
    'mysql-client'
    'mysql-common'
    'mysql-server'
    'network-manager-config-connectivity-ubuntu'
    'network-manager-dev'
    'network-manager-gnome'
    'network-manager-openvpn-gnome'
    'network-manager-openvpn'
    'network-manager-pptp-gnome'
    'network-manager-pptp'
    'network-manager'
    'networkd-dispatcher'
    'nginx-common'
    'nginx-confgen'
    'nginx-core'
    'nginx-dev'
    'nginx-doc'
    'nginx-extras'
    'nginx-full'
    'nginx-light'
    'nginx'
    'open-vm-tools-desktop'
    'open-vm-tools-dev'
    'open-vm-tools'
    'php-all-dev'
    'php-amqp'
    'php-amqplib'
    'php-apcu-all-dev'
    'php-apcu'
    'php-ast-all-dev'
    'php-ast'
    'php-bacon-qr-code'
    'php-bcmath'
    'php-brick-math'
    'php-brick-varexporter'
    'php-bz2'
    'php-cas'
    'php-cgi'
    'php-cli'
    'php-code-lts-u2f-php-server'
    'php-common'
    'php-crypt-gpg'
    'php-curl'
    'php-db'
    'php-dba'
    'php-decimal'
    'php-dev'
    'php-ds-all-dev'
    'php-ds'
    'php-email-validator'
    'php-embed'
    'php-enchant'
    'php-excimer'
    'php-faker'
    'php-fpm'
    'php-fxsl'
    'php-gd'
    'php-gearman'
    'php-gettext-languages'
    'php-gmagick-all-dev'
    'php-gmagick'
    'php-gmp'
    'php-gnupg-all-dev'
    'php-gnupg'
    'php-gnupg'
    'php-grpc'
    'php-http'
    'php-igbinary'
    'php-imagick'
    'php-imap'
    'php-inotify'
    'php-interbase'
    'php-intl'
    'php-ldap'
    'php-mailparse'
    'php-maxminddb'
    'php-mbstring'
    'php-mcrypt'
    'php-memcache'
    'php-memcached'
    'php-mongodb'
    'php-msgpack'
    'php-mysql'
    'php-oauth'
    'php-odbc'
    'php-pcov'
    'php-pgsql'
    'php-phpdbg'
    'php-ps'
    'php-pspell'
    'php-psr'
    'php-raphf'
    'php-readline'
    'php-redis'
    'php-rrd'
    'php-smbclient'
    'php-snmp'
    'php-soap'
    'php-solr'
    'php-sqlite3'
    'php-ssh2'
    'php-stomp'
    'php-sybase'
    'php-tideways'
    'php-tidy'
    'php-uopz'
    'php-uploadprogress'
    'php-uuid'
    'php-xdebug'
    'php-xml'
    'php-xmlrpc'
    'php-yac'
    'php-yaml'
    'php-zip'
    'php-zmq'
    'php'
    'snap'
    'snapd'
    'wget'
)

##--------------------------------------------------------------------------
#   list > architectures
##--------------------------------------------------------------------------

lst_arch=(
    'all'
    'amd64'
    'arm64'
)

##--------------------------------------------------------------------------
#   distro
#
#   returns distro information.
##--------------------------------------------------------------------------

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

##--------------------------------------------------------------------------
#   upload to github > precheck
##--------------------------------------------------------------------------

app_run_github_precheck( )
{

    echo -e "  ${GREYL}Registering Github Config Entries${WHITE}"

    git config --global credential.helper store

    # see if repo directory is in safelist for git
    if git config --global --get-all safe.directory | grep -q "$app_dir"; then
        bFoundSafe=true
    fi

    # if new repo, add to safelist
    if ! [ $bFoundSafe ]; then
        git config --global --add safe.directory $app_dir
    fi

    git config --global init.defaultBranch ${app_repo_branch}
    git config --global user.name ${GITHUB_NAME}
    git config --global user.email ${GITHUB_EMAIL}
    ##git config --global pull.rebase true
}

##--------------------------------------------------------------------------
#   check > secrets file doesnt exist
##--------------------------------------------------------------------------

if ! [ -f secrets.sh ]; then
    echo
    echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}secrets.sh file not found${NORMAL}"
    echo -e "  ${BOLD}${WHITE}Must create a ${FUCHSIA}secrets.sh${WHITE} file.${NORMAL}"
    echo -e "  ${BOLD}${WHITE}This file defines things such as your${NORMAL}"
    echo -e "  ${BOLD}${WHITE}GPG key and Github Personal Token.${NORMAL}"
    echo

    printf "  Press any key to abort ... ${NORMAL}"
    read -n 1 -s -r -p ""
    echo
    echo

    set +m
    trap "kill -9 $app_pid 2> /dev/null" `seq 0 15`
    kill $app_pid
    set -m
fi

##--------------------------------------------------------------------------
#   check > gpg key added to .gitignore
##--------------------------------------------------------------------------

checkgit_signing=$( git config --global --get-all user.signingKey )
if [ -z "${checkgit_signing}" ]; then
    echo
    echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}Missing ${YELLOW}user.signingKey${WHITE} in ${YELLOW}/home/${USER}/.gitconfig${NORMAL}"
    echo -e "  ${BOLD}${WHITE}You should have the below entries in your ${FUCHSIA}.gitconfig${WHITE}:${NORMAL}"
    echo
    echo -e "  ${BOLD}${WHITE}    ${GREYL}[user]${NORMAL}"
    echo -e "  ${BOLD}${WHITE}         ${BLUE}signingKey${WHITE} = ${GPG_KEY}${NORMAL}"
    echo
    echo -e "  ${BOLD}${WHITE}    ${GREYL}[commit]${NORMAL}"
    echo -e "  ${BOLD}${WHITE}         ${BLUE}gpgsign${WHITE} = true${NORMAL}"
    echo
    echo -e "  ${BOLD}${WHITE}    ${GREYL}[gpg]${NORMAL}"
    echo -e "  ${BOLD}${WHITE}         ${BLUE}program${WHITE} = gpg${NORMAL}"
    echo
    echo -e "  ${BOLD}${WHITE}    ${GREYL}[tag]${NORMAL}"
    echo -e "  ${BOLD}${WHITE}         ${BLUE}forceSignAnnotated${WHITE} = true${NORMAL}"
    echo

    git config --global gpg.program gpg
    git config --global commit.gpgsign true
    git config --global tag.forceSignAnnotated true
    git config --global user.signingkey ${GPG_KEY}!
    git config --global credential.helper store

    sleep 1

    echo -e "  ${BOLD}${WHITE}Automatically adding these values to your ${FUCHSIA}.gitconfig${WHITE}:${NORMAL}"

    sleep 2

    checkgit_signing=$( git config --global --get-all user.signingKey )
    if [ -z "${checkgit_signing}" ]; then
        echo
        echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}Could not add the above entries to ${YELLOW}/home/${USER}/.gitconfig${NORMAL}"
        echo -e "  ${BOLD}${WHITE}You will need to manually add these entries.${WHITE}:${NORMAL}"
        echo
    else
        echo
        echo -e "  ${BOLD}${GREEN}SUCCESS  ${WHITE}Entries added to ${YELLOW}/home/${USER}/.gitconfig${NORMAL}"
        echo
    fi
fi

##--------------------------------------------------------------------------
#   check > GPG key
#
#   GPG_KEY comes from export GPG_KEY in secrets.sh
##--------------------------------------------------------------------------

if [ -z "${GPG_KEY}" ]; then
    echo
    echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}GPG Key not specified${NORMAL}"
    echo -e "  ${BOLD}${WHITE}Must create a ${FUCHSIA}secrets.sh${WHITE} file and define your GPG key.${NORMAL}"
    echo
    echo -e "  ${BOLD}${WHITE}    ${RED}export ${GREEN}GPG_KEY=${WHITE}XXXXXXXX${NORMAL}"
    echo

    printf "  Press any key to abort ... ${NORMAL}"
    read -n 1 -s -r -p ""
    echo
    echo

    set +m
    trap "kill -9 $app_pid 2> /dev/null" `seq 0 15`
    kill $app_pid
    set -m
fi

##--------------------------------------------------------------------------
#   check > Github / Gitlab API tokens
#
#   Must use the values
#       - GITHUB_API_TOKEN
#       - GITLAB_PA_TOKEN
#
#   Do not rename them, these are the globals recognized by LastVersion
##--------------------------------------------------------------------------

if [ -z "${GITHUB_API_TOKEN}" ] && [ -z "${GITLAB_PA_TOKEN}" ]; then
    echo
    echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}Missing ${YELLOW}API Tokens${WHITE}${NORMAL}"
    echo -e "  ${BOLD}${WHITE}Must create a ${FUCHSIA}secrets.sh${WHITE} file and define an API token${NORMAL}"
    echo -e "  ${BOLD}${WHITE}for either Github or Gitlab.${NORMAL}"
    echo
    echo -e "  ${BOLD}${WHITE}    ${RED}export ${GREEN}GITHUB_API_TOKEN=${WHITE}XXXXXXX${NORMAL}"
    echo -e "  ${BOLD}${WHITE}    ${RED}export ${GREEN}GITLAB_PA_TOKEN=${WHITE}XXXXXXX${NORMAL}"
    echo
    echo -e "  ${BOLD}${WHITE}Without supplying this, you will be rate limited.${NORMAL}"
    echo -e "  ${BOLD}${WHITE}on queries using ${YELLOW}LastVersion${WHITE}${NORMAL}"
    echo

    printf "  Press any key to abort ... ${NORMAL}"
    read -n 1 -s -r -p ""
    echo
    echo

    set +m
    trap "kill -9 $app_pid 2> /dev/null" `seq 0 15`
    kill $app_pid
    set -m
fi

##--------------------------------------------------------------------------
#   func > get version
#
#   returns current version of app
#   converts to human string.
#       e.g.    "1" "2" "4" "0"
#               1.2.4.0
##--------------------------------------------------------------------------

get_version()
{
    ver_join=${app_ver[@]}
    ver_str=${ver_join// /.}
    echo ${ver_str}
}

##--------------------------------------------------------------------------
#   func > version > compare greater than
#
#   this function compares two versions and determines if an update may
#   be available. or the user is running a lesser version of a program.
##--------------------------------------------------------------------------

get_version_compare_gt()
{
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

##--------------------------------------------------------------------------
#   options
#
#       -d      developer mode
#       -h      help menu
#       -n      developer: null run
#       -s      silent mode | logging disabled
#       -t      theme
##--------------------------------------------------------------------------

opt_usage()
{
    echo
    printf "  ${BLUE}${app_title}${NORMAL}\n" 1>&2
    printf "  ${GREYL}${gui_about}${NORMAL}\n" 1>&2
    echo
    printf '  %-5s %-40s\n' "Usage:" "" 1>&2
    printf '  %-5s %-40s\n' "    " "${0} [${GREYL}options${NORMAL}]" 1>&2
    printf '  %-5s %-40s\n\n' "    " "${0} [${GREYL}-h${NORMAL}] [${GREYL}-d${NORMAL}] [${GREYL}-n${NORMAL}] [${GREYL}-s${NORMAL}] [${GREYL}-t THEME${NORMAL}] [${GREYL}-v${NORMAL}]" 1>&2
    printf '  %-5s %-40s\n' "Options:" "" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-d, --dev" "dev mode" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-h, --help" "show help menu" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-g, --githubOnly" "only update github packages" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-s, --sourceOnly" "only update apt source packages" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-n, --nullrun" "dev: null run" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "simulate app installs (no changes)" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-q, --quiet" "quiet mode which disables logging" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-u, --update" "update ${app_file_proteus} executable" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "    --branch" "branch to update from" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-v, --version" "current version of app manager" 1>&2
    echo
    echo
    exit 1
}

while [ $# -gt 0 ]; do
  case "$1" in
    -d|--dev)
            OPT_DEV_ENABLE=true
            echo -e "  ${FUCHSIA}${BLINK}Devmode Enabled${NORMAL}"
            ;;

    -dd*|--dist*)
            if [[ "$1" != *=* ]]; then shift; fi
            OPT_DISTRIBUTION="${1#*=}"
            if [ -z "${OPT_DISTRIBUTION}" ]; then
                echo -e "  ${NORMAL}Must specify a valid distribution"
                echo -e "  ${NORMAL}      Default:  ${YELLOW}${sys_code}${NORMAL}"

                exit 1
            fi
            ;;

    -g*|--githubOnly*)
            OPT_ONLY_GIT=true
            echo "Update Github Only"
            ;;

    -p*|--sourceOnly*)
            OPT_ONLY_SRC=true
            echo "Update Source Packages Only"
            ;;

    -h*|--help*)
            opt_usage
            ;;

    -b*|--branch*)
            if [[ "$1" != *=* ]]; then shift; fi
            OPT_BRANCH="${1#*=}"
            if [ -z "${OPT_BRANCH}" ]; then
                echo -e "  ${NORMAL}Must specify a valid branch"
                echo -e "  ${NORMAL}      Default:  ${YELLOW}${app_repo_branch}${NORMAL}"

                exit 1
            fi
            ;;

    -n|--nullrun)
            OPT_DEV_NULLRUN=true
            echo -e "  ${FUCHSIA}${BLINK}Devnull Enabled${NORMAL}"
            ;;

    -q|--quiet)
            OPT_NOLOG=true
            echo -e "  ${FUCHSIA}${BLINK}Logging Disabled{NORMAL}"
            ;;

    -u|--update)
            OPT_UPDATE=true
            ;;

    -v|--version)
            echo
            echo -e "  ${GREEN}${BOLD}${app_title}${NORMAL} - v$(get_version)${NORMAL}"
            echo -e "  ${GREYL}${BOLD}${app_repo_url}${NORMAL}"
            echo -e "  ${GREYL}${BOLD}${OS} | ${OS_VER}${NORMAL}"
            echo
            exit 1
            ;;
    *)
            opt_usage
            ;;
  esac
  shift
done

##--------------------------------------------------------------------------
#   vars > active repo branch
##--------------------------------------------------------------------------

app_repo_branch_sel=$( [[ -n "$OPT_BRANCH" ]] && echo "$OPT_BRANCH" || echo "$app_repo_branch"  )

##--------------------------------------------------------------------------
#   distribution
#   jammy, lunar, focal, noble, etc
##--------------------------------------------------------------------------

app_repo_dist_sel=$( [[ -n "$OPT_DISTRIBUTION" ]] && echo "$OPT_DISTRIBUTION" || echo "$sys_code"  )

##--------------------------------------------------------------------------
#   line > comment
#
#   comment REGEX FILE [COMMENT-MARK]
#   comment "skip-grant-tables" "/etc/mysql/my.cnf"
##--------------------------------------------------------------------------

line_comment()
{
    local regx="${1:?}"
    local targ="${2:?}"
    local mark="${3:-#}"
    sudo sed -ri "s:^([ ]*)($regx):\\1$mark\\2:" "$targ"
}

##--------------------------------------------------------------------------
#   line > uncomment
#
#   uncomment REGEX FILE [COMMENT-MARK]
#   uncomment "skip-grant-tables" "/etc/mysql/my.cnf"
##--------------------------------------------------------------------------

line_uncomment()
{
    local regx="${1:?}"
    local targ="${2:?}"
    local mark="${3:-#}"
    sudo sed -ri "s:^([ ]*)[$mark]+[ ]?([ ]*$regx):\\1\\2:" "$targ"
}

##--------------------------------------------------------------------------
#   func > logs > begin
##--------------------------------------------------------------------------

Logs_Begin()
{
    if [ $OPT_NOLOG ] ; then
        echo
        echo
        printf '%-50s %-5s' "    Logging for this package has been disabled." ""
        echo
        echo
        sleep 3
    else
        mkdir -p $LOGS_DIR
        LOGS_PIPE=${LOGS_FILE}.pipe

        # get name of display in use
        local display=":$(ls /tmp/.X11-unix/* | sed 's#/tmp/.X11-unix/X##' | head -n 1)"

        # get user using display
        local user=$(who | grep '('$display')' | awk '{print $1}' | head -n 1)

        if ! [[ -p $LOGS_PIPE ]]; then
            mkfifo -m 775 $LOGS_PIPE
            printf "%-50s %-5s\n" "${TIME}      Creating new pipe ${LOGS_PIPE}" | tee -a "${LOGS_FILE}" >/dev/null
        fi

        LOGS_OBJ=${LOGS_FILE}
        exec 3>&1
        tee -a ${LOGS_OBJ} <$LOGS_PIPE >&3 &
        app_pid_tee=$!
        exec 1>$LOGS_PIPE
        PIPE_OPENED=1

        printf "%-50s %-5s\n" "${TIME}      Logging to ${LOGS_OBJ}" | tee -a "${LOGS_FILE}" >/dev/null

        printf "%-50s %-5s\n" "${TIME}      Software  : ${app_title}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-50s %-5s\n" "${TIME}      Version   : v$(get_version)" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-50s %-5s\n" "${TIME}      Process   : $$" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-50s %-5s\n" "${TIME}      OS        : ${OS}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-50s %-5s\n" "${TIME}      OS VER    : ${OS_VER}" | tee -a "${LOGS_FILE}" >/dev/null

        printf "%-50s %-5s\n" "${TIME}      DATE      : ${DATE}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-50s %-5s\n" "${TIME}      TIME      : ${TIME}" | tee -a "${LOGS_FILE}" >/dev/null

    fi
}

##--------------------------------------------------------------------------
#   func > logs > finish
##--------------------------------------------------------------------------

Logs_Finish()
{
    if [ ${PIPE_OPENED} ] ; then
        exec 1<&3
        sleep 0.2
        ps --pid $app_pid_tee >/dev/null
        if [ $? -eq 0 ] ; then
            # using $(wait $app_pid_tee) would be better
            # however, some commands leave file descriptors open
            sleep 1
            kill $app_pid_tee >> $LOGS_FILE 2>&1
        fi

        printf "%-50s %-15s\n" "${TIME}      Destroying Pipe ${LOGS_PIPE} (${app_pid_tee})" | tee -a "${LOGS_FILE}" >/dev/null

        rm $LOGS_PIPE
        unset PIPE_OPENED
    fi

    duration=$SECONDS
    elapsed="$(($duration / 60)) minutes and $(($duration % 60)) seconds elapsed."

    printf "%-50s %-15s\n" "${TIME}      User Input: OnClick ......... Exit App" | tee -a "${LOGS_FILE}" >/dev/null
    printf "%-50s %-15s\n\n\n\n" "${TIME}      ${elapsed}" | tee -a "${LOGS_FILE}" >/dev/null
}

##--------------------------------------------------------------------------
#   Begin Logging
##--------------------------------------------------------------------------

Logs_Begin

##--------------------------------------------------------------------------
#   Cache Sudo Password
#
#   require normal user sudo authentication for certain actions
##--------------------------------------------------------------------------

if [[ $EUID -ne 0 ]]; then
    sudo -k # make sure to ask for password on next sudo
    if sudo true && [ -n "${USER}" ]; then
        printf "\n%-50s %-5s\n\n" "${TIME}      SUDO [SIGN-IN]: Welcome, ${USER}" | tee -a "${LOGS_FILE}" >/dev/null
    else
        printf "\n%-50s %-5s\n\n" "${TIME}      SUDO Failure: Wrong Password x3" | tee -a "${LOGS_FILE}" >/dev/null
        exit 1
    fi
else
    if [ -n "${USER}" ]; then
        printf "\n%-50s %-5s\n\n" "${TIME}      SUDO [EXISTING]: $USER" | tee -a "${LOGS_FILE}" >/dev/null
    fi
fi

##--------------------------------------------------------------------------
#   func > spinner animation
##--------------------------------------------------------------------------

spin()
{
    spinner="-\\|/-\\|/"

    while :
    do
        for i in `seq 0 7`
        do
            echo -n "${spinner:$i:1}"
            echo -en "\010"
            sleep 0.4
        done
    done
}

##--------------------------------------------------------------------------
#   func > spinner > halt
##--------------------------------------------------------------------------

spinner_halt()
{
    if ps -p $app_pid_spin > /dev/null
    then
        kill -9 $app_pid_spin 2> /dev/null
        printf "\n%-50s %-5s\n" "${TIME}      KILL Spinner: PID (${app_pid_spin})" | tee -a "${LOGS_FILE}" >/dev/null
    fi
}

##--------------------------------------------------------------------------
#   func > cli selection menu
##--------------------------------------------------------------------------

cli_options()
{
    opts_show()
    {
        local it=$( echo $1 )
        for i in ${!CHOICES[*]}; do
            if [[ "$i" == "$it" ]]; then
                tput rev
                printf '\e[1;33m'
                printf '%4d. \e[1m\e[33m %s\t\e[0m\n' $i "${LIME_YELLOW}  ${CHOICES[$i]}  "
                tput sgr0
            else
                printf '\e[1;33m'
                printf '%4d. \e[1m\e[33m %s\t\e[0m\n' $i "${LIME_YELLOW}  ${CHOICES[$i]}  "
            fi
            tput cuf 2
        done
    }

    tput civis
    it=0
    tput cuf 2

    opts_show $it

    while true; do
        read -rsn1 key
        local escaped_char=$( printf "\u1b" )
        if [[ $key == $escaped_char ]]; then
            read -rsn2 key
        fi

        tput cuu ${#CHOICES[@]} && tput ed
        tput sc

        case $key in
            '[A' | '[C' )
                it=$(($it-1));;
            '[D' | '[B')
                it=$(($it+1));;
            '' )
                return $it && exit;;
        esac

        local min_len=0
        local farr_len=$(( ${#CHOICES[@]}-1))
        if [[ "$it" -lt "$min_len" ]]; then
            it=$(( ${#CHOICES[@]}-1 ))
        elif [[ "$it" -gt "$farr_len"  ]]; then
            it=0
        fi

        opts_show $it

    done
}

##--------------------------------------------------------------------------
#   func > cli question
#
#   used for command-line to prompt the user with a question
##--------------------------------------------------------------------------

cli_question( )
{
    local syntax def response

    while true; do

        # end argument determines type of syntax
        if [ "${2:-}" = "Y" ]; then
            syntax="Y / n"
            def=Y
        elif [ "${2:-}" = "N" ]; then
            syntax="y / N"
            def=N
        else
            syntax="Y / N"
            def=
        fi

        #printf '%-60s %13s %-5s' "    $1 " "${YELLOW}[$syntax]${NORMAL}" ""
        echo -n "$1 [$syntax] "

        read response </dev/tty

        # NULL response uses default
        if [ -z "$response" ]; then
            response=$def
        fi

        # validate response
        case "$response" in
            Y|y|yes|YES)
                return 0
                ;;
            N|n|no|NO)
                return 1
                ;;
        esac

    done
}

##--------------------------------------------------------------------------
#   func > open url
#
#   opening urls in bash can be wonky as hell. just doing it the manual
#   way to ensure a browser gets opened.
##--------------------------------------------------------------------------

open_url()
{
   local URL="$1"
   xdg-open $URL || firefox $URL || sensible-browser $URL || x-www-browser $URL || gnome-open $URL
}

##--------------------------------------------------------------------------
#   func > cmd title
##--------------------------------------------------------------------------

title()
{
    printf '%-57s %-5s' "  ${1}" ""
    sleep 0.3
}

##--------------------------------------------------------------------------
#   func > begin action
##--------------------------------------------------------------------------

begin()
{
    # start spinner
    spin &

    # spinner PID
    app_pid_spin=$!

    printf "%-50s %-5s\n\n" "${TIME}      NEW Spinner: PID (${app_pid_spin})" | tee -a "${LOGS_FILE}" >/dev/null

    # kill spinner on any signal
    trap "kill -9 $app_pid_spin 2> /dev/null" `seq 0 15`

    printf '%-50s %-5s' "  ${1}" ""

    sleep 0.3
}

##--------------------------------------------------------------------------
#   func > finish action
#
#   this func supports opening a url at the end of the installation
#   however the command needs to have
#       finish "${1}"
##--------------------------------------------------------------------------

finish()
{
    arg1=${1}

    spinner_halt

    # if arg1 not empty
    if ! [ -z "${arg1}" ]; then
        assoc_uri="${get_docs_uri[$arg1]}"
        app_queue_url+=($assoc_uri)
    fi
}

##--------------------------------------------------------------------------
#   func > exit action
##--------------------------------------------------------------------------

exit()
{
    finish
    clear
}

##--------------------------------------------------------------------------
#   func > env path (add)
#
#   creates a new file inside /etc/profile.d/ which includes the new
#   proteus bin folder.
#
#   proteus-aptget.sh will house the path needed for the script to run
#   anywhere with an entry similar to:
#
#       export PATH="/home/aetherinox/bin:$PATH"
##--------------------------------------------------------------------------

envpath_add()
{
    local file_env=/etc/profile.d/proteus-git.sh
    if [ "$2" = "force" ] || ! echo $PATH | $(which egrep) -q "(^|:)$1($|:)" ; then
        if [ "$2" = "after" ] ; then
            echo 'export PATH="$PATH:'$1'"' | sudo tee $file_env > /dev/null
        else
            echo 'export PATH="'$1':$PATH"' | sudo tee $file_env > /dev/null
        fi
    fi
}

##--------------------------------------------------------------------------
#   func > app update
#
#   updates the /home/USER/bin/proteus file which allows proteus to be
#   ran from anywhere.
##--------------------------------------------------------------------------

app_update()
{
    local repo_branch=$([ "${1}" ] && echo "${1}" || echo "${app_repo_branch}" )
    local branch_uri="${app_script/BRANCH/"$repo_branch"}"
    local IsSilent=${2}

    begin "Updating from branch [${repo_branch}]"

    sleep 1
    echo

    printf '%-50s %-5s' "    |--- Downloading update" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo wget -O "${app_file_proteus}" -q "$branch_uri" >> $LOGS_FILE 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    printf '%-50s %-5s' "    |--- Set ownership to ${USER}" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo chgrp ${USER} ${app_file_proteus} >> $LOGS_FILE 2>&1
        sudo chown ${USER} ${app_file_proteus} >> $LOGS_FILE 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    printf '%-50s %-5s' "    |--- Set perms to u+x" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo chmod u+x ${app_file_proteus} >> $LOGS_FILE 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    echo

    sleep 2
    echo -e "  ${BOLD}${GREEN}Update Complete!${NORMAL}" >&2
    sleep 2

    finish
}

##--------------------------------------------------------------------------
#   func > app update
#
#   updates the /home/USER/bin/proteus file which allows proteus to be
#   ran from anywhere.
##--------------------------------------------------------------------------

if [ "$OPT_UPDATE" = true ]; then
    app_update ${app_repo_branch_sel}
fi

##--------------------------------------------------------------------------
#   func > first time setup
#
#   this is the default func executed when script is launched to make sure
#   end-user has all the required libraries.
#
#   since we're working on other distros, add curl and wget into the mix
#   since some distros don't include these.
#
#   [ GPG KEY / APT REPO ]
#
#   NOTE:   can be removed via:
#               sudo rm -rf /etc/apt/sources.list.d/aetherinox*list
#
#           gpg ksy stored in:
#               /usr/share/keyrings/aetherinox-proteus-apt-repo-archive.gpg
#               sudo rm -rf /usr/share/keyrings/aetherinox*gpg
#
#   as of 1.0.0.3-alpha, deprecated apt-key method removed for adding
#   gpg key. view readme for new instructions. registered repo now
#   contains two files
#       -   trusted gpg key:        aetherinox-proteus-apt-repo-archive.gpg
#       -   source .list:           /etc/apt/sources.list.d/aetherinox*list
##--------------------------------------------------------------------------

app_setup()
{

    clear

    local bMissingAptMove=false
    local bMissingAptUrl=false
    local bMissingCurl=false
    local bMissingWget=false
    local bMissingTree=false
    local bMissingGPG=false
    local bMissingGChrome=false
    local bMissingMFirefox=false
    local bMissingRepo=false
    local bMissingReprepro=false
    local bGPGLoaded=false

    # require whiptail
    if ! [ -x "$(command -v apt-move)" ]; then
        bMissingAptMove=true
    fi

    # require whiptail
    if ! [ -x "$(command -v apt-url)" ]; then
        bMissingAptUrl=true
    fi

    # require curl
    if ! [ -x "$(command -v curl)" ]; then
        bMissingCurl=true
    fi

    # require wget
    if ! [ -x "$(command -v wget)" ]; then
        bMissingWget=true
    fi

    # require tree
    if ! [ -x "$(command -v tree)" ]; then
        bMissingTree=true
    fi

    # require reprepro
    if ! [ -x "$(command -v reprepro)" ]; then
        bMissingReprepro=true
    fi

    ##--------------------------------------------------------------------------
    #   Missing proteus-apt-repo gpg key
    #
    #   NOTE:   apt-key has been deprecated
    #           sudo add-apt-repository -y "deb [arch=amd64] https://raw.githubusercontent.com/${app_repo_author}/${app_repo_apt}/master focal main" >> $LOGS_FILE 2>&1
    ##--------------------------------------------------------------------------

    if ! [ -f "/usr/share/keyrings/${app_repo_apt_pkg}.gpg" ]; then
        bMissingGPG=true
    fi

    ##--------------------------------------------------------------------------
    #   Missing browsers .list (google chrome, firefox)
    ##--------------------------------------------------------------------------

    if ! [ -f "/etc/apt/sources.list.d/google-chrome.list" ]; then
        bMissingGChrome=true
    fi

    if ! [ -f "/etc/apt/sources.list.d/mozilla.list" ]; then
        bMissingMFirefox=true
    fi

    ##--------------------------------------------------------------------------
    #   Missing proteus-apt-repo .list
    ##--------------------------------------------------------------------------

    if ! [ -f "/etc/apt/sources.list.d/${app_repo_apt_pkg}.list" ]; then
        bMissingRepo=true
    fi

    # Check if contains title
    # If so, called from another function
    if [ "$bMissingAptMove" = true ] || [ "$bMissingAptUrl" = true ] || [ "$bMissingCurl" = true ] || [ "$bMissingWget" = true ] || [ "$bMissingTree" = true ] || [ "$bMissingGPG" = true ] ||  [ "$bMissingGChrome" = true ]  || [ "$bMissingMFirefox" = true ] || [ "$bMissingRepo" = true ] || [ "$bMissingReprepro" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        echo
        title "Addressing Dependencies ..."
        echo
        sleep 1
    fi

    ##--------------------------------------------------------------------------
    #   find a gpg key that can be imported
    #   maybe later add a loop to check for multiple.
    ##--------------------------------------------------------------------------

    if [ -z "${GPG_KEY}" ]; then
        echo
        echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}GPG Key not specified${NORMAL}"
        echo -e "  ${BOLD}${WHITE}Must create a ${FUCHSIA}secrets.sh${WHITE} file and define your GPG key.${NORMAL}"
        echo
        echo -e "  ${BOLD}${WHITE}    ${RED}export ${GREEN}GPG_KEY=${WHITE}XXXXXXXX${NORMAL}"
        echo

        printf "  Press any key to abort ... ${NORMAL}"
        read -n 1 -s -r -p ""
        echo
        echo

        set +m
        trap "kill -9 $app_pid 2> /dev/null" `seq 0 15`
        kill $app_pid
        set -m
    else
        gpg_id=$( gpg --list-secret-keys --keyid-format=long | grep $GPG_KEY )
        if [[ $? == 0 ]]; then 
            echo
            echo -e "  ${WHITE}GPG key ${GREEN}${GPG_KEY}${NORMAL} found."
            echo

            bGPGLoaded=true

            sleep 5
        else
            echo
            echo
            echo -e "  ${ORANGE}Error${WHITE}"
            echo -e "  "
            echo -e "  ${WHITE}Specified GPG key ${YELLOW}${GPG_KEY}${NORMAL} is not imported into GPG."
            echo -e "  ${WHITE}Searching ${YELLOW}$app_dir/.gpg/${NORMAL} for a GPG key to import."
            echo
            echo

            printf "  Press any key to continue ... ${NORMAL}"
            read -n 1 -s -r -p ""
            echo

            if [ -f $app_dir/.gpg/*.gpg ]; then
                gpg_file=$app_dir/.gpg/*.gpg
                gpg --import $gpg_file
                bGPGLoaded=true
            fi
        fi
    fi

    ##--------------------------------------------------------------------------
    #   missing gpg key after searching numerous places, including .gpg folder
    #
    #   bGPGLoaded      true if one of two conditions are met
    #                   1. gpg --list-keys KEY_ID found
    #                   2. found a .gpg file in the ./gpg folder
    ##--------------------------------------------------------------------------

    if [ "$bGPGLoaded" = false ]; then
        echo
        echo
        echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}Private GPG key not found${NORMAL}"
        echo
        echo -e "  ${WHITE}You must have a private GPG key imported to use this program.${NORMAL}"
        echo -e "  ${WHITE}Your private GPG key is used to sign commits and the deb package${NORMAL}"
        echo -e "  ${WHITE}repositories that you upload.${NORMAL}"
        echo
        echo -e "  ${WHITE}You must either add a private .gpg keyfile to the folder:${NORMAL}"
        echo -e "       ${YELLOW}$app_dir/.gpg/${NORMAL}"
        echo -e "  ${WHITE}Or manually import a GPG key to your system's GPG keyring${NORMAL}"
        echo

        printf "  Press any key to abort ... ${NORMAL}"
        read -n 1 -s -r -p ""
        echo
        echo

        set +m
        trap "kill -9 $app_pid 2> /dev/null" `seq 0 15`
        kill $app_pid
        set -m
    fi


    ##--------------------------------------------------------------------------
    #   missing curl
    ##--------------------------------------------------------------------------

    if [ "$bMissingCurl" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing curl package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-50s %-5s' "    |--- Adding curl package" ""
        sleep 0.5
    
        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install curl -y -qq >> /dev/null 2>&1
        fi
    
        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing wget
    ##--------------------------------------------------------------------------

    if [ "$bMissingWget" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing wget package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-50s %-5s' "    |--- Adding wget package" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install wget -y -qq >> /dev/null 2>&1
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing tree
    ##--------------------------------------------------------------------------

    if [ "$bMissingTree" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing tree package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-50s %-5s' "    |--- Adding tree package" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install tree -y -qq >> /dev/null 2>&1
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing gpg trusted file
    #
    #   bMissingGPG     File /usr/share/keyrings/${app_repo_apt_pkg}.gpg not found
    ##--------------------------------------------------------------------------

    if [ "$bMissingGPG" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Adding ${app_repo_author} GPG key: [https://github.com/${app_repo_author}.gpg]" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-50s %-5s' "    |--- Adding github.com/${app_repo_author}.gpg" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo wget -qO - "https://github.com/${app_repo_author}.gpg" | sudo gpg --batch --yes --dearmor -o "/usr/share/keyrings/${app_repo_apt_pkg}.gpg" >/dev/null
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi


    ##--------------------------------------------------------------------------
    #   missing google chrome
    #
    #   add google source repo so that chrome can be downloaded using apt-get
    ##--------------------------------------------------------------------------

    if [ "$bMissingGChrome" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Registering Chrome: /etc/apt/sources.list.d/google-chrome.list" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-50s %-5s' "    |--- Registering Chrome" ""
        sleep 0.5

        sudo install -d -m 0755 /etc/apt/keyrings

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo wget -qO - "https://dl-ssl.google.com/linux/linux_signing_key.pub" | sudo gpg --batch --yes --dearmor -o "/etc/apt/keyrings/dl.google.com.gpg" >/dev/null
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/dl.google.com.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
        fi

        # change priority
        echo 'Package: * Pin: origin dl.google.com Pin-Priority: 1000' | sudo tee /etc/apt/preferences.d/google-chrome >/dev/null

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"

        printf "%-50s %-5s\n" "${TIME}      Updating user repo list with apt-get update" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-50s %-5s' "    |--- Updating repo list" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >/dev/null
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing mozilla repo
    #
    #   add mozilla source repo so that firefox can be downloaded using apt-get
    #   instructions via:
    #       https://support.mozilla.org/en-US/kb/install-firefox-linux#w_install-firefox-deb-package-for-debian-based-distributions
    ##--------------------------------------------------------------------------

    if [ "$bMissingMFirefox" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Registering Mozilla: /etc/apt/sources.list.d/mozilla.list" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-50s %-5s' "    |--- Registering Mozilla" ""
        sleep 0.5

        sudo install -d -m 0755 /etc/apt/keyrings
        sudo wget -qO - "https://packages.mozilla.org/apt/repo-signing-key.gpg" | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list >/dev/null
        fi

        # change priority
        echo 'Package: * Pin: origin packages.mozilla.org Pin-Priority: 1000' | sudo tee /etc/apt/preferences.d/mozilla >/dev/null

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"

        printf "%-50s %-5s\n" "${TIME}      Updating user repo list with apt-get update" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-50s %-5s' "    |--- Updating repo list" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >/dev/null
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing proteus apt repo
    ##--------------------------------------------------------------------------

    if [ "$bMissingRepo" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Registering ${app_repo_apt}: https://raw.githubusercontent.com/${app_repo_author}/${app_repo_apt}/${app_repo_branch}" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-50s %-5s' "    |--- Registering ${app_repo_apt}" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/${app_repo_apt_pkg}.gpg] https://raw.githubusercontent.com/${app_repo_author}/${app_repo_apt}//${app_repo_branch} $(lsb_release -cs) ${app_repo_branch}" | sudo tee /etc/apt/sources.list.d/${app_repo_apt_pkg}.list >/dev/null
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"

        printf "%-50s %-5s\n" "${TIME}      Updating user repo list with apt-get update" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-50s %-5s' "    |--- Updating repo list" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >/dev/null
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   install proteus-git in /home/$USER/bin/proteus-git
    ##--------------------------------------------------------------------------

    if ! [ -f "$app_file_proteus" ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing ${app_title}" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-50s %-5s' "    |--- Installing ${app_title}" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            mkdir -p "$app_dir_home"

            local branch_uri="${app_script/BRANCH/"$app_repo_branch_sel"}"
            sudo wget -O "${app_file_proteus}" -q "$branch_uri" >> $LOGS_FILE 2>&1
            sudo chgrp ${USER} ${app_file_proteus} >> $LOGS_FILE 2>&1
            sudo chown ${USER} ${app_file_proteus} >> $LOGS_FILE 2>&1
            sudo chmod u+x ${app_file_proteus} >> $LOGS_FILE 2>&1
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi


    ##--------------------------------------------------------------------------
    #   missing apt-move
    ##--------------------------------------------------------------------------

    if [ "$bMissingAptMove" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing apt-move package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-50s %-5s' "    |--- Adding apt-move package" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install apt-move -y -qq >> /dev/null 2>&1
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   missing apt-url
    ##--------------------------------------------------------------------------

    if [ "$bMissingAptUrl" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing apt-url package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-50s %-5s' "    |--- Adding apt-url package" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install apt-url -y -qq >> /dev/null 2>&1
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi


    ##--------------------------------------------------------------------------
    #   missing reprepro
    ##--------------------------------------------------------------------------

    if [ "$bMissingReprepro" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing reprepro package" | tee -a "${LOGS_FILE}" >/dev/null

        printf '%-50s %-5s' "    |--- Adding reprepro package" ""
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install reprepro -y -qq >> /dev/null 2>&1
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    ##--------------------------------------------------------------------------
    #   add env path /home/$USER/bin/
    ##--------------------------------------------------------------------------

    envpath_add '$HOME/bin'

    sleep 0.5

}
app_setup

##--------------------------------------------------------------------------
#   .git folder doesnt exist
##--------------------------------------------------------------------------

if [ ! -d .git ]; then

    echo
    echo
    echo -e "  ${ORANGE}Error${WHITE}"
    echo -e "  "
    echo -e "  ${WHITE}Folder ${YELLOW}.git${NORMAL} does not exist."
    echo -e "  ${WHITE}Must clone the ${YELLOW}proteus-apt-repo${NORMAL} first."
    echo
    echo

    app_run_github_precheck

    git init --initial-branch=${app_repo_branch}
    git add .;git commit -m'Proteus-Git Setup'
    git remote add origin https://github.com/Aetherinox/proteus-apt-repo.git
    git pull origin ${app_repo_branch} --allow-unrelated-histories
fi

##--------------------------------------------------------------------------
#   output some logging
##--------------------------------------------------------------------------

[ -n "${OPT_DEV_ENABLE}" ] && printf "%-50s %-5s\n" "${TIME}      Notice: Dev Mode Enabled" | tee -a "${LOGS_FILE}" >/dev/null
[ -z "${OPT_DEV_ENABLE}" ] && printf "%-50s %-5s\n" "${TIME}      Notice: Dev Mode Disabled" | tee -a "${LOGS_FILE}" >/dev/null

[ -n "${OPT_DEV_NULLRUN}" ] && printf "%-50s %-5s\n\n" "${TIME}      Notice: Dev Option: 'No Actions' Enabled" | tee -a "${LOGS_FILE}" >/dev/null
[ -z "${OPT_DEV_NULLRUN}" ] && printf "%-50s %-5s\n\n" "${TIME}      Notice: Dev Option: 'No Actions' Disabled" | tee -a "${LOGS_FILE}" >/dev/null

##--------------------------------------------------------------------------
#   associated app urls
#
#   when certain apps are installed, we may want to open a browser window
#   so that the user can get a better understanding of where to find
#   resources for that app.
#
#   not all apps have to have a website, as that would get annoying.
##--------------------------------------------------------------------------

declare -A get_docs_uri
get_docs_uri=(
    ["$app_dialog"]='http://url.here'
)

##--------------------------------------------------------------------------
#   header
##--------------------------------------------------------------------------

show_header()
{
    clear

    sleep 0.3

    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo -e " ${GREEN}${BOLD} ${app_title} - v$(get_version)${NORMAL}${MAGENTA}"
    echo
    echo -e "  This is a package which handles the Proteus App Manager behind"
    echo -e "  the scene by grabbing from the list of registered packages"
    echo -e "  and adding them to the queue to be updated."
    echo

    printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}GPG KEY ${NORMAL}" "${BOLD}${FUCHSIA} $GPG_KEY ${NORMAL}"
    echo

    if [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}PID ${NORMAL}" "${BOLD}${FUCHSIA} $$ ${NORMAL}"
        printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}USER ${NORMAL}" "${BOLD}${FUCHSIA} ${USER} ${NORMAL}"
        printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}APPS ${NORMAL}" "${BOLD}${FUCHSIA} ${app_i} ${NORMAL}"
        printf '%-35s %-40s\n' "  ${BOLD}${DEVGREY}DEV ${NORMAL}" "${BOLD}${FUCHSIA} $([ -n "${OPT_DEV_ENABLE}" ] && echo "Enabled" || echo "Disabled" ) ${NORMAL}"
        echo
    fi

    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo

    sleep 0.3

    printf "%-50s %-5s\n" "${TIME}      Successfully loaded ${app_i} packages" | tee -a "${LOGS_FILE}" >/dev/null
    printf "%-50s %-5s\n" "${TIME}      Waiting for user input ..." | tee -a "${LOGS_FILE}" >/dev/null
}

##--------------------------------------------------------------------------
#   app > run > apt source packages
#
#   updates apt source packages for the distro being used
##--------------------------------------------------------------------------

app_run_dl_aptsrc()
{
    ##--------------------------------------------------------------------------
    #   sort alphabetically
    ##--------------------------------------------------------------------------

    IFS=$'\n' lst_pkgs_sorted=($(sort <<<"${lst_packages[*]}"))
    unset IFS

    ##--------------------------------------------------------------------------
    #   add countdown to the num of packages to install
    #   add +1 so we're not hitting 0
    ##--------------------------------------------------------------------------

    count=${#lst_pkgs_sorted[@]}
    (( count++ ))

    begin "Downloading Packages [ $count ]"
    echo

    mkdir -p ${app_dir_storage}/{all,amd64,arm64}

    ##--------------------------------------------------------------------------
    #   loop sorted packages
    ##--------------------------------------------------------------------------

    for i in "${!lst_pkgs_sorted[@]}"; do
        pkg=${lst_pkgs_sorted[$i]}

        for j in "${!lst_arch[@]}"; do
            #   returns arch
            #   amd64, arm64, i386, all
            arch=${lst_arch[$j]}
            
            #   package:arch
            local pkg_arch="$pkg:$arch"

            ##--------------------------------------------------------------------------
            #   download "package:arch"
            #   
            #   originally apt-get download was utilized, however it has a weird bug
            #   where certain files saved will have a colon in the filename, which
            #   will set the filename to include %3a
            #   
            #   to combat this, we will use wget to download the file since this
            #   doesnt seem to have the issue.
            #   apt download "$pkg_arch" >> $LOGS_FILE 2>&1
            #   
            #   http://us.archive.ubuntu.com/ubuntu/pool/universe/d/<package>/<package>_1.x.x-x_<arch>.deb
            #   app_url=$(sudo ./apt-url "$pkg_arch" | tail -n 1 )
            #   
            ##--------------------------------------------------------------------------

            #   <package>_1.x.x-x_<arch>.deb
            query=$( sudo apt-url "$pkg_arch" )
            app_filename=$( echo "$query" | head -n 1; )
            app_url=$( echo "$query" | tail -n 1; )

            sudo pkill -9 "reprepro"
            if [ -f "$app_dir/db/lockfile" ]; then
                sudo rm "$app_dir/db/lockfile"
            fi

            wget "$app_url" -q

            if [[ -f "$app_dir/$app_filename" ]]; then

                ##--------------------------------------------------------------------------
                #   architecture > all
                ##--------------------------------------------------------------------------

                if [[ "$arch" == "all" ]] && [[ $app_filename == *all.deb ]]; then
                    printf ' %-25s %-60s %-5s' "    ${GREYL}|---${NORMAL} ${YELLOW}[ $count ]${NORMAL}" "${FUCHSIA}${BOLD}Get ${app_filename:0:35}...${NORMAL}" "" 1>&2
                    mv "$app_dir/$app_filename" "$app_dir_storage/all/"
                    echo -e "[ ${STATUS_OK} ]"

                    if [ -n "${bRep}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then
                        #   full path to deb package
                        deb_package="$app_dir_repo/$arch/$app_filename"
                        reprepro -V \
                            --section utils \
                            --component main \
                            --priority 0 \
                            includedeb $app_repo_dist_sel "$deb_package"
                    fi

                    echo

                ##--------------------------------------------------------------------------
                #   architecture > amd64
                ##--------------------------------------------------------------------------

                elif [[ "$arch" == "amd64" ]] && [[ $app_filename == *amd64.deb ]]; then
                    printf ' %-25s %-60s %-5s' "    ${GREYL}|---${NORMAL} ${YELLOW}[ $count ]${NORMAL}" "${FUCHSIA}${BOLD}Get ${app_filename:0:35}...${NORMAL}" "" 1>&2
                    mv "$app_dir/$app_filename" "$app_dir_storage/amd64/"
                    echo -e "[ ${STATUS_OK} ]"

                    if [ -n "${bRep}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then
                        #   full path to deb package
                        deb_package="$app_dir_repo/$arch/$app_filename"
                        reprepro -V \
                            --section utils \
                            --component main \
                            --priority 0 \
                            --architecture $arch \
                            includedeb $app_repo_dist_sel "$deb_package"
                    fi

                    echo

                ##--------------------------------------------------------------------------
                #   architecture > arm64
                ##--------------------------------------------------------------------------

                elif [[ "$arch" == "arm64" ]] && [[ $app_filename == *arm64.deb ]]; then
                    printf ' %-25s %-60s %-5s' "    ${GREYL}|---${NORMAL} ${YELLOW}[ $count ]${NORMAL}" "${FUCHSIA}${BOLD}Get ${app_filename:0:35}...${NORMAL}" "" 1>&2
                    mv "$app_dir/$app_filename" "$app_dir_storage/arm64/"
                    echo -e "[ ${STATUS_OK} ]"

                    if [ -n "${bRep}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then
                        #   full path to deb package
                        deb_package="$app_dir_repo/$arch/$app_filename"
                        reprepro -V \
                            --section utils \
                            --component main \
                            --priority 0 \
                            --architecture $arch \
                            includedeb $app_repo_dist_sel "$deb_package"
                    fi

                    echo

                ##--------------------------------------------------------------------------
                #   certain packages will output an *amd64 or *arm64 file when calling
                #   the "all" architecture, which means you'll have double the files.
                #
                #   delete the left-over files since we already have them.
                ##--------------------------------------------------------------------------

                else
                    rm "$app_dir/$app_filename"
                fi

                sleep 1

            fi
        done

        (( count-- ))
        echo

    done

}

##--------------------------------------------------------------------------
#   app > run > github
##--------------------------------------------------------------------------

app_run_dl_gh()
{
    count=${#lst_github[@]}

    begin "Downloading Github Packages [ $count ]"
    echo

    mkdir -p ${app_dir_storage}/{all,amd64,arm64}

    #   loop github URLs
    for i in "${!lst_github[@]}"
    do
        repo=${lst_github[$i]}

        #   (?:\b|_)(?:amd64|arm64|$app_repo_dist_sel)\b.*\.deb$
        #   (?:\b|_)(?:amd64|arm64|$app_repo_dist_sel).*\b.*\.deb$
        lst_releases=($( lastversion --pre --assets $repo --filter "(?:\b|_)(?:amd64|arm64|$app_repo_dist_sel)\b.*\.deb$" ))

        if [ -z ${count_git} ]; then
            count_git=${#lst_releases[@]}
        fi

        #   loop each downloadable package
        for key in "${!lst_releases[@]}"
        do
            repo_file_url=${lst_releases[$key]}
            app_filename="${repo_file_url##*/}"

            #   The filtering in the lastversion query should be enough, however, some people name their packages in a way
            #   where it would be difficult to rely only on that.
            #
            #   makedeb/makedeb uses a file structure similar to the following:
            #       makedeb-beta_16.1.0-beta1_armhf_focal.deb
            #       makedeb-beta_16.1.0-beta1_arm64_focal.deb
            #   
            #   this filters out "armhf", however, readds it because the word focal matches
            #   so we need to do additional filtering below.

            check=`echo $app_filename | grep '\armhf\|armv7l'`
            if [ -n "$check" ]; then
                continue
            fi

            wget "$repo_file_url" -q

            for j in "${!lst_arch[@]}"; do
                #   returns arch
                #   amd64, arm64, i386, all
                arch=${lst_arch[$j]}

                if [ -f "$app_dir/$app_filename" ]; then
                    if [[ "$arch" == "all" ]] && [[ $app_filename == *all.deb || $app_filename == *all*.deb ]]; then
                        printf ' %-25s %-60s %-5s' "    ${GREYL}|---${NORMAL}" "${FUCHSIA}${BOLD}Get ${app_filename:0:35}...${NORMAL}" "" 1>&2
                        mv "$app_dir/$app_filename" "$app_dir_storage/all/"
                        echo -e "[ ${STATUS_OK} ]"

                        if [ -n "${bRep}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then
                            #   full path to deb package
                            deb_package="$app_dir_repo/$arch/$app_filename"

                            reprepro -V \
                                --section utils \
                                --component main \
                                --priority 0 \
                                includedeb $app_repo_dist_sel "$deb_package"
                        fi

                        echo

                    elif [[ "$arch" == "amd64" ]] && [[ $app_filename == *amd64.deb || $app_filename == *amd64*.deb ]]; then
                        printf ' %-25s %-60s %-5s' "    ${GREYL}|---${NORMAL}" "${FUCHSIA}${BOLD}Get ${app_filename:0:35}...${NORMAL}" "" 1>&2
                        mv "$app_dir/$app_filename" "$app_dir_storage/amd64/"
                        echo -e "[ ${STATUS_OK} ]"

                        if [ -n "${bRep}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then
                            #   full path to deb package
                            deb_package="$app_dir_repo/$arch/$app_filename"

                            reprepro -V \
                                --section utils \
                                --component main \
                                --priority 0 \
                                --architecture $arch \
                                includedeb $app_repo_dist_sel "$deb_package"
                        fi

                        echo

                    elif [[ "$arch" == "arm64" ]] && [[ $app_filename == *arm64.deb || $app_filename == *arm64*.deb ]]; then
                        printf ' %-25s %-60s %-5s' "    ${GREYL}|---${NORMAL}" "${FUCHSIA}${BOLD}Get ${app_filename:0:35}...${NORMAL}" "" 1>&2
                        mv "$app_dir/$app_filename" "$app_dir_storage/arm64/"
                        echo -e "[ ${STATUS_OK} ]"

                        if [ -n "${bRep}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then
                            #   full path to deb package
                            deb_package="$app_dir_repo/$arch/$app_filename"

                            reprepro -V \
                                --section utils \
                                --component main \
                                --priority 0 \
                                --architecture $arch \
                                includedeb $app_repo_dist_sel "$deb_package"
                        fi

                        echo

                    fi
                fi
            done
        done

        echo

    done
}

##--------------------------------------------------------------------------
#   upload to github
##--------------------------------------------------------------------------

app_run_gh_end()
{
    app_run_github_precheck

    echo
    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo
    echo -e "  ${GREYL}Updating Github: $app_repo_branch${WHITE}"
    echo
    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo

    git branch -m $app_repo_branch
    git add --all
    git add -u

    sleep 1

    local app_repo_commit="[E] auto-update [ $app_repo_dist_sel ] @ $NOW"
    git commit -S -m "$app_repo_commit"

    sleep 1

    git push -u origin $app_repo_branch
}

##--------------------------------------------------------------------------
#   start github process
##--------------------------------------------------------------------------

app_run_gh_start()
{

    ##--------------------------------------------------------------------------
    #   .app folder
    ##--------------------------------------------------------------------------

    local manifest_dir=$app_dir/.app/
    mkdir -p            $manifest_dir

    ##--------------------------------------------------------------------------
    #   .app folder > create .json
    ##--------------------------------------------------------------------------

tee $manifest_dir/$app_repo_dist_sel.json >/dev/null <<EOF
{
    "name":             "${app_title}",
    "version":          "$(get_version)",
    "author":           "${app_repo_author}",
    "description":      "${app_about}",
    "distrib":          "${app_repo_dist_sel}",
    "url":              "${app_repo_url}",
    "last_duration":    ".......",
    "last_update":      "Running ...............",
    "last_update_ts":   "${DATE_TS}"
}
EOF

    app_run_github_precheck

    git branch -m $app_repo_branch
    git add --all
    git add -u

    sleep 1

    local app_repo_commit="[S] auto-update [ $app_repo_dist_sel ] @ $NOW"

    echo -e "  ${WHITE}Starting commit ${FUCHSIA}${app_repo_commit}${WHITE}${NORMAL}"

    git commit -S -m "[S] auto-update [ $app_repo_dist_sel ] @ 02.22.2024 00:29:44"

    sleep 1

    echo -e "  ${WHITE}Starting push ${FUCHSIA}${app_repo_branch}${WHITE}${NORMAL}"
    git push -u origin $app_repo_branch

}

##--------------------------------------------------------------------------
#   update tree
##--------------------------------------------------------------------------

app_run_tree_update()
{
    ##--------------------------------------------------------------------------
    #   .app folder
    ##--------------------------------------------------------------------------

    local manifest_dir=$app_dir/.app/
    mkdir -p            $manifest_dir

    ##--------------------------------------------------------------------------
    #   duration elapsed
    ##--------------------------------------------------------------------------

    duration=$SECONDS
    elapsed="$(($duration / 60))m $(( $duration % 60 ))s"

    ##--------------------------------------------------------------------------
    #   .app folder > create .json
    ##--------------------------------------------------------------------------

tee $manifest_dir/$app_repo_dist_sel.json >/dev/null <<EOF
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

    ##--------------------------------------------------------------------------
    #   tree
    ##--------------------------------------------------------------------------

    tree_output=$( tree -a -I ".git" --dirsfirst )
    tree -a -I ".git" --dirsfirst -J > $manifest_dir/tree.json

    #   useful for Gitea with HTML rendering plugin, not useful for Github
    #   tree -a --dirsfirst -I '.git' -H https://github.com/${app_repo_author}/${app_repo}/src/branch/$app_repo_branch/ -o $app_dir/.data/tree.html

    ##--------------------------------------------------------------------------
    #   tree.md content
    ##--------------------------------------------------------------------------

tee $app_dir/tree.md >/dev/null <<EOF
# Repo Tree
Last generated on \`$NOW\`

<br />

---

<br />

\`\`\`
$tree_output
\`\`\`
EOF
}

##--------------------------------------------------------------------------
#   Start App
##--------------------------------------------------------------------------

app_start()
{

    show_header

    ##--------------------------------------------------------------------------
    #   set seconds for duration
    ##--------------------------------------------------------------------------

    export SECONDS=0

    ##--------------------------------------------------------------------------
    #   pull all changes from github
    ##--------------------------------------------------------------------------

    git_pull=$( git pull origin $app_repo_branch )

    echo -e "  ${GREYL}Git Pull${WHITE}"
    echo -e "  ${WHITE}${git_pull}${NORMAL}"
    echo
    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo

    ##--------------------------------------------------------------------------
    #   check for reprepro
    ##--------------------------------------------------------------------------

    if [ -x "$(command -v reprepro)" ]; then
        bRep=true
    fi

    ##--------------------------------------------------------------------------
    #   reprepro missing
    ##--------------------------------------------------------------------------

    if [ -z "${bRep}" ]; then
        echo
        echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}Reprepro Missing${NORMAL}"
        echo -e "  ${BOLD}${WHITE}It appears the package ${FUCHSIA}Reprepro${WHITE} is missing.${NORMAL}"
        echo
        echo -e "  ${BOLD}${WHITE}Try installing the package with:${NORMAL}"
        echo -e "  ${BOLD}${WHITE}     sudo apt-get update${NORMAL}"
        echo -e "  ${BOLD}${WHITE}     sudo apt-get install reprepro${NORMAL}"
        echo

        printf "  Press any key to abort ... ${NORMAL}"
        read -n 1 -s -r -p ""
        echo
        echo

        set +m
        trap "kill -9 $app_pid 2> /dev/null" `seq 0 15`
        kill $app_pid
        set -m
    fi

    ##--------------------------------------------------------------------------
    #   run
    ##--------------------------------------------------------------------------

    if [ -n "${OPT_ONLY_GIT}" ]; then
        app_run_gh_start
        app_run_dl_gh
        app_run_tree_update
        app_run_gh_end
    elif [ -n "${OPT_ONLY_SRC}" ]; then
        app_run_gh_start
        app_run_dl_aptsrc
        app_run_tree_update
        app_run_gh_end
    else
        app_run_gh_start
        app_run_dl_aptsrc
        app_run_dl_gh
        app_run_tree_update
        app_run_gh_end
    fi

    ##--------------------------------------------------------------------------
    #   duration elapsed
    ##--------------------------------------------------------------------------

    duration=$SECONDS
    elapsed="$(($duration / 60)) minutes and $(( $duration % 60 )) seconds elapsed."

    printf "%-57s %-15s\n\n\n\n" "${TIME}      ${elapsed}" | tee -a "${LOGS_FILE}" >/dev/null

    echo
    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo
    echo -e "  ${GREYL}Total Execution Time: $elapsed${WHITE}"
    echo
    echo -e " ${BLUE}-------------------------------------------------------------------------${NORMAL}"
    echo

    sleep 10

    ##--------------------------------------------------------------------------
    #   close logs, kill spinner, and finish process
    ##--------------------------------------------------------------------------

    finish
    Logs_Finish
    exit
}

app_start