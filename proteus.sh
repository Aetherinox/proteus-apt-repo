#!/bin/bash

# #
#   @author             aetherinox
#   @script             Proteus Apt Git
#   @date               2025-01-24 00:00:00
#   @url                https://github.com/Aetherinox/proteus-git
#   
#   ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
#   
#   requires chmod +x proteus_git.sh
#   
#   This requires you to have the following files in your home directory:
#       /server/.secrets/CSI_BASE                       Base secrets: GITHUB_NAME, GITHUB_EMAIL, GPG_KEY
#       /server/.secrets/CSI_SUDO_PASSWD                Linux sudo password
#       /server/.secrets/CSI_GPG_PASSWD                 GPG password
#       /server/.secrets/CSI_PAT_GITHUB                 Github PAT Token, not required if using Gitlab
#       /server/.secrets/CSI_PAT_GITLAB                 Gitlab PAT Token, not required if using Github
#   
#   LastVersion requires that two env variables be exported when running that app, otherwise you will
#   be rate-limited by Github and Gitlab.
#       export GITHUB_API_TOKEN=${CSI_PAT_GITHUB}
#       export GITLAB_PA_TOKEN=${CSI_PAT_GITLAB}
#
#   DO NOT change the name of the above env variables otherwise it will not work.
#       - GITHUB_API_TOKEN
#       - GITLAB_PA_TOKEN
#
#   This script requires a minimum Reprepro version or it will cause database errors:
#       - v5.4.6
#   
#   ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
#   
#   To test the functionality of this script without actually 
#   writing anything to Github or Reprepro, you can use the command
#       ./proteus.sh --onlyTest --dev
#   
# #

# #
#   Define > colors
#
#   Use the color table at:
#       - https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
# #

END=$'\e[0m'
WHITE=$'\e[97m'
BOLD=$'\e[1m'
DIM=$'\e[2m'
UNDERLINE=$'\e[4m'
STRIKE=$'\e[9m'
BLINK=$'\e[5m'
INVERTED=$'\e[7m'
HIDDEN=$'\e[8m'
BLACK=$'\e[38;5;0m'
FUCHSIA1=$'\e[38;5;205m'
FUCHSIA2=$'\e[38;5;198m'
RED=$'\e[38;5;160m'
RED2=$'\e[38;5;196m'
ORANGE=$'\e[38;5;202m'
ORANGE2=$'\e[38;5;208m'
MAGENTA=$'\e[38;5;5m'
BLUE=$'\e[38;5;033m'
BLUE2=$'\e[38;5;39m'
BLUE3=$'\e[38;5;68m'
CYAN=$'\e[38;5;51m'
GREEN=$'\e[38;5;2m'
GREEN2=$'\e[38;5;76m'
YELLOW=$'\e[38;5;184m'
YELLOW2=$'\e[38;5;190m'
YELLOW3=$'\e[38;5;193m'
GREY1=$'\e[38;5;240m'
GREY2=$'\e[38;5;244m'
GREY3=$'\e[38;5;250m'
NAVY=$'\e[38;5;62m'
OLIVE=$'\e[38;5;144m'
PEACH=$'\e[38;5;210m'

# #
#   Define > general
# #

app_title="Proteus Apt Git"
app_about="Internal system to Proteus App Manager which grabs debian packages."
app_ver=("1" "3" "0" "0")
app_pid_spin=0
app_pid=$BASHPID
app_queue_url=()
app_i=0

# #
#   Define > env vars
# #

CSI_PAT_GITHUB=
CSI_PAT_GITLAB=
CSI_SUDO_PASSWD=
CSI_GPG_PASSWD=

# #
#   DEFINE > Packages > apt-get
# #

lst_packages=(
    'adduser'
    'argon2'
    'apt-move'
    'apt-transport-https'
    'apt-utils'
    'clevis'
    'clevis-dracut'
    'clevis-udisks2'
    'clevis-tpm2'
    'dialog'
    'firefox'
    'flatpak'
    'gnome-keyring'
    'gnome-keysign'
    'gnome-shell-extension-manager'
    'git'
    'gpg'
    'gpgconf'
    'gpgv'
    'jose'
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
    'lintian'
    'lsb-base'
    'lz4'
    'mysql-client'
    'mysql-common'
    'mysql-server'
    'net-tools'
    'neofetch'
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
    'pass'
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
    'sks'
    'snap'
    'snapd'
    'tcptrack'
    'trash-cli'
    'tree'
    'wget'
)

# #
#   DEFINE > Packages > Github Repos (LastVersion)
# #

lst_github=(
    'obsidianmd/obsidian-releases'
    'AppOutlet/AppOutlet'
    'bitwarden/clients'
    'shiftkey/desktop'
    'FreeTubeApp/FreeTube'
    'makedeb/makedeb'
    'Aetherinox/debian-apt-url'
    'Aetherinox/opengist-debian'
)

# #
#   list > architectures
# #

lst_arch=(
    'all'
    'amd64'
    'arm64'
    'i386'
)

# #
#   Define > system
# #

sys_arch=$(dpkg --print-architecture)
sys_code=$(lsb_release -cs)

# #
#   distro > freedesktop.org and systemd
#       returns distro information.
# #

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        SYS_OS=$NAME
        SYS_OS_VER=$VERSION_ID

# #
#   distro > linuxbase.org
# #

    elif type lsb_release >/dev/null 2>&1; then
        SYS_OS=$(lsb_release -si)
        SYS_OS_VER=$(lsb_release -sr)

# #
#   distro > versions of Debian/Ubuntu without lsb_release cmd
# #

    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        SYS_OS=$DISTRIB_ID
        SYS_OS_VER=$DISTRIB_RELEASE

# #
#   distro > older Debian/Ubuntu/etc distros
# #

    elif [ -f /etc/debian_version ]; then
        SYS_OS=Debian
        SYS_OS_VER=$(cat /etc/debian_version)

# #
#   distro > fallback: uname, e.g. "Linux <version>", also works for BSD
# #

    else
        SYS_OS=$(uname -s)
        SYS_OS_VER=$(uname -r)
    fi

# #
#   Define > status
# #

STATUS_MISS="${BOLD}${GREY2} MISS ${END}"
STATUS_SKIP="${BOLD}${GREY2} SKIP ${END}"
STATUS_OK="${BOLD}${GREEN}  OK  ${END}"
STATUS_FAIL="${BOLD}${RED} FAIL ${END}"
STATUS_HALT="${BOLD}${YELLOW} HALT ${END}"

# #
#   Define > dirs
# #

app_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
app_dir_b="${PWD}"                                          # current script directory
app_dir_bin="${HOME}/bin"                                   # /home/$USER/bin
app_dir_secrets="/server/.secrets"                          # path to .secrets folder
app_dir_gpg=".gpg"                                          # .gpg folder
app_dir_storage="$app_dir/incoming/packages/${sys_code}"
app_dir_repo="incoming/packages/${sys_code}"

# #
#   Ensure we're in the correct directory
# #

cd ${app_dir}

# #
#   Define > Files
# #

app_file_this=$(basename "$0")                      # proteus.sh (with ext)
app_file_bin="${app_file_this%.*}"                  # proteus (without ext)
app_file_bin_bws=bws                                # bws
app_file_secret="secrets.sh"                        # secrets.sh file
app_file_secret_base="CSI_BASE"                     # clevis encrypted > base file
app_file_secret_passwd_sudo="CSI_SUDO_PASSWD"       # clevis encrypted > sudo password
app_file_secret_passwd_gpg="CSI_GPG_PASSWD"         # clevis encrypted > gpg password
app_file_secret_pat_github="CSI_PAT_GITHUB"         # clevis encrypted > PAT github
app_file_secret_pat_gitlab="CSI_PAT_GITLAB"         # clevis encrypted > PAT gitlab

# #
#   Define > Paths
# #

path_usr_local_bin="/usr/local/bin"                                                 # /usr/local/bin
path_tmp="/tmp/downloads"                                                           # temp download path

path_file_bin_binary="${app_dir_bin}/${app_file_bin}"                               # /home/$USER/bin/proteus
path_file_secret_base=${app_dir_secrets}/${app_file_secret_base}                    # GPG_KEY, GITHUB_NAME, GITHUB_EMAIL
path_file_secret_passwd_sudo=${app_dir_secrets}/${app_file_secret_passwd_sudo}      # file for sudo passwd
path_file_secret_passwd_gpg=${app_dir_secrets}/${app_file_secret_passwd_gpg}        # file for gpg passwd
path_file_secret_pat_github=${app_dir_secrets}/${app_file_secret_pat_github}        # file for github PAT
path_file_secret_pat_gitlab=${app_dir_secrets}/${app_file_secret_pat_gitlab}        # file for gitlab PAT
path_file_secret_sh=${app_dir}/${app_file_secret}                                   # old version

path_file_secret_gpg_passwd_sudo=${HOME}/.${app_file_secret_passwd_sudo}            # GPG File > sudo passwd
path_file_secret_gpg_passwd_gpg=${HOME}/.${app_file_secret_passwd_gpg}              # GPG File > gpg passwd
path_file_secret_gpg_pat_github=${HOME}/.${app_file_secret_pat_github}              # GPG File > github PAT
path_file_secret_gpg_pat_gitlab=${HOME}/.${app_file_secret_pat_gitlab}              # GPG File > gitlab PAT

# #
#   define > general
# #

app_guid="1000"                                     # group id for permission assignment
app_uuid="1000"                                     # user id for permission assignment
app_bFoundSafe=false                                # git safe.directory found
now=`date '+%m.%d.%Y %H:%M:%S'`;                    # current date/time
app_tang_domain="https://tang1.betelgeuse.dev"      # tang server domain
app_repo_domain="Aetherinox/proteus-apt-repo"       # repo domain
app_repo_developer="aetherinox"                     # repo developer
app_repo_commit_msg="synchronize - $now"            # repo commit message

# #
#   args
# #

OPT_DEV_ENABLE=false
OPT_TEST_ENABLED=false
OPT_VERBOSE_ENABLE=false

# #
#   DEFINE > Exports
# #

export DATE=$(date -u '+%m%d%y')
export DATE_TS=$(date -u +%s)
export YEAR=$(date -u +'%Y')
export TIME=$(date -u '+%H:%M:%S')
export NOW=$(date -u '+%m.%d.%Y %H:%M:%S')
export ARGS=$1
export LOGS_DIR="${app_dir}/logs"
export LOGS_FILE="${LOGS_DIR}/proteus-${DATE}.log"
export SECONDS=0

# #
#   Packages > git not installed
# #

if ! [ -x "$(command -v git)" ]; then
    echo -e "  ${GREEN}OK           ${END}Installing package ${BLUE2}Git${END}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install git -y -qq >/dev/null 2>&1
fi

# #
#   Packages > git not installed
# #

if ! [ -x "$(command -v gpg)" ]; then
    echo -e "  ${GREEN}OK           ${END}Installing package ${BLUE2}GPG${END}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install gpg -y -qq >/dev/null 2>&1
fi

# #
#   Create .gitignore
# #

if [ ! -f "${app_dir}/.gitignore" ] || [ ! -s "${app_dir}/.gitignore" ]; then

    touch "${app_dir}/.gitignore"

sudo tee ${app_dir}/.gitignore << EOF > /dev/null
# ----------------------------------------
#   Misc
# ----------------------------------------
incoming/
.env
sources-*.list
.pipe
/*.deb

# ----------------------------------------
#   Logs
# ----------------------------------------
logs/
*-log
*.log

# ----------------------------------------
#   GPG keys
# ----------------------------------------
/${app_dir_gpg}/*.gpg
/${app_dir_gpg}/*.asc
/*.gpg
/*.asc

# ----------------------------------------
#   Secrets Files
# ----------------------------------------
${app_file_secret}
${app_file_secret_base}
${app_file_secret_passwd_sudo}
${app_file_secret_passwd_gpg}
${app_file_secret_pat_github}
${app_file_secret_pat_gitlab}

secrets/*
.secrets/*
EOF

fi

# #
#   get mode
# #

get_mode()
{

    # bitwarden secrets cli
    if [ -f "${path_usr_local_bin}/${app_file_bin_bws}" ] && [ -n "${BWS_ACCESS_TOKEN}" ]; then
        CSI_SUDO_PASSWD_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_SUDO_PASSWD\").id)[0]")
        if [ -n "${CSI_SUDO_PASSWD_ID}" ]; then
            CSI_SUDO_PASSWD=$(bws secret get $CSI_SUDO_PASSWD_ID | jq -r ".value")

            if [ -n "${CSI_SUDO_PASSWD}" ]; then
                echo "Bitwarden"
            fi
        fi
    fi

    # clevis mode
    if [ -x "$(command -v clevis)" ] && ([ -z "${CSI_SUDO_PASSWD}" ]); then
        tang_status=`curl -Is "https://tang1.betelgeuse.dev" | tac | grep -o "^HTTP.*" | cut -f 2 -d' ' | head -1`

        if [ "$tang_status" == "200" ] && [ -d "${app_dir_secrets}" ] && [ -f ${path_file_secret_passwd_sudo} ]; then
            CSI_SUDO_PASSWD=$(cat ${path_file_secret_passwd_sudo} | clevis decrypt 2>/dev/null)
            if [ -n "${CSI_SUDO_PASSWD}" ]; then
                echo "Clevis"
            fi
        fi
    fi

    # secrets.sh mode
    if [ -z "${CSI_SUDO_PASSWD}" ] && [ -f "${path_file_secret_sh}" ]; then
        source "${path_file_secret_sh}"
        if [ -n "${CSI_SUDO_PASSWD}" ] && [ "$CSI_SUDO_PASSWD" != "xxxxxxxxxxxxxxx" ]; then
            echo "Secrets.sh"
        fi
    fi

    # gpg encrypt mode
    if ([ -z "${CSI_SUDO_PASSWD}" ] || [ "$CSI_SUDO_PASSWD" == "xxxxxxxxxxxxxxx" ] ) && [ -f "${HOME}/.${app_file_secret_passwd_sudo}" ]; then
        CSI_SUDO_PASSWD=$(gpg --decrypt "${HOME}/.${app_file_secret_passwd_sudo}" 2>/dev/null)

        if [ -n "${CSI_SUDO_PASSWD}" ]; then
            echo "GPG Encrypt"
        fi
    fi

    if [ -z "${CSI_SUDO_PASSWD}" ] || [ "$CSI_SUDO_PASSWD" == "xxxxxxxxxxxxxxx" ]; then
        echo "No Working Modes Available"
    fi
}

# #
#   func > get version
#
#   returns current version of app
#   converts to human string.
#       e.g.    "1" "2" "4" "0"
#               1.2.4.0
# #

get_version()
{
    ver_join=${app_ver[@]}
    ver_str=${ver_join// /.}
    echo ${ver_str}
}

# #
#   func > version > compare greater than
#
#   this function compares two versions and determines if an update may
#   be available. or the user is running a lesser version of a program.
# #

get_version_compare_gt()
{
    test "$(printf '%s\n' "$@" | sort -V | head -n 1)" != "$1";
}

# #
#   print an error and exit with failure
#   $1: error message
# #

function error()
{
    echo -e "  ⭕ ${GREY2}${app_file_this}${END}: \n     ${BOLD}${RED}Error${NORMAL}: ${END}$1"
    echo -e
    exit 0
}

# #
#   throws an error to the user if they are missing the CSI_BASE secrets file
# #

error_missing_file_base()
{
    local file_base_path="Unknown"
    if [ "${mode_clevis}" = true ]; then
        file_base_path="${path_file_secret_base}"
    else
        file_base_path="${path_file_secret_sh}"
    fi

    echo -e 
    echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
    echo
    echo -e "  ${ORANGE}WARNING      ${WHITE}Missing ${YELLOW}${path_file_secret_base}${END}"
    echo -e "               Create new ${FUCHSIA1}${path_file_secret_base}${END} file and add the following lines:${END}"
    echo -e
    echo -e "               ${GREY2}#!/bin/bash${END}"
    echo -e "               ${GREY2}PATH=\"/bin:/usr/bin:/sbin:/usr/sbin:${HOME}/bin\"${END}"
    echo -e "               ${RED}export ${GREEN}CSI_PAT_GITHUB=${WHITE}github_pat_xxxxxxxxxxxxxxx${END}"
    echo -e "               ${RED}export ${GREEN}CSI_PAT_GITLAB=${WHITE}glpat-xxxxxxxxxxxxxxx${END}"
    echo -e "               ${RED}export ${GREEN}CSI_SUDO_PASSWD=${WHITE}xxxxxxxxxxxxxxx${END}"
    echo -e "               ${RED}export ${GREEN}CSI_GPG_PASSWD=${WHITE}xxxxxxxxxxxxxxx${END}"
    echo -e "               ${RED}export ${GREEN}GPG_KEY=${WHITE}XXXXXXXX${END}"
    echo -e "               ${RED}export ${GREEN}GITHUB_NAME=${WHITE}GithubUsername${END}"
    echo -e "               ${RED}export ${GREEN}GITHUB_EMAIL=${WHITE}user@email${END}"
    echo
    echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
    echo -e

    printf "  Press any key to abort ... ${END}"
    read -n 1 -s -r -p ""
    echo -e
    echo -e

    set +m
    trap "kill -9 ${app_pid} 2> /dev/null" `seq 0 15`
    kill ${app_pid}
    set -m
}

# #
#   func > error > GPG_KEY missing
#
#   throws an error if GPG_KEY is not specified
# #

error_missing_value_gpg()
{
    local file_base_path="Unknown"
    if [ "${mode_clevis}" = true ]; then
        file_base_path="${path_file_secret_base}"
    else
        file_base_path="${path_file_secret_sh}"
    fi

    echo -e 
    echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
    echo
    echo -e "  ${ORANGE}WARNING      ${WHITE}Missing ${YELLOW}\$GPG_KEY${END}"
    echo -e "               Create the file ${FUCHSIA1}${path_file_secret_base}${END} and specify the following env variables inside:${END}"
    echo -e "               Relaunch Proteus when you are finished.${END}"
    echo -e
    echo -e "               ${GREY2}#!/bin/bash${END}"
    echo -e "               ${GREY2}PATH=\"/bin:/usr/bin:/sbin:/usr/sbin:${HOME}/bin\"${END}"
    echo -e "               ${RED}export ${GREEN}CSI_PAT_GITHUB=${WHITE}github_pat_xxxxxxxxxxxxxxx${END}"
    echo -e "               ${RED}export ${GREEN}CSI_PAT_GITLAB=${WHITE}glpat-xxxxxxxxxxxxxxx${END}"
    echo -e "               ${RED}export ${GREEN}CSI_SUDO_PASSWD=${WHITE}xxxxxxxxxxxxxxx${END}"
    echo -e "               ${RED}export ${GREEN}CSI_GPG_PASSWD=${WHITE}xxxxxxxxxxxxxxx${END}"
    echo -e "               ${RED}export ${GREEN}GPG_KEY=${WHITE}XXXXXXXX${END}"
    echo -e "               ${RED}export ${GREEN}GITHUB_NAME=${WHITE}GithubUsername${END}"
    echo -e "               ${RED}export ${GREEN}GITHUB_EMAIL=${WHITE}user@email${END}"
    echo
    echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
    echo -e

    printf "  Press any key to abort ... ${END}"
    read -n 1 -s -r -p ""
    echo -e
    echo -e

    set +m
    trap "kill -9 ${app_pid} 2> /dev/null" `seq 0 15`
    kill ${app_pid}
    set -m
}

# #
#   Display Usage Help
#
#   activate using ./proteus.sh --help or -h
# #

opt_usage()
{
    echo -e 
    printf "  ${BLUE}${app_title}${END}\n" 1>&2
    printf "  ${GREY2}${gui_about}${END}\n" 1>&2
    echo -e 
    printf '  %-5s %-40s\n' "Usage:" "" 1>&2
    printf '  %-5s %-40s\n' "    " "${0} [${GREY2}options${END}]" 1>&2
    printf '  %-5s %-40s\n\n' "    " "${0} [${GREY2}-s${END}] [${GREY2}-t${END}] [${GREY2}-g${END}] [${GREY2}-p${END}] [${GREY2}-d${END}] [${GREY2}-n${END}] [${GREY2}-q${END}] [${GREY2}-u${END}] [${GREY2}-b main | dev${END}] [${GREY2}-r${END}]" 1>&2
    printf '  %-5s %-40s\n' "Options:" "" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-s, --setup" "install script packages (git, wget, reprepro, etc.), setup gpg daemon, configure gpg key" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-t, --onlyTest" "download packages from apt-get and LastVersion, do not push to git repo" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-g, --onlyGithub" "only update packages using LastVersion, push to git" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-p, --onlyAptget" "only update packages using AptGet, push to git" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-d, --dev" "dev mode (advanced logs)" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-n, --nullrun" "run script without adding packages to reprepro" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "simulate app installs (no changes)" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-q, --quiet" "disable logging" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-r, --report" "show info about ${app_file_this}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "current paths, installed dependencies, etc." 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-u, --update" "update ${app_file_this} executable" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-b, --branch" "branch to use for downloading/updating this script" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-v, --version" "current version of app manager" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-h, --help" "show help menu" 1>&2
    echo -e 
    echo -e 
    exit 1
}

# #
#   Display Report
# #

opt_report()
{

    clear

    sleep 0.3

    local secrets_mode=$(get_mode)
    local file_base_path="Missing"
    var_clevis_status='Disabled'
    if [ "${mode_clevis}" = true ]; then
        file_base_path="${path_file_secret_base}"
        var_clevis_status='Enabled'
    else
        file_base_path="${path_file_secret_sh}"
        var_clevis_status='Disabled'
    fi

    # #
    #   base > load /.secrets/.base
    # #

    if [ -f ${path_file_secret_base} ]; then
        source ${path_file_secret_base}
    elif [ -f ${path_file_secret_sh} ]; then
        source ${path_file_secret_sh}
    fi

    # #
    #   base > secrets mode > color
    #
    #   changes the color of the "secrets.sh" mode to a dark gray if clevis mode is enabled
    # #

    clrSecretsModeSh_Title=$([ ${var_clevis_status} == "Enabled" ] && echo ${STRIKE}${GREY1} || echo ${YELLOW3})
    clrSecretsModeSh_Item=$([ ${var_clevis_status} == "Enabled" ] && echo ${GREY3} || echo ${BLUE2})

    # #
    #  Section > Header 
    # #

    echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
    echo -e " ${GREEN}${BOLD} ${app_title} - v$(get_version)${END}${MAGENTA}"
    echo
    echo -e "  This is a package which handles the Proteus App Manager behind"
    echo -e "  the scene by grabbing from the list of registered packages"
    echo -e "  and adding them to the queue to be updated."
    echo -e 

    # #
    #  Section > Settings
    # #

    echo -e
    echo -e "  ${YELLOW3}${BOLD}[ Settings ]${END}"

    Val_SecretMode=$([ ${var_clevis_status} == "Enabled" ] && echo "Clevis Mode (Enabled)" || echo "Secrets.sh (Unencrypted)")
    Val_Pkgs_Aptget=${#lst_packages[@]}
    Val_Pkgs_Github=${#lst_github[@]}
    Val_Pkgs_Arch=${#lst_arch[@]}

    printf "%-5s %-40s %-40s %-40s\n" "" "${BLUE2}⚙️  Script" "${END}${app_file_this}" "${END}"
    printf "%-5s %-40s %-40s %-40s\n" "" "${BLUE2}⚙️  Path" "${END}${app_dir}" "${END}"
    printf "%-5s %-40s %-40s %-40s\n" "" "${BLUE2}⚙️  Version" "${END}v$(get_version)" "${END}"
    printf "%-5s %-40s %-40s %-40s\n" "" "${BLUE2}⚙️  Secret Mode" "${END}${secrets_mode}" "${END}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${BLUE2}📦 Packages (Apt)" "${END}${Val_Pkgs_Aptget}" "${END}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${BLUE2}📦 Packages (Github)" "${END}${Val_Pkgs_Github}" "${END}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${BLUE2}📦 Architectures" "${END}${Val_Pkgs_Arch}" "${END}"

    # #
    #  Section > Variables
    # #

    echo -e
    echo -e
    echo -e "  ${YELLOW3}${BOLD}[ Variables ]${END}"

    bExists_Val_GPG=$([ -z "${GPG_KEY}" ] && echo "Missing" || echo "${GPG_KEY}")
    bExists_Val_GithubName=$([ -z "${GITHUB_NAME}" ] && echo "Missing" || echo "${GITHUB_NAME}")
    bExists_Val_GithubEmail=$([ -z "${GITHUB_EMAIL}" ] && echo "Missing" || echo "${GITHUB_EMAIL}")

    printf "%-5s %-37s %-40s %-40s\n" "" "${BLUE2}✎ GPG_KEY" "${END}${bExists_Val_GPG}" "${END}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${BLUE2}✎ GITHUB_NAME" "${END}${bExists_Val_GithubName}" "${END}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${BLUE2}✎ GITHUB_EMAIL" "${END}${bExists_Val_GithubEmail}" "${END}"
    echo -e

    # #
    #  Section > Paths
    # #

    echo -e
    echo -e "  ${YELLOW3}${BOLD}[ Paths - Clevis Mode]${END}"

    bExists_Fold_Secrets=$([ ! -d "${app_dir_secrets}" ] && echo "Missing" || echo "${app_dir_secrets}")
    bExists_File_Base=$([ ! -f "${path_file_secret_base}" ] && echo "Missing" || echo "${path_file_secret_base}")
    bExists_File_Github=$([ ! -f "${path_file_secret_pat_github}" ] && echo "Missing" || echo "${path_file_secret_pat_github}")
    bExists_File_Gitlab=$([ ! -f "${path_file_secret_pat_gitlab}" ] && echo "Missing" || echo "${path_file_secret_pat_gitlab}")
    bExists_File_Passwd=$([ ! -f "${path_file_secret_passwd_sudo}" ] && echo "Missing" || echo "${path_file_secret_passwd_sudo}")
    bExists_File_PasswdGpg=$([ ! -f "${path_file_secret_passwd_gpg}" ] && echo "Missing" || echo "${path_file_secret_passwd_gpg}")

    printf "%-5s %-37s %-40s %-40s\n" "" "${BLUE2}📁 ${app_dir_secrets}" "${END}${bExists_Fold_Secrets}" "${GREY3}${Val_SecretMode}${END}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${BLUE2}📄 ${app_file_secret_base}" "${END}${bExists_File_Base}${END}" ""
    printf "%-5s %-37s %-40s %-40s\n" "" "${BLUE2}📄 ${app_file_secret_passwd_sudo}" "${END}${bExists_File_Passwd}${END}" ""
    printf "%-5s %-37s %-40s %-40s\n" "" "${BLUE2}📄 ${app_file_secret_passwd_gpg}" "${END}${bExists_File_PasswdGpg}${END}" ""
    printf "%-5s %-37s %-40s %-40s\n" "" "${BLUE2}📄 ${app_file_secret_pat_github}" "${END}${bExists_File_Github}${END}" ""
    printf "%-5s %-37s %-40s %-40s\n" "" "${BLUE2}📄 ${app_file_secret_pat_gitlab}" "${END}${bExists_File_Gitlab}${END}" ""
    echo -e

    # #
    #  Section > Paths > Secrets.Sh Mode
    # #

    echo -e
    echo -e "  ${clrSecretsModeSh_Title}${BOLD}[ Paths - ${app_file_secret} Mode]${END}"

    bExists_File_SecretsSh=$([ ! -f "${path_file_secret_sh}" ] && echo "Missing" || echo 'Found')
    if [ "$bExists_File_SecretsSh" == "Found" ] && [ "$var_clevis_status" == "Enabled" ]; then
        bExists_File_SecretsSh="Not Loaded"
    fi

    printf "%-5s %-37s %-40s %-40s\n" "" "${clrSecretsModeSh_Item}📄 ${app_file_secret}" " ${END}${bExists_File_SecretsSh}" "${GREY3}${Val_SecretMode}${END}"
    echo -e

    # #
    #  Section > Dependencies 
    # #

    echo -e
    echo -e "  ${YELLOW3}${BOLD}[ Dependencies ]${END}"

    bInstalled_AptMove=$([ ! -x "$(command -v apt-move)" ] && echo "Missing" || echo 'Installed')
    bInstalled_Git=$([ ! -x "$(command -v git)" ] && echo "Missing" || echo 'Installed')
    bInstalled_Clevis=$([ ! -x "$(command -v clevis)" ] && echo "Missing" || echo 'Installed')
    bInstalled_Reprepro=$([ ! -x "$(command -v reprepro)" ] && echo "Missing" || echo 'Installed')
    bInstalled_GPG=$([ ! -x "$(command -v gpg)" ] && echo "Missing" || echo 'Installed')
    bInstalled_Wget=$([ ! -x "$(command -v wget)" ] && echo "Missing" || echo 'Installed')
    bInstalled_Curl=$([ ! -x "$(command -v curl)" ] && echo "Missing" || echo 'Installed')
    bInstalled_Tree=$([ ! -x "$(command -v tree)" ] && echo "Missing" || echo 'Installed')

    printf "%-5s %-38s %-40s\n" "" "${BLUE2}🗔  apt-move" "${END}${bInstalled_AptMove}${END}"
    printf "%-5s %-38s %-40s\n" "" "${BLUE2}🗔  git" "${END}${bInstalled_Git}${END}"
    printf "%-5s %-38s %-40s\n" "" "${BLUE2}🗔  clevis" "${END}${bInstalled_Clevis}${END}"
    printf "%-5s %-38s %-40s\n" "" "${BLUE2}🗔  reprepro" "${END}${bInstalled_Reprepro}${END}"
    printf "%-5s %-38s %-40s\n" "" "${BLUE2}🗔  gPG" "${END}${bInstalled_GPG}${END}"
    printf "%-5s %-38s %-40s\n" "" "${BLUE2}🗔  wget" "${END}${bInstalled_Wget}${END}"
    printf "%-5s %-38s %-40s\n" "" "${BLUE2}🗔  curl" "${END}${bInstalled_Curl}${END}"
    printf "%-5s %-38s %-40s\n" "" "${BLUE2}🗔  tree" "${END}${bInstalled_Tree}${END}"

    # #
    #  Section > gpg-agent.conf 
    # #

    echo -e
    echo -e "  ${YELLOW3}${BOLD}[ gpg-agent.conf ]${END}"

    gpgagent_cfg_file="${HOME}/.gnupg/gpg-agent.conf"
    if [ -f ${gpgagent_cfg_file} ]; then
        sed "s/^/      /" ${gpgagent_cfg_file}
    fi

    # #
    #  Section > Footer
    # #

    echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
    echo -e
    echo -e

    sleep 0.3

    exit 1
}

# #
#   command-line options
#
#   reminder that any functions which need executed must be defined BEFORE
#   this point. Bash sucks like that.
#
#   --dev           show advanced printing
#
#   --dist          specifies a specific distribution
#                   jammy, lunar, focal, noble, etc
#
#   --setup         installs all required dependencies for proteus script
#                   apt-move, apt-url, curl, wget, tree, reprepro, lastversion
#
#   --gpg           adds new entries to "${HOME}/.gnupg/gpg-agent.conf"
#
#   --onlyTest      downloads packages from both apt-get and LastVersion
#                   does not push packages to Github proteus repo
#
#   --onlyGithub    only downloads packages from github using LastVersion
#                   does not download packages from apt-get
#
#   --onlyAptget    only downloads packages from apt-get
#                   does not download packages from github using LastVersion
#
#   --help          show help and usage information
#
#   --branch        used in combination with --update
#                   used to install proteus apt script from another github
#                   branch such as development branch
#
#   --nullrun       used for testing functionality
#                   does not download packages
#                   does not modify file permissions
#                   does not add packages to reprepro
#                   does not push changes to github
#
#   --quiet         no logs output to pipe file
#
#   --update        downloads the latest proteus script to local folder
#
#   --version       display version information
# #

while [ $# -gt 0 ]; do
  case "$1" in
    -d|--dev)
            OPT_DEV_ENABLE=true
            echo -e "  ${FUCHSIA1}${BLINK}Devmode Enabled${END}"
            ;;

    -dd*|--dist*)
            if [[ "$1" != *=* ]]; then shift; fi
            OPT_DISTRIBUTION="${1#*=}"
            if [ -z "${OPT_DISTRIBUTION}" ]; then
                echo -e "  ${END}Must specify a valid distribution"
                echo -e "  ${END}      Default:  ${YELLOW}${sys_code}${END}"

                exit 1
            fi
            ;;

    -s*|--setup*)
            app_setup
            ;;

    -t*|--onlyTest*)
            OPT_DLPKG_ONLY_TEST=true
            ;;

    -g*|--onlyGithub*)
            OPT_DLPKG_ONLY_LASTVER=true
            ;;

    -p*|--onlyAptget*)
            OPT_DL_ONLY_APTGET=true
            ;;

    -h*|--help*)
            opt_usage
            ;;

    -r*|--report*)
            opt_report
            ;;

    -c|--clean)
            # #
            #   originally to delete left-behind .deb files; we used compgen
            #       if compgen -G "${app_dir}/*.deb" > /dev/null; then
            #           echo -e "  ${GREY2}Cleaning up left-over .deb: ${YELLOW}${app_dir}/*.deb${WHITE}"
            #           rm ${app_dir}/*.deb >/dev/null
            #       fi
            #
            #   alternative method:
            #       test command:       find . -maxdepth 1 -name "*.deb*" -type f
            #       delete command:     find . -maxdepth 1 -name "*.deb*" -type f -delete
            #
            # #

            if compgen -G "${app_dir}/*.deb*" > /dev/null; then
                echo -e "  ${GREY2}Cleaning up left-over .deb: ${YELLOW}${app_dir}/*.deb${WHITE}"
            fi
            exit 1
            ;;

    -b*|--branch*)
            if [[ "$1" != *=* ]]; then shift; fi
            OPT_BRANCH="${1#*=}"
            if [ -z "${OPT_BRANCH}" ]; then
                echo -e "  ${END}Must specify a valid branch"
                echo -e "  ${END}      Default:  ${YELLOW}${app_repo_branch}${END}"

                exit 1
            fi
            ;;

    -n|--nullrun)
            OPT_DEV_NULLRUN=true
            echo -e "  ${FUCHSIA1}${BLINK}Devnull Enabled${END}"
            ;;

    -q|--quiet)
            OPT_NOLOG=true
            echo -e "  ${FUCHSIA1}${BLINK}Logging Disabled{END}"
            ;;

    -u|--update)
            OPT_UPDATE=true
            ;;

    -v|--version)
            echo
            echo -e "  ${GREEN}${BOLD}${app_title}${END} - v$(get_version)${END}"
            echo -e "  ${GREY2}${BOLD}${app_repo_url}${END}"
            echo -e "  ${GREY2}${BOLD}${SYS_OS} | ${SYS_OS_VER}${END}"
            echo
            exit 1
            ;;
    *)
            opt_usage
            ;;
  esac
  shift
done

# #
#   Bash Logging > Disable
# #

set +o history

# #
#   SECRETS > METHOD > BWS
#       Found BWS binary, found BWS token
# #

echo -e printenv
printenv

echo -e "BWS_ACCESS_TOKEN               $BWS_ACCESS_TOKEN"
echo -e "Test"

if [ -f "${path_usr_local_bin}/${app_file_bin_bws}" ] && [ -n "${BWS_ACCESS_TOKEN}" ]; then
    echo -e "  ${GREEN}OK           ${GREEN}BWS Mode Activated${END}"
    echo -e "  ${GREEN}OK           ${END}Found ${NAVY}\$BWS_ACCESS_TOKEN${END}"
    echo -e "  ${GREEN}OK           ${END}Found Bitwarden Secrets Manager CLI${END}"

    # #
    #   SECRETS > METHOD > BWS
    #       sudo password id
    # #

    CSI_SUDO_PASSWD_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_SUDO_PASSWD\").id)[0]")

    if [ -z "${CSI_SUDO_PASSWD_ID}" ] || [ "${CSI_SUDO_PASSWD_ID}" == "null" ]; then
        echo
        echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_SUDO_PASSWD_ID${END}"
        echo -e "               Could not locate the id ${GREEN}CSI_SUDO_PASSWD_ID${END} in Bitwarden Secrets Manager CLI${END}"
        echo -e
        echo -e "               Script will now try other ways of obtaining your secrets${END}"
        echo
    elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
        echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_SUDO_PASSWD_ID${END} with value ${GREEN}${CSI_SUDO_PASSWD_ID}${END}"
    fi

    # #
    #   SECRETS > METHOD > BWS
    #       sudo password
    # #

    CSI_SUDO_PASSWD=$(bws secret get $CSI_SUDO_PASSWD_ID | jq -r ".value")

    if [ -z "${CSI_SUDO_PASSWD}" ]; then
        echo
        echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_SUDO_PASSWD${END}"
        echo -e "               Could not locate the env var ${GREEN}CSI_SUDO_PASSWD${END} in Bitwarden Secrets Manager CLI${END}"
        echo -e
        echo -e "               Script will now try other ways of obtaining your secrets${END}"
        echo
    elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
        echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_SUDO_PASSWD${END} with value ${GREEN}${CSI_SUDO_PASSWD}${END}"
    fi

    # #
    #   SECRETS > METHOD > BWS
    #       elevate script with sudo
    # #

    echo "$CSI_SUDO_PASSWD" | echo | sudo -S su
    if [ "${OPT_VERBOSE_ENABLE}" = true ]; then
        echo -e "  ${NAVY}DEV          ${GREY2}Elevating script with ${GREY1}SUDO${GREY2} using passwd ${GREY1}${CSI_SUDO_PASSWD}${END}"
    fi

    # #
    #   SECRETS > METHOD > BWS
    #       gpg password id
    # #

    CSI_GPG_PASSWD_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_GPG_PASSWD\").id)[0]")

    if [ -z "${CSI_GPG_PASSWD_ID}" ] || [ "${CSI_GPG_PASSWD_ID}" == "null" ]; then
        echo
        echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_GPG_PASSWD_ID${END}"
        echo -e "               Could not locate the id ${GREEN}CSI_GPG_PASSWD_ID${END} in Bitwarden Secrets Manager CLI${END}"
        echo -e
        echo -e "               Script will now try other ways of obtaining your secrets${END}"
        echo
    elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
        echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_GPG_PASSWD_ID${END} with value ${GREEN}${CSI_GPG_PASSWD_ID}${END}"
    fi

    # #
    #   SECRETS > METHOD > BWS
    #       gpg password
    # #

    CSI_GPG_PASSWD=$(bws secret get $CSI_GPG_PASSWD_ID | jq -r ".value")

    if [ -z "${CSI_GPG_PASSWD}" ]; then
        echo
        echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_GPG_PASSWD${END}"
        echo -e "               Could not locate the env var ${GREEN}CSI_GPG_PASSWD${END} in Bitwarden Secrets Manager CLI${END}"
        echo -e
        echo -e "               Script will now try other ways of obtaining your secrets${END}"
        echo
    elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
        echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_GPG_PASSWD${END} with value ${GREEN}${CSI_GPG_PASSWD}${END}"
    fi

    # #
    #   SECRETS > METHOD > BWS
    #       github pat
    # #

    CSI_PAT_GITHUB_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_PAT_GITHUB\").id)[0]")

    if [ -z "${CSI_PAT_GITHUB_ID}" ] || [ "${CSI_PAT_GITHUB_ID}" == "null" ]; then
        echo
        echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_PAT_GITHUB_ID${END}"
        echo -e "               Could not locate the id ${GREEN}CSI_PAT_GITHUB_ID${END} in Bitwarden Secrets Manager CLI${END}"
        echo -e
        echo -e "               Script will now try other ways of obtaining your secrets${END}"
        echo
    elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
        echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_PAT_GITHUB_ID${END} with value ${GREEN}${CSI_PAT_GITHUB_ID}${END}"
    fi

    # #
    #   SECRETS > METHOD > BWS
    #       github pat
    # #

    CSI_PAT_GITHUB=$(bws secret get $CSI_PAT_GITHUB_ID | jq -r ".value")

    if [ -z "${CSI_PAT_GITHUB}" ]; then
        echo
        echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_PAT_GITHUB${END}"
        echo -e "               Could not locate the env var ${GREEN}CSI_PAT_GITHUB${END} in Bitwarden Secrets Manager CLI${END}"
        echo -e
        echo -e "               Script will now try other ways of obtaining your secrets${END}"
        echo
    elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
        echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_PAT_GITHUB${END} with value ${GREEN}${CSI_PAT_GITHUB}${END}"
    fi

    if [ -n "${CSI_PAT_GITHUB}" ]; then
        export GITHUB_API_TOKEN=${CSI_PAT_GITHUB}
    fi

    # #
    #   SECRETS > METHOD > BWS
    #       gitlab pat
    # #

    if [ -z "$CSI_PAT_GITHUB" ]; then
        CSI_PAT_GITLAB_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_PAT_GITLAB\").id)[0]")

        if [ -z "${CSI_PAT_GITLAB_ID}" ] || [ "${CSI_PAT_GITLAB_ID}" == "null" ]; then
            echo
            echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_PAT_GITLAB_ID${END}"
            echo -e "               Could not locate the id ${GREEN}CSI_PAT_GITLAB_ID${END} in Bitwarden Secrets Manager CLI${END}"
            echo -e
            echo -e "               Script will now try other ways of obtaining your secrets${END}"
            echo
        elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
            echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_PAT_GITLAB_ID${END} with value ${GREEN}${CSI_PAT_GITLAB_ID}${END}"
        fi

        # #
        #   SECRETS > METHOD > BWS
        #       gitlab pat
        # #

        CSI_PAT_GITLAB=$(bws secret get $CSI_PAT_GITLAB_ID | jq -r ".value")

        if [ -z "${CSI_PAT_GITLAB}" ]; then
            echo
            echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_PAT_GITLAB${END}"
            echo -e "               Could not locate the env var ${GREEN}CSI_PAT_GITLAB${END} in Bitwarden Secrets Manager CLI${END}"
            echo -e
            echo -e "               Script will now try other ways of obtaining your secrets${END}"
            echo
        elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
            echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_PAT_GITLAB${END} with value ${GREEN}${CSI_PAT_GITLAB}${END}"
        fi

        if [ -n "${CSI_PAT_GITLAB}" ]; then
            export GITLAB_PA_TOKEN=${CSI_PAT_GITLAB}
        fi
    fi

# #
#   SECRETS > METHOD > BWS
#       Missing BWS binary, found BWS token
#       Script requires LastVersion to install BWS
# #

elif [ ! -f "${path_usr_local_bin}/${app_file_bin_bws}" ] && [ -n "${BWS_ACCESS_TOKEN}" ]; then

    if ! [ -x "$(command -v lastversion)" ]; then
        echo
        echo -e "  ${ORANGE}WARNING      ${WHITE}Missing Bitwarden Secrets CLI & LastVersion${END}"
        echo -e "               Missing Bitwarden Secrets CLI. In order to automatically install the Secrets Manager, this script requires LastVersion,${END}"
        echo -e "               which you do not have.${END}"
        echo -e
        echo -e "               Script will now try other ways of obtaining your secrets${END}"
        echo
    elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
        echo -e "  ${NAVY}DEV          ${GREY2}Package ${GREY1}LastVersion${GREY2} already installed${END}"
    fi

    echo -e "  ${GREEN}OK           ${END}Installing Bitwarden Secrets Manager CLI${END}"
    bws_download=$(lastversion "bitwarden/sdk-sm" --assets --having-asset "~bws-x86_64-unknown-linux-gnu-(.+).(.+).(.+).zip")
    bws_filename=$(basename ${bws_download})

    echo -e "  ${GREEN}OK           ${END}Creating folder ${FUCHSIA1}${path_tmp}${END}"
    mkdir -p "${path_tmp}"

    echo -e "  ${GREEN}OK           ${END}Downloading Bitwarden Secrets Manager CLI from ${FUCHSIA1}${bws_download}${END}"
    sudo wget -O "${path_tmp}/${bws_filename}" -q "${bws_download}"

    echo -e "  ${GREEN}OK           ${END}Unzipping to current folder ${FUCHSIA1}${app_dir}${END}"
    unzip "${path_tmp}/${bws_filename}" -d ./           # unzip to /server/gitea folder

    echo -e "  ${GREEN}OK           ${END}Setting permission u+x on ${FUCHSIA1}${bws_filename}${END}"
    sudo chmod u+x "${bws_filename}"

    echo -e "  ${GREEN}OK           ${END}Moving ${FUCHSIA1}${bws_filename}${END} to ${FUCHSIA1}${path_usr_local_bin}/${bws_filename}${END}"
    sudo cp "${bws_filename}" "${path_usr_local_bin}"   # move /server/gitea/bws to /usr/local/bin/bws

    if [ "${cfg_Storage_BwsCLI}" = true ] && [ ! -f "${path_usr_local_bin}/${bws_filename}" ]; then
        echo -e "  ${GREEN}OK           ${END}Successfully installed package ${FUCHSIA1}${path_usr_local_bin}/${bws_filename}${END}"
    fi

    echo -e "  ${GREEN}OK           ${END}Creating symbolic link ${FUCHSIA1}${path_usr_local_bin}/${bws_filename}${END} to ${FUCHSIA1}/bin/${bws_filename}${END}"
    sudo ln -s "${path_usr_local_bin}/${bws_filename}" "/bin/${bws_filename}"

    # #
    #   SECRETS > METHOD > BWS
    #       One final check
    #       must find BWS binary and BWS token from /server/.secrets/BWS_TOKEN
    # #

    if [ -f "${path_usr_local_bin}/${app_file_bin_bws}" ] && [ -n "${BWS_ACCESS_TOKEN}" ]; then

        # #
        #   SECRETS > METHOD > BWS
        #       Initially we couldn't find BWS CLI or BWS_TOKEN, but after installing, now we can.
        # #

        echo -e "  ${GREEN}OK           ${END}Found BWS_ACCESS_TOKEN${END}"
        echo -e "  ${GREEN}OK           ${END}Found Bitwarden Secrets Manager CLI${END}"

        # #
        #   SECRETS > METHOD > BWS
        #       sudo password id
        # #

        CSI_SUDO_PASSWD_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_SUDO_PASSWD\").id)[0]")

        if [ -z "${CSI_SUDO_PASSWD_ID}" ] || [ "${CSI_SUDO_PASSWD_ID}" == "null" ]; then
            echo
            echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_SUDO_PASSWD_ID${END}"
            echo -e "               Could not locate the id ${GREEN}CSI_SUDO_PASSWD_ID${END} in Bitwarden Secrets Manager CLI${END}"
            echo -e
            echo -e "               Script will now try other ways of obtaining your secrets${END}"
            echo
        elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
            echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_SUDO_PASSWD_ID${END} with value ${GREEN}${CSI_SUDO_PASSWD_ID}${END}"
        fi

        # #
        #   SECRETS > METHOD > BWS
        #       sudo password
        # #

        CSI_SUDO_PASSWD=$(bws secret get $CSI_SUDO_PASSWD_ID | jq -r ".value")

        if [ -z "${CSI_SUDO_PASSWD}" ]; then
            echo
            echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_SUDO_PASSWD${END}"
            echo -e "               Could not locate the env var ${GREEN}CSI_SUDO_PASSWD${END} in Bitwarden Secrets Manager CLI${END}"
            echo -e
            echo -e "               Script will now try other ways of obtaining your secrets${END}"
            echo
        elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
            echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_SUDO_PASSWD${END} with value ${GREEN}${CSI_SUDO_PASSWD}${END}"
        fi

        # #
        #   SECRETS > METHOD > BWS
        #       elevate script with sudo
        # #

        echo "$CSI_SUDO_PASSWD" | echo | sudo -S su
        if [ "${OPT_VERBOSE_ENABLE}" = true ]; then
            echo -e "  ${NAVY}DEV          ${GREY2}Elevating script with ${GREY1}SUDO${GREY2} using passwd ${GREY1}${CSI_SUDO_PASSWD}${END}"
        fi

        # #
        #   SECRETS > METHOD > BWS
        #       gpg password id
        # #

        CSI_GPG_PASSWD_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_GPG_PASSWD\").id)[0]")

        if [ -z "${CSI_GPG_PASSWD_ID}" ] || [ "${CSI_GPG_PASSWD_ID}" == "null" ]; then
            echo
            echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_GPG_PASSWD_ID${END}"
            echo -e "               Could not locate the id ${GREEN}CSI_GPG_PASSWD_ID${END} in Bitwarden Secrets Manager CLI${END}"
            echo -e
            echo -e "               Script will now try other ways of obtaining your secrets${END}"
            echo
        elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
            echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_GPG_PASSWD_ID${END} with value ${GREEN}${CSI_GPG_PASSWD_ID}${END}"
        fi

        # #
        #   SECRETS > METHOD > BWS
        #       gpg password
        # #

        CSI_GPG_PASSWD=$(bws secret get $CSI_GPG_PASSWD_ID | jq -r ".value")

        if [ -z "${CSI_GPG_PASSWD}" ]; then
            echo
            echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_GPG_PASSWD${END}"
            echo -e "               Could not locate the env var ${GREEN}CSI_GPG_PASSWD${END} in Bitwarden Secrets Manager CLI${END}"
            echo -e
            echo -e "               Script will now try other ways of obtaining your secrets${END}"
            echo
        elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
            echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_GPG_PASSWD${END} with value ${GREEN}${CSI_GPG_PASSWD}${END}"
        fi

        # #
        #   SECRETS > METHOD > BWS
        #       github pat
        # #

        CSI_PAT_GITHUB_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_PAT_GITHUB\").id)[0]")

        if [ -z "${CSI_PAT_GITHUB_ID}" ] || [ "${CSI_PAT_GITHUB_ID}" == "null" ]; then
            echo
            echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_PAT_GITHUB_ID${END}"
            echo -e "               Could not locate the id ${GREEN}CSI_PAT_GITHUB_ID${END} in Bitwarden Secrets Manager CLI${END}"
            echo -e
            echo -e "               Script will now try other ways of obtaining your secrets${END}"
            echo
        elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
            echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_PAT_GITHUB_ID${END} with value ${GREEN}${CSI_PAT_GITHUB_ID}${END}"
        fi

        # #
        #   SECRETS > METHOD > BWS
        #       github pat
        # #

        CSI_PAT_GITHUB=$(bws secret get $CSI_PAT_GITHUB_ID | jq -r ".value")

        if [ -z "${CSI_PAT_GITHUB}" ]; then
            echo
            echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_PAT_GITHUB${END}"
            echo -e "               Could not locate the env var ${GREEN}CSI_PAT_GITHUB${END} in Bitwarden Secrets Manager CLI${END}"
            echo -e
            echo -e "               Script will now try other ways of obtaining your secrets${END}"
            echo
        elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
            echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_PAT_GITHUB${END} with value ${GREEN}${CSI_PAT_GITHUB}${END}"
        fi

        if [ -n "${CSI_PAT_GITHUB}" ]; then
            export GITHUB_API_TOKEN=${CSI_PAT_GITHUB}
        fi

        # #
        #   SECRETS > METHOD > BWS
        #       gitlab pat
        # #

        if [ -z "$CSI_PAT_GITHUB" ]; then
            CSI_PAT_GITLAB_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_PAT_GITLAB\").id)[0]")

            if [ -z "${CSI_PAT_GITLAB_ID}" ] || [ "${CSI_PAT_GITLAB_ID}" == "null" ]; then
                echo
                echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_PAT_GITLAB_ID${END}"
                echo -e "               Could not locate the id ${GREEN}CSI_PAT_GITLAB_ID${END} in Bitwarden Secrets Manager CLI${END}"
                echo -e
                echo -e "               Script will now try other ways of obtaining your secrets${END}"
                echo
            elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
                echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_PAT_GITLAB_ID${END} with value ${GREEN}${CSI_PAT_GITLAB_ID}${END}"
            fi

            # #
            #   SECRETS > METHOD > BWS
            #       gitlab pat
            # #

            CSI_PAT_GITLAB=$(bws secret get $CSI_PAT_GITLAB_ID | jq -r ".value")

            if [ -z "${CSI_PAT_GITLAB}" ]; then
                echo
                echo -e "  ${ORANGE}WARNING      ${WHITE}Missing CSI_PAT_GITLAB${END}"
                echo -e "               Could not locate the env var ${GREEN}CSI_PAT_GITLAB${END} in Bitwarden Secrets Manager CLI${END}"
                echo -e
                echo -e "               Script will now try other ways of obtaining your secrets${END}"
                echo
            elif [ "${OPT_VERBOSE_ENABLE}" = true ]; then
                echo -e "  ${NAVY}DEV          ${END}+ var ${NAVY}\$CSI_PAT_GITLAB${END} with value ${GREEN}${CSI_PAT_GITLAB}${END}"
            fi

            if [ -n "${CSI_PAT_GITLAB}" ]; then
                export GITLAB_PA_TOKEN=${CSI_PAT_GITLAB}
            fi
        fi

    else

        # #
        #   SECRETS > METHOD > BWS
        #   Still couldn't find required Bitwarden binary or BWS_TOKEN env, aborting
        # #

        echo
        echo -e "  ${ORANGE}WARNING      ${WHITE}Still Could Not Find Bitwarden Binary of BWS_TOKEN${END}"
        echo -e "               After an attempt to install the Bitwarden Secret's Manager CLI and find the BWS_TOKEN, we still could not.${END}"
        echo -e
        echo -e "               Script will now try other ways of obtaining your secrets${END}"
        echo
    fi

# #
#   SECRETS > METHOD > BWS
#       Found BWS binary, missing BWS token
# #

elif [ -f "${path_usr_local_bin}/${app_file_bin_bws}" ] && [ -z "${BWS_ACCESS_TOKEN}" ]; then

    echo
    echo -e "  ${ORANGE}WARNING      ${WHITE}Found Bitwarden CLI but missing env var BWS_ACCESS_TOKEN${END}"
    echo -e "               The Bitwarden CLI binary was found, but you are missing the BWS_ACCESS_TOKEN:${END}"
    echo -e "                    ${GREY2}${GREEN}BWS_ACCESS_TOKEN=${END}0.cdf2c081-XXXX-XX-XXXX-b1d10066acb7.sabZWAV0xIEnLYsdvgUpuXXXXXXXXX:XXXX/XXXXXXXXXXXXXXXXX==${END}"
    echo -e
    echo -e "               Script will now try other ways of obtaining your secrets${END}"
    echo
fi

# #
#   SECRETS > METHOD > CLEVIS
#       Bitwarden Secrets Manager CLI failed to locate secrets.
#       Try Clevis
# #

if [ ! -x "$(command -v clevis)" ] && ([ -z "${CSI_GPG_PASSWD}" ] || [ -z "${CSI_SUDO_PASSWD}" ]); then
    echo
    echo -e "  ${ORANGE}WARNING      ${WHITE}Could not find needed env variables using Bitwarden Secrets Manager CLI${END}"
    echo -e "               Script will now attempt to use Clevis to find encrypted files in the folder:${END}"
    echo -e "                    ${GREY2}${app_dir_secrets}${END}"
    echo

    echo -e "  ${GREEN}OK           ${END}Installing package ${BLUE2}Clevis${END}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt --fix-broken install >/dev/null 2>&1
    sudo apt-get install clevis clevis-udisks2 clevis-tpm2 -y -qq >/dev/null 2>&1
fi

if [ -x "$(command -v clevis)" ] && ([ -z "${CSI_GPG_PASSWD}" ] || [ -z "${CSI_SUDO_PASSWD}" ]); then
    echo -e "  ${GREEN}OK           ${GREEN}Clevis Mode Activated${END}"

    tang_status=`curl -Is "https://tang1.betelgeuse.dev" | tac | grep -o "^HTTP.*" | cut -f 2 -d' ' | head -1`

    if [ "$tang_status" == "307" ]; then
        echo
        echo -e "  ${ORANGE}WARNING      ${WHITE}Could Not Communicate With Tang Server${END}"
        echo -e "               Tang server returned a redirect. Tang server may not be online.${END}"
        echo -e "                    ${GREY2}${app_tang_domain}${END}"
        echo

        skip_clevis=true
    fi

    if [ "$skip_clevis" = false ]; then

        # #
        #   SECRETS > METHOD > CLEVIS
        #       /server/.secrets/ folder not found
        # #

        if [ ! -d "${app_dir_secrets}" ]; then

            echo
            echo -e "  ${ORANGE}WARNING      ${WHITE}Could not find ${FUCHSIA1}${app_dir_secrets} - Creating new secrets folder${END}"
            echo -e "               Additional files will be created which you must open and add your Clevis encrypted secrets to.${END}"
            echo -e "               Relaunch Gitea Backup when you are finished.${END}"
            echo

            mkdir -p ${app_dir_secrets}
            touch ${path_file_secret_base}
            touch ${path_file_secret_pat_github}
            touch ${path_file_secret_pat_gitlab}
            touch ${path_file_secret_passwd_sudo}
            touch ${path_file_secret_passwd_gpg}

            printf "  Press any key to abort ... ${END}"
            read -n 1 -s -r -p ""
            echo
            echo

            set +m
            trap "kill -9 ${app_pid} 2> /dev/null" `seq 0 15`
            kill ${app_pid}
            set -m

        # #
        #   SECRETS > METHOD > CLEVIS
        #       /server/.secrets/ folder exists
        # #

        else
            echo -e "  ${GREEN}OK           ${END}Found folder ${BLUE2}${app_dir_secrets}${END}"

            # #
            #   SECRETS > METHOD > CLEVIS
            #
            #       loads clevis secret strings from files:
            #           /server/.secrets/CSI_BASE
            #           /server/.secrets/CSI_PAT_GITHUB
            #           /server/.secrets/CSI_PAT_GITLAB
            #           /server/.secrets/CSI_SUDO_PASSWD
            #           /server/.secrets/CSI_GPG_PASSWD
            #
            #       the contents of the files should be encrypted using Clevis, either tpm or a tang server.
            #
            #       clevis encrypt tang '{"url": "https://tang1.domain.com"}' <<< 'github_pat_XXXXXX' > /server/.secrets/CSI_PAT_GITHUB
            #       clevis decrypt < /server/.secrets/CSI_PAT_GITHUB
            # #

            # #
            #   SECRETS > METHOD > CLEVIS
            #       found /server/.secrets/CSI_PAT_GITHUB
            #       need this check twice to warn user
            # #

            if [ -f ${path_file_secret_pat_github} ]; then
                echo -e "  ${GREEN}OK           ${END}Found file CSI_PAT_GITHUB ${BLUE2}${path_file_secret_pat_github}${END}"
            else
                echo -e "  ${ORANGE}WARN         ${END}Could not find ${BLUE2}${path_file_secret_pat_github}${END}"
            fi

            bMissingSecret=false

            # #
            #   SECRETS > METHOD > CLEVIS
            #       found /server/.secrets/CSI_PAT_GITHUB
            # #

            if [ -f ${path_file_secret_pat_github} ]; then
                CSI_PAT_GITHUB=$(cat ${path_file_secret_pat_github} | clevis decrypt 2>/dev/null)

                # #
                #   SECRETS > METHOD > CLEVIS
                #       CSI_PAT_GITHUB var valid (not empty)
                # #

                if [ -n "${CSI_PAT_GITHUB}" ]; then
                    if [ "${OPT_VERBOSE_ENABLE}" = true ]; then
                        echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_PAT_GITHUB${END} with value ${GREEN}${CSI_PAT_GITHUB}${END}"
                    else
                        echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_PAT_GITHUB${END} with value  ${GREEN}***********${CSI_PAT_GITHUB:(-8)}${END}"
                    fi

                    export GITHUB_API_TOKEN=${CSI_PAT_GITHUB}
                else
                    # #
                    #   SECRETS > METHOD > CLEVIS
                    #       CSI_PAT_GITHUB var empty
                    # #

                    echo -e "  ${ORANGE}WARN         ${END}${RED2}\$CSI_PAT_GITHUB${END} not declared in ${RED2}${path_file_secret_pat_github}${END}"
                    bMissingSecret=true
                fi
            else
                # #
                #   SECRETS > METHOD > CLEVIS
                #       missing /server/.secrets/CSI_PAT_GITHUB
                # #

                echo -e "  ${RED}ERROR        ${END}Missing file ${RED2}${path_file_secret_pat_github}${END}"

                mkdir -p ${app_dir_secrets}
                touch ${path_file_secret_pat_github}
            fi

            # #
            #   SECRETS > METHOD > CLEVIS
            #       found /server/.secrets/CSI_PAT_GITLAB
            #       need this check twice to warn user
            # #

            if [ -f ${path_file_secret_pat_gitlab} ]; then
                echo -e "  ${GREEN}OK           ${END}Found file CSI_PAT_GITLAB ${BLUE2}${path_file_secret_pat_gitlab}${END}"
            else
                echo -e "  ${ORANGE}WARN         ${END}Could not find ${BLUE2}${path_file_secret_pat_gitlab}${END}"
            fi

            # #
            #   SECRETS > METHOD > CLEVIS
            #       found /server/.secrets/CSI_PAT_GITLAB
            # #

            if [ -f ${path_file_secret_pat_gitlab} ]; then
                CSI_PAT_GITLAB=$(cat ${path_file_secret_pat_gitlab} | clevis decrypt 2>/dev/null)

                # #
                #   SECRETS > METHOD > CLEVIS
                #       CSI_PAT_GITLAB var valid (not empty)
                # #

                if [ -n "${CSI_PAT_GITLAB}" ]; then
                    if [ "${OPT_VERBOSE_ENABLE}" = true ]; then
                        echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_PAT_GITLAB${END} with value ${GREEN}${CSI_PAT_GITLAB}${END}"
                    else
                        echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_PAT_GITLAB${END} with value  ${GREEN}***********${CSI_PAT_GITLAB:(-8)}${END}"
                    fi

                    export GITLAB_PA_TOKEN=${CSI_PAT_GITLAB}
                else
                    # #
                    #   SECRETS > METHOD > CLEVIS
                    #       CSI_PAT_GITLAB var empty
                    # #

                    echo -e "  ${ORANGE}WARN         ${END}${RED2}\$CSI_PAT_GITLAB${END} not declared in ${RED2}${path_file_secret_pat_gitlab}${END}"

                    # #
                    #   Only mark the Gitlab one as missing and show the error if they also havent specified one for Github.
                    # #

                    if [ -z "${CSI_PAT_GITHUB}" ] || [ "${CSI_PAT_GITHUB}" == "!" ]; then
                        bMissingSecret=true
                    fi
                fi
            else
                # #
                #   SECRETS > METHOD > CLEVIS
                #       missing /server/.secrets/CSI_PAT_GITLAB
                # #

                echo -e "  ${RED}ERROR        ${END}Missing file ${RED2}${path_file_secret_pat_gitlab}${END}"

                mkdir -p ${app_dir_secrets}
                touch ${path_file_secret_pat_gitlab}
            fi

            # #
            #   SECRETS > METHOD > CLEVIS
            #       found /server/.secrets/CSI_SUDO_PASSWD
            # #

            if [ -f ${path_file_secret_passwd_sudo} ]; then
                CSI_SUDO_PASSWD=$(cat ${path_file_secret_passwd_sudo} | clevis decrypt 2>/dev/null)

                # #
                #   SECRETS > METHOD > CLEVIS
                #       CSI_SUDO_PASSWD var valid (not empty)
                # #

                if [ -n "${CSI_SUDO_PASSWD}" ]; then
                    if [ "${OPT_VERBOSE_ENABLE}" = true ]; then
                        echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_SUDO_PASSWD${END} with value ${GREEN}${CSI_SUDO_PASSWD}${END}"
                    else
                        echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_SUDO_PASSWD${END} with value  ${GREEN}***********${CSI_SUDO_PASSWD:(-8)}${END}"
                    fi
                    
                    echo "$CSI_SUDO_PASSWD" | sudo -S su 2> /dev/null
                    if [ "${OPT_VERBOSE_ENABLE}" = true ]; then
                        echo -e "  ${NAVY}DEV          ${GREY2}Elevating script with ${GREY1}SUDO${GREY2} using passwd ${GREY1}${CSI_SUDO_PASSWD}${END}"
                    fi
                else
                    # #
                    #   SECRETS > METHOD > CLEVIS
                    #       CSI_SUDO_PASSWD var empty
                    # #

                    echo -e "  ${ORANGE}WARN         ${END}${RED2}\$CSI_SUDO_PASSWD${END} not declared in ${RED2}${path_file_secret_passwd_sudo}${END}"
                    bMissingSecret=true
                fi
            else
                # #
                #   SECRETS > METHOD > CLEVIS
                #       missing /server/.secrets/CSI_SUDO_PASSWD
                # #

                echo -e "  ${RED}ERROR        ${END}Missing file ${RED2}${path_file_secret_passwd_sudo}${END}"

                mkdir -p ${app_dir_secrets}
                touch ${path_file_secret_passwd_sudo}
            fi

            # #
            #   SECRETS > METHOD > CLEVIS
            #       found /server/.secrets/CSI_GPG_PASSWD
            # #

            if [ -f ${path_file_secret_passwd_gpg} ]; then
                CSI_GPG_PASSWD=$(cat ${path_file_secret_passwd_gpg} | clevis decrypt 2>/dev/null)

                # #
                #   SECRETS > METHOD > CLEVIS
                #       CSI_GPG_PASSWD var valid (not empty)
                # #

                if [ -n "${CSI_GPG_PASSWD}" ]; then
                    if [ "${OPT_VERBOSE_ENABLE}" = true ]; then
                        echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_GPG_PASSWD${END} with value ${GREEN}${CSI_GPG_PASSWD}${END}"
                    else
                        echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_GPG_PASSWD${END} with value  ${GREEN}***********${CSI_GPG_PASSWD:(-8)}${END}"
                    fi

                    echo "${CSI_GPG_PASSWD}" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 --output /dev/null --sign >> /dev/null 2>&1
                else
                    # #
                    #   SECRETS > METHOD > CLEVIS
                    #       CSI_GPG_PASSWD var empty
                    # #

                    echo -e "  ${ORANGE}WARN         ${END}${RED2}\$CSI_GPG_PASSWD${END} not declared in ${RED2}${path_file_secret_passwd_gpg}${END}"
                    bMissingSecret=true
                fi
            else
                # #
                #   SECRETS > METHOD > CLEVIS
                #       missing /server/.secrets/CSI_GPG_PASSWD
                # #

                echo -e "  ${RED}ERROR        ${END}Missing file ${RED2}${path_file_secret_passwd_gpg}${END}"

                mkdir -p ${app_dir_secrets}
                touch ${path_file_secret_passwd_gpg}
            fi

            # #
            #   SECRETS > METHOD > CLEVIS
            #       one of the required secrets are missing, abort
            # #

            if [ "${bMissingSecret}" = true ]; then

                echo -e 
                echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
                echo
                echo -e "  ${ORANGE}WARNING      ${WHITE}Missing Required Secrets${END}"
                echo -e "               You must define your secrets within files inside ${RED}${app_dir_secrets}${END}"
                echo -e "               Each line belongs in its own file, and must be encrypted using Clevis${END}"
                echo -e
                printf "%-19s %-60s %-40s\n" "" "${BLUE2}${path_file_secret_base}" "${WHITE}GPG_KEY, GITHUB_NAME, GITHUB_EMAIL${END}"
                printf "%-19s %-60s %-40s\n" "" "${BLUE2}${path_file_secret_pat_github}" "${WHITE}github_pat_xxxxxx_xxxxxx${END}"
                printf "%-19s %-60s %-40s\n" "" "${BLUE2}${path_file_secret_pat_gitlab}" "${WHITE}glpat-xxxxxxx${END}"
                printf "%-19s %-60s %-40s\n" "" "${BLUE2}${path_file_secret_passwd_sudo}" "${WHITE}YourSudoPassword${END}"
                printf "%-19s %-60s %-40s\n" "" "${BLUE2}${path_file_secret_passwd_gpg}" "${WHITE}YourGPGPassword${END}"
                echo -e
                echo -e "               ${GREY2}(Left)   File you should create${END}"
                echo -e "               ${GREY2}(Right)  What each file should have inside${END}"
                echo -e
                echo -e "               You can create and encrypt each file at the same time using these commands:${END}"
                echo -e "                    ${GREY2}clevis encrypt tang '{"url": "https://tang1.domain.com"}' <<< 'github_pat_xxxxxx_xxxxxx' > ${app_file_secret_pat_github}${END}"
                echo -e "                    ${GREY2}clevis encrypt tang '{"url": "https://tang1.domain.com"}' <<< 'glpat-xxxxxxx' > ${app_file_secret_pat_gitlab}${END}"
                echo -e "                    ${GREY2}clevis encrypt tang '{"url": "https://tang1.domain.com"}' <<< 'YourSudoPassword' > ${app_file_secret_passwd_sudo}${END}"
                echo -e "                    ${GREY2}clevis encrypt tang '{"url": "https://tang1.domain.com"}' <<< 'YourGPGPassword' > ${app_file_secret_passwd_gpg}${END}"
                echo -e
                echo -e "               You can decrypt these files using these commands:${END}"
                echo -e "                    ${GREY2}clevis decrypt < ${path_file_secret_pat_github}${END}"
                echo -e "                    ${GREY2}clevis decrypt < ${path_file_secret_pat_github} > ${app_file_secret_pat_github}_decrypted${END}"
                echo
                echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
                echo -e

                printf "  Press any key to abort ... ${END}"
                read -n 1 -s -r -p ""
                echo
                echo

                set +m
                trap "kill -9 ${app_pid} 2> /dev/null" `seq 0 15`
                kill ${app_pid}
                set -m
            fi

            sleep 1
        fi
    fi
else
    echo -e "  ${NAVY}DEV          ${GREY2}Skipping ${GREY1}Clevis Mode${GREY2}, already have ${GREY1}\$CSI_SUDO_PASSWD${END} and ${GREY1}\$CSI_GPG_PASSWD${END}"
fi

# #
#   SECRETS > METHOD > SECRETS.SH
#       opens /server/gitea/secrets.sh
# #

if [ -z "${CSI_SUDO_PASSWD}" ]; then
    echo -e "  ${GREEN}OK           ${GREEN}Secrets.sh Mode Activated${END}"

    # #
    #   SECRETS > METHOD > SECRETS.SH
    #       secrets.sh found, load secrets
    # #

    if [ -f "${path_file_secret_sh}" ]; then

        source "${path_file_secret_sh}"

        # #
        #   SECRETS > METHOD > SECRETS.SH
        #       CSI_PAT_GITHUB var valid (not empty)
        # #

        if [ -n "${CSI_PAT_GITHUB}" ]; then
            if [ "${OPT_VERBOSE_ENABLE}" = true ]; then
                echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_PAT_GITHUB${END} with value ${GREEN}${CSI_PAT_GITHUB}${END}"
            else
                echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_PAT_GITHUB${END} with value  ${GREEN}***********${CSI_PAT_GITHUB:(-8)}${END}"
            fi

            export GITHUB_API_TOKEN=${CSI_PAT_GITHUB}
        else
            # #
            #   SECRETS > METHOD > SECRETS.SH
            #       CSI_PAT_GITHUB var empty
            # #

            echo -e "  ${ORANGE}WARN         ${END}${RED2}\$CSI_PAT_GITHUB${END} not declared in ${RED2}${path_file_secret_sh}${END}"
            bMissingSecret=true
        fi

        # #
        #   SECRETS > METHOD > SECRETS.SH
        #       CSI_PAT_GITLAB var valid (not empty)
        # #

        if [ -n "${CSI_PAT_GITLAB}" ]; then
            if [ "${OPT_VERBOSE_ENABLE}" = true ]; then
                echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_PAT_GITLAB${END} with value ${GREEN}${CSI_PAT_GITLAB}${END}"
            else
                echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_PAT_GITLAB${END} with value  ${GREEN}***********${CSI_PAT_GITLAB:(-8)}${END}"
            fi

            export GITLAB_PA_TOKEN=${CSI_PAT_GITLAB}
        else
            # #
            #   SECRETS > METHOD > SECRETS.SH
            #       CSI_PAT_GITLAB var empty
            # #

            echo -e "  ${ORANGE}WARN         ${END}${RED2}\$CSI_PAT_GITLAB${END} not declared in ${RED2}${path_file_secret_sh}${END}"

            # #
            #   Only mark the Gitlab one as missing and show the error if they also havent specified one for Github.
            # #

            if [ -z "${CSI_PAT_GITHUB}" ] || [ "${CSI_PAT_GITHUB}" == "!" ]; then
                bMissingSecret=true
            fi
        fi

        # #
        #   SECRETS > METHOD > SECRETS.SH
        #       CSI_SUDO_PASSWD var valid (not empty)
        # #

        if [ -n "${CSI_SUDO_PASSWD}" ]; then

            if [ "$CSI_SUDO_PASSWD" == "xxxxxxxxxxxxxxx" ]; then
                echo -e "  ${RED}ERROR        ${END}Default value for ${RED2}\$CSI_SUDO_PASSWD${END} not changed in ${RED2}${path_file_secret_sh}${END}"
            else
                if [ "${OPT_VERBOSE_ENABLE}" = true ]; then
                    echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_SUDO_PASSWD${END} with value ${GREEN}${CSI_SUDO_PASSWD}${END}"
                else
                    echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_SUDO_PASSWD${END} with value  ${GREEN}***********${CSI_SUDO_PASSWD:(-8)}${END}"
                fi
                
                echo "$CSI_SUDO_PASSWD" | sudo -S su 2> /dev/null
                if [ "${OPT_VERBOSE_ENABLE}" = true ]; then
                    echo -e "  ${NAVY}DEV          ${GREY2}Elevating script with ${GREY1}SUDO${GREY2} using passwd ${GREY1}${CSI_SUDO_PASSWD}${END}"
                fi
            fi
        else
            # #
            #   SECRETS > METHOD > CLEVIS
            #       CSI_SUDO_PASSWD var empty
            # #

            echo -e "  ${ORANGE}WARN         ${END}${RED2}\$CSI_SUDO_PASSWD${END} not declared in ${RED2}${path_file_secret_sh}${END}"
            bMissingSecret=true
        fi

        # #
        #   SECRETS > METHOD > SECRETS.SH
        #       CSI_GPG_PASSWD var valid (not empty)
        # #

        if [ -n "${CSI_GPG_PASSWD}" ]; then
            if [ "${OPT_VERBOSE_ENABLE}" = true ]; then
                echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_GPG_PASSWD${END} with value ${GREEN}${CSI_GPG_PASSWD}${END}"
            else
                echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$CSI_GPG_PASSWD${END} with value  ${GREEN}***********${CSI_GPG_PASSWD:(-8)}${END}"
            fi
        else
            echo -e "  ${ORANGE}WARN         ${END}${RED2}\$CSI_GPG_PASSWD${END} not declared in ${RED2}${path_file_secret_sh}${END}"
            bMissingSecret=true
        fi

    else
        echo
        echo -e "  ${ORANGE}WARNING      ${WHITE}${FUCHSIA1}${path_file_secret_sh}${WHITE} file not found! Creating a blank ${FUCHSIA1}${app_file_secret}${END}"
        echo -e "               This file defines things such as your GPG key and Github Personal Token.${END}"
        echo -e "               Open the newly created ${FUCHSIA1}${path_file_secret_sh}${END} and add your secrets${END}"
        echo

        touch ${path_file_secret_sh}

sudo tee ${path_file_secret_sh} << EOF > /dev/null
#!/bin/bash
PATH="/bin:/usr/bin:/sbin:/usr/sbin:${HOME}/bin"
export CSI_PAT_GITHUB=github_pat_xxxxxxxxxxxxxxx
export CSI_PAT_GITLAB=glpat-xxxxxxxxxxxxxxx
export CSI_SUDO_PASSWD=xxxxxxxxxxxxxxx
export CSI_GPG_PASSWD=xxxxxxxxxxxxxxx
export GPG_KEY=XXXXXXXX
export GITHUB_NAME=GithubUsername
export GITHUB_EMAIL=user@email
EOF

        printf "  Press any key to abort ... ${END}"
        read -n 1 -s -r -p ""
        echo
        echo

        set +m
        trap "kill -9 ${app_pid} 2> /dev/null" `seq 0 15`
        kill ${app_pid}
        set -m
    fi

else
    echo -e "  ${NAVY}DEV          ${GREY2}Skipping ${GREY1}Secrets.sh Mode${GREY2}, already have ${GREY1}\$CSI_SUDO_PASSWD_ID${END}"
fi

# #
#   SECRETS > METHOD > CSI_SUDO_PASSWD FILE
#       Found local files:
#           ~/.CSI_SUDO_PASSWD
#           ~/.CSI_GPG_PASSWD
#
#       This is a single file you can place inside your home folder /home/$USER/.CSI_SUDO_PASSWD
#       It contains your sudo password GPG encrypted.
# #

if [ -z "${CSI_SUDO_PASSWD}" ]; then
    if [ -f "${HOME}/.${app_file_secret_passwd_gpg}" ]; then
        echo -e "  ${GREEN}OK           ${END}Found local file ${FUCHSIA1}${HOME}/.${app_file_secret_passwd_gpg}${END}"

        CSI_GPG_PASSWD=$(gpg --decrypt "${HOME}/.${app_file_secret_passwd_gpg}" 2>/dev/null)
    fi

    if [ -f "${HOME}/.${app_file_secret_passwd_sudo}" ]; then
        echo -e "  ${GREEN}OK           ${END}Found local file ${FUCHSIA1}${HOME}/.${app_file_secret_passwd_sudo}${END}"

        CSI_SUDO_PASSWD=$(gpg --decrypt "${HOME}/.${app_file_secret_passwd_sudo}" 2>/dev/null)
        echo "$CSI_SUDO_PASSWD" | echo | sudo -S su

        if [ "${OPT_VERBOSE_ENABLE}" = true ]; then
            echo -e "  ${NAVY}DEV          ${GREY2}Elevating script with ${GREY1}SUDO${GREY2} using passwd ${GREY1}${CSI_SUDO_PASSWD}${END}"
        fi
    fi
fi

# #
#   Final Check for env vars, or abort
# #

if [ -z "${CSI_SUDO_PASSWD}" ]; then
    if [ -f "${HOME}/.${app_file_secret_passwd_sudo}" ]; then
        echo -e "  ${GREEN}OK           ${END}Found local file ${FUCHSIA1}${HOME}/.${app_file_secret_passwd_sudo}${END}"

        CSI_SUDO_PASSWD=$(gpg --decrypt "${HOME}/.${app_file_secret_passwd_sudo}" 2>/dev/null)
        echo "$CSI_SUDO_PASSWD" | echo | sudo -S su

        if [ "${OPT_VERBOSE_ENABLE}" = true ]; then
            echo -e "  ${NAVY}DEV          ${GREY2}Elevating script with ${GREY1}SUDO${GREY2} using passwd ${GREY1}${CSI_SUDO_PASSWD}${END}"
        fi
    fi

    if [ -z "${CSI_SUDO_PASSWD}" ]; then
        echo -e "  ${RED}ERROR        ${END}${RED2}\$CSI_SUDO_PASSWD${END} not declared, aborting.${END}"
        exit 1
    fi
else
    echo -e "  ${NAVY}DEV          ${GREY2}Skipping ${GREY1}${HOME}/.${app_file_secret_passwd_sudo} Mode${GREY2}, already have ${GREY1}\$CSI_SUDO_PASSWD${END}"
fi

if [ -z "${CSI_GPG_PASSWD}" ] || [ -z "${CSI_SUDO_PASSWD}" ]; then
    if [ -z "${CSI_GPG_PASSWD}" ] && [ -f "${HOME}/.${app_file_secret_passwd_gpg}" ]; then
        echo -e "  ${GREEN}OK           ${END}Found local file ${FUCHSIA1}${HOME}/.${app_file_secret_passwd_gpg}${END}"

        CSI_GPG_PASSWD=$(gpg --decrypt "${HOME}/.${app_file_secret_passwd_gpg}" 2>/dev/null)
    fi

    if [ -z "${CSI_SUDO_PASSWD}" ] && [ -f "${HOME}/.${app_file_secret_passwd_sudo}" ]; then
        echo -e "  ${GREEN}OK           ${END}Found local file ${FUCHSIA1}${HOME}/.${app_file_secret_passwd_sudo}${END}"

        CSI_GPG_PASSWD=$(gpg --decrypt "${HOME}/.${app_file_secret_passwd_sudo}" 2>/dev/null)
    fi

    if [ -z "${CSI_GPG_PASSWD}" ]; then
        echo -e "  ${RED}ERROR        ${END}${RED2}\$CSI_GPG_PASSWD${END} not declared, aborting.${END}"
        exit 1
    fi

    if [ -z "${CSI_SUDO_PASSWD}" ]; then
        echo -e "  ${RED}ERROR        ${END}${RED2}\$CSI_SUDO_PASSWD${END} not declared, aborting.${END}"
        exit 1
    fi
else
    echo -e "  ${NAVY}DEV          ${GREY2}Skipping ${GREY1}${HOME}/.${app_file_secret_passwd_gpg} Mode${GREY2}, already have ${GREY1}\$CSI_SUDO_PASSWD${END} and ${GREY1}\$CSI_GPG_PASSWD${END}"
fi

# #
#   SECRETS > BASE
#       this needs to be done after all attempts to load other secrets
#       this will load GPG_KEY, GITHUB_NAME, GITHUB_EMAIL
#
#       load /server/.secrets/CSI_BASE
# #

if [ -f ${path_file_secret_base} ]; then
    echo -e "  ${GREEN}OK           ${END}Found file CSI_BASE ${BLUE2}${path_file_secret_base}${END}"
else
    echo -e "  ${ORANGE}WARN         ${END}Could not find ${BLUE2}${path_file_secret_base}${END}"
fi

# #
#   SECRETS > BASE
#       /server/.secrets/CSI_BASE
# #

if [ -f "${path_file_secret_base}" ]; then

    echo -e "  ${GREEN}OK           ${END}Loading base secrets from ${BLUE2}${path_file_secret_base}${END}"

    # #
    #   SECRETS > BASE
    #       load /server/.secrets/CSI_BASE
    # #

    source "${path_file_secret_base}"

    # #
    #   SECRETS > BASE
    #       verify GPG_KEY env var exists
    # #

    if [ -z "${GPG_KEY}" ]; then
        echo -e "  ${ORANGE}WARN         ${END}${YELLOW3}\$GPG_KEY${END} empty or undefined in ${YELLOW3}${path_file_secret_base}${END}"
    elif [ "${GPG_KEY}" == "!" ]; then
        echo -e "  ${ORANGE}WARN         ${END}${RED}\$GPG_KEY${END} invalid key !${END}"
    else
        echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$GPG_KEY${END} with value ${GREEN}${GPG_KEY}${END}"
    fi

    # #
    #   SECRETS > BASE
    #       verify GITHUB_NAME env var exists
    # #

    if [ -z "${GITHUB_NAME}" ]; then
        echo -e "  ${ORANGE}WARN         ${END}${YELLOW3}\$GITHUB_NAME${END} empty or undefined in ${YELLOW3}${path_file_secret_base}${END}"
    else
        echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$GITHUB_NAME${END} with value ${GREEN}${GITHUB_NAME}${END}"
    fi

    # #
    #   SECRETS > BASE
    #       verify GITHUB_EMAIL env var exists
    # #

    if [ -z "${GITHUB_EMAIL}" ]; then
        echo -e "  ${ORANGE}WARN         ${END}${YELLOW3}\$GITHUB_EMAIL${END} empty or undefined in ${YELLOW3}${path_file_secret_base}${END}"
    else
        echo -e "  ${GREEN}OK           ${END}+ var ${NAVY}\$GITHUB_EMAIL${END} with value ${GREEN}${GITHUB_EMAIL}${END}"
    fi

else

# #
#   SECRETS > BASE
#       missing /server/.secrets/BASE
#       create BASE file, and throw error, then exit
# #

    echo -e "  ${RED}ERROR        ${END}Missing file ${RED2}${path_file_secret_base}${END}"

    mkdir -p ${app_dir_secrets}
    touch ${path_file_secret_base}

    error_missing_file_base
fi

# #
#   check > GPG key
#
#   you must define GPG_KEY
# #

if [ -z "${GPG_KEY}" ] || [ "${GPG_KEY}" == "!" ]; then
    error_missing_value_gpg
fi

set -o history

# #
#   DEFINE > App repo paths and commands
# #

app_repo_script="proteus-git"
app_repo_branch="main"
app_repo_apt="proteus-apt-repo"
app_repo_apt_pkg="aetherinox-${app_repo_apt}-archive"
app_repo_url="https://github.com/${GITHUB_NAME}/${app_repo_script}"
app_repo_apt_url="https://github.com/${GITHUB_NAME}/${app_repo_apt}"
app_repo_mnfst="https://raw.githubusercontent.com/${GITHUB_NAME}/${app_repo_script}/${app_repo_branch}/manifest.json"
app_repo_script="https://raw.githubusercontent.com/${GITHUB_NAME}/${app_repo_script}/BRANCH/setup.sh"

# #
#   DEV > Show Arguments
# #

if [ "${OPT_DEV_ENABLE}" = true ]; then

    echo -e
    echo -e "  ${YELLOW3}${BOLD}[ Arguments ]${END}"
    [ "${OPT_DEV_ENABLE}" = true ] && printf "%-3s %-15s %-10s\n" "" "--dev" "${GREEN}${OPT_DEV_ENABLE}${END}"
    [ "${OPT_DLPKG_ONLY_TEST}" = true ] && printf "%-3s %-15s %-10s\n" "" "--onlyTest" "${GREEN}${OPT_DLPKG_ONLY_TEST}${END}"
    [ "${OPT_DLPKG_ONLY_LASTVER}" = true ] && printf "%-3s %-15s %-10s\n" "" "--onlyGithub" "${GREEN}${OPT_DLPKG_ONLY_LASTVER}${END}"
    [ "${OPT_DL_ONLY_APTGET}" = true ] && printf "%-3s %-15s %-10s\n" "" "--onlyAptget" "${GREEN}${OPT_DL_ONLY_APTGET}${END}"
    [ "${OPT_DEV_NULLRUN}" = true ] && printf "%-3s %-15s %-10s\n" "" "--nullrun" "${GREEN}${OPT_DEV_NULLRUN}${END}"
    [ "${OPT_NOLOG}" = true ] && printf "%-3s %-15s %-10s\n" "" "--quiet" "${GREEN}${OPT_NOLOG}${END}"
    [ -n "${OPT_DISTRIBUTION}" ] && printf "%-3s %-15s %-10s\n" "" "--dist" "${GREEN}${OPT_DISTRIBUTION}${END}"
    [ -n "${OPT_BRANCH}" ] && printf "%-3s %-15s %-10s\n" "" "--branch" "${GREEN}${OPT_BRANCH}${END}"
    echo -e

    sleep 5
fi

# #
#   upload to github > precheck
# #

app_run_github_precheck( )
{
    echo -e "  ${GREY2}Configuring git config${WHITE}"

    # #
    #   delete lock
    # #

    rm -f "${app_dir}.git/index.lock"

    # #
    #   set credential.helper
    # #

    git config --global credential.helper store

    # #
    #   set default action for conflicts
    # #

    git config pull.rebase false

    # #
    #   turn off lfs locksverify
    # #

    git config lfs.https://github.com.locksverify false
    git config --global lfs.https://github.com.locksverify false

    # #
    #   GIT > SAFE DIRECTORY
    #
    #   allow sharing across users in the same group (OU/no admin rights)
    #   These config entries specify Git-tracked directories that are considered
    #   safe even if they are owned by someone other than the current user. 
    # #

    # #
    #   see if repo directory is in safelist for git
    # #

    if git config --global --get-all safe.directory | grep -q "${app_dir}"; then
        bFoundSafe=true
    fi

    # #
    #   if new repo, add to safelist
    # #

    if ! [ ${bFoundSafe} ]; then
        git config --global --add safe.directory ${app_dir}
    fi

    # #
    #   default branch > main
    # #

    git config --global init.defaultBranch ${app_repo_branch}

    # #
    #   username / email
    # #

    git config --global user.name ${GITHUB_NAME}
    git config --global user.email ${GITHUB_EMAIL}

    # #
    #   init
    # #

    git config --global init.defaultBranch ${app_repo_branch}

    # #
    #   http
    # #

    git config --global http.postBuffer 524288000
    git config --global http.lowSpeedLimit 0
}

# #
#   check if GPG key defined in git config user.signingKey
# #

checkgit_signing=$( git config --global --get-all user.signingKey )
if [ -z "${checkgit_signing}" ] || [ "${checkgit_signing}" == "!" ]; then
    echo
    echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}Missing ${YELLOW}user.signingKey${WHITE} in ${YELLOW}${HOME}/.gitconfig${END}"
    echo -e "  ${BOLD}${WHITE}You should have the below entries in your ${FUCHSIA1}.gitconfig${WHITE}:${END}"
    echo
    echo -e "  ${BOLD}${WHITE}    ${GREY2}[user]${END}"
    echo -e "  ${BOLD}${WHITE}         ${BLUE}signingKey${WHITE} = ${GPG_KEY}${END}"
    echo
    echo -e "  ${BOLD}${WHITE}    ${GREY2}[commit]${END}"
    echo -e "  ${BOLD}${WHITE}         ${BLUE}gpgsign${WHITE} = true${END}"
    echo
    echo -e "  ${BOLD}${WHITE}    ${GREY2}[gpg]${END}"
    echo -e "  ${BOLD}${WHITE}         ${BLUE}program${WHITE} = gpg${END}"
    echo
    echo -e "  ${BOLD}${WHITE}    ${GREY2}[tag]${END}"
    echo -e "  ${BOLD}${WHITE}         ${BLUE}forceSignAnnotated${WHITE} = true${END}"
    echo
    echo -e "  ${BOLD}${WHITE}    ${GREY2}[init]${END}"
    echo -e "  ${BOLD}${WHITE}         ${BLUE}defaultBranch${WHITE} = main${END}"
    echo
    echo -e "  ${BOLD}${WHITE}    ${GREY2}[http]${END}"
    echo -e "  ${BOLD}${WHITE}         ${BLUE}postBuffer${WHITE} = 524288000${END}"
    echo -e "  ${BOLD}${WHITE}         ${BLUE}lowSpeedLimit${WHITE} = 0${END}"
    echo

    git config --global gpg.program gpg
    git config --global commit.gpgsign true
    git config --global tag.forceSignAnnotated true
    git config --global user.signingkey ${GPG_KEY}!
    git config --global credential.helper store
    git config --global init.defaultBranch ${app_repo_branch}
    git config --global http.postBuffer 524288000
    git config --global http.lowSpeedLimit 0

    sleep 1

    echo -e "  ${BOLD}${WHITE}Automatically adding these values to your ${FUCHSIA1}.gitconfig${WHITE}:${END}"

    sleep 2

    # #
    #   run the same check as above to double confirm that user.signingKey
    #   has been defined.
    # #

    checkgit_signing=$( git config --global --get-all user.signingKey )
    if [ -z "${checkgit_signing}" ]; then
        echo
        echo -e "  ${ORANGE}WARNING      ${WHITE}Could not add the above entries to ${YELLOW}${HOME}/.gitconfig${END}"
        echo -e "               You will need to manually add these entries.${END}"
        echo
    else
        echo
        echo -e "  ${GREEN}SUCCESS      ${WHITE}Entries added to ${YELLOW}${HOME}/.gitconfig${END}"
        echo
    fi
fi

# #
#   vars > active repo branch
#   typically "main"
# #

app_repo_branch_sel=$( [[ -n "$OPT_BRANCH" ]] && echo "$OPT_BRANCH" || echo "$app_repo_branch"  )

# #
#   distribution
#   jammy, lunar, focal, noble, etc
# #

app_repo_dist_sel=$( [[ -n "$OPT_DISTRIBUTION" ]] && echo "$OPT_DISTRIBUTION" || echo "$sys_code"  )

# #
#   line > comment
#
#   allows for lines to be commented out
#
#   comment REGEX FILE [COMMENT-MARK]
#   comment "skip-grant-tables" "/etc/mysql/my.cnf"
# #

line_comment()
{
    local regx="${1:?}"
    local targ="${2:?}"
    local mark="${3:-#}"
    sudo sed -ri "s:^([ ]*)($regx):\\1$mark\\2:" "$targ"
}

# #
#   line > uncomment
#
#   allows for lines to be uncommented
#
#   uncomment REGEX FILE [COMMENT-MARK]
#   uncomment "skip-grant-tables" "/etc/mysql/my.cnf"
# #

line_uncomment()
{
    local regx="${1:?}"
    local targ="${2:?}"
    local mark="${3:-#}"
    sudo sed -ri "s:^([ ]*)[$mark]+[ ]?([ ]*$regx):\\1\\2:" "$targ"
}

# #
#   func > logs > begin
#
#   sets the script up to provide logging to the /logs/ folder
# #

Logs_Begin()
{
    if [ $OPT_NOLOG ] ; then
        echo -e
        echo -e
        printf '%-50s %-5s' "    Logging for this package has been disabled." ""
        echo -e
        echo -e
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
        printf "%-50s %-5s\n" "${TIME}      OS        : ${SYS_OS}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-50s %-5s\n" "${TIME}      OS VER    : ${SYS_OS_VER}" | tee -a "${LOGS_FILE}" >/dev/null

        printf "%-50s %-5s\n" "${TIME}      DATE      : ${DATE}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-50s %-5s\n" "${TIME}      TIME      : ${TIME}" | tee -a "${LOGS_FILE}" >/dev/null

    fi
}

# #
#   func > logs > finish
#
#   stop logging system. Mainly kills the pipe otherwise you can't access
#   the file.
# #

Logs_Finish()
{
    if [ ${PIPE_OPENED} ] ; then
        exec 1<&3
        sleep 0.2
        ps --pid ${app_pid_tee} >/dev/null
        if [ $? -eq 0 ] ; then
            # using $(wait $app_pid_tee) would be better
            # however, some commands leave file descriptors open
            sleep 1
            kill ${app_pid_tee} >> ${LOGS_FILE} 2>&1
        fi

        printf "%-50s %-15s\n" "${TIME}      Destroying Pipe ${LOGS_PIPE} (${app_pid_tee})" | tee -a "${LOGS_FILE}" >/dev/null

        rm ${LOGS_PIPE}
        unset PIPE_OPENED
    fi

    duration=${SECONDS}
    elapsed="$((${duration} / 60)) minutes and $((${duration} % 60)) seconds elapsed."

    printf "%-50s %-15s\n" "${TIME}      User Input: OnClick ......... Exit App" | tee -a "${LOGS_FILE}" >/dev/null
    printf "%-50s %-15s\n\n\n\n" "${TIME}      ${elapsed}" | tee -a "${LOGS_FILE}" >/dev/null
}

# #
#   Begin Logging
# #

Logs_Begin

# #
#   Cache Sudo Password
#
#   require normal user sudo authentication for certain actions
# #

if [[ ${EUID} -ne 0 ]]; then
    sudo -k # make sure to ask for password on next sudo
    if sudo true && [ -n "${USER}" ]; then
        printf "\n%-50s %-5s\n\n" "${TIME}      SUDO [SIGN-IN]: Welcome, ${USER}" | tee -a "${LOGS_FILE}" >/dev/null
    else
        printf "\n%-50s %-5s\n\n" "${TIME}      SUDO Failure: Wrong Password x3" | tee -a "${LOGS_FILE}" >/dev/null
        exit 1
    fi
else
    if [ -n "${USER}" ]; then
        printf "\n%-50s %-5s\n\n" "${TIME}      SUDO [EXISTING]: ${USER}" | tee -a "${LOGS_FILE}" >/dev/null
    fi
fi

# #
#   func > spinner animation
# #

spin()
{
    spinner="-\\|/-\\|/"

}

# #
#   func > spinner > halt
#
#   destroy text spinner process id
# #

spinner_halt()
{
    if ps -p ${app_pid_spin} > /dev/null
    then
        kill -9 ${app_pid_spin} 2> /dev/null
        printf "\n%-50s %-5s\n" "${TIME}      KILL Spinner: PID (${app_pid_spin})" | tee -a "${LOGS_FILE}" >/dev/null
    fi
}

# #
#   func > cli selection menu
#
#   allows for prompting user with questions and to select their desired
#   choice.
#
#   echo -e "  ${BOLD}${FUCHSIA1}ATTENTION  ${WHITE}This is a question${END}"
#
#   export CHOICES=( "Choice 1" "Choice 2" )
#   cli_options
#   case $? in
#       0 )
#           bChoiceProteus=true
#       ;;
#       1 )
#           bChoiceSqlSecure=true
#       ;;
#   esac
# #

cli_options()
{
    opts_show()
    {
        local it=$( echo $1 )
        for i in ${!CHOICES[*]}; do
            if [[ "$i" == "$it" ]]; then
                tput rev
                printf '\e[1;33m'
                printf '%4d. \e[1m\e[33m %s\t\e[0m\n' $i "${YELLOW3}  ${CHOICES[$i]}  "
                tput sgr0
            else
                printf '\e[1;33m'
                printf '%4d. \e[1m\e[33m %s\t\e[0m\n' $i "${YELLOW3}  ${CHOICES[$i]}  "
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
        if [[ ${key} == ${escaped_char} ]]; then
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
                return ${it} && exit;;
        esac

        local min_len=0
        local farr_len=$(( ${#CHOICES[@]}-1))
        if [[ "$it" -lt "$min_len" ]]; then
            it=$(( ${#CHOICES[@]}-1 ))
        elif [[ "$it" -gt "${farr_len}"  ]]; then
            it=0
        fi

        opts_show ${it}

    done
}

# #
#   func > cli question
#
#   used for command-line to prompt the user with a question
#
#   if cli_question "  Install the above packages?"; then
#       sleep 0.5
#
#       for key in "${!pendinstall[@]}"
#       do
#           app_name="${pendinstall[${key}]}"
#           app_func="${app_functions[$app_name]}"
#
#           $app_func "${app_name}" "${app_func}"
#       done
#   fi
# #

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

        #printf '%-60s %13s %-5s' "    $1 " "${YELLOW}[$syntax]${END}" ""
        echo -n "$1 [$syntax] "

        read response </dev/tty

        # NULL response uses default
        if [ -z "${response}" ]; then
            response=$def
        fi

        # validate response
        case "${response}" in
            Y|y|yes|YES)
                return 0
                ;;
            N|n|no|NO)
                return 1
                ;;
        esac

    done
}

# #
#   func > open url
#
#   opening urls in bash can be wonky as hell. just doing it the manual
#   way to ensure a browser gets opened.
#
#   example
#       open_url "http://127.0.0.1"
# #

open_url()
{
   local URL="$1"
   xdg-open $URL || firefox $URL || sensible-browser $URL || x-www-browser $URL || gnome-open $URL
}

# #
#   func > cmd title
#
#   example
#       title "First Time Setup ..."
# #

title()
{
    printf '%-57s %-5s' "  ${1}" ""
    sleep 0.3
}

# #
#   func > begin action
#
#   example
#       begin "Updating from branch main"
# #

begin()
{
    # start spinner
    spin &

    # spinner PID
    app_pid_spin=$!

    printf "%-50s %-5s\n\n" "${TIME}      NEW Spinner: PID (${app_pid_spin})" | tee -a "${LOGS_FILE}" >/dev/null

    # kill spinner on any signal
    trap "kill -9 ${app_pid_spin} 2> /dev/null" `seq 0 15`

    printf '%-50s %-5s' "  ${1}" ""

    sleep 0.3
}

# #
#   func > finish action
#
#   this func supports opening a url at the end of the installation
#   however the command needs to have
#       finish "${1}"
# #

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

# #
#   func > exit action
# #

exit()
{
    finish
    clear
}

# #
#   func > env path (add)
#
#   creates a new file inside /etc/profile.d/ which includes the new
#   proteus bin folder.
#
#   proteus-aptget.sh will house the path needed for the script to run
#   anywhere with an entry similar to:
#
#       export PATH="/home/aetherinox/bin:$PATH"
# #

envpath_add_proteus()
{
    local file_env=/etc/profile.d/proteus.sh
    if [ "$2" = "force" ] || ! echo ${PATH} | $(which egrep) -q "(^|:)$1($|:)" ; then
        if [ "$2" = "after" ] ; then
            echo 'export PATH="$PATH:'$1'"' | sudo tee ${file_env} > /dev/null
        else
            echo 'export PATH="'$1':$PATH"' | sudo tee ${file_env} > /dev/null
        fi
    fi
}

envpath_add_lastversion()
{
    local file_env=/etc/profile.d/lastversion.sh
    if [ "$2" = "force" ] || ! echo ${PATH} | $(which egrep) -q "(^|:)$1($|:)" ; then
        if [ "$2" = "after" ] ; then
            echo 'export PATH="$PATH:'$1'"' | sudo tee ${file_env} > /dev/null
        else
            echo 'export PATH="'$1':$PATH"' | sudo tee ${file_env} > /dev/null
        fi
    fi
}

# #
#   func > app update
#
#   updates the /home/USER/bin/proteus file which allows proteus to be
#   ran from anywhere.
#
#   activate using ./proteus --update or -u
# #

app_update()
{
    local repo_branch=$([ "${1}" ] && echo "${1}" || echo "${app_repo_branch}" )
    local branch_uri="${app_repo_script/BRANCH/"$repo_branch"}"
    local IsSilent=${2}

    begin "Updating from branch [${repo_branch}]"

    sleep 1
    echo -e

    printf '%-50s %-5s' "    |--- Downloading update" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo wget -O "${path_file_bin_binary}" -q "${branch_uri}" >> ${LOGS_FILE} 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    printf '%-50s %-5s' "    |--- Set ownership to ${USER}" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo chgrp ${USER} ${path_file_bin_binary} >> ${LOGS_FILE} 2>&1
        sudo chown ${USER} ${path_file_bin_binary} >> ${LOGS_FILE} 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    printf '%-50s %-5s' "    |--- Set perms to u+x" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo chmod u+x ${path_file_bin_binary} >> ${LOGS_FILE} 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"
    echo -e

    sleep 2
    echo -e "  ${BOLD}${GREEN}Update Complete!${END}" >&2
    sleep 2

    finish
}

# #
#   func > app update
#
#   updates the /home/USER/bin/proteus file which allows proteus to be
#   ran from anywhere.
# #

if [ "${OPT_UPDATE}" = true ]; then
    app_update ${app_repo_branch_sel}
fi

# #
#   .git folder doesnt exist
#
#   this feature is not fully developed. It is supposed to allow
#   the proteus apt repo to be downloaded locally to the server and 
#   ran.
#
#   for now, manually use git clone and then run the proteus script
# #

if [ ! -d .git ]; then

    echo -e
    echo -e "  ${ORANGE}Error${WHITE}"
    echo -e "  "
    echo -e "  ${WHITE}Folder ${YELLOW}.git${END} does not exist."
    echo -e "  ${WHITE}Must clone ${YELLOW}${app_repo_apt_url}${END} first."
    echo -e
    echo -e "  Couldn't find .git folder in ${app_dir}"
    echo -e

    app_run_github_precheck

    # git clone -b main https://github.com/Aetherinox/proteus-apt-repo.git
    git init --initial-branch=${app_repo_branch}
    git remote add origin https://github.com/${GITHUB_NAME}/${app_repo_apt}.git
    git fetch
    git checkout origin/main -b main

    git add .

    # #
    #   
    #   -m <msg>, --message=<msg> 
    #   -s, --signoff 
    # #

    git commit -S -m "New Server Addition"
    git pull https://${GITHUB_NAME}:${CSI_PAT_GITHUB}@github.com/${GITHUB_NAME}/${app_repo_apt}.git

    # git remote add origin https://github.com/Aetherinox/${${app_repo_apt}}.git
    # git pull origin ${app_repo_branch} --allow-unrelated-histories
    # git push --set-upstream origin main 
fi

# #
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
# #

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
    local bMissingLastVersion=false

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

    # require lastversion
    if ! [ -x "$(command -v lastversion)" ]; then
        bMissingLastVersion=true
    fi

    # #
    #   Missing proteus-apt-repo gpg key
    #
    #   NOTE:   apt-key has been deprecated
    #           sudo add-apt-repository -y "deb [arch=amd64] https://raw.githubusercontent.com/${GITHUB_NAME}/${app_repo_apt}/master focal main" >> $LOGS_FILE 2>&1
    # #

    if ! [ -f "/usr/share/keyrings/${app_repo_apt_pkg}.gpg" ]; then
        bMissingGPG=true
    fi

    # #
    #   Missing browsers .list (google chrome, firefox)
    # #

    if ! [ -f "/etc/apt/sources.list.d/google-chrome.list" ]; then
        bMissingGChrome=true
    fi

    if ! [ -f "/etc/apt/sources.list.d/mozilla.list" ]; then
        bMissingMFirefox=true
    fi

    # #
    #   Missing proteus-apt-repo .list
    # #

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

    # #
    #   find a gpg key that can be imported
    #   maybe later add a loop to check for multiple.
    #
    #   PATH GPG_KEY missing from secrets.sh
    # #

    if [ -z "${GPG_KEY}" ]; then
        echo
        echo -e "  ${ORANGE}WARNING      ${YELLOW}GPG_KEY${WHITE} Not Specified${END}"
        echo -e "               Must create ${FUCHSIA1}${path_file_secret_sh}${END} file and define your GPG key.${END}"
        echo -e
        echo -e "                    ${GREY2}${RED}export ${GREEN}GPG_KEY=${WHITE}XXXXXXXX${END}"
        echo

        printf "  Press any key to abort ... ${END}"
        read -n 1 -s -r -p ""
        echo -e
        echo -e

        set +m
        trap "kill -9 $app_pid 2> /dev/null" `seq 0 15`
        kill $app_pid
        set -m

    # #
    #   no gpg key registered with gpg command line via gpg --list-secret-keys
    # #

    else
        gpg_id=$( gpg --list-secret-keys --keyid-format=long | grep $GPG_KEY )
    
        echo -e "  ${GREEN}OK           ${END}Found GPG key ${BLUE2}${gpg_id}${END}"
    
        if [[ $? == 0 ]]; then 
            echo -e
            echo -e "  ${GREEN}OK           ${END}Loading GPG key ${BLUE2}${gpg_id}${END}"
            echo -e

            bGPGLoaded=true

            sleep 5
        else
            echo -e
            echo -e "  ${ORANGE}Error${END}"
            echo -e "  "
            echo -e "  ${END}Specified GPG key ${YELLOW}${GPG_KEY}${END} not found in GnuPG key store."
            echo -e "  ${END}Searching ${YELLOW}${app_dir}/${app_dir_gpg}/${END} for a GPG key to import."
            echo -e

            sleep 1

            # #
            #   find *.gpg
            # #

            if [ -f $app_dir/.gpg/*.gpg ]; then
                gpg_file=$app_dir/${app_dir_gpg}/*.gpg
                gpg --import $gpg_file
                bGPGLoaded=true

                echo -e
                echo -e "  ${GREEN}OK           ${END}Found ${YELLOW}${app_dir}/${app_dir_gpg}/${gpg_file}${END} to import.${END}"
                echo -e

            # #
            #   find *.asc
            # #

            elif [ -f $app_dir/.gpg/*.asc ]; then
                gpg_file=${app_dir}/${app_dir_gpg}/*.asc
                gpg --import $gpg_file
                bGPGLoaded=true

                echo -e
                echo -e "  ${GREEN}OK           ${END}Found ${YELLOW}${app_dir}/${app_dir_gpg}/${gpg_file}${END} to import.${END}"
                echo -e

            # #
            #   no .gpg, .asc keys found
            # #

            else
                if [ -z "${OPT_DLPKG_ONLY_TEST}" ]; then
                    echo -e
                    echo -e "  ${RED2}ERROR        ${END}No GPG keys found to import. ${RED}Aborting${END}"
                    echo -e

                    set +m
                    trap "kill -9 $app_pid 2> /dev/null" `seq 0 15`
                    kill $app_pid
                    set -m
                else
                    echo -e
                    echo -e "  ${RED2}WARN         ${END}No GPG keys found to import. Since you are in ${YELLOW}--onlyTest${END} mode, ${YELLOW}Skipping}${END}"
                    echo -e
                fi
            fi

            printf "  Press any key to continue ... ${END}"
            read -n 1 -s -r -p ""
            echo -e
        fi
    fi

    # #
    #   missing gpg key after searching numerous places, including .gpg folder
    #
    #   bGPGLoaded      TRUE if either condition is met:
    #                   1. gpg --list-keys KEY_ID found
    #                   2. found .gpg file in ./gpg folder
    # #

    if [ "$bGPGLoaded" = false ] && [ -z "${OPT_DLPKG_ONLY_TEST}" ]; then

        echo -e 
        echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
        echo
        echo -e "  ${ORANGE}WARNING      ${WHITE}Missing Private GPG Key${END}"
        echo -e "               You must have a private GPG key imported to use this program.${END}"
        echo -e "               Your private GPG key is used to sign commits and the deb package${END}"
        echo -e "               repositories that you upload.${END}"
        echo -e
        echo -e "               You must either add a private .gpg keyfile to the folder:${END}"
        echo -e "                    ${GREY2}${YELLOW}${app_dir}/${app_dir_gpg}/${END}"
        echo -e
        echo -e "               Or manually import a GPG key to your system's GPG keyring${END}"
        echo
        echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
        echo -e

        printf "  Press any key to abort ... ${END}"
        read -n 1 -s -r -p ""
        echo
        echo

        set +m
        trap "kill -9 $app_pid 2> /dev/null" `seq 0 15`
        kill $app_pid
        set -m
    fi

    # #
    #   missing curl
    # #

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

    # #
    #   missing wget
    # #

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

    # #
    #   missing tree
    # #

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

    # #
    #   missing gpg trusted file
    #
    #   bMissingGPG     File /usr/share/keyrings/${app_repo_apt_pkg}.gpg not found
    # #

    if [ "$bMissingGPG" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Adding ${GITHUB_NAME} GPG key: [https://github.com/${GITHUB_NAME}.gpg]" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Adding github.com/${GITHUB_NAME}.gpg" ""

        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo wget -qO - "https://github.com/${GITHUB_NAME}.gpg" | sudo gpg --batch --yes --dearmor -o "/usr/share/keyrings/${app_repo_apt_pkg}.gpg" >/dev/null
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    # #
    #   missing google chrome
    #
    #   add google source repo so that chrome can be downloaded using apt-get
    # #

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

        printf "%-50s %-5s\n" "${TIME}      Updating user repo list with apt-get update" | tee -a "${LOGS_FILE}" >/dev/null

        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >/dev/null
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    # #
    #   missing mozilla repo
    #
    #   add mozilla source repo so that firefox can be downloaded using apt-get
    #   instructions via:
    #       https://support.mozilla.org/en-US/kb/install-firefox-linux#w_install-firefox-deb-package-for-debian-based-distributions
    # #

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

        printf "%-50s %-5s\n" "${TIME}      Updating user repo list with apt-get update" | tee -a "${LOGS_FILE}" >/dev/null

        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >/dev/null
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    # #
    #   missing proteus apt repo
    # #

    if [ "$bMissingRepo" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Registering ${app_repo_apt}: https://raw.githubusercontent.com/${GITHUB_NAME}/${app_repo_apt}/${app_repo_branch}" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Registering ${app_repo_apt}" ""

        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/${app_repo_apt_pkg}.gpg] https://raw.githubusercontent.com/${GITHUB_NAME}/${app_repo_apt}//${app_repo_branch} $(lsb_release -cs) ${app_repo_branch}" | sudo tee /etc/apt/sources.list.d/${app_repo_apt_pkg}.list >/dev/null
        fi

        sleep 0.5

        printf "%-50s %-5s\n" "${TIME}      Updating user repo list with apt-get update" | tee -a "${LOGS_FILE}" >/dev/null
        
        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >/dev/null
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    # #
    #   install proteus binary in ${HOME}/bin/proteus
    # #

    if ! [ -f "$path_file_bin_binary" ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing ${app_title}" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Installing ${app_title}" ""

        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            mkdir -p "$app_dir_bin"

            local branch_uri="${app_repo_script/BRANCH/"$app_repo_branch_sel"}"
            sudo wget -O "${path_file_bin_binary}" -q "$branch_uri" >> $LOGS_FILE 2>&1
            sudo chgrp ${USER} ${path_file_bin_binary} >> $LOGS_FILE 2>&1
            sudo chown ${USER} ${path_file_bin_binary} >> $LOGS_FILE 2>&1
            sudo chmod u+x ${path_file_bin_binary} >> $LOGS_FILE 2>&1
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    # #
    #   missing apt-move
    # #

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

    # #
    #   missing apt-url
    # #

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

    # #
    #   missing reprepro
    # #

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

    # #
    #   add env path ${HOME}/bin/
    # #

    envpath_add_proteus '${HOME}/bin'

    # #
    #   missing lastversion
    # #

    if [ "$bMissingLastVersion" = true ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing LastVersion" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Adding LastVersion package" ""

        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install python3-pip python3-venv -y -qq >> /dev/null 2>&1
            sudo pip3 install --upgrade --force pip >> /dev/null 2>&1

            # wget https://github.com/dvershinin/lastversion/archive/refs/tags/v3.5.0.zip
            # mkdir ${HOME}/Packages/
            # unzip v3.5.0.zip -d ${HOME}/Packages/lastversion

            # #
            #   Uninstall with
            #       pip uninstall lastversion
            #
            #   note:   --break-system-packages is only available for pip
            #           23.1 and forward.
            #
            #           get version by using
            #               pip --version
            # #

            pip install lastversion --break-system-packages
            cp ${HOME}/.local/bin/lastversion ${HOME}/bin/
            sudo touch /etc/profile.d/lastversion.sh

            envpath_add_lastversion '${HOME}/bin'

            echo 'export PATH="${HOME}/bin:$PATH"' | sudo tee /etc/profile.d/lastversion.sh

            . ~/.bashrc
            . ~/.profile

            source ${HOME}/.profile # not executing for some reason
        fi

        sleep 0.5
        echo -e "[ ${STATUS_OK} ]"
    fi

    # #
    #   modify gpg-agent.conf
    #
    #   first check if GPG installed (usually on Ubuntu it is)
    #   then modify user's gpg-agent.conf file
    # #

    gpgconfig_file="${HOME}/.gnupg/gpg-agent.conf"

    if ! [ -x "$(command -v gpg)" ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf '%-57s' "    |--- Installing GPG"
        sleep 1

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install gpg -y -qq >> /dev/null 2>&1
        fi

        echo -e "[ ${STATUS_OK} ]"
        sleep 1
    fi

    printf '%-57s' "    |--- Import GPG configs into ${gpgconfig_file}"
    sleep 1
sudo tee ${gpgconfig_file} << EOF > /dev/null
enable-putty-support
enable-ssh-support
use-standard-socket
default-cache-ttl-ssh 60
max-cache-ttl-ssh 120
default-cache-ttl 63072000 # gpg key cache time
max-cache-ttl 63072000 # max gpg key cache time
pinentry-program "/usr/bin/pinentry"
allow-loopback-pinentry
allow-preset-passphrase
pinentry-timeout 0
EOF
    echo -e "[ ${STATUS_OK} ]"

    printf '%-57s' "    |--- Set ownership to ${USER}"
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo chgrp ${USER} ${gpgconfig_file} >> $LOGS_FILE 2>&1
        sudo chown ${USER} ${gpgconfig_file} >> $LOGS_FILE 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    printf '%-57s' "    |--- Restart GPG Agent"
    sleep 1
    gpgconf --kill gpg-agent
    echo -e "[ ${STATUS_OK} ]"

    # #
    #   SECRETS > GPG precache
    # #

    if [ -f ${path_file_secret_passwd_gpg} ]; then
        CSI_GPG_PASSWD=$(cat ${path_file_secret_passwd_gpg} | clevis decrypt 2>/dev/null)

        # #
        #   SECRETS > METHOD > CLEVIS
        #       CSI_GPG_PASSWD valid (not empty)
        # #

        if [ -n "${CSI_GPG_PASSWD}" ]; then
            echo "${CSI_GPG_PASSWD}" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 --output /dev/null --sign
        fi
    fi

    sleep 0.5

}
app_setup

# #
#   output some logging
# #

[ -n "${OPT_DEV_ENABLE}" ] && printf "%-50s %-5s\n" "${TIME}      Notice: Dev Mode Enabled" | tee -a "${LOGS_FILE}" >/dev/null
[ -z "${OPT_DEV_ENABLE}" ] && printf "%-50s %-5s\n" "${TIME}      Notice: Dev Mode Disabled" | tee -a "${LOGS_FILE}" >/dev/null

[ -n "${OPT_DEV_NULLRUN}" ] && printf "%-50s %-5s\n\n" "${TIME}      Notice: Dev Option: 'No Actions' Enabled" | tee -a "${LOGS_FILE}" >/dev/null
[ -z "${OPT_DEV_NULLRUN}" ] && printf "%-50s %-5s\n\n" "${TIME}      Notice: Dev Option: 'No Actions' Disabled" | tee -a "${LOGS_FILE}" >/dev/null

# #
#   header
# #

show_header()
{
    clear

    sleep 0.3

    echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
    echo -e " ${GREEN}${BOLD} ${app_title} - v$(get_version)${END}${MAGENTA}"
    echo
    echo -e "  This is a package which handles the Proteus App Manager behind"
    echo -e "  the scene by grabbing from the list of registered packages"
    echo -e "  and adding them to the queue to be updated."
    echo

    printf '%-35s %-40s\n' "  ${BOLD}${GREY3}GPG KEY ${END}" "${BOLD}${FUCHSIA1} $GPG_KEY ${END}"
    echo

    if [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf '%-35s %-40s\n' "  ${BOLD}${GREY3}PID ${END}" "${BOLD}${FUCHSIA1} $$ ${END}"
        printf '%-35s %-40s\n' "  ${BOLD}${GREY3}USER ${END}" "${BOLD}${FUCHSIA1} ${USER} ${END}"
        printf '%-35s %-40s\n' "  ${BOLD}${GREY3}APPS ${END}" "${BOLD}${FUCHSIA1} ${app_i} ${END}"
        printf '%-35s %-40s\n' "  ${BOLD}${GREY3}DEV ${END}" "${BOLD}${FUCHSIA1} $([ -n "${OPT_DEV_ENABLE}" ] && echo "Enabled" || echo "Disabled" ) ${END}"
        echo
    fi

    echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
    echo

    sleep 0.3

    printf "%-50s %-5s\n" "${TIME}      Successfully loaded ${app_i} packages" | tee -a "${LOGS_FILE}" >/dev/null
    printf "%-50s %-5s\n" "${TIME}      Waiting for user input ..." | tee -a "${LOGS_FILE}" >/dev/null
}

# #
#   app > run > apt source packages
#
#   updates apt source packages for the distro being used
# #

app_run_dl_aptget()
{

    # #
    #   sort alphabetically
    # #

    IFS=$'\n' lst_pkgs_sorted=($(sort <<<"${lst_packages[*]}"))
    unset IFS

    # #
    #   add countdown to the num of packages to install
    # #

    count=${#lst_pkgs_sorted[@]}

    # #
    #   Begin
    # #

    begin "Aptget Packages [ $count ]"
    echo -e

    # #
    #   Create main folders for architecture
    #   all, amd64, arm54, i386
    # #

    mkdir -p ${app_dir_storage}/{all,amd64,arm64,i386}

    # #
    #   set new package
    #
    #   each main package has several downloads, one for amd64, one for arm64, and all
    #   when this script is ran and each package is shown in terminal for the user as it downloads,
    #   this flag groups things together so that you don't see the same count for each sub package.
    #
    #   a new package will start out with its current number in line to the left of the package name.
    #   all sub-packages are listed under without the count.
    #
    #   |--- [ 120 ] Get networkd-dispatcher:all
    #           Package         networkd-dispatcher:all
    #           File            networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
    #           Download        http://us.archive.ubuntu.com/ubuntu/pool/main/n/networkd-dispatcher/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
    #           Move            /server/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb > /server/proteus/incoming/packages/jammy/all/
    #           Status:         💡 Already exists
    #
    #       Get networkd-dispatcher:amd64
    #           Package         networkd-dispatcher:amd64
    #           File            networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
    #           Status:         ⭕ Double file detected /server/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
    #
    #       Get networkd-dispatcher:arm64
    #           Package         networkd-dispatcher:arm64
    #           File            Couldn't find package networkd-dispatcher:arm64
    #           Status:         🔍 arm64 doesn't exist for this package
    # #

    local bNewPackage=true

    # #
    #   loop sorted packages
    # #

    for i in "${!lst_pkgs_sorted[@]}"; do

        # #
        #   get package name
        #       networkd-dispatcher
        # #

        pkg=${lst_pkgs_sorted[$i]}

        # #
        #   loop each architecture for each package
        #       all
        #       amd64
        #       arm64
        #       i386
        # #

        for j in "${!lst_arch[@]}"; do

            # #
            #   get architecture
            #       amd64, arm64, i386, all
            # #

            arch=${lst_arch[$j]}
            
            # #
            #   get package name and arch combined
            #       networkd-dispatcher:all
            #       networkd-dispatcher:amd64
            #       networkd-dispatcher:arm64
            # #

            local pkg_arch="${pkg}:${arch}"

            # #
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
            # #

            # #
            #   run package through apt-url
            #   this returns a multi-line result which needs broken up into two values
            #
            #   an alternative to apt-url is using
            #       apt download --print-uris apt-move:all
            # #

            apturl_exit_code="0"
            apturl_query="$(sudo apt-url "${pkg_arch}" \
                "$@" 2>&1)" \
                || { apturl_exit_code="$?" ; true; };

            # #
            #   break the two apturl values up into separate variables
            #       app_filename        networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
            #       app_url             http://us.archive.ubuntu.com/ubuntu/pool/main/n/networkd-dispatcher/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
            # #

            app_filename=$( echo "${apturl_query}" | head -n 1; )
            app_url=$( echo "${apturl_query}" | tail -n 1; )

            # #
            #   determines if a new package should be shown, or the architecture
            #   
            #   bNewPackage = true
            #       |--- [ 120 ] Get networkd-dispatcher:all
            #   
            #   bNewPackage = false
            #       Get networkd-dispatcher:amd64
            # #

            if [ "$bNewPackage" = true ]; then
                echo -e "     ${GREY2}|--- ${YELLOW}[ ${count} ]${FUCHSIA1}${BOLD} Get ${pkg_arch:0:35}${END}"
            else
                echo -e "               ${FUCHSIA1}${BOLD} Get ${pkg_arch:0:35}${END}"
            fi

            # #
            #   kill reprepro if running
            # #

            sudo pkill -9 "reprepro"

            # #
            #   lockfile exists, remove it to ensure we can download the package
            # #

            if [ -f "${app_dir}/db/lockfile" ]; then
                sudo rm "${app_dir}/db/lockfile"
            fi

            # #
            #   take the download url provided by apt-url and download the package using wget
            # #

            wget "${app_url}" -q

            # #
            #   output > package info
            # #

            echo -e "  ${WHITE}                Package         ${FUCHSIA1}${pkg_arch}${END}"
            echo -e "  ${WHITE}                File            ${FUCHSIA1}${app_filename}${END}"

            # #
            #   output > architecture doesn't exist for this package
            # #

            if echo "$apturl_query" | grep --quiet --ignore-case "find package" ; then
                echo -e "  ${WHITE}                ${GREEN}Status:         ${FUCHSIA1}🔍 ${arch:0:35}${END} doesn't exist for this package"
            fi

            # #
            #   output > apt-url cannot be run because apt get is held up by another process
            # #

            if echo "$apturl_query" | grep --quiet --ignore-case "It is held by process" ; then
                echo -e "  ${WHITE}                ${GREEN}Status:         ${FUCHSIA1}🗔 ${pkg_arch:0:35}${END} held up by process"
            fi

            # #
            #   check if file exists
            #       ${HOME}/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
            # #

            if [[ -f "${app_dir}/${app_filename}" ]]; then

                # #
                #   architecture > all
                #   file must end with 'all.deb'
                # #

                if [[ "${arch}" == "all" ]] && [[ ${app_filename} == *all.deb ]]; then
                    echo -e "  ${WHITE}                Download        ${FUCHSIA1}${app_url}${END}"

                    # #
                    #   architecture > all
                    #   move package to its final location inside the reprepro directory
                    #       move    ${HOME}/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
                    #       to      ${HOME}/proteus/incoming/packages/jammy/all/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
                    # #

                    mv "${app_dir}/${app_filename}" "${app_dir_storage}/all/"

                    echo -e "  ${WHITE}                Move            ${FUCHSIA1}${app_dir}/${app_filename}${WHITE} > ${FUCHSIA1}${app_dir_storage}/all/${END}"

                    if [ -n "${bRepreproInstalled}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then

                        # #
                        #   architecture > all > full package path
                        #
                        #       deb_package             incoming/proteus-git/jammy/all/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
                        # #

                        deb_package="${app_dir_repo}/${arch}/${app_filename}"

                        # #
                        #   architecture > all > reprepro
                        #   add package to reprepro database
                        #
                        #       app_repo_dist_sel       jammy
                        #       deb_package             incoming/packages/jammy/all/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
                        # #

                        echo -e "  ${WHITE}                Reprepro        ${FUCHSIA1}${deb_package}${END} for dist ${FUCHSIA1}${app_repo_dist_sel}${END}"
                        echo -e "  ${WHITE}                                    ${FUCHSIA1}reprepro -V --section utils --component main --priority 0 includedeb ${app_repo_dist_sel} ${deb_package}${END}"

                        reprepro_exit_code="0"
                        reprepro_output="$(reprepro -V \
                            --section utils \
                            --component main \
                            --priority 0 \
                            includedeb "${app_repo_dist_sel}" "${deb_package}" \
                            "$@" 2>&1)" \
                            || { reprepro_exit_code="$?" ; true; };

                        # #
                        #   architecture > all > reprepro
                        #
                        #   output > package already added to reprepro
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "exists" ; then
                            echo -e "  ${WHITE}                ${GREEN}Status:         ${END}💡 Already exists${END}"
                        fi

                        # #
                        #   architecture > all > reprepro
                        #
                        #   output > new package added
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                            echo -e "  ${WHITE}                ${GREEN}Status:         ${END}✅ New package added${END}"
                        fi
                    fi

                    bNewPackage=false

                # #
                #   architecture > amd64
                #   file must end with 'amd64.deb'
                # #

                elif [[ "${arch}" == "amd64" ]] && [[ ${app_filename} == *amd64.deb ]]; then
                    echo -e "  ${WHITE}                Download        ${FUCHSIA1}${app_url}${END}"

                    # #
                    #   architecture > amd64
                    #   move package to its final location inside the reprepro directory
                    #       move    ${HOME}/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.2_amd64.deb
                    #       to      ${HOME}/proteus/incoming/packages/jammy/amd64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_amd64.deb
                    # #

                    mv "${app_dir}/${app_filename}" "${app_dir_storage}/amd64/"

                    echo -e "  ${WHITE}                Move            ${FUCHSIA1}${app_dir}/${app_filename}${WHITE} > ${FUCHSIA1}${app_dir_storage}/amd64/${END}"

                    if [ -n "${bRepreproInstalled}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then

                        # #
                        #   architecture > amd64 > full package path
                        #
                        #       deb_package             incoming/packages/jammy/amd64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_amd64.deb
                        # #

                        deb_package="${app_dir_repo}/${arch}/${app_filename}"

                        # #
                        #   architecture > amd64 > reprepro
                        #   add package to reprepro database
                        #
                        #       app_repo_dist_sel       jammy
                        #       deb_package             incoming/packages/jammy/amd64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_amd64.deb
                        # #

                        echo -e "  ${WHITE}                Reprepro        ${FUCHSIA1}${deb_package}${END} for dist ${FUCHSIA1}${app_repo_dist_sel}${END}"
                        echo -e "  ${WHITE}                                    ${FUCHSIA1}reprepro -V --section utils --component main --priority 0 includedeb ${app_repo_dist_sel} ${deb_package}${END}"

                        reprepro_exit_code="0"
                        reprepro_output="$(reprepro -V \
                            --section utils \
                            --component main \
                            --priority 0 \
                            --architecture ${arch} \
                            includedeb "${app_repo_dist_sel}" "${deb_package}" \
                            "$@" 2>&1)" \
                            || { reprepro_exit_code="$?" ; true; };

                        # #
                        #   architecture > amd64 > reprepro
                        #
                        #   output > package already added to reprepro
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "exists" ; then
                            echo -e "  ${WHITE}                ${GREEN}Status:         ${END}💡 Already exists${END}"
                        fi

                        # #
                        #   architecture > amd64 > reprepro
                        #
                        #   output > new package added
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                            echo -e "  ${WHITE}                ${GREEN}Status:         ${END}✅ New package added${END}"
                        fi
                    fi

                    bNewPackage=false

                # #
                #   architecture > arm64
                #   file must end with 'arm64.deb'
                # #

                elif [[ "${arch}" == "arm64" ]] && [[ ${app_filename} == *arm64.deb ]]; then
                    echo -e "  ${WHITE}                Download        ${FUCHSIA1}${app_url}${END}"

                    # #
                    #   architecture > arm64
                    #   move package to its final location inside the reprepro directory
                    #       move    ${HOME}/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.2_arm64.deb
                    #       to      ${HOME}/proteus/incoming/packages/jammy/arm64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_arm64.deb
                    # #

                    mv "${app_dir}/${app_filename}" "${app_dir_storage}/arm64/"

                    echo -e "  ${WHITE}                Move            ${FUCHSIA1}${app_dir}/${app_filename}${WHITE} > ${FUCHSIA1}${app_dir_storage}/arm64/${END}"

                    if [ -n "${bRepreproInstalled}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then

                        # #
                        #   architecture > arm64 > full package path
                        #
                        #       deb_package             incoming/packages/jammy/arm64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_arm64.deb
                        # #

                        deb_package="${app_dir_repo}/${arch}/${app_filename}"

                        # #
                        #   architecture > arm64 > reprepro
                        #   add package to reprepro database
                        #
                        #       app_repo_dist_sel       jammy
                        #       deb_package             incoming/packages/jammy/arm64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_arm64.deb
                        # #

                        echo -e "  ${WHITE}                Reprepro        ${FUCHSIA1}${deb_package}${END} for dist ${FUCHSIA1}${app_repo_dist_sel}${END}"
                        echo -e "  ${WHITE}                                    ${FUCHSIA1}reprepro -V --section utils --component main --priority 0 includedeb ${app_repo_dist_sel} ${deb_package}${END}"

                        reprepro_exit_code="0"
                        reprepro_output="$(reprepro -V \
                            --section utils \
                            --component main \
                            --priority 0 \
                            --architecture ${arch} \
                            includedeb "${app_repo_dist_sel}" "${deb_package}" \
                            "$@" 2>&1)" \
                            || { reprepro_exit_code="$?" ; true; };

                        # #
                        #   architecture > arm64 > reprepro
                        #
                        #   output > package already added to reprepro
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "exists" ; then
                            echo -e "  ${WHITE}                ${GREEN}Status:         ${END}💡 Already exists${END}"
                        fi

                        # #
                        #   architecture > arm64 > reprepro
                        #
                        #   output > new package added
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                            echo -e "  ${WHITE}                ${GREEN}Status:         ${END}✅ New package added${END}"
                        fi
                    fi

                    bNewPackage=false

                # #
                #   architecture > i386
                #   file must end with 'i386.deb'
                # #

                elif [[ "$arch" == "i386" || "$arch" == "386" ]] && [[ $app_filename == *i386.deb || $app_filename == *i386*.deb || $app_filename == *386.deb || $app_filename == *386*.deb ]]; then
                    echo -e "  ${WHITE}                Download        ${FUCHSIA1}${app_url}${END}"

                    # #
                    #   architecture > i386
                    #   move package to its final location inside the reprepro directory
                    #       move    ${HOME}/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.i386.deb
                    #       to      ${HOME}/proteus/incoming/packages/jammy/i386/networkd-dispatcher_2.1-2ubuntu0.22.04.i386.deb
                    # #

                    mv "${app_dir}/${app_filename}" "${app_dir_storage}/i386/"

                    echo -e "  ${WHITE}                Move            ${FUCHSIA1}${app_dir}/${app_filename}${WHITE} > ${FUCHSIA1}${app_dir_storage}/i386/${END}"

                    if [ -n "${bRepreproInstalled}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then

                        # #
                        #   architecture > i386 > full package path
                        #
                        #       deb_package             incoming/packages/jammy/i386/networkd-dispatcher_2.1-2ubuntu0.22.04.i386.deb
                        # #

                        deb_package="${app_dir_repo}/${arch}/${app_filename}"

                        # #
                        #   architecture > i386 > reprepro
                        #   add package to reprepro database
                        #
                        #       app_repo_dist_sel       jammy
                        #       deb_package             incoming/packages/jammy/i386/networkd-dispatcher_2.1-2ubuntu0.22.04.i386.deb
                        # #

                        echo -e "  ${WHITE}                Reprepro        ${FUCHSIA1}${deb_package}${END} for dist ${FUCHSIA1}${app_repo_dist_sel}${END}"
                        echo -e "  ${WHITE}                                    ${FUCHSIA1}reprepro -V --section utils --component main --priority 0 includedeb ${app_repo_dist_sel} ${deb_package}${END}"

                        reprepro_exit_code="0"
                        reprepro_output="$(reprepro -V \
                            --section utils \
                            --component main \
                            --priority 0 \
                            --architecture ${arch} \
                            includedeb "${app_repo_dist_sel}" "${deb_package}" \
                            "$@" 2>&1)" \
                            || { reprepro_exit_code="$?" ; true; };

                        # #
                        #   architecture > i386 > reprepro
                        #
                        #   output > package already added to reprepro
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "exists" ; then
                            echo -e "  ${WHITE}                ${GREEN}Status:         ${END}💡 Already exists${END}"
                        fi

                        # #
                        #   architecture > i386 > reprepro
                        #
                        #   output > new package added
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                            echo -e "  ${WHITE}                ${GREEN}Status:         ${END}✅ New package added${END}"
                        fi
                    fi

                    bNewPackage=false

                # #
                #   certain packages will output an *amd64, *arm64 and *i386 file when calling
                #   the "all" architecture, which means you'll have double the files.
                #
                #   delete the left-over files since we already have them.
                # #

                else
                    rm "${app_dir}/${app_filename}"
                    echo -e "  ${WHITE}                ${GREEN}Status:         ${END}⭕ Double file detected ${FUCHSIA1}${app_dir}/${app_filename}${END}${END}"
                fi

                sleep 1

            fi

            bNewPackage=false
            echo -e
        done

        (( count-- ))

        bNewPackage=true
        echo -e

    done

}

# #
#   app > run > github (using lastversion)
#
#   check github repos and download any updates that will be added to our
#   apt repo.
# #

app_run_dl_lastver()
{

    # #
    #   add countdown to the num of packages to install
    # #

    count=${#lst_github[@]}

    # #
    #   Begin
    # #

    begin "Github Packages [ $count ]"
    echo -e

    # #
    #   Create main folders for architecture
    #   all, amd64, arm54, i386
    # #

    mkdir -p ${app_dir_storage}/{all,amd64,arm64,i386}

    # #
    #   set new package
    #
    #   each main package has several downloads, one for amd64, one for arm64, and all
    #   when this script is ran and each package is shown in terminal for the user as it downloads,
    #   this flag groups things together so that you don't see the same count for each sub package.
    #
    #   a new package will start out with its current number in line to the left of the package name.
    #   all sub-packages are listed under without the count.
    #
    #   |--- [ 4 ] Get GitHubDesktop-linux-amd64-3.4.2-linux1.deb
    #           Package         amd64
    #           File            GitHubDesktop-linux-amd64-3.4.2-linux1.deb
    #           Download        https://github.com/shiftkey/desktop/releases/download/release-3.4.2-linux1/GitHubDesktop-linux-amd64-3.4.2-linux1.deb
    #           Move            ${HOME}/Repos/GitHubDesktop-linux-amd64-3.4.2-linux1.deb > ${HOME}/Repos/incoming/packages/jammy/amd64/
    #           Reprepro        incoming/packages/jammy/amd64/GitHubDesktop-linux-amd64-3.4.2-linux1.deb for dist jammy
    #           Status:         💡 Already exists
    #
    #       Get GitHubDesktop-linux-arm64-3.4.2-linux1.deb
    #           Package         arm64
    #           File            GitHubDesktop-linux-arm64-3.4.2-linux1.deb
    #           Download        https://github.com/shiftkey/desktop/releases/download/release-3.4.2-linux1/GitHubDesktop-linux-arm64-3.4.2-linux1.deb
    #           Move            ${HOME}/Repos/GitHubDesktop-linux-arm64-3.4.2-linux1.deb > ${HOME}/Repos/incoming/packages/jammy/arm64/
    #           Reprepro        incoming/packages/jammy/arm64/GitHubDesktop-linux-arm64-3.4.2-linux1.deb for dist jammy
    #           Status:         💡 Already exists
    # #

    local bNewPackage=true

    # #
    #   loop each package listed in the lastver / github table
    # #

    for i in "${!lst_github[@]}"
    do

        # #
        #   set repo url to variable
        #
        #       obsidianmd/obsidian-releases
        #       AppOutlet/AppOutlet
        # #

        repo=${lst_github[$i]}

        # #
        #   use LastVersion to view all of the releases on a github repo and pull out the files that match the filenames:
        #       *amd64*.deb
        #       *arm64*.deb
        #       *i386*.deb
        #       *386*.deb
        #
        #       *jammy*.deb
        #       *focal*.deb
        #       *mantic*.deb
        #
        #   (?:\b|_)(?:amd64|arm64|$app_repo_dist_sel)\b.*\.deb$
        #   (?:\b|_)(?:amd64|arm64|$app_repo_dist_sel).*\b.*\.deb$
        # #

        lst_releases=($( lastversion --pre --assets $repo --filter "(?:\b|_)(?:amd64|arm64|i386|386|$app_repo_dist_sel)\b.*\.deb$" ))

        # #
        #   if git count empty, set it to the number of packages in the lst_releases table
        # #

        if [ -z ${count_git} ]; then
            count_git=${#lst_releases[@]}
        fi

        # #
        #   loop each downloadable package
        #   
        #       key     returns number 0, 1, ...
        #       0           GitHubDesktop-linux-amd64-3.4.2-linux1.deb
        #       1           GitHubDesktop-linux-arm64-3.4.2-linux1.deb
        # #
    
        for key in "${!lst_releases[@]}"
        do

            # #
            #   repo_file_url       https://github.com/shiftkey/desktop/releases/download/release-3.4.2-linux1/GitHubDesktop-linux-amd64-3.4.2-linux1.deb
            #                       https://github.com/shiftkey/desktop/releases/download/release-3.4.2-linux1/GitHubDesktop-linux-arm64-3.4.2-linux1.deb
            #   
            #   app_filename        GitHubDesktop-linux-amd64-3.4.2-linux1.deb
            #                       GitHubDesktop-linux-arm64-3.4.2-linux1.deb
            # #

            repo_file_url=${lst_releases[$key]}
            app_filename="${repo_file_url##*/}"

            # #
            #   determines if a new package should be shown, or the architecture
            #   
            #   bNewPackage = true
            #       |--- [ 1 ] Get GitHubDesktop-linux-amd64-3.4.2-linux1.deb
            #   
            #   bNewPackage = false
            #       Get GitHubDesktop-linux-arm64-3.4.2-linux1.deb
            # #

            if [ "$bNewPackage" = true ]; then
                echo -e "     ${GREY2}|--- ${YELLOW}[ ${count} ]${FUCHSIA1}${BOLD} Get ${app_filename:0:100}${END}"
            else
                echo -e "               ${FUCHSIA1}${BOLD} Get ${app_filename:0:100}${END}"
            fi

            # #
            #   The filtering in the lastversion query should be enough, however, some people name their packages in a way
            #   where it would be difficult to rely only on that.
            #
            #   makedeb/makedeb uses a file structure similar to the following:
            #       makedeb-beta_16.1.0-beta1_armhf_focal.deb
            #       makedeb-beta_16.1.0-beta1_arm64_focal.deb
            #   
            #   this filters out "armhf", however, reads it because the word focal matches
            #   so we need to do additional filtering below.
            # #

            check=`echo $app_filename | grep '\armhf\|armv7l'`
            if [ -n "$check" ]; then
                continue
            fi

            # #
            #   take the download url provided from github and download the package using wget
            # #

            wget "$repo_file_url" -q

            # #
            #   loop each architecture for each package
            #       all
            #       amd64
            #       arm64
            #       i386
            # #

            for j in "${!lst_arch[@]}"; do

                # #
                #   get architecture
                #       amd64, arm64, i386, all
                # #

                arch=${lst_arch[$j]}

                # #
                #   check if file exists
                #       ${HOME}/Repos/GitHubDesktop-linux-amd64-3.4.2-linux1.deb
                #       ${HOME}/Repos/GitHubDesktop-linux-amd64-3.4.2-linux1.deb
                # #

                if [ -f "$app_dir/$app_filename" ]; then

                    # #
                    #   architecture > all
                    #   file must end with 'all.deb' or '*all*.deb'
                    # #

                    if [[ "$arch" == "all" ]] && [[ $app_filename == *all.deb || $app_filename == *all*.deb ]]; then
                        echo -e "  ${WHITE}                Package         ${FUCHSIA1}${arch}${END}"
                        echo -e "  ${WHITE}                File            ${FUCHSIA1}${app_filename}${END}"
                        echo -e "  ${WHITE}                Download        ${FUCHSIA1}${repo_file_url}${END}"

                        # #
                        #   architecture > all
                        #   move package to its final location inside the reprepro directory
                        #       move    ${HOME}/Repos/GitHubDesktop-linux-all-3.4.2-linux1.deb
                        #       to      ${HOME}/Repos/incoming/packages/jammy/all/
                        # #

                        mv "$app_dir/$app_filename" "$app_dir_storage/all/"
                        echo -e "  ${WHITE}                Move            ${FUCHSIA1}${app_dir}/${app_filename}${WHITE} > ${FUCHSIA1}${app_dir_storage}/all/${END}"

                        if [ -n "${bRepreproInstalled}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then

                            # #
                            #   architecture > all > full package path
                            #
                            #       deb_package             incoming/packages/jammy/all/GitHubDesktop-linux-all-3.4.2-linux1.deb
                            # #

                            deb_package="${app_dir_repo}/${arch}/${app_filename}"

                            # #
                            #   architecture > all > reprepro
                            #   add package to reprepro database
                            #
                            #       app_repo_dist_sel       jammy
                            #       deb_package             incoming/packages/jammy/all/GitHubDesktop-linux-all-3.4.2-linux1.deb
                            # #

                            echo -e "  ${WHITE}                Reprepro        ${FUCHSIA1}${deb_package}${END} for dist ${FUCHSIA1}${app_repo_dist_sel}${END}"
                            echo -e "  ${WHITE}                                    ${FUCHSIA1}reprepro -V --section utils --component main --priority 0 includedeb ${app_repo_dist_sel} ${deb_package}${END}"

                            reprepro_exit_code="0"
                            reprepro_output="$(reprepro -V \
                                --section utils \
                                --component main \
                                --priority 0 \
                                includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                "$@" 2>&1)" \
                                || { reprepro_exit_code="$?" ; true; };

                            # #
                            #   architecture > all > reprepro
                            #
                            #   output > package already added to reprepro
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "exists" ; then
                                echo -e "  ${WHITE}                ${GREEN}Status:         ${END}💡 Already exists${END}"
                            fi

                            # #
                            #   architecture > all > reprepro
                            #
                            #   output > new package added
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                                echo -e "  ${WHITE}                ${GREEN}Status:         ${END}✅ New package added${END}"
                            fi
                        fi

                        echo -e
                        bNewPackage=false

                    elif [[ "$arch" == "amd64" ]] && [[ $app_filename == *amd64.deb || $app_filename == *amd64*.deb ]]; then
                        echo -e "  ${WHITE}                Package         ${FUCHSIA1}${arch}${END}"
                        echo -e "  ${WHITE}                File            ${FUCHSIA1}${app_filename}${END}"
                        echo -e "  ${WHITE}                Download        ${FUCHSIA1}${repo_file_url}${END}"

                        # #
                        #   architecture > amd64
                        #   move package to its final location inside the reprepro directory
                        #       move    /home/aetherx/Repos/GitHubDesktop-linux-amd64-3.4.2-linux1.deb
                        #       to      /home/aetherx/Repos/incoming/packages/jammy/amd64/
                        # #

                        mv "$app_dir/$app_filename" "$app_dir_storage/amd64/"
                        echo -e "  ${WHITE}                Move            ${FUCHSIA1}${app_dir}/${app_filename}${WHITE} > ${FUCHSIA1}${app_dir_storage}/amd64/${END}"

                        if [ -n "${bRepreproInstalled}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then

                            # #
                            #   architecture > amd64 > full package path
                            #
                            #       deb_package             incoming/packages/jammy/amd64/GitHubDesktop-linux-amd64-3.4.2-linux1.deb
                            # #

                            deb_package="$app_dir_repo/$arch/$app_filename"

                            # #
                            #   architecture > amd64 > reprepro
                            #   add package to reprepro database
                            #
                            #       app_repo_dist_sel       jammy
                            #       deb_package             incoming/packages/jammy/amd64/GitHubDesktop-linux-amd64-3.4.2-linux1.deb
                            # #

                            echo -e "  ${WHITE}                Reprepro        ${FUCHSIA1}${deb_package}${END} for dist ${FUCHSIA1}${app_repo_dist_sel}${END}"
                            echo -e "  ${WHITE}                                    ${FUCHSIA1}reprepro -V --section utils --component main --priority 0 includedeb ${app_repo_dist_sel} ${deb_package}${END}"

                            reprepro_exit_code="0"
                            reprepro_output="$(reprepro -V \
                                --section utils \
                                --component main \
                                --priority 0 \
                                --architecture $arch \
                                includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                "$@" 2>&1)" \
                                || { reprepro_exit_code="$?" ; true; };

                            # #
                            #   architecture > amd64 > reprepro
                            #
                            #   output > package already added to reprepro
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "exists" ; then
                                echo -e "  ${WHITE}                ${GREEN}Status:         ${END}💡 Already exists${END}"
                            fi

                            # #
                            #   architecture > amd64 > reprepro
                            #
                            #   output > new package added
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                                echo -e "  ${WHITE}                ${GREEN}Status:         ${END}✅ New package added${END}"
                            fi
                        fi

                        echo -e
                        bNewPackage=false
 
                    elif [[ "$arch" == "arm64" ]] && [[ $app_filename == *arm64.deb || $app_filename == *arm64*.deb ]]; then
                        echo -e "  ${WHITE}                Package         ${FUCHSIA1}${arch}${END}"
                        echo -e "  ${WHITE}                File            ${FUCHSIA1}${app_filename}${END}"
                        echo -e "  ${WHITE}                Download        ${FUCHSIA1}${repo_file_url}${END}"

                        # #
                        #   architecture > arm64
                        #   move package to its final location inside the reprepro directory
                        #       move    /home/aetherx/Repos/GitHubDesktop-linux-arm64-3.4.2-linux1.deb
                        #       to      /home/aetherx/Repos/incoming/packages/jammy/arm64/
                        # #

                        mv "$app_dir/$app_filename" "$app_dir_storage/arm64/"
                        echo -e "  ${WHITE}                Move            ${FUCHSIA1}${app_dir}/${app_filename}${WHITE} > ${FUCHSIA1}${app_dir_storage}/arm64/${END}"

                        if [ -n "${bRepreproInstalled}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then

                            # #
                            #   architecture > arm64 > full package path
                            #
                            #       deb_package             incoming/packages/jammy/arm64/GitHubDesktop-linux-arm64-3.4.2-linux1.deb
                            # #

                            deb_package="$app_dir_repo/$arch/$app_filename"

                            # #
                            #   architecture > arm64 > reprepro
                            #   add package to reprepro database
                            #
                            #       app_repo_dist_sel       jammy
                            #       deb_package             incoming/packages/jammy/arm64/GitHubDesktop-linux-arm64-3.4.2-linux1.deb
                            # #

                            echo -e "  ${WHITE}                Reprepro        ${FUCHSIA1}${deb_package}${END} for dist ${FUCHSIA1}${app_repo_dist_sel}${END}"
                            echo -e "  ${WHITE}                                    ${FUCHSIA1}reprepro -V --section utils --component main --priority 0 includedeb ${app_repo_dist_sel} ${deb_package}${END}"

                            reprepro_exit_code="0"
                            reprepro_output="$(reprepro -V \
                                --section utils \
                                --component main \
                                --priority 0 \
                                --architecture $arch \
                                includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                "$@" 2>&1)" \
                                || { reprepro_exit_code="$?" ; true; };

                            # #
                            #   architecture > arm64 > reprepro
                            #
                            #   output > package already added to reprepro
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "exists" ; then
                                echo -e "  ${WHITE}                ${GREEN}Status:         ${END}💡 Already exists${END}"
                            fi

                            # #
                            #   architecture > arm64 > reprepro
                            #
                            #   output > new package added
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                                echo -e "  ${WHITE}                ${GREEN}Status:         ${END}✅ New package added${END}"
                            fi
                        fi

                        echo -e
                        bNewPackage=false

                    elif [[ "$arch" == "i386" || "$arch" == "386" ]] && [[ $app_filename == *i386.deb || $app_filename == *i386*.deb || $app_filename == *386.deb || $app_filename == *386*.deb ]]; then
                        echo -e "  ${WHITE}                Package         ${FUCHSIA1}${arch}${END}"
                        echo -e "  ${WHITE}                File            ${FUCHSIA1}${app_filename}${END}"
                        echo -e "  ${WHITE}                Download        ${FUCHSIA1}${repo_file_url}${END}"

                        # #
                        #   architecture > i386
                        #   move package to its final location inside the reprepro directory
                        #       move    /home/aetherx/Repos/GitHubDesktop-linux-i386-3.4.2-linux1.deb
                        #       to      /home/aetherx/Repos/incoming/packages/jammy/i386/
                        # #

                        mv "$app_dir/$app_filename" "$app_dir_storage/i386/"
                        echo -e "  ${WHITE}                Move            ${FUCHSIA1}${app_dir}/${app_filename}${WHITE} > ${FUCHSIA1}${app_dir_storage}/i386/${END}"

                        if [ -n "${bRepreproInstalled}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then

                            # #
                            #   architecture > i386 > full package path
                            #
                            #       deb_package             incoming/packages/jammy/i386/GitHubDesktop-linux-i386-3.4.2-linux1.deb
                            # #

                            deb_package="$app_dir_repo/$arch/$app_filename"

                            # #
                            #   architecture > i386 > reprepro
                            #   add package to reprepro database
                            #
                            #       app_repo_dist_sel       jammy
                            #       deb_package             incoming/packages/jammy/i386/GitHubDesktop-linux-i386-3.4.2-linux1.deb
                            # #

                            echo -e "  ${WHITE}                Reprepro        ${FUCHSIA1}${deb_package}${END} for dist ${FUCHSIA1}${app_repo_dist_sel}${END}"
                            echo -e "  ${WHITE}                                    ${FUCHSIA1}reprepro -V --section utils --component main --priority 0 includedeb ${app_repo_dist_sel} ${deb_package}${END}"

                            reprepro_exit_code="0"
                            reprepro_output="$(reprepro -V \
                                --section utils \
                                --component main \
                                --priority 0 \
                                --architecture $arch \
                                includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                "$@" 2>&1)" \
                                || { reprepro_exit_code="$?" ; true; };

                            # #
                            #   architecture > i386 > reprepro
                            #
                            #   output > package already added to reprepro
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "exists" ; then
                                echo -e "  ${WHITE}                ${GREEN}Status:         ${END}💡 Already exists${END}"
                            fi

                            # #
                            #   architecture > i386 > reprepro
                            #
                            #   output > new package added
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                                echo -e "  ${WHITE}                ${GREEN}Status:         ${END}✅ New package added${END}"
                            fi
                        fi

                        echo -e
                        bNewPackage=false

                    fi
                fi

                bNewPackage=false

            done
        done

        (( count-- ))

        bNewPackage=true
        echo -e

    done
}

# #
#   Github > Start
# #

app_run_gh_start()
{

    if [ -z "${OPT_DEV_NULLRUN}" ] && [ -z "${OPT_DLPKG_ONLY_TEST}" ]; then

        cd ${app_dir}

        #   ensure git config is updated
        app_run_github_precheck

        #   add origin
        echo -e "  ${GREY2}Git: ${YELLOW3}git remote add origin https://github.com/${GITHUB_NAME}/${app_repo_apt}.git${WHITE}"
        git remote add origin https://github.com/${GITHUB_NAME}/${app_repo_apt}.git

        #   remove all changes and sync with remote repo
        echo -e "  ${GREY2}Git: ${YELLOW3}git fetch --prune${WHITE}"
        git fetch --prune

        #   force head to match with remote repo
        echo -e "  ${GREY2}Git: ${YELLOW3}git reset --hard origin/${app_repo_branch}${WHITE}"
        git reset --hard origin/${app_repo_branch}

        #   must have at least one commit for this to work
        #   -m / --move flag to rename a branch in our local repository
        echo -e "  ${GREY2}Git: ${YELLOW3}git branch -m ${app_repo_branch}${WHITE}"
        git branch -m ${app_repo_branch}

        # #
        #   .app folder
        # #

        local manifest_dir="${app_dir}/.app"
        mkdir -p            ${manifest_dir}

        # #
        #   .app folder > create .json
        # #

sudo tee ${manifest_dir}/${app_repo_dist_sel}.json >/dev/null <<EOF
{
    "name":             "${app_title}",
    "version":          "$(get_version)",
    "author":           "${GITHUB_NAME}",
    "description":      "${app_about}",
    "distrib":          "${app_repo_dist_sel}",
    "url":              "${app_repo_url}",
    "last_duration":    "...........",
    "last_update":      "Running ...............",
    "last_update_ts":   "${DATE_TS}"
}
EOF

        git_pull=$( git pull origin ${app_repo_branch} --allow-unrelated-histories )

        echo -e "  ${WHITE}Git Pull: ${YELLOW3}${git_pull}${END}"
        echo
        echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
        echo

        # git add -A, --all     stages all changes
        # git add .             stages new files and modifications, without deletions (on the current directory and its subdirectories).
        # git add -u            stages modifications and deletions, without new files

        echo -e "  ${GREY2}Git: ${YELLOW3}git add --all${WHITE}"
        git add --all

        sleep 1

        local NOW=$(date -u '+%m.%d.%Y %H:%M:%S')
        local app_repo_commit="[S] auto-update [ ${app_repo_dist_sel} ] @ ${NOW}"
        echo -e "  ${WHITE}Starting commit ${FUCHSIA1}${app_repo_commit}${END}"

        # #
        #   The command below can throw the following errors:
        #   
        #       error: gpg failed to sign the data:
        #       gpg: skipped "!": No secret key
        #       [GNUPG:] INV_SGNR 9 !
        #       [GNUPG:] FAILURE sign 17
        #       gpg: signing failed: No secret key
        # #

        echo -e "  ${GREY2}Git: ${YELLOW3}git commit -S -m ${app_repo_commit}${WHITE}"
        git commit -S -m "${app_repo_commit}"

        sleep 1

        echo -e "  ${WHITE}Starting push ${FUCHSIA1}${app_repo_branch}${END}"

        if [ "${OPT_DEV_ENABLE}" = true ]; then
            echo -e "  ${GREY2}Git: ${YELLOW3}git push https://${CSI_PAT_GITHUB}@github.com/${GITHUB_NAME}/${app_repo_apt}${WHITE}"
        fi

        git push https://${CSI_PAT_GITHUB}@github.com/${GITHUB_NAME}/${app_repo_apt}

    fi # end devnull

}

# #
#   Github > End
#
#   push all packages / upload to proteus apt repo
# #

app_run_gh_end()
{

    if [ -z "${OPT_DEV_NULLRUN}" ] && [ -z "${OPT_DLPKG_ONLY_TEST}" ]; then

        cd ${app_dir}

        # #
        #   clean up left-over .deb files in root directory
        # #

        if compgen -G "${app_dir}/*.deb" > /dev/null; then
            echo -e "  ${GREY2}Cleaning up left-over .deb: ${YELLOW}${app_dir}/*.deb${WHITE}"
            rm ${app_dir}/*.deb >/dev/null
        fi

        app_run_github_precheck

        echo
        echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
        echo
        echo -e "  ${GREY2}Updating Github: $app_repo_branch${WHITE}"
        echo
        echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
        echo

        #   must have at least one commit for this to work
        #   -m / --move flag to rename a branch in our local repository
        git branch -m ${app_repo_branch}

        git add --all
        git add -u

        sleep 1

        local NOW=$(date -u '+%m.%d.%Y %H:%M:%S')
        local app_repo_commit="[E] auto-update [ $app_repo_dist_sel ] @ $NOW"
        git commit -S -m "$app_repo_commit"

        sleep 1

        # can use -u, --set-upstream
        git push https://${CSI_PAT_GITHUB}@github.com/${GITHUB_NAME}/${app_repo_apt}

    fi # end devnull
}

## #
#   update tree
# #

app_run_tree_update()
{
    # #
    #   .app folder
    # #

    local manifest_dir="${app_dir}/.app"
    mkdir -p            ${manifest_dir}

    # #
    #   duration elapsed
    # #

    duration=${SECONDS}
    elapsed="$((${duration} / 60))m $(( ${duration} % 60 ))s"

    # #
    #   .app folder > create .json
    # #

sudo tee ${manifest_dir}/${app_repo_dist_sel}.json >/dev/null <<EOF
{
    "name":             "${app_title}",
    "version":          "$(get_version)",
    "author":           "${GITHUB_NAME}",
    "description":      "${app_about}",
    "distrib":          "${app_repo_dist_sel}",
    "url":              "${app_repo_url}",
    "last_duration":    "${elapsed}",
    "last_update":      "${NOW}",
    "last_update_ts":   "${DATE_TS}"
}
EOF

    # #
    #   tree
    # #

    tree_output=$( tree -a -I ".git" -I "logs" -I "docs" -I ".gpg" -I "incoming" --dirsfirst )
    tree -a -I ".git" --dirsfirst -J > ${manifest_dir}/tree.json

    #   useful for Gitea with HTML rendering plugin, not useful for Github
    #   tree -a --dirsfirst -I '.git' -H https://github.com/${GITHUB_NAME}/${app_repo_script}/src/branch/$app_repo_branch/ -o $app_dir/.data/tree.html

    # #
    #   tree.md content
    # #

sudo tee ${app_dir}/tree.md >/dev/null <<EOF
# Repo Tree
Last generated on \`${NOW}\`

<br />

---

<br />

\`\`\`
${tree_output}
\`\`\`
EOF
}

# #
#   Start App
# #

app_start()
{

    show_header

    # #
    #   set seconds for duration
    # #

    export SECONDS=0

    # #
    #   check for reprepro
    # #

    if [ -x "$(command -v reprepro)" ]; then
        bRepreproInstalled=true
    fi

    # #
    #   reprepro missing
    # #

    if [ -z "${bRepreproInstalled}" ]; then
        echo
        echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}Reprepro Missing${END}"
        echo -e "  ${BOLD}${WHITE}It appears the package ${FUCHSIA1}Reprepro${WHITE} is missing.${END}"
        echo
        echo -e "  ${BOLD}${WHITE}Try installing the package with:${END}"
        echo -e "  ${BOLD}${WHITE}     sudo apt-get update${END}"
        echo -e "  ${BOLD}${WHITE}     sudo apt-get install reprepro${END}"
        echo

        printf "  Press any key to abort ... ${END}"
        read -n 1 -s -r -p ""
        echo
        echo

        set +m
        trap "kill -9 $app_pid 2> /dev/null" `seq 0 15`
        kill $app_pid
        set -m
    fi

    # #
    #   run
    # #

    if [ -n "${OPT_DLPKG_ONLY_LASTVER}" ]; then
        app_run_gh_start
        app_run_dl_lastver
        app_run_tree_update
        app_run_gh_end
    elif [ -n "${OPT_DL_ONLY_APTGET}" ]; then
        app_run_gh_start
        app_run_dl_aptget
        app_run_tree_update
        app_run_gh_end
    else
        app_run_gh_start
        app_run_dl_aptget
        app_run_dl_lastver
        app_run_tree_update
        app_run_gh_end
    fi

    # #
    #   duration elapsed
    # #

    duration=${SECONDS}
    elapsed="$((${duration} / 60)) minutes and $(( ${duration} % 60 )) seconds elapsed."

    printf "%-57s %-15s\n\n\n\n" "${TIME}      ${elapsed}" | tee -a "${LOGS_FILE}" >/dev/null

    echo
    echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
    echo
    echo -e "  ${GREY2}Total Execution Time: $elapsed${WHITE}"
    echo
    echo -e " ${BLUE}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${END}"
    echo

    sleep 10

    # #
    #   close logs, kill spinner, and finish process
    # #

    finish
    Logs_Finish

    # #
    #   Bash Logging > Disable
    # #

    set -o history
}

app_start
