# #
#   @author :           aetherinox
#   @script :           Proteus Apt Git
#   @date   :           2024-07-27 03:15:53
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
#   
#   ----------------------------------------------------------------
#   
#   To test the functionality of this script without actually 
#   writing anything to Github or Reprepro, you can use the command
#       ./proteus-git.sh --onlyTest --dev
#   
# #

#!/bin/bash
PATH="/bin:/usr/bin:/sbin:/usr/sbin:/home/${USER}/bin"
echo 

# #
#   DEFINE > Packages > apt-get
# #

lst_packages=(
    'adduser'
    'argon2'
    'apt-move'
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
    'sks',
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
)

# #
#   list > architectures
# #

lst_arch=(
    'all'
    'amd64'
    'arm64'
)

# #
#   vars > colors
#
#   tput setab  [1-7]       : Set a background color using ANSI escape
#   tput setb   [1-7]       : Set a background color
#   tput setaf  [1-7]       : Set a foreground color using ANSI escape
#   tput setf   [1-7]       : Set a foreground color
# #

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
STRIKE="\e[9m"
END="\e[0m"

# #
#   vars > status messages
# #

STATUS_MISS="${BOLD}${GREYL} MISS ${NORMAL}"
STATUS_SKIP="${BOLD}${GREYL} SKIP ${NORMAL}"
STATUS_OK="${BOLD}${GREEN}  OK  ${NORMAL}"
STATUS_FAIL="${BOLD}${RED} FAIL ${NORMAL}"
STATUS_HALT="${BOLD}${YELLOW} HALT ${NORMAL}"

# #
#   vars > system
# #

sys_arch=$(dpkg --print-architecture)
sys_code=$(lsb_release -cs)

# #
#   vars > app > folders
# #

app_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
app_dir_home="${HOME}/bin"
app_dir_storage="$app_dir/incoming/proteus-git/${sys_code}"
app_dir_repo="incoming/proteus-git/${sys_code}"
app_dir_wd=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
app_dir_secrets="${HOME}/.secrets"

# #
#   Ensure we're in the correct directory
# #

cd ${app_dir}

# #
#   vars > app > files
#
#   OLD VERSION (Unencrypted)
#       app_file_secrets_sh
#
#   NEW VERSION (Clevis Encrypted)
#       app_file_secrets_github
#       app_file_secrets_gitlab
#       app_file_secrets_passwd
#       app_file_secrets_general
# #

app_file_this=$(basename "$0")
app_file_proteus="${app_dir_home}/proteus-git"
app_file_secrets_github=${app_dir_secrets}/.pat_github
app_file_secrets_gitlab=${app_dir_secrets}/.pat_gitlab
app_file_secrets_passwd=${app_dir_secrets}/.passwd
app_file_secrets_general=${app_dir_secrets}/.base
app_file_secrets_sh=${app_dir}/secrets.sh

# #
#   vars > app > general
# #

app_title="Proteus Apt Git"
app_about="Internal system to Proteus App Manager which grabs debian packages."
app_ver=("1" "2" "0" "0")
app_pid_spin=0
app_pid=$BASHPID
app_queue_url=()
app_i=0

# #
#   DEFINE > Clevis Secret Files
# #

cfg_Storage_Clevis=true

# #
#   requite packages before anything begins.
#   we need these to assign variables in the next step for 
#       app_repo_user
#       app_repo_email
# #

if ! [ -x "$(command -v git)" ]; then
    echo -e "  ${GREYL}Installing package ${MAGENTA}Git${WHITE}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install git -y -qq >/dev/null 2>&1

    echo -e "  ${GREYL}Installing package ${MAGENTA}GPG${WHITE}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install gpg -y -qq >/dev/null 2>&1
fi

# #
#   clevis required to decrypt tokens
# #

if [ "${cfg_Storage_Clevis}" = true ] && [ ! -x "$(command -v clevis)" ]; then
    echo -e "  ${GREYL}Installing package ${MAGENTA}Clevis${WHITE}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install clevis clevis-udisks2 clevis-tpm2 -y -qq >/dev/null 2>&1
fi

# #
#   Create .gitignore
# #

if [ ! -f "${app_dir}/.gitignore" ] || [ ! -s "${app_dir}/.gitignore" ]; then

    touch $app_dir/.gitignore

sudo tee $app_dir/.gitignore << EOF > /dev/null
# ----------------------------------------
#   Misc
# ----------------------------------------
incoming/
.env
sources-*.list
.pipe

# ----------------------------------------
# Logs
# ----------------------------------------
logs/
*-log
*.log

# ----------------------------------------
# GPG keys
# ----------------------------------------
.gpg/*.gpg
.gpg/*.asc

# ----------------------------------------
# Secrets Files
# ----------------------------------------
secrets.sh
secrets/*
.secrets/*
EOF

fi

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
#   func > error > base file missing error
#
#   throws an error to the user if they are missing the .base secrets file
# #

error_missing_file_base()
{
    file_base_path="Unknown"
    if [ "${cfg_Storage_Clevis}" = true ]; then
        file_base_path="${app_file_secrets_general}"
    else
        file_base_path="${app_file_secrets_sh}"
    fi

    echo -e 
    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
    echo -e
    echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}Missing base config file${NORMAL}"
    echo -e "  ${BOLD}${WHITE}Create new ${FUCHSIA}${file_base_path}${WHITE} file and add the following lines:${NORMAL}"
    echo -e
    echo -e "  ${BOLD}${WHITE}    ${DEVGREY}#!/bin/bash${NORMAL}"
    echo -e "  ${BOLD}${WHITE}    ${DEVGREY}PATH=\"/bin:/usr/bin:/sbin:/usr/sbin:/home/$USER/bin\"${NORMAL}"
    echo -e "  ${BOLD}${WHITE}    ${RED}export ${GREEN}GPG_KEY=${WHITE}XXXXXXXX${NORMAL}"
    echo -e "  ${BOLD}${WHITE}    ${RED}export ${GREEN}GITHUB_NAME=${WHITE}YourName${NORMAL}"
    echo -e "  ${BOLD}${WHITE}    ${RED}export ${GREEN}GITHUB_EMAIL=${WHITE}username@email.com${NORMAL}"
    echo -e 
    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
    echo -e

    printf "  Press any key to abort ... ${NORMAL}"
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
    file_base_path="Unknown"
    if [ "${cfg_Storage_Clevis}" = true ]; then
        file_base_path="${app_file_secrets_general}"
    else
        file_base_path="${app_file_secrets_sh}"
    fi

    echo -e 
    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
    echo -e
    echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}GPG_KEY value not specified${NORMAL}"
    echo -e "  ${BOLD}${WHITE}Make sure ${FUCHSIA}${file_base_path}${WHITE} exists and contains the following lines:${NORMAL}"
    echo -e
    echo -e "  ${BOLD}${WHITE}    ${DEVGREY}#!/bin/bash${NORMAL}"
    echo -e "  ${BOLD}${WHITE}    ${DEVGREY}PATH=\"/bin:/usr/bin:/sbin:/usr/sbin:/home/$USER/bin\"${NORMAL}"
    echo -e "  ${BOLD}${WHITE}    ${RED}export ${GREEN}GPG_KEY=${WHITE}XXXXXXXX${NORMAL}"
    echo -e "  ${BOLD}${WHITE}    ${RED}export ${GREEN}GITHUB_NAME=${WHITE}YourName${NORMAL}"
    echo -e "  ${BOLD}${WHITE}    ${RED}export ${GREEN}GITHUB_EMAIL=${WHITE}username@email.com${NORMAL}"
    echo -e 
    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
    echo -e

    printf "  Press any key to abort ... ${NORMAL}"
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
#   activate using ./proteus-git.sh --help or -h
# #

opt_usage()
{
    echo
    printf "  ${BLUE}${app_title}${NORMAL}\n" 1>&2
    printf "  ${GREYL}${gui_about}${NORMAL}\n" 1>&2
    echo
    printf '  %-5s %-40s\n' "Usage:" "" 1>&2
    printf '  %-5s %-40s\n' "    " "${0} [${GREYL}options${NORMAL}]" 1>&2
    printf '  %-5s %-40s\n\n' "    " "${0} [${GREYL}-s${NORMAL}] [${GREYL}-t${NORMAL}] [${GREYL}-g${NORMAL}] [${GREYL}-p${NORMAL}] [${GREYL}-d${NORMAL}] [${GREYL}-n${NORMAL}] [${GREYL}-q${NORMAL}] [${GREYL}-u${NORMAL}] [${GREYL}-b main | dev${NORMAL}] [${GREYL}-r${NORMAL}]" 1>&2
    printf '  %-5s %-40s\n' "Options:" "" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-s, --setup" "install script packages (git, wget, reprepro, etc.), setup gpg daemon, configure gpg key" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-t, --onlyTest" "download packages from apt-get and LastVersion, do not push to git repo" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-g, --onlyGithub" "only update packages using LastVersion, push to git" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-p, --onlyAptget" "only update packages using AptGet, push to git" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-d, --dev" "dev mode (advanced logs)" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-n, --nullrun" "run script without adding packages to reprepro" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "simulate app installs (no changes)" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-q, --quiet" "disable logging" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-r, --report" "how info about ${app_file_this}" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "" "current paths, installed dependencies, etc." 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-u, --update" "update ${app_file_this} executable" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-b, --branch" "branch to use for downloading/updating this script" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-v, --version" "current version of app manager" 1>&2
    printf '  %-5s %-18s %-40s\n' "    " "-h, --help" "show help menu" 1>&2
    echo
    echo
    exit 1
}

# #
#   Display Report
# #

opt_report()
{

    clear

    sleep 0.3

    file_base_path="Missing"
    var_clevis_status='Disabled'
    if [ "${cfg_Storage_Clevis}" = true ]; then
        file_base_path="${app_file_secrets_general}"
        var_clevis_status='Enabled'
    else
        file_base_path="${app_file_secrets_sh}"
        var_clevis_status='Disabled'
    fi

    # #
    #   base > load /.secrets/.base
    # #

    if [ -f ${app_file_secrets_general} ]; then
        source ${app_file_secrets_general}
    elif [ -f ${app_file_secrets_sh} ]; then
        source ${app_file_secrets_sh}
    fi

    # #
    #   base > secrets mode > color
    #
    #   changes the color of the "secrets.sh" mode to a dark gray if clevis mode is enabled
    # #

    clrSecretsModeSh_Title=$([ ${var_clevis_status} == "Enabled" ] && echo ${STRIKE}${DEVGREY} || echo ${LIME_YELLOW})
    clrSecretsModeSh_Item=$([ ${var_clevis_status} == "Enabled" ] && echo ${DEVGREY} || echo ${POWDER_BLUE})

    # #
    #  Section > Header 
    # #

    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
    echo -e " ${GREEN}${BOLD} ${app_title} - v$(get_version)${NORMAL}${MAGENTA}"
    echo
    echo -e "  This is a package which handles the Proteus App Manager behind"
    echo -e "  the scene by grabbing from the list of registered packages"
    echo -e "  and adding them to the queue to be updated."
    echo

    # #
    #  Section > Settings
    # #

    echo -e
    echo -e "  ${LIME_YELLOW}${BOLD}[ Settings ]${NORMAL}"

    Val_SecretMode=$([ ${var_clevis_status} == "Enabled" ] && echo "Clevis (Encrypted)" || echo "Secrets.sh (Unencrypted)")
    Val_Pkgs_Aptget=${#lst_packages[@]}
    Val_Pkgs_Github=${#lst_github[@]}
    Val_Pkgs_Arch=${#lst_arch[@]}

    printf "%-5s %-40s %-40s %-40s\n" "" "${POWDER_BLUE}⚙️  Script" "${WHITE}${app_file_this}" "${NORMAL}"
    printf "%-5s %-40s %-40s %-40s\n" "" "${POWDER_BLUE}⚙️  Path" "${WHITE}${app_dir}" "${NORMAL}"
    printf "%-5s %-40s %-40s %-40s\n" "" "${POWDER_BLUE}⚙️  Version" "${WHITE}v$(get_version)" "${NORMAL}"
    printf "%-5s %-40s %-40s %-40s\n" "" "${POWDER_BLUE}⚙️  Secret Mode" "${WHITE}${Val_SecretMode}" "${NORMAL}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${POWDER_BLUE}📦 Packages (Apt)" "${WHITE}${Val_Pkgs_Aptget}" "${NORMAL}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${POWDER_BLUE}📦 Packages (Github)" "${WHITE}${Val_Pkgs_Github}" "${NORMAL}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${POWDER_BLUE}📦 Architextures" "${WHITE}${Val_Pkgs_Arch}" "${NORMAL}"

    echo

    # #
    #  Section > Variables
    # #

    echo -e
    echo -e "  ${LIME_YELLOW}${BOLD}[ Variables ]${NORMAL}"

    bExists_Val_GPG=$([ -z "${GPG_KEY}" ] && echo "Missing" || echo "${GPG_KEY}")
    bExists_Val_GithubName=$([ -z "${GITHUB_NAME}" ] && echo "Missing" || echo "${GITHUB_NAME}")
    bExists_Val_GithubEmail=$([ -z "${GITHUB_EMAIL}" ] && echo "Missing" || echo "${GITHUB_EMAIL}")

    printf "%-5s %-37s %-40s %-40s\n" "" "${POWDER_BLUE}✎ GPG_KEY" "${WHITE}${bExists_Val_GPG}" "${NORMAL}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${POWDER_BLUE}✎ GITHUB_NAME" "${WHITE}${bExists_Val_GithubName}" "${NORMAL}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${POWDER_BLUE}✎ GITHUB_EMAIL" "${WHITE}${bExists_Val_GithubEmail}" "${NORMAL}"
    echo

    # #
    #  Section > Paths
    # #

    echo -e
    echo -e "  ${LIME_YELLOW}${BOLD}[ Paths - Clevis Mode]${NORMAL}"

    bExists_Fold_Secrets=$([ ! -d "${app_dir_secrets}" ] && echo "Missing" || echo "${app_dir_secrets}")
    bExists_File_Base=$([ ! -f "${app_file_secrets_general}" ] && echo "Missing" || echo "${app_file_secrets_general}")
    bExists_File_Github=$([ ! -f "${app_file_secrets_github}" ] && echo "Missing" || echo "${app_file_secrets_github}")
    bExists_File_Gitlab=$([ ! -f "${app_file_secrets_gitlab}" ] && echo "Missing" || echo "${app_file_secrets_gitlab}")
    bExists_File_Passwd=$([ ! -f "${app_file_secrets_passwd}" ] && echo "Missing" || echo "${app_file_secrets_passwd}")

    printf "%-5s %-37s %-40s %-40s\n" "" "${POWDER_BLUE}📁 .secrets" "${WHITE}${bExists_Fold_Secrets}" "${DEVGREY}${Val_SecretMode}${NORMAL}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${POWDER_BLUE}📄 .base" "${WHITE}${bExists_File_Base}${NORMAL}" ""
    printf "%-5s %-37s %-40s %-40s\n" "" "${POWDER_BLUE}📄 .passwd" "${WHITE}${bExists_File_Passwd}${NORMAL}" ""
    printf "%-5s %-37s %-40s %-40s\n" "" "${POWDER_BLUE}📄 .pat_github" "${WHITE}${bExists_File_Github}${NORMAL}" ""
    printf "%-5s %-37s %-40s %-40s\n" "" "${POWDER_BLUE}📄 .pat_gitlab" "${WHITE}${bExists_File_Gitlab}${NORMAL}" ""
    echo

    # #
    #  Section > Paths > Secrets.Sh Mode
    # #

    echo -e
    echo -e "  ${clrSecretsModeSh_Title}${BOLD}[ Paths - Secrets.sh Mode]${NORMAL}"

    bExists_File_SecretsSh=$([ ! -f "${app_file_secrets_sh}" ] && echo "Missing" || echo 'Found')

    printf "%-5s %-37s %-40s %-40s\n" "" "${clrSecretsModeSh_Item}📄 secrets.sh" "${WHITE}${bExists_File_SecretsSh}" "${DEVGREY}${Val_SecretMode}${NORMAL}"
    echo

    # #
    #  Section > Dependencies 
    # #

    echo -e
    echo -e "  ${LIME_YELLOW}${BOLD}[ Dependencies ]${NORMAL}"

    bInstalled_AptMove=$([ ! -x "$(command -v apt-move)" ] && echo "Missing" || echo 'Installed')
    bInstalled_Git=$([ ! -x "$(command -v git)" ] && echo "Missing" || echo 'Installed')
    bInstalled_Clevis=$([ ! -x "$(command -v clevis)" ] && echo "Missing" || echo 'Installed')
    bInstalled_Reprepro=$([ ! -x "$(command -v reprepro)" ] && echo "Missing" || echo 'Installed')
    bInstalled_GPG=$([ ! -x "$(command -v gpg)" ] && echo "Missing" || echo 'Installed')
    bInstalled_Wget=$([ ! -x "$(command -v wget)" ] && echo "Missing" || echo 'Installed')
    bInstalled_Curl=$([ ! -x "$(command -v curl)" ] && echo "Missing" || echo 'Installed')
    bInstalled_Tree=$([ ! -x "$(command -v tree)" ] && echo "Missing" || echo 'Installed')

    printf "%-5s %-38s %-40s\n" "" "${POWDER_BLUE}🗔  apt-move" "${WHITE}${bInstalled_AptMove}${NORMAL}"
    printf "%-5s %-38s %-40s\n" "" "${POWDER_BLUE}🗔  git" "${WHITE}${bInstalled_Git}${NORMAL}"
    printf "%-5s %-38s %-40s\n" "" "${POWDER_BLUE}🗔  clevis" "${WHITE}${bInstalled_Clevis}${NORMAL}"
    printf "%-5s %-38s %-40s\n" "" "${POWDER_BLUE}🗔  reprepro" "${WHITE}${bInstalled_Reprepro}${NORMAL}"
    printf "%-5s %-38s %-40s\n" "" "${POWDER_BLUE}🗔  gPG" "${WHITE}${bInstalled_GPG}${NORMAL}"
    printf "%-5s %-38s %-40s\n" "" "${POWDER_BLUE}🗔  wget" "${WHITE}${bInstalled_Wget}${NORMAL}"
    printf "%-5s %-38s %-40s\n" "" "${POWDER_BLUE}🗔  curl" "${WHITE}${bInstalled_Curl}${NORMAL}"
    printf "%-5s %-38s %-40s\n" "" "${POWDER_BLUE}🗔  tree" "${WHITE}${bInstalled_Tree}${NORMAL}"

    # #
    #  Section > Footer
    # #

    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
    echo

    sleep 0.3

    echo
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
#   --gpg           adds new entries to "/home/${USER}/.gnupg/gpg-agent.conf"
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

# #
#   DEV > Show Arguments
# #

if [ "${OPT_DEV_ENABLE}" = true ]; then

    echo -e
    echo -e "  ${LIME_YELLOW}${BOLD}[ Arguments ]${NORMAL}"

    [ "${OPT_DEV_ENABLE}" = true ] && printf "%-3s %-15s %-10s\n" "" "--dev" "${GREEN}${OPT_DEV_ENABLE}${NORMAL}"
    [ "${OPT_DLPKG_ONLY_TEST}" = true ] && printf "%-3s %-15s %-10s\n" "" "--onlyTest" "${GREEN}${OPT_DLPKG_ONLY_TEST}${NORMAL}"
    [ "${OPT_DLPKG_ONLY_LASTVER}" = true ] && printf "%-3s %-15s %-10s\n" "" "--onlyGithub" "${GREEN}${OPT_DLPKG_ONLY_LASTVER}${NORMAL}"
    [ "${OPT_DL_ONLY_APTGET}" = true ] && printf "%-3s %-15s %-10s\n" "" "--onlyAptget" "${GREEN}${OPT_DL_ONLY_APTGET}${NORMAL}"
    [ "${OPT_DEV_NULLRUN}" = true ] && printf "%-3s %-15s %-10s\n" "" "--nullrun" "${GREEN}${OPT_DEV_NULLRUN}${NORMAL}"
    [ "${OPT_NOLOG}" = true ] && printf "%-3s %-15s %-10s\n" "" "--quiet" "${GREEN}${OPT_NOLOG}${NORMAL}"
    [ -n "${OPT_DISTRIBUTION}" ] && printf "%-3s %-15s %-10s\n" "" "--dist" "${GREEN}${OPT_DISTRIBUTION}${NORMAL}"
    [ -n "${OPT_BRANCH}" ] && printf "%-3s %-15s %-10s\n" "" "--branch" "${GREEN}${OPT_BRANCH}${NORMAL}"

    echo -e
    sleep 5
fi

# #
#   DEFINE > App repo paths and commands
# #

app_repo_author="Aetherinox"
app_repo="proteus-git"
app_repo_branch="main"
app_repo_user=$( git config --global --get-all user.name )
app_repo_email=$( git config --global --get-all user.email )
app_repo_apt="proteus-apt-repo"
app_repo_apt_pkg="aetherinox-${app_repo_apt}-archive"
app_repo_url="https://github.com/${app_repo_author}/${app_repo}"
app_repo_apt_url="https://github.com/${app_repo_author}/${app_repo_apt}"
app_repo_mnfst="https://raw.githubusercontent.com/${app_repo_author}/${app_repo}/${app_repo_branch}/manifest.json"
app_repo_script="https://raw.githubusercontent.com/${app_repo_author}/${app_repo}/BRANCH/setup.sh"

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
export LOGS_FILE="${LOGS_DIR}/proteus-git-${DATE}.log"
export SECONDS=0

# #
#   distro
#
#   returns distro information.
# #

    # #
    #   freedesktop.org and systemd
    # #

        if [ -f /etc/os-release ]; then
            . /etc/os-release
            OS=$NAME
            OS_VER=$VERSION_ID

    # #
    #   linuxbase.org
    # #

        elif type lsb_release >/dev/null 2>&1; then
            OS=$(lsb_release -si)
            OS_VER=$(lsb_release -sr)

    # #
    #   versions of Debian/Ubuntu without lsb_release cmd
    # #

        elif [ -f /etc/lsb-release ]; then
            . /etc/lsb-release
            OS=$DISTRIB_ID
            OS_VER=$DISTRIB_RELEASE

    # #
    #   older Debian/Ubuntu/etc distros
    # #

        elif [ -f /etc/debian_version ]; then
            OS=Debian
            OS_VER=$(cat /etc/debian_version)

    # #
    #   fallback: uname, e.g. "Linux <version>", also works for BSD
    # #

        else
            OS=$(uname -s)
            OS_VER=$(uname -r)
        fi

# #
#   SECRETS > METHOD > CLEVIS
# #

if [ "${cfg_Storage_Clevis}" = true ]; then

    # #
    #   the Clevis /.secrets directory doesnt exist
    #   create the folder and the needed files.
    #   make user re-launch proteus
    # #

    # #
    #   /.secrets/ folder missing
    # #

    if [ ! -d "${app_dir_secrets}" ]; then

        echo
        echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE} Creating new secrets folder ${FUCHSIA}${app_dir_secrets}${WHITE}.${NORMAL}"
        echo -e "  ${BOLD}${WHITE}Additional files will be created which you must open and add your Clevis encrypted secrets to.${NORMAL}"
        echo -e "  ${BOLD}${WHITE}Relaunch Proteus when you are finished.${NORMAL}"
        echo

        mkdir -p ${app_dir_secrets}
        touch ${app_file_secrets_general}
        touch ${app_file_secrets_github}
        touch ${app_file_secrets_gitlab}
        touch ${app_file_secrets_passwd}

        printf "  Press any key to abort ... ${NORMAL}"
        read -n 1 -s -r -p ""
        echo
        echo

        set +m
        trap "kill -9 ${app_pid} 2> /dev/null" `seq 0 15`
        kill ${app_pid}
        set -m

    # #
    #   /.secrets/ folder exists
    # #

    else

        # #
        #   SECRETS > CLEVIS > LOAD
        #
        #   loads clevis secured secrets from the following files:
        #       ./secrets/.pat_github
        #       ./secrets/.pat_gitlab
        #       ./secrets/.passwd
        #
        #   the contents of the files should be encrypted using Clevis, either tpm
        #   or a tang server.
        #
        #   clevis encrypt tang '{"url": "https://tang1.domain.com"}' <<< 'github_pat_XXXXXX' > /.secrets/.pat_github
        #   clevis decrypt < /.secrets/.pat_github
        # #

        echo -e
        echo -e "  ${LIME_YELLOW}${BOLD}[ Public Values ]${NORMAL}"

        # #
        #   SECRETS > Base / General
        # #

        if [ -f ${app_file_secrets_general} ]; then

            # #
            #   base > load /.secrets/.base
            # #

            if [ -f ${app_file_secrets_general} ]; then
                source ${app_file_secrets_general}
            fi

            # #
            #   base > verify gpg key
            # #

            if [ -z "${GPG_KEY}" ]; then
                printf "%-3s %-15s %-10s\n" "" "GPG Key" "${LIME_YELLOW}GPG_KEY${ORANGE} empty or undefined in ${LIME_YELLOW}${app_file_secrets_general}${NORMAL}"
            elif [ "${GPG_KEY}" == "!" ]; then
                printf "%-3s %-15s %-10s\n" "" "GPG Key" "${RED}GPG_KEY${ORANGE} invalid key !${NORMAL}"
            else
                printf "%-3s %-15s %-10s\n" "" "GPG Key" "${GREEN}${GPG_KEY}${NORMAL}"
            fi

            # #
            #   base > github name
            # #

            if [ -z "${GITHUB_NAME}" ]; then
                printf "%-3s %-15s %-10s\n" "" "Github Name" "${LIME_YELLOW}GITHUB_NAME${ORANGE} empty or undefined in ${LIME_YELLOW}${app_file_secrets_general}${NORMAL}"
            else
                printf "%-3s %-15s %-10s\n" "" "Github Name" "${GREEN}${GITHUB_NAME}${NORMAL}"
            fi

            # #
            #   base > github email
            # #

            if [ -z "${GITHUB_EMAIL}" ]; then
                printf "%-3s %-15s %-10s\n" "" "Github Email" "${LIME_YELLOW}GITHUB_EMAIL${ORANGE} empty or undefined in ${LIME_YELLOW}${app_file_secrets_general}${NORMAL}"
            else
                printf "%-3s %-15s %-10s\n" "" "Github Email" "${GREEN}${GITHUB_EMAIL}${NORMAL}"
            fi

        # #
        #   SECRETS > Base File > Missing
        #
        #   create .base file, and throw warning to user, then exit
        # #

        else
            printf "%-3s %-15s %-10s\n" "" "Base" "${RED}${app_file_secrets_passwd} Missing ${LIME_YELLOW}${app_file_secrets_general}${NORMAL}"

            mkdir -p ${app_dir_secrets}
            touch ${app_file_secrets_general}

            error_missing_file_base
        fi

        echo -e
        echo -e "  ${LIME_YELLOW}${BOLD}[ Secrets ]${NORMAL}"
        bMissingSecret=false

        # #
        #   SECRETS > Github PAT
        # #

        if [ -f ${app_file_secrets_github} ]; then
            CSI_PAT_GITHUB=$(cat ${app_file_secrets_github} | clevis decrypt 2>/dev/null)

            # #
            #   SECRETS > Github PAT > Valid
            # #

            if [ -n "${CSI_PAT_GITHUB}" ]; then
                if [ "${OPT_DEV_ENABLE}" = true ]; then
                    printf "%-3s %-15s %-10s\n" "" "Github PAT" "${GREEN}${CSI_PAT_GITHUB}${NORMAL}"
                else
                    printf "%-3s %-15s %-10s\n" "" "Github PAT" "${GREEN}***********${NORMAL}"
                fi

                export GITHUB_API_TOKEN=${CSI_PAT_GITHUB}

            # #
            #   SECRETS > Github PAT > Empty
            # #

            else
                printf "%-3s %-15s %-10s\n" "" "Github PAT" "${LIME_YELLOW}CSI_PAT_GITHUB${ORANGE} Not declared in ${LIME_YELLOW}${app_file_secrets_github}${NORMAL}"
                bMissingSecret=true
            fi
        else
            printf "%-3s %-15s %-10s\n" "" "Github PAT" "${RED}${app_file_secrets_github} Missing ${LIME_YELLOW}${app_file_secrets_github}${NORMAL}"

            mkdir -p ${app_dir_secrets}
            touch ${app_file_secrets_github}
        fi

        # #
        #   SECRETS > Gitlab PAT
        # #

        if [ -f ${app_file_secrets_gitlab} ]; then
            CSI_PAT_GITLAB=$(cat ${app_file_secrets_gitlab} | clevis decrypt 2>/dev/null)

            # #
            #   SECRETS > Gitlab PAT > Valid
            # #

            if [ -n "${CSI_PAT_GITLAB}" ]; then
                if [ "${OPT_DEV_ENABLE}" = true ]; then
                    printf "%-3s %-15s %-10s\n" "" "Gitlab PAT" "${GREEN}${CSI_PAT_GITLAB}${NORMAL}"
                else
                    printf "%-3s %-15s %-10s\n" "" "Gitlab PAT" "${GREEN}***********${NORMAL}"
                fi

                export GITLAB_PA_TOKEN=${CSI_PAT_GITLAB}

            # #
            #   SECRETS > Gitlab PAT > Empty
            # #

            else
                printf "%-3s %-15s %-10s\n" "" "Gitlab PAT" "${LIME_YELLOW}CSI_PAT_GITLAB${ORANGE} Not declared in ${LIME_YELLOW}${app_file_secrets_gitlab}${NORMAL}"

                # #
                #   Only mark the Gitlab one as missing and show the error if they also havent specified one for Github.
                # #

                if [ -z "${CSI_PAT_GITHUB}" ] || [ "${CSI_PAT_GITHUB}" == "!" ]; then
                    bMissingSecret=true
                fi
            fi
        else
            printf "%-3s %-15s %-10s\n" "" "Gitlab PAT" "${RED}${app_file_secrets_gitlab} Missing ${LIME_YELLOW}${app_file_secrets_gitlab}${NORMAL}"

            mkdir -p ${app_dir_secrets}
            touch ${app_file_secrets_gitlab}
        fi

        # #
        #   SECRETS > Sudo
        # #

        if [ -f ${app_file_secrets_passwd} ]; then
            CSI_SUDO_PASSWD=$(cat ${app_file_secrets_passwd} | clevis decrypt 2>/dev/null)

            # #
            #   SECRETS > Sudo Passwd > Valid
            # #

            if [ -n "${CSI_SUDO_PASSWD}" ]; then
                if [ "${OPT_DEV_ENABLE}" = true ]; then
                    printf "%-3s %-15s %-10s\n" "" "Sudo Passwd" "${GREEN}${CSI_SUDO_PASSWD}${NORMAL}"
                else
                    printf "%-3s %-15s %-10s\n" "" "Sudo Passwd" "${GREEN}***********${NORMAL}"
                fi

                echo "$CSI_SUDO_PASSWD" | sudo -S su 2> /dev/null

            # #
            #   SECRETS > Sudo Passwd > Empty
            # #

            else
                printf "%-3s %-15s %-10s\n" "" "Sudo Passwd" "${LIME_YELLOW}CSI_SUDO_PASSWD${ORANGE} Not declared in ${LIME_YELLOW}${app_file_secrets_passwd}${NORMAL}"
                bMissingSecret=true
            fi
        else
            printf "%-3s %-15s %-10s\n" "" "Sudo Passwd" "${RED}${app_file_secrets_passwd} Missing ${LIME_YELLOW}${app_file_secrets_passwd}${NORMAL}"

            mkdir -p ${app_dir_secrets}
            touch ${app_file_secrets_passwd}
        fi

        if [ "${bMissingSecret}" = true ]; then

            echo -e
            echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
            echo -e
            echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}You are missing required secrets.${NORMAL}"
            echo -e "  ${BOLD}${WHITE}You must define your secrets within files inside ${RED}${app_dir_secrets}${NORMAL}"
            echo -e "  ${BOLD}${WHITE}Each line belongs in its own file, and must be encrypted using Clevis${NORMAL}"
            echo -e 
            printf "%-5s %-60s %-40s\n" "" "${POWDER_BLUE}${app_file_secrets_github}" "${WHITE}github_pat_xxxxxx_xxxxxx${NORMAL}"
            printf "%-5s %-60s %-40s\n" "" "${POWDER_BLUE}${app_file_secrets_gitlab}" "${WHITE}glpat-xxxxxxx${NORMAL}"
            printf "%-5s %-60s %-40s\n" "" "${POWDER_BLUE}${app_file_secrets_passwd}" "${WHITE}YourSudoPassword${NORMAL}"
            echo -e 
            echo -e "  ${BOLD}${WHITE}(Left)   File you should create${NORMAL}"
            echo -e "  ${BOLD}${WHITE}(Right)  What each file should have inside${NORMAL}"
            echo -e 
            echo -e "  ${BOLD}${WHITE}You can create and encrypt each file at the same time using these commands:${NORMAL}"
            echo -e "      ${BOLD}${DEVGREY}clevis encrypt tang '{"url": "https://tang1.domain.com"}' <<< 'github_pat_xxxxxx_xxxxxx' > .pat_github${NORMAL}"
            echo -e "      ${BOLD}${DEVGREY}clevis encrypt tang '{"url": "https://tang1.domain.com"}' <<< 'glpat-xxxxxxx' > .pat_gitlab${NORMAL}"
            echo -e "      ${BOLD}${DEVGREY}clevis encrypt tang '{"url": "https://tang1.domain.com"}' <<< 'YourSudoPassword' > .passwd${NORMAL}"
            echo -e 
            echo -e "  ${BOLD}${WHITE}You can decrypt these files using these commands:${NORMAL}"
            echo -e "      ${BOLD}${DEVGREY}clevis decrypt < .pat_github${NORMAL}"
            echo -e "      ${BOLD}${DEVGREY}clevis decrypt < .pat_github > .pat_github_decrypted${NORMAL}"
            echo -e 
            echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
            echo -e

            printf "  Press any key to abort ... ${NORMAL}"
            read -n 1 -s -r -p ""
            echo
            echo

            set +m
            trap "kill -9 ${app_pid} 2> /dev/null" `seq 0 15`
            kill ${app_pid}
            set -m
        fi

        echo -e
        sleep 5
    fi

# #
#   SECRETS > METHOD > SECRETS.SH (OLD)
# #

else

    # #
    #   secrets.sh missing
    #
    #   warn the user.
    #   create a new secrets.sh file
    # #

    if [ ! -f ${app_file_secrets_sh} ]; then
        echo
        echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}secrets.sh file not found! Creating a blank ${FUCHSIA}secrets.sh${WHITE} file.${NORMAL}"
        echo -e "  ${BOLD}${WHITE}This file defines things such as your GPG key and Github Personal Token.${NORMAL}"
        echo -e "  ${BOLD}${WHITE}Open the newly created ${FUCHSIA}secrets.sh${WHITE} file and add your secrets${NORMAL}"
        echo

        touch ${app_file_secrets_sh}

sudo tee ${app_file_secrets_sh} << EOF > /dev/null
#!/bin/bash
PATH="/bin:/usr/bin:/sbin:/usr/sbin:/home/${USER}/bin"
export GITHUB_API_TOKEN=github_pat_xxxxxxxxx
export GITLAB_PA_TOKEN=glpat-xxxxxxxxxxxxxxx
export GPG_KEY=
export GITHUB_NAME=
export GITHUB_EMAIL=
EOF

        printf "  Press any key to abort ... ${NORMAL}"
        read -n 1 -s -r -p ""
        echo
        echo

        set +m
        trap "kill -9 ${app_pid} 2> /dev/null" `seq 0 15`
        kill ${app_pid}
        set -m

    # #
    #   secrets.sh found
    #
    #   load secrets.sh variables
    # #

    else
        if [ -f ${app_file_secrets_sh} ]; then
            source ${app_file_secrets_sh}
        fi
    fi

fi

# #
#   check > GPG key
#
#   you must define GPG_KEY in the secrets.sh file
# #

if [ -z "${GPG_KEY}" ] || [ "${GPG_KEY}" == "!" ]; then
    error_missing_value_gpg
fi

# #
#   upload to github > precheck
# #

app_run_github_precheck( )
{
    echo -e "  ${GREYL}Configuring git config${WHITE}"

    git config --global credential.helper store

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

    git config --global init.defaultBranch ${app_repo_branch}
    git config --global user.name ${GITHUB_NAME}
    git config --global user.email ${GITHUB_EMAIL}
}

# #
#   check if GPG key defined in git config user.signingKey
# #

checkgit_signing=$( git config --global --get-all user.signingKey )
if [ -z "${checkgit_signing}" ] || [ "${checkgit_signing}" == "!" ]; then
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

    # #
    #   run the same check as above to double confirm that user.signingKey
    #   has been defined.
    # #

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
#   echo -e "  ${BOLD}${FUCHSIA}ATTENTION  ${WHITE}This is a question${NORMAL}"
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

        #printf '%-60s %13s %-5s' "    $1 " "${YELLOW}[$syntax]${NORMAL}" ""
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
    local file_env=/etc/profile.d/proteus-git.sh
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
#   activate using ./proteus-git --update or -u
# #

app_update()
{
    local repo_branch=$([ "${1}" ] && echo "${1}" || echo "${app_repo_branch}" )
    local branch_uri="${app_repo_script/BRANCH/"$repo_branch"}"
    local IsSilent=${2}

    begin "Updating from branch [${repo_branch}]"

    sleep 1
    echo

    printf '%-50s %-5s' "    |--- Downloading update" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo wget -O "${app_file_proteus}" -q "${branch_uri}" >> ${LOGS_FILE} 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    printf '%-50s %-5s' "    |--- Set ownership to ${USER}" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo chgrp ${USER} ${app_file_proteus} >> ${LOGS_FILE} 2>&1
        sudo chown ${USER} ${app_file_proteus} >> ${LOGS_FILE} 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    printf '%-50s %-5s' "    |--- Set perms to u+x" ""
    sleep 1
    if [ -z "${OPT_DEV_NULLRUN}" ]; then
        sudo chmod u+x ${app_file_proteus} >> ${LOGS_FILE} 2>&1
    fi
    echo -e "[ ${STATUS_OK} ]"

    echo

    sleep 2
    echo -e "  ${BOLD}${GREEN}Update Complete!${NORMAL}" >&2
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

    echo
    echo
    echo -e "  ${ORANGE}Error${WHITE}"
    echo -e "  "
    echo -e "  ${WHITE}Folder ${YELLOW}.git${NORMAL} does not exist."
    echo -e "  ${WHITE}Must clone ${YELLOW}${app_repo_apt_url}${NORMAL} first."
    echo -e
    echo -e "  Couldn't find .git folder in ${app_dir}"
    echo
    echo

    app_run_github_precheck

    # git clone -b main https://github.com/Aetherinox/proteus-apt-repo.git
    git init --initial-branch=${app_repo_branch}
    git remote add origin https://github.com/Aetherinox/proteus-apt-repo.git
    git fetch
    git checkout origin/main -b main

    git add .

    # #
    #   
    #   -m <msg>, --message=<msg> 
    #   -s, --signoff 
    # #

    git commit -S -m "New Server Addition"
    git pull https://${GITHUB_NAME}:${CSI_PAT_GITHUB}@github.com/${app_repo_author}/${app_repo_apt}.git


    # git remote add origin https://github.com/Aetherinox/proteus-apt-repo.git
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
    #           sudo add-apt-repository -y "deb [arch=amd64] https://raw.githubusercontent.com/${app_repo_author}/${app_repo_apt}/master focal main" >> $LOGS_FILE 2>&1
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
        echo -e "  ${BOLD}${ORANGE}WARNING  ${WHITE}GPG Key not specified${NORMAL}"
        echo -e "  ${BOLD}${WHITE}Must create ${FUCHSIA}secrets.sh${WHITE} file and define your GPG key.${NORMAL}"
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

    # #
    #   no gpg key registered with gpg command line via gpg --list-secret-keys
    # #

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
            echo -e "  ${WHITE}Specified GPG key ${YELLOW}${GPG_KEY}${NORMAL} not found in GnuPG key store."
            echo -e "  ${WHITE}Searching ${YELLOW}$app_dir/.gpg/${NORMAL} for a GPG key to import."
            echo
            echo

            sleep 1

            if [ -f $app_dir/.gpg/*.gpg ]; then
                gpg_file=$app_dir/.gpg/*.gpg
                gpg --import $gpg_file
                bGPGLoaded=true

                echo
                echo -e "  ${WHITE}Found ${YELLOW}$app_dir/.gpg/${gpg_file}${NORMAL} to import."
                echo
            else
                if [ -z "${OPT_DLPKG_ONLY_TEST}" ]; then
                    echo
                    echo -e "  ${WHITE}No GPG keys found to import. ${RED}Aborting${NORMAL}"
                    echo

                    set +m
                    trap "kill -9 $app_pid 2> /dev/null" `seq 0 15`
                    kill $app_pid
                    set -m
                else
                    echo
                    echo -e "  ${WHITE}No GPG keys found to import. Since you are in ${YELLOW}--onlyTest${NORMAL} mode, ${YELLOW}Skipping${NORMAL}"
                    echo
                fi
            fi

            printf "  Press any key to continue ... ${NORMAL}"
            read -n 1 -s -r -p ""
            echo
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
        printf "%-50s %-5s\n" "${TIME}      Adding ${app_repo_author} GPG key: [https://github.com/${app_repo_author}.gpg]" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Adding github.com/${app_repo_author}.gpg" ""

        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            sudo wget -qO - "https://github.com/${app_repo_author}.gpg" | sudo gpg --batch --yes --dearmor -o "/usr/share/keyrings/${app_repo_apt_pkg}.gpg" >/dev/null
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
        printf "%-50s %-5s\n" "${TIME}      Registering ${app_repo_apt}: https://raw.githubusercontent.com/${app_repo_author}/${app_repo_apt}/${app_repo_branch}" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Registering ${app_repo_apt}" ""

        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/${app_repo_apt_pkg}.gpg] https://raw.githubusercontent.com/${app_repo_author}/${app_repo_apt}//${app_repo_branch} $(lsb_release -cs) ${app_repo_branch}" | sudo tee /etc/apt/sources.list.d/${app_repo_apt_pkg}.list >/dev/null
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
    #   install proteus-git binary in /home/${USER}/bin/proteus-git
    # #

    if ! [ -f "$app_file_proteus" ] || [ -n "${OPT_DEV_NULLRUN}" ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing ${app_title}" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Installing ${app_title}" ""

        sleep 0.5

        if [ -z "${OPT_DEV_NULLRUN}" ]; then
            mkdir -p "$app_dir_home"

            local branch_uri="${app_repo_script/BRANCH/"$app_repo_branch_sel"}"
            sudo wget -O "${app_file_proteus}" -q "$branch_uri" >> $LOGS_FILE 2>&1
            sudo chgrp ${USER} ${app_file_proteus} >> $LOGS_FILE 2>&1
            sudo chown ${USER} ${app_file_proteus} >> $LOGS_FILE 2>&1
            sudo chmod u+x ${app_file_proteus} >> $LOGS_FILE 2>&1
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
    #   add env path /home/${USER}/bin/
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
            # mkdir /home/${USER}/Packages/
            # unzip v3.5.0.zip -d /home/${USER}/Packages/lastversion

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
            cp /home/${USER}/.local/bin/lastversion /home/${USER}/bin/
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

    gpgconfig_file="/home/${USER}/.gnupg/gpg-agent.conf"

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

sudo tee ${gpgconfig_file} << EOF > /dev/null
enable-putty-support
enable-ssh-support
use-standard-socket
default-cache-ttl-ssh 60
max-cache-ttl-ssh 120
default-cache-ttl 28800 # gpg key cache time
max-cache-ttl 28800 # max gpg key cache time
pinentry-program "/usr/bin/pinentry"
allow-loopback-pinentry
allow-preset-passphrase
pinentry-timeout 0
EOF

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

    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
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

    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
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
    #   add +1 so we're not hitting 0
    # #

    count=${#lst_pkgs_sorted[@]}
    local countNow=count

    # #
    #   Begin
    # #

    begin "Aptget Packages [ $count ]"
    echo -e

    # #
    #   Create main folders for architecture
    #   all, amd64, arm54
    # #

    mkdir -p ${app_dir_storage}/{all,amd64,arm64}

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
    #           Move            /server/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb > /server/proteus/incoming/proteus-git/jammy/all/
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
                echo -e "     ${GREYL}|--- ${YELLOW}[ ${count} ]${FUCHSIA}${BOLD} Get ${pkg_arch:0:35}${NORMAL}"
            else
                echo -e "               ${FUCHSIA}${BOLD} Get ${pkg_arch:0:35}${NORMAL}"
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

            echo -e "  ${WHITE}                Package         ${FUCHSIA}${pkg_arch}${NORMAL}"
            echo -e "  ${WHITE}                File            ${FUCHSIA}${app_filename}${NORMAL}"

            # #
            #   output > architecture doesn't exist for this package
            # #

            if echo "$apturl_query" | grep --quiet --ignore-case "find package" ; then
                echo -e "  ${WHITE}                ${GREEN}Status:         ${FUCHSIA}🔍 ${arch:0:35}${NORMAL} doesn't exist for this package"
            fi

            # #
            #   output > apt-url cannot be run because apt get is held up by another process
            # #

            if echo "$apturl_query" | grep --quiet --ignore-case "It is held by process" ; then
                echo -e "  ${WHITE}                ${GREEN}Status:         ${FUCHSIA}🗔 ${pkg_arch:0:35}${NORMAL} held up by process"
            fi

            # #
            #   check if file exists
            #       /home/$USER/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
            # #

            if [[ -f "${app_dir}/${app_filename}" ]]; then

                # #
                #   architecture > all
                #   file must end with 'all.deb'
                # #

                if [[ "${arch}" == "all" ]] && [[ ${app_filename} == *all.deb ]]; then
                    echo -e "  ${WHITE}                Download        ${FUCHSIA}${app_url}${NORMAL}"

                    # #
                    #   architecture > all
                    #   move package to its final location inside the reprepro directory
                    #       move    /home/$USER/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
                    #       to      /home/$USER/proteus/incoming/proteus-git/jammy/all/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
                    # #

                    mv "${app_dir}/${app_filename}" "${app_dir_storage}/all/"

                    echo -e "  ${WHITE}                Move            ${FUCHSIA}${app_dir}/${app_filename}${WHITE} > ${FUCHSIA}${app_dir_storage}/all/${NORMAL}"

                    if [ -n "${bRepreproInstalled}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then

                        # #
                        #   architecture > all > full package path
                        #
                        #       deb_package             incoming/proteus-git/jammy/all/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
                        # #

                        deb_package="${app_dir_repo}/${arch}/${app_filename}"

                        if [ -n "${OPT_DEV_ENABLE}" ] || [ -n "${OPT_DLPKG_ONLY_TEST}" ]; then
                            echo -e "  ${WHITE}                Reprepro        ${FUCHSIA}${deb_package}${NORMAL} for dist ${FUCHSIA}${app_repo_dist_sel}${NORMAL}"
                        fi

                        # #
                        #   architecture > all > reprepro
                        #   add package to reprepro database
                        #
                        #       app_repo_dist_sel       jammy
                        #       deb_package             incoming/proteus-git/jammy/all/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
                        # #

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
                            echo -e "  ${WHITE}                ${GREEN}Status:         ${NORMAL}💡 Already exists${NORMAL}"
                        fi

                        # #
                        #   architecture > all > reprepro
                        #
                        #   output > new package added
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                            echo -e "  ${WHITE}                ${GREEN}Status:         ${NORMAL}✅ New package added${NORMAL}"
                        fi
                    fi

                    bNewPackage=false

                # #
                #   architecture > amd64
                #   file must end with 'amd64.deb'
                # #

                elif [[ "${arch}" == "amd64" ]] && [[ ${app_filename} == *amd64.deb ]]; then
                    echo -e "  ${WHITE}                Download        ${FUCHSIA}${app_url}${NORMAL}"

                    # #
                    #   architecture > amd64
                    #   move package to its final location inside the reprepro directory
                    #       move    /home/$USER/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.2_amd64.deb
                    #       to      /home/$USER/proteus/incoming/proteus-git/jammy/amd64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_amd64.deb
                    # #

                    mv "${app_dir}/${app_filename}" "${app_dir_storage}/amd64/"

                    echo -e "  ${WHITE}                Move            ${FUCHSIA}${app_dir}/${app_filename}${WHITE} > ${FUCHSIA}${app_dir_storage}/amd64/${NORMAL}"

                    if [ -n "${bRepreproInstalled}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then

                        # #
                        #   architecture > amd64 > full package path
                        #
                        #       deb_package             incoming/proteus-git/jammy/amd64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_amd64.deb
                        # #

                        deb_package="${app_dir_repo}/${arch}/${app_filename}"

                        if [ -n "${OPT_DEV_ENABLE}" ] || [ -n "${OPT_DLPKG_ONLY_TEST}" ]; then
                            echo -e "  ${WHITE}                Reprepro        ${FUCHSIA}${deb_package}${NORMAL} for dist ${FUCHSIA}${app_repo_dist_sel}${NORMAL}"
                        fi
                        
                        # #
                        #   architecture > amd64 > reprepro
                        #   add package to reprepro database
                        #
                        #       app_repo_dist_sel       jammy
                        #       deb_package             incoming/proteus-git/jammy/amd64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_amd64.deb
                        # #

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
                            echo -e "  ${WHITE}                ${GREEN}Status:         ${NORMAL}💡 Already exists${NORMAL}"
                        fi

                        # #
                        #   architecture > amd64 > reprepro
                        #
                        #   output > new package added
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                            echo -e "  ${WHITE}                ${GREEN}Status:         ${NORMAL}✅ New package added${NORMAL}"
                        fi
                    fi

                    bNewPackage=false

                # #
                #   architecture > arm64
                #   file must end with 'arm64.deb'
                # #

                elif [[ "${arch}" == "arm64" ]] && [[ ${app_filename} == *arm64.deb ]]; then
                    echo -e "  ${WHITE}                Download        ${FUCHSIA}${app_url}${NORMAL}"

                    # #
                    #   architecture > arm64
                    #   move package to its final location inside the reprepro directory
                    #       move    /home/$USER/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.2_arm64.deb
                    #       to      /home/$USER/proteus/incoming/proteus-git/jammy/arm64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_arm64.deb
                    # #

                    mv "${app_dir}/${app_filename}" "${app_dir_storage}/arm64/"

                    echo -e "  ${WHITE}                Move            ${FUCHSIA}${app_dir}/${app_filename}${WHITE} > ${FUCHSIA}${app_dir_storage}/arm64/${NORMAL}"

                    if [ -n "${bRepreproInstalled}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then

                        # #
                        #   architecture > arm64 > full package path
                        #
                        #       deb_package             incoming/proteus-git/jammy/arm64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_arm64.deb
                        # #

                        deb_package="${app_dir_repo}/${arch}/${app_filename}"

                        if [ -n "${OPT_DEV_ENABLE}" ] || [ -n "${OPT_DLPKG_ONLY_TEST}" ]; then
                            echo -e "  ${WHITE}                Reprepro        ${FUCHSIA}${deb_package}${NORMAL} for dist ${FUCHSIA}${app_repo_dist_sel}${NORMAL}"
                        fi

                        # #
                        #   architecture > arm64 > reprepro
                        #   add package to reprepro database
                        #
                        #       app_repo_dist_sel       jammy
                        #       deb_package             incoming/proteus-git/jammy/arm64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_arm64.deb
                        # #

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
                            echo -e "  ${WHITE}                ${GREEN}Status:         ${NORMAL}💡 Already exists${NORMAL}"
                        fi

                        # #
                        #   architecture > arm64 > reprepro
                        #
                        #   output > new package added
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                            echo -e "  ${WHITE}                ${GREEN}Status:         ${NORMAL}✅ New package added${NORMAL}"
                        fi
                    fi

                    bNewPackage=false

                # #
                #   certain packages will output an *amd64 or *arm64 file when calling
                #   the "all" architecture, which means you'll have double the files.
                #
                #   delete the left-over files since we already have them.
                # #

                else
                    rm "${app_dir}/${app_filename}"
                    echo -e "  ${WHITE}                ${GREEN}Status:         ${NORMAL}⭕ Double file detected ${FUCHSIA}${app_dir}/${app_filename}${NORMAL}${NORMAL}"
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
    echo

    # #
    #   Create main folders for architecture
    #   all, amd64, arm54
    # #

    mkdir -p ${app_dir_storage}/{all,amd64,arm64}

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
    #           Move            /home/$USER/Repos/GitHubDesktop-linux-amd64-3.4.2-linux1.deb > /home/$USER/Repos/incoming/proteus-git/jammy/amd64/
    #           Reprepro        incoming/proteus-git/jammy/amd64/GitHubDesktop-linux-amd64-3.4.2-linux1.deb for dist jammy
    #           Status:         💡 Already exists
    #
    #       Get GitHubDesktop-linux-arm64-3.4.2-linux1.deb
    #           Package         arm64
    #           File            GitHubDesktop-linux-arm64-3.4.2-linux1.deb
    #           Download        https://github.com/shiftkey/desktop/releases/download/release-3.4.2-linux1/GitHubDesktop-linux-arm64-3.4.2-linux1.deb
    #           Move            /home/$USER/Repos/GitHubDesktop-linux-arm64-3.4.2-linux1.deb > /home/$USER/Repos/incoming/proteus-git/jammy/arm64/
    #           Reprepro        incoming/proteus-git/jammy/arm64/GitHubDesktop-linux-arm64-3.4.2-linux1.deb for dist jammy
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
        #
        #       *jammy*.deb
        #       *focal*.deb
        #       *mantic*.deb
        #
        #   (?:\b|_)(?:amd64|arm64|$app_repo_dist_sel)\b.*\.deb$
        #   (?:\b|_)(?:amd64|arm64|$app_repo_dist_sel).*\b.*\.deb$
        # #

        lst_releases=($( lastversion --pre --assets $repo --filter "(?:\b|_)(?:amd64|arm64|$app_repo_dist_sel)\b.*\.deb$" ))

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
                echo -e "     ${GREYL}|--- ${YELLOW}[ ${count} ]${FUCHSIA}${BOLD} Get ${app_filename:0:100}${NORMAL}"
            else
                echo -e "               ${FUCHSIA}${BOLD} Get ${app_filename:0:100}${NORMAL}"
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
                #       /home/$USER/Repos/GitHubDesktop-linux-amd64-3.4.2-linux1.deb
                #       /home/$USER/Repos/GitHubDesktop-linux-amd64-3.4.2-linux1.deb
                # #

                if [ -f "$app_dir/$app_filename" ]; then

                    # #
                    #   architecture > all
                    #   file must end with 'all.deb' or '*all*.deb'
                    # #

                    if [[ "$arch" == "all" ]] && [[ $app_filename == *all.deb || $app_filename == *all*.deb ]]; then
                        echo -e "  ${WHITE}                Package         ${FUCHSIA}${arch}${NORMAL}"
                        echo -e "  ${WHITE}                File            ${FUCHSIA}${app_filename}${NORMAL}"
                        echo -e "  ${WHITE}                Download        ${FUCHSIA}${repo_file_url}${NORMAL}"

                        # #
                        #   architecture > all
                        #   move package to its final location inside the reprepro directory
                        #       move    /home/$USER/Repos/GitHubDesktop-linux-all-3.4.2-linux1.deb
                        #       to      /home/$USER/Repos/incoming/proteus-git/jammy/all/
                        # #

                        mv "$app_dir/$app_filename" "$app_dir_storage/all/"
                        echo -e "  ${WHITE}                Move            ${FUCHSIA}${app_dir}/${app_filename}${WHITE} > ${FUCHSIA}${app_dir_storage}/all/${NORMAL}"

                        if [ -n "${bRepreproInstalled}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then

                            # #
                            #   architecture > all > full package path
                            #
                            #       deb_package             incoming/proteus-git/jammy/all/GitHubDesktop-linux-all-3.4.2-linux1.deb
                            # #

                            deb_package="${app_dir_repo}/${arch}/${app_filename}"

                            if [ -n "${OPT_DEV_ENABLE}" ] || [ -n "${OPT_DLPKG_ONLY_TEST}" ]; then
                                echo -e "  ${WHITE}                Reprepro        ${FUCHSIA}${deb_package}${NORMAL} for dist ${FUCHSIA}${app_repo_dist_sel}${NORMAL}"
                            fi

                            # #
                            #   architecture > all > reprepro
                            #   add package to reprepro database
                            #
                            #       app_repo_dist_sel       jammy
                            #       deb_package             incoming/proteus-git/jammy/all/GitHubDesktop-linux-all-3.4.2-linux1.deb
                            # #

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
                                echo -e "  ${WHITE}                ${GREEN}Status:         ${NORMAL}💡 Already exists${NORMAL}"
                            fi

                            # #
                            #   architecture > all > reprepro
                            #
                            #   output > new package added
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                                echo -e "  ${WHITE}                ${GREEN}Status:         ${NORMAL}✅ New package added${NORMAL}"
                            fi
                        fi

                        echo -e
                        bNewPackage=false

                    elif [[ "$arch" == "amd64" ]] && [[ $app_filename == *amd64.deb || $app_filename == *amd64*.deb ]]; then
                        echo -e "  ${WHITE}                Package         ${FUCHSIA}${arch}${NORMAL}"
                        echo -e "  ${WHITE}                File            ${FUCHSIA}${app_filename}${NORMAL}"
                        echo -e "  ${WHITE}                Download        ${FUCHSIA}${repo_file_url}${NORMAL}"

                        # #
                        #   architecture > amd64
                        #   move package to its final location inside the reprepro directory
                        #       move    /home/aetherx/Repos/GitHubDesktop-linux-amd64-3.4.2-linux1.deb
                        #       to      /home/aetherx/Repos/incoming/proteus-git/jammy/amd64/
                        # #

                        mv "$app_dir/$app_filename" "$app_dir_storage/amd64/"
                        echo -e "  ${WHITE}                Move            ${FUCHSIA}${app_dir}/${app_filename}${WHITE} > ${FUCHSIA}${app_dir_storage}/amd64/${NORMAL}"

                        if [ -n "${bRepreproInstalled}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then

                            # #
                            #   architecture > amd64 > full package path
                            #
                            #       deb_package             incoming/proteus-git/jammy/amd64/GitHubDesktop-linux-amd64-3.4.2-linux1.deb
                            # #

                            deb_package="$app_dir_repo/$arch/$app_filename"

                            if [ -n "${OPT_DEV_ENABLE}" ] || [ -n "${OPT_DLPKG_ONLY_TEST}" ]; then
                                echo -e "  ${WHITE}                Reprepro        ${FUCHSIA}${deb_package}${NORMAL} for dist ${FUCHSIA}${app_repo_dist_sel}${NORMAL}"
                            fi

                            # #
                            #   architecture > amd64 > reprepro
                            #   add package to reprepro database
                            #
                            #       app_repo_dist_sel       jammy
                            #       deb_package             incoming/proteus-git/jammy/amd64/GitHubDesktop-linux-amd64-3.4.2-linux1.deb
                            # #

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
                                echo -e "  ${WHITE}                ${GREEN}Status:         ${NORMAL}💡 Already exists${NORMAL}"
                            fi

                            # #
                            #   architecture > amd64 > reprepro
                            #
                            #   output > new package added
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                                echo -e "  ${WHITE}                ${GREEN}Status:         ${NORMAL}✅ New package added${NORMAL}"
                            fi
                        fi

                        echo -e
                        bNewPackage=false
 
                    elif [[ "$arch" == "arm64" ]] && [[ $app_filename == *arm64.deb || $app_filename == *arm64*.deb ]]; then
                        echo -e "  ${WHITE}                Package         ${FUCHSIA}${arch}${NORMAL}"
                        echo -e "  ${WHITE}                File            ${FUCHSIA}${app_filename}${NORMAL}"
                        echo -e "  ${WHITE}                Download        ${FUCHSIA}${repo_file_url}${NORMAL}"

                        # #
                        #   architecture > arm64
                        #   move package to its final location inside the reprepro directory
                        #       move    /home/aetherx/Repos/GitHubDesktop-linux-arm64-3.4.2-linux1.deb
                        #       to      /home/aetherx/Repos/incoming/proteus-git/jammy/arm64/
                        # #

                        mv "$app_dir/$app_filename" "$app_dir_storage/arm64/"
                        echo -e "  ${WHITE}                Move            ${FUCHSIA}${app_dir}/${app_filename}${WHITE} > ${FUCHSIA}${app_dir_storage}/arm64/${NORMAL}"

                        if [ -n "${bRepreproInstalled}" ] && [ -z "${OPT_DEV_NULLRUN}" ]; then

                            # #
                            #   architecture > arm64 > full package path
                            #
                            #       deb_package             incoming/proteus-git/jammy/arm64/GitHubDesktop-linux-arm64-3.4.2-linux1.deb
                            # #

                            deb_package="$app_dir_repo/$arch/$app_filename"

                            if [ -n "${OPT_DEV_ENABLE}" ] || [ -n "${OPT_DLPKG_ONLY_TEST}" ]; then
                                echo -e "  ${WHITE}                Reprepro        ${FUCHSIA}${deb_package}${NORMAL} for dist ${FUCHSIA}${app_repo_dist_sel}${NORMAL}"
                            fi

                            # #
                            #   architecture > arm64 > reprepro
                            #   add package to reprepro database
                            #
                            #       app_repo_dist_sel       jammy
                            #       deb_package             incoming/proteus-git/jammy/arm64/GitHubDesktop-linux-arm64-3.4.2-linux1.deb
                            # #

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
                                echo -e "  ${WHITE}                ${GREEN}Status:         ${NORMAL}💡 Already exists${NORMAL}"
                            fi

                            # #
                            #   architecture > arm64 > reprepro
                            #
                            #   output > new package added
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                                echo -e "  ${WHITE}                ${GREEN}Status:         ${NORMAL}✅ New package added${NORMAL}"
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
    "author":           "${app_repo_author}",
    "description":      "${app_about}",
    "distrib":          "${app_repo_dist_sel}",
    "url":              "${app_repo_url}",
    "last_duration":    "...........",
    "last_update":      "Running ...............",
    "last_update_ts":   "${DATE_TS}"
}
EOF

        app_run_github_precheck

        git branch -m ${app_repo_branch}

        # git add -A        stages all changes
        # git add .         stages new files and modifications, without deletions (on the current directory and its subdirectories).
        # git add -u        stages modifications and deletions, without new files

        git add --all
        sleep 1

        local NOW=$(date -u '+%m.%d.%Y %H:%M:%S')
        local app_repo_commit="[S] auto-update [ ${app_repo_dist_sel} ] @ ${NOW}"
        echo -e "  ${WHITE}Starting commit ${FUCHSIA}${app_repo_commit}${NORMAL}"

        # #
        #   The command below can throw the following errors:
        #   
        #       error: gpg failed to sign the data:
        #       gpg: skipped "!": No secret key
        #       [GNUPG:] INV_SGNR 9 !
        #       [GNUPG:] FAILURE sign 17
        #       gpg: signing failed: No secret key
        # #

        git commit -S -m "$app_repo_commit"

        sleep 1

        echo -e "  ${WHITE}Starting push ${FUCHSIA}${app_repo_branch}${NORMAL}"
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

        app_run_github_precheck

        echo
        echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
        echo
        echo -e "  ${GREYL}Updating Github: $app_repo_branch${WHITE}"
        echo
        echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
        echo

        git branch -m $app_repo_branch
        git add --all
        git add -u

        sleep 1

        local NOW=$(date -u '+%m.%d.%Y %H:%M:%S')
        local app_repo_commit="[E] auto-update [ $app_repo_dist_sel ] @ $NOW"
        git commit -S -m "$app_repo_commit"

        sleep 1

        git push -u origin $app_repo_branch

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
    "author":           "${app_repo_author}",
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

    tree_output=$( tree -a -I ".git" --dirsfirst )
    tree -a -I ".git" --dirsfirst -J > ${manifest_dir}/tree.json

    #   useful for Gitea with HTML rendering plugin, not useful for Github
    #   tree -a --dirsfirst -I '.git' -H https://github.com/${app_repo_author}/${app_repo}/src/branch/$app_repo_branch/ -o $app_dir/.data/tree.html

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
    #   pull all changes from github
    # #
    
    # remove all changes and sync with remote repo
    # git fetch --prune

    # delete lock
    rm -f "${app_dir}.git/index.lock"

    # force head to match with remote repo
    # git reset --hard origin/main

    git config pull.rebase false
    git_reset=$( reset --hard origin/${app_repo_branch} )
    git_pull=$( git pull origin ${app_repo_branch} --allow-unrelated-histories)

    echo -e "  ${GREYL}Git Pull${WHITE}"
    echo -e "  ${WHITE}${git_pull}${NORMAL}"
    echo -e "  ${WHITE}${git_reset}${NORMAL}"
    echo
    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
    echo

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
    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
    echo
    echo -e "  ${GREYL}Total Execution Time: $elapsed${WHITE}"
    echo
    echo -e " ${BLUE}---------------------------------------------------------------------------------------------------${NORMAL}"
    echo

    sleep 10

    # #
    #   close logs, kill spinner, and finish process
    # #

    finish
    Logs_Finish
}

app_start
