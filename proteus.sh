#!/bin/bash

# #
#   @author             aetherinox
#   @script             Proteus Apt Git
#   @date               2025-05-01 00:00:00
#   @url                https://github.com/Aetherinox/proteus-git
#   
#   ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
#   
#   requires chmod +x proteus.sh
#   
#   This requires you to have the following files in your home directory:
#       /server/.secrets/CSI_BASE                       Base secrets: CSI_GITHUB_NAME, CSI_GITHUB_EMAIL, CSI_GPG_KEY, CSI_TANG_SERVER
#       /server/.secrets/CSI_SUDO_PASSWD                Linux sudo password
#       /server/.secrets/CSI_PAT_GITHUB                 Github PAT Token, not required if using Gitlab
#       /server/.secrets/CSI_PAT_GITLAB                 Gitlab PAT Token, not required if using Github
#       /server/.secrets/CSI_GPG_PASSWD                 GPG password
#       /server/.secrets/CSI_GPG_KEY                    GPG key
#       /server/.secrets/CSI_GITHUB_NAME                Github Author Name
#       /server/.secrets/CSI_GITHUB_EMAIL               Github Author Email
#       /server/.secrets/CSI_TANG_SERVER                Tang Server Url
#   
#   LastVersion requires two env variables be exported when running, otherwise you will be rate-limited by Github and Gitlab.
#       export GITHUB_API_TOKEN=${CSI_PAT_GITHUB}
#       export GITLAB_PA_TOKEN=${CSI_PAT_GITLAB}
#
#   DO NOT change the name of the above env variables otherwise LastVersion will not work and will be rate-limited.
#       - GITHUB_API_TOKEN
#       - GITLAB_PA_TOKEN
#
#   This script requires a minimum Reprepro version or it will cause database errors:
#       - v5.4.6
#   
#   ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
#   
#   To test the functionality of this script without actually  writing anything to Github or Reprepro, you can use the command
#       ./proteus.sh --dev --dryrun
#   
#   ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
#   @usage          ./proteus.sh -d -S                                                          (skip-commit) will add new packages to reprepro database, but will not commit to github
#                   ./proteus.sh -d -D                                                          (dryrun) test the entire script without actually making changes or updating packages
#                   ./proteus.sh -d -D --package opensc                                         (dryrun) test adding new apt-get package without actually adding
#                   ./proteus.sh -d --package opensc                                            add new apt-get package to current ubuntu distro
#                   ./proteus.sh -f                                                             set owner root:root and permissions +x for proteus.sh
#                   ./proteus.sh -f username                                                    set owner username:username and permissions +x for proteus.sh
#                   ./proteus.sh -k                                                             kill existing processes of proteus script
#                   ./proteus -L                                                                list locally / manually installed packages
#                   ./proteus -l                                                                list all installed packages
#                   ./proteus -D -d -t "focal" -a "amd64" -l "reprepro_5.4.7-1_amd64.deb"       (dryrun) add local package but don't push changes to reprepro or github
#                   ./proteus -t "focal" -a "amd64" -l "reprepro_5.4.7-1_amd64.deb"             (commit) add local package; push changes to reprepro or github
# #

# #
#   define > system
# #

sys_arch=$(dpkg --print-architecture)
sys_code=$(lsb_release -cs)

# #
#   define > distro
#       freedesktop.org and systemd
#       returns distro information.
# #

    if [ -f /etc/os-release ]; then
        . /etc/os-release
        sys_os_name=$NAME
        sys_os_ver=$VERSION_ID

# #
#   distro > linuxbase.org
# #

    elif type lsb_release >/dev/null 2>&1; then
        sys_os_name=$(lsb_release -si)
        sys_os_ver=$(lsb_release -sr)

# #
#   distro > versions of Debian/Ubuntu without lsb_release cmd
# #

    elif [ -f /etc/lsb-release ]; then
        . /etc/lsb-release
        sys_os_name=$DISTRIB_ID
        sys_os_ver=$DISTRIB_RELEASE

# #
#   distro > older Debian/Ubuntu/etc distros
# #

    elif [ -f /etc/debian_version ]; then
        sys_os_name=Debian
        sys_os_ver=$(cat /etc/debian_version)

# #
#   distro > fallback: uname, e.g. "Linux <version>", also works for BSD
# #

    else
        sys_os_name=$(uname -s)
        sys_os_ver=$(uname -r)
    fi

# #
#   define > colors
#
#   Use the color table at:
#       - https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797
# #

declare -A c=(
    [end]=$'\e[0m'
    [white]=$'\e[97m'
    [bold]=$'\e[1m'
    [dim]=$'\e[2m'
    [underline]=$'\e[4m'
    [strike]=$'\e[9m'
    [blink]=$'\e[5m'
    [inverted]=$'\e[7m'
    [hidden]=$'\e[8m'
    [black]=$'\e[38;5;0m'
    [fuchsia1]=$'\e[38;5;205m'
    [fuchsia2]=$'\e[38;5;198m'
    [red]=$'\e[38;5;160m'
    [red2]=$'\e[38;5;196m'
    [orange]=$'\e[38;5;202m'
    [orange2]=$'\e[38;5;208m'
    [magenta]=$'\e[38;5;5m'
    [blue]=$'\e[38;5;033m'
    [blue2]=$'\e[38;5;033m'
    [blue3]=$'\e[38;5;68m'
    [cyan]=$'\e[38;5;51m'
    [green]=$'\e[38;5;2m'
    [green2]=$'\e[38;5;76m'
    [yellow]=$'\e[38;5;184m'
    [yellow2]=$'\e[38;5;190m'
    [yellow3]=$'\e[38;5;193m'
    [grey1]=$'\e[38;5;240m'
    [grey2]=$'\e[38;5;244m'
    [grey3]=$'\e[38;5;250m'
    [navy]=$'\e[38;5;62m'
    [olive]=$'\e[38;5;144m'
    [peach]=$'\e[38;5;210m'
)

# #
#   unicode for emojis
#       https://apps.timwhitlock.info/emoji/tables/unicode
# #

declare -A icon=(
    ["symbolic link"]=$'\xF0\x9F\x94\x97' # 🔗
    ["regular file"]=$'\xF0\x9F\x93\x84' # 📄
    ["directory"]=$'\xF0\x9F\x93\x81' # 📁
    ["regular empty file"]=$'\xe2\xad\x95' # ⭕
    ["log"]=$'\xF0\x9F\x93\x9C' # 📜
    ["1"]=$'\xF0\x9F\x93\x9C' # 📜
    ["2"]=$'\xF0\x9F\x93\x9C' # 📜
    ["3"]=$'\xF0\x9F\x93\x9C' # 📜
    ["4"]=$'\xF0\x9F\x93\x9C' # 📜
    ["5"]=$'\xF0\x9F\x93\x9C' # 📜
    ["pem"]=$'\xF0\x9F\x94\x92' # 🔑
    ["pub"]=$'\xF0\x9F\x94\x91' # 🔒
    ["pfx"]=$'\xF0\x9F\x94\x92' # 🔑
    ["p12"]=$'\xF0\x9F\x94\x92' # 🔑
    ["key"]=$'\xF0\x9F\x94\x91' # 🔒
    ["crt"]=$'\xF0\x9F\xAA\xAA ' # 🪪
    ["gz"]=$'\xF0\x9F\x93\xA6' # 📦
    ["zip"]=$'\xF0\x9F\x93\xA6' # 📦
    ["gzip"]=$'\xF0\x9F\x93\xA6' # 📦
    ["deb"]=$'\xF0\x9F\x93\xA6' # 📦
    ["sh"]=$'\xF0\x9F\x97\x94' # 🗔
)

# #
#   define > general
# #

app_title="Proteus Apt Git"
app_about="Internal system to Proteus App Manager which grabs debian packages."
app_ver=("1" "4" "0" "0")
app_pid_spin=0
app_pid=$BASHPID
app_pid_tee=0                                                                       # tee process id
app_queue_url=()
app_count=0
app_guid="1000"                                                                     # group id for permission assignment
app_uuid="1000"                                                                     # user id for permission assignment
app_bFoundSafe=false                                                                # git safe.directory found
now=`date '+%m.%d.%Y %H:%M:%S'`;                                                    # current date/time
app_tang_domain="https://tang.domain.lan"                                           # tang server domain
app_repo_domain="Aetherinox/proteus-apt-repo"                                       # repo domain
app_repo_developer="aetherinox"                                                     # repo developer
app_repo_commit_msg="synchronize - $now"                                            # repo commit message

# #
#   define > dirs
# #

app_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"            # path where script was last found in
app_dir_this_dir="${PWD}"                                                           # current script directory
app_dir_bin="${HOME}/bin"                                                           # /home/$USER/bin
app_dir_secrets="/server/.secrets"                                                  # path to .secrets folder
app_dir_gpg=".gpg"                                                                  # .gpg folder
app_dir_incoming="incoming/packages/${sys_code}"                                    # temp storage location for newly downloaded packages

# #
#   define > vars
# #

argLocalPackage=
argAptPackage=
argGithubPackage=
argDevEnabled=false
argNoLogs=false
argSkipGitCommit=false
argDryRun=false
argVerbose=false
argBranch=
argDistribution=
argArchitecture=amd64
argChownOwner=root
app_repo_dist_sel=
skip_clevis=false

# #
#   define > env vars
# #

CSI_PAT_GITHUB=
CSI_PAT_GITLAB=
CSI_SUDO_PASSWD=
CSI_GPG_PASSWD=

# #
#   define > packages > apt-get
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
    'dos2unix'
    'firefox'
    'flatpak'
    'geoipupdate'
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
    'sirikali'
    'sks'
    'snap'
    'snapd'
    'tcptrack'
    'trash-cli'
    'tree'
    'wget'
    'zram-tools'
)

# #
#   define > packages > Github Repos (LastVersion)
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
    'muesli/duf'
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
#   count packages
# #

app_count=${#lst_packages[@]}

# #
#   ensure we're in the correct directory
# #

cd ${app_dir}

# #
#   define > files
# #

app_file_this=$(basename "$0")                                                      # proteus.sh (with ext)
app_file_bin="${app_file_this%.*}"                                                  # proteus (without ext)
app_file_bin_bws=bws                                                                # bws
app_file_secret_base="CSI_BASE"                                                     # clevis encrypted > base file
app_file_secret_sudo_passwd="CSI_SUDO_PASSWD"                                       # clevis encrypted > sudo password
app_file_secret_gpg_passwd="CSI_GPG_PASSWD"                                         # clevis encrypted > gpg password
app_file_secret_pat_github="CSI_PAT_GITHUB"                                         # clevis encrypted > PAT github
app_file_secret_pat_gitlab="CSI_PAT_GITLAB"                                         # clevis encrypted > PAT gitlab
app_file_secret_gpg_key="CSI_GPG_KEY"
app_file_secret_gh_name="CSI_GITHUB_NAME"
app_file_secret_gh_email="CSI_GITHUB_EMAIL"
app_file_secret_tang_server="CSI_TANG_SERVER"

# #
#   define > paths
# #

path_usr_local_bin="/usr/local/bin"                                                 #  /usr/local/bin
path_tmp="/tmp/downloads"                                                           #  temp download path
path_file_bin_binary="${app_dir_bin}/${app_file_bin}"                               #  /home/$USER/bin/proteus
path_file_bin_bws="${path_usr_local_bin}/${app_file_bin_bws}"                       #  /usr/local/bin/bws

path_file_secret_base=${app_dir_secrets}/${app_file_secret_base}                    #  CSI_GPG_KEY, CSI_GITHUB_NAME, CSI_GITHUB_EMAIL, CSI_TANG_SERVER
path_file_secret_sudo_passwd=${app_dir_secrets}/${app_file_secret_sudo_passwd}      #  file for sudo passwd
path_file_secret_pat_github=${app_dir_secrets}/${app_file_secret_pat_github}        #  file for github PAT
path_file_secret_pat_gitlab=${app_dir_secrets}/${app_file_secret_pat_gitlab}        #  file for gitlab PAT
path_file_secret_gpg_passwd=${app_dir_secrets}/${app_file_secret_gpg_passwd}        #  file for gpg passwd
path_file_secret_gpg_key=${app_dir_secrets}/${app_file_secret_gpg_key}              #  file for gpg key
path_file_secret_gh_name=${app_dir_secrets}/${app_file_secret_gh_name}              #  file for github name
path_file_secret_gh_email=${app_dir_secrets}/${app_file_secret_gh_email}            #  file for github email
path_file_secret_tang_server=${app_dir_secrets}/${app_file_secret_tang_server}      #  file for tang server

path_file_secret_gpg_passwd_sudo=${HOME}/.${app_file_secret_sudo_passwd}            #  GPG File > sudo passwd
path_file_secret_gpg_passwd_gpg=${HOME}/.${app_file_secret_gpg_passwd}              #  GPG File > gpg passwd
path_file_secret_gpg_pat_github=${HOME}/.${app_file_secret_pat_github}              #  GPG File > github PAT
path_file_secret_gpg_pat_gitlab=${HOME}/.${app_file_secret_pat_gitlab}              #  GPG File > gitlab PAT

# #
#   define > exports
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
#   packages > git not installed
# #

if ! [ -x "$(command -v git)" ]; then
    echo -e "  ${c[green]}OK           ${c[end]}Installing package ${c[blue2]}Git${c[end]}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install git -y -qq >/dev/null 2>&1
fi

# #
#   packages > git not installed
# #

if ! [ -x "$(command -v gpg)" ]; then
    echo -e "  ${c[green]}OK           ${c[end]}Installing package ${c[blue2]}GPG${c[end]}"
    sudo apt-get update -y -q >/dev/null 2>&1
    sudo apt-get install gpg -y -qq >/dev/null 2>&1
fi

# #
#   Create .gitignore
# #

if [ ! -f "${app_dir}/.gitignore" ] || [ ! -s "${app_dir}/.gitignore" ]; then

    touch "${app_dir}/.gitignore"

sudo tee ${app_dir}/.gitignore << EOF > /dev/null
# #
#   Misc
# #
incoming/
.env
sources-*.list
.pipe
/*.deb

# #
#   Logs
# #
logs/
*-log
*.log

# #
#   GPG keys
# #
/${app_dir_gpg}/*.gpg
/${app_dir_gpg}/*.asc
/*.gpg
/*.asc

# #
#   Secrets Files
# #
${app_file_secret_base}
${app_file_secret_sudo_passwd}
${app_file_secret_gpg_passwd}
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

    # #
    #   bitwarden secrets cli
    # #

    if [ -f "${path_file_bin_bws}" ] && [ -n "${BWS_ACCESS_TOKEN}" ]; then
        CSI_SUDO_PASSWD_ID=$(${path_file_bin_bws} secret list | jq -r ". | map(select(.key == \"CSI_SUDO_PASSWD\").id)[0]")
        if [ -n "${CSI_SUDO_PASSWD_ID}" ]; then
            CSI_SUDO_PASSWD=$(${path_file_bin_bws} secret get $CSI_SUDO_PASSWD_ID | jq -r ".value")

            if [ -n "${CSI_SUDO_PASSWD}" ]; then
                echo "Bitwarden"
            fi
        fi
    fi

    # #
    #   clevis mode
    # #

    if [ -x "$(command -v clevis)" ] && ([ -z "${CSI_SUDO_PASSWD}" ]); then
        tang_status=`curl -Is "${CSI_TANG_SERVER}" | tac | grep -o "^HTTP.*" | cut -f 2 -d' ' | head -1`

        if [ "$tang_status" == "200" ] && [ -d "${app_dir_secrets}" ] && [ -f ${path_file_secret_sudo_passwd} ]; then
            CSI_SUDO_PASSWD=$(cat ${path_file_secret_sudo_passwd} | clevis decrypt 2>/dev/null)
            if [ -n "${CSI_SUDO_PASSWD}" ]; then
                echo "Clevis"
            fi
        fi
    fi

    # #
    #   gpg encrypt mode
    # #

    if ([ -z "${CSI_SUDO_PASSWD}" ] || [ "$CSI_SUDO_PASSWD" == "xxxxxxxxxxxxxxx" ] ) && [ -f "${HOME}/.${app_file_secret_sudo_passwd}" ]; then
        CSI_SUDO_PASSWD=$(gpg --decrypt "${HOME}/.${app_file_secret_sudo_passwd}" 2>/dev/null)

        if [ -n "${CSI_SUDO_PASSWD}" ]; then
            echo "GPG Encrypt"
        fi
    fi

    # #
    #   no modes available
    # #

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
    echo -e "  ⭕ ${c[grey2]}${app_file_this}${c[end]}: \n     ${c[bold]}${c[red]}Error${NORMAL}: ${c[end]}$1"
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
    fi

    echo -e 
    echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
    echo
    echo -e "  ${c[orange]}WARNING      ${c[end]}Missing ${c[yellow]}${path_file_secret_base}${c[end]}"
    echo -e "               Create new ${c[fuchsia1]}${path_file_secret_base}${c[end]} file and add the following lines:${c[end]}"
    echo -e
    echo -e "               ${c[grey2]}#!/bin/bash${c[end]}"
    echo -e "               ${c[grey2]}PATH=\"/bin:/usr/bin:/sbin:/usr/sbin:${HOME}/bin\"${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_SUDO_PASSWD=${c[end]}xxxxxxxxxxxxxxx${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_PAT_GITHUB=${c[end]}github_pat_xxxxxxxxxxxxxxx${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_PAT_GITLAB=${c[end]}glpat-xxxxxxxxxxxxxxx${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_GPG_PASSWD=${c[end]}xxxxxxxxxxxxxxx${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_GPG_KEY=${c[end]}XXXXXXXX${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_GITHUB_NAME=${c[end]}GithubUsername${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_GITHUB_EMAIL=${c[end]}user@email${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_TANG_SERVER=${c[end]}https://tang.domain.lan${c[end]}"
    echo
    echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
    echo -e

    printf "  Press any key to abort ... ${c[end]}"
    read -n 1 -s -r -p ""
    echo -e
    echo -e

    set +m
    trap "kill -9 ${app_pid} 2> /dev/null" `seq 0 15`
    kill ${app_pid}
    set -m
}

# #
#   func > error > CSI_GPG_KEY missing
#
#   throws an error if CSI_GPG_KEY is not specified
# #

error_missing_value_gpg()
{
    local file_base_path="Unknown"
    if [ "${mode_clevis}" = true ]; then
        file_base_path="${path_file_secret_base}"
    fi

    echo -e 
    echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
    echo
    echo -e "  ${c[orange]}WARNING      ${c[end]}Missing ${c[yellow]}\$CSI_GPG_KEY${c[end]}"
    echo -e "               Create the file ${c[fuchsia1]}${path_file_secret_base}${c[end]} and specify the following env variables inside:${c[end]}"
    echo -e "               Relaunch Proteus when you are finished.${c[end]}"
    echo -e
    echo -e "               ${c[grey2]}#!/bin/bash${c[end]}"
    echo -e "               ${c[grey2]}PATH=\"/bin:/usr/bin:/sbin:/usr/sbin:${HOME}/bin\"${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_PAT_GITHUB=${c[end]}github_pat_xxxxxxxxxxxxxxx${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_PAT_GITLAB=${c[end]}glpat-xxxxxxxxxxxxxxx${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_SUDO_PASSWD=${c[end]}xxxxxxxxxxxxxxx${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_GPG_PASSWD=${c[end]}xxxxxxxxxxxxxxx${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_GPG_KEY=${c[end]}XXXXXXXX${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_GITHUB_NAME=${c[end]}GithubUsername${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_GITHUB_EMAIL=${c[end]}user@email${c[end]}"
    echo -e "               ${c[red]}export ${c[green]}CSI_TANG_SERVER=${c[end]}https://tang.domain.lan${c[end]}"
    echo
    echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
    echo -e

    printf "  Press any key to abort ... ${c[end]}"
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
    app_repo_dist_sel=$( [[ -n "$argDistribution" ]] && echo "$argDistribution" || echo "$sys_code"  )

    echo -e
    printf "  ${c[blue]}${app_title}${c[end]}\n" 1>&2
    printf "  ${c[grey2]}${app_about}${c[end]}\n" 1>&2
    printf "  ${c[fuchsia2]}${app_file_this}${c[end]} ${c[grey2]}--precheck ${c[end]} || ${c[grey2]}--current ${c[yellow]}\"1.10.0\"${c[end]} [ ${c[grey2]}--force${c[end]} ] \n" 1>&2
    echo -e
    echo -e
    printf '  %-5s %-40s\n' "${c[grey1]}Syntax:${c[end]}" "" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}Command${c[end]}           " "${c[fuchsia2]}${app_file_this}${c[end]} [ ${c[grey2]}-option${c[end]} [ ${c[yellow]}arg${c[end]} ]${c[end]} ]" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}Options${c[end]}           " "${c[fuchsia2]}${app_file_this}${c[end]} [ ${c[grey2]}-h${c[end]} | ${c[grey2]}--help${c[end]} ]" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "    ${c[grey2]}-A${c[end]}            " "required" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "    ${c[grey2]}-A...${c[end]}         " "required; multiple can be specified" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "    ${c[grey2]}[ -A ]${c[end]}        " "optional" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "    ${c[grey2]}[ -A... ]${c[end]}     " "optional; multiple can be specified" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "    ${c[grey2]}{ -A | -B }${c[end]}   " "one or the other; do not use both" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}Arguments${c[end]}         " "${c[fuchsia2]}${app_file_this}${c[end]} [ ${c[grey2]}-r${c[yellow]} arg${c[end]} | ${c[grey2]}--repo ${c[yellow]}arg${c[end]} ] ${c[yellow]}arg${c[end]}" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}Examples${c[end]}          " "${c[fuchsia2]}${app_file_this}${c[end]}${c[end]}" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}${c[end]}                  " "${c[fuchsia2]}${app_file_this}${c[end]} ${c[grey2]}--skip-commit --dev${c[end]}" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}${c[end]}                  " "${c[fuchsia2]}${app_file_this}${c[end]} ${c[grey2]}--apt-package${c[yellow]} \"opensc\"${c[end]} ${c[grey2]}--dev${c[end]}" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}${c[end]}                  " "${c[fuchsia2]}${app_file_this}${c[end]} ${c[grey2]}--fix-perms${c[yellow]} \"${argChownOwner}\"${c[end]} ${c[grey2]}--dev${c[end]}" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}${c[end]}                  " "${c[fuchsia2]}${app_file_this}${c[end]} ${c[grey2]}--kill${c[end]}" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}${c[end]}                  " "${c[fuchsia2]}${app_file_this}${c[end]} ${c[grey2]}--reset${c[yellow]} \"${app_repo_branch}\"${c[end]}" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}${c[end]}                  " "${c[fuchsia2]}${app_file_this}${c[end]} ${c[grey2]}--dist${c[yellow]} \"${app_repo_dist_sel}\"${c[grey2]} --arch${c[yellow]} \"${argArchitecture}\"${c[grey2]} --local-package${c[yellow]} \"reprepro_5.4.7-1_amd64.deb\"${c[end]}" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}${c[end]}                  " "${c[fuchsia2]}${app_file_this}${c[end]} ${c[grey2]}--dist${c[yellow]} \"${app_repo_dist_sel}\"${c[grey2]} --arch${c[yellow]} \"${argArchitecture}\"${c[grey2]} --local-package${c[yellow]} \"reprepro_5.4.7-1_amd64.deb\"${c[grey2]} --dryrun${c[end]}" 1>&2
    printf '  %-5s %-48s %-40s\n' "    " "${c[grey1]}${c[end]}                  " "${c[fuchsia2]}${app_file_this}${c[end]} ${c[grey2]}--url-package${c[yellow]} \"reprepro\"${c[grey2]}${c[end]}" 1>&2

    echo -e
    printf '  %-5s %-40s\n' "${c[grey1]}Options:${c[end]}" "" 1>&2

    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-A${c[grey1]},${c[blue2]}  --only-apt ${c[yellow]}${c[end]}                " "only download pkgs from apt-get; do not download packages from github using lastversion${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-G${c[grey1]},${c[blue2]}  --only-git ${c[yellow]}${c[end]}                " "only download pkgs from github using lastversion; do not download from apt-get${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-p${c[grey1]},${c[blue2]}  --apt-package ${c[yellow]}<pkg>${c[end]}        " "add new pkg from apt-get for distro you are currently running${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}                ${c[yellow]}     ${c[end]}        " "cannot specify different distro (jammy, noble, etc)${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}                ${c[yellow]}     ${c[end]}        " "does not add pkg to bash script list (it is a one-time update)${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-g${c[grey1]},${c[blue2]}  --git-package ${c[yellow]}<pkg>${c[end]}        " "add new pkg from github for distro you are currently running${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}                ${c[yellow]}     ${c[end]}        " "cannot specify different distro (jammy, noble, etc)${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}                ${c[yellow]}     ${c[end]}        " "does not add pkg to bash script list (it is a one-time update)${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-l${c[grey1]},${c[blue2]}  --local-package ${c[yellow]}<pkg.deb>${c[end]}  " "add new local .deb package in root folder ${c[navy]}${app_dir}${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}                ${c[yellow]}     ${c[end]}        " "can specify different distro (jammy, noble, etc) using ${c[navy]}--dist \"${app_repo_dist_sel}\"${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}                ${c[yellow]}     ${c[end]}        " "can specify different arch (amd64, arm64, i386) using ${c[navy]}--arch \"${argArchitecture}\"${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}                ${c[yellow]}${c[end]}             " "   ${c[grey1]}${app_file_this} --dist \"${app_repo_dist_sel}\" --arch \"${argArchitecture}\" --local-package \"reprepro_5.4.7-1_amd64.deb\"${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-U${c[grey1]},${c[blue2]}  --url-package ${c[yellow]}<pkg>${c[end]}        " "get online repo url that a package is hosted from${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-L${c[grey1]},${c[blue2]}  --list-packages ${c[yellow]}${c[end]}           " "list installed apt-get packages${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-O${c[grey1]},${c[blue2]}  --list-packages-local ${c[yellow]}${c[end]}     " "list local manually installed packages; usually installed using ${c[navy]}dpkg -i packagename.deb${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-f${c[grey1]},${c[blue2]}  --fix-perms ${c[yellow]}<owner>${c[end]}        " "fix permissions and owner for script ${c[navy]}${app_file_this}${c[end]}; optional owner arg ${c[navy]}<default> ${c[peach]}${argChownOwner}${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-R${c[grey1]},${c[blue2]}  --reset ${c[yellow]}<string>${c[end]}           " "reset local repo files to state of remote git branch by performing ${c[navy]}git reset --hard origin/${app_repo_branch}${c[end]}; optional git branch arg ${c[navy]}<default> ${c[peach]}${app_repo_branch}${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-t${c[grey1]},${c[blue2]}  --dist ${c[yellow]}<string>${c[end]}            " "specify distribution for pkgs ${c[navy]}<default> ${c[peach]}${sys_code}${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow]}${c[end]}                       " "   ${c[grey1]}focal, jammy, noble" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-a${c[grey1]},${c[blue2]}  --arch ${c[yellow]}<string>${c[end]}            " "specify architecture for pkgs when used with  ${c[navy]}-l, --local-package${c[end]} to add pkg to different dist; ${c[navy]}<default> ${c[peach]}${argArchitecture}${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}         ${c[yellow]}${c[end]}                    " "   ${c[grey1]}amd64, arm64, i386" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-S${c[grey1]},${c[blue2]}  --skip-commit ${c[yellow]}${c[end]}             " "runs script; but only registers new pkgs with reprepro; no github commits${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-D${c[grey1]},${c[blue2]}  --dryrun ${c[yellow]}${c[end]}                  " "runs script; does not download pkgs; does not add pkg to reprepro; does not commit to git${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-k${c[grey1]},${c[blue2]}  --kill ${c[yellow]}${c[end]}                    " "force running instances of script to be killed${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-r${c[grey1]},${c[blue2]}  --report ${c[yellow]}${c[end]}                  " "show stats about pkgs, variables, etc.${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-c${c[grey1]},${c[blue2]}  --clean ${c[yellow]}${c[end]}                   " "remove lingering .deb files from file structure left behind${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-s${c[grey1]},${c[blue2]}  --setup ${c[yellow]}${c[end]}                   " "runs initial setup; installs any pkgs required by script${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}  ${c[grey1]} ${c[blue2]}      ${c[yellow]}${c[end]}                       " "   ${c[grey1]}apt-move, apt-url, curl, wget, tree, reprepro, lastversion" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-u${c[grey1]},${c[blue2]}  --update ${c[yellow]}<string>${c[end]}          " "download new version of script from github${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-b${c[grey1]},${c[blue2]}  --branch ${c[yellow]}<string>${c[end]}          " "specifies update branch; used with option ${c[navy]}-u, --update ${c[navy]}<default> ${c[peach]}${app_repo_branch}${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-d${c[grey1]},${c[blue2]}  --dev ${c[yellow]}${c[end]}                     " "developer mode; verbose logging${c[end]}" 1>&2
    printf '  %-5s %-81s %-40s\n' "    " "${c[blue2]}-h${c[grey1]},${c[blue2]}  --help ${c[yellow]}${c[end]}                    " "show this help menu${c[end]}" 1>&2
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

    load_secrets

    local secrets_mode=$(get_mode)
    local file_base_path="Missing"
    var_clevis_status='Disabled'
    if [ "${mode_clevis}" = true ]; then
        file_base_path="${path_file_secret_base}"
        var_clevis_status='Enabled'
    fi

    # #
    #   base > load /.secrets/.base
    # #

    if [ -f ${path_file_secret_base} ]; then
        source ${path_file_secret_base}
    fi

    # #
    #   base > secrets mode > color
    #
    #   changes the color of the "secrets.sh" mode to a dark gray if clevis mode is enabled
    # #

    clrSecretsModeSh_Title=$([ ${var_clevis_status} == "Enabled" ] && echo ${c[strike]}${c[grey1]} || echo ${c[yellow]})
    clrSecretsModeSh_Item=$([ ${var_clevis_status} == "Enabled" ] && echo ${c[grey3]} || echo ${c[blue2]})

    # #
    #  Section > Header 
    # #

    echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
    echo -e " ${c[green]}${c[bold]} ${app_title} - v$(get_version)${c[end]}${c[magenta]}"
    echo -e "  This app downloads the latest version of numerous packages and posts them to the Proteus Apt Repo."
    echo -e 

    # #
    #  Section > Settings
    # #

    echo -e
    echo -e "  ${c[yellow]}${c[bold]}[ Settings ]${c[end]}"

    # #
    #   count packages
    # #

    #  reee
    local secrets_mode=$([ ${var_clevis_status} == "Enabled" ] && echo "Clevis Mode (Enabled)" || echo "Unencrypted")
    local iPackages_apt=${#lst_packages[@]}
    local iPackages_github=${#lst_github[@]}
    local iPackages_arch=${#lst_arch[@]}

    printf "%-5s %-40s %-40s %-40s\n" "" "${c[blue2]}⚙️  Script" "${c[end]}${app_file_this}" "${c[end]}"
    printf "%-5s %-40s %-40s %-40s\n" "" "${c[blue2]}⚙️  Path" "${c[end]}${app_dir}" "${c[end]}"
    printf "%-5s %-40s %-40s %-40s\n" "" "${c[blue2]}⚙️  Version" "${c[end]}v$(get_version)" "${c[end]}"
    printf "%-5s %-40s %-40s %-40s\n" "" "${c[blue2]}⚙️  Secret Mode" "${c[end]}${secrets_mode}" "${c[end]}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}📦 Packages (Apt)" "${c[end]}${iPackages_apt}" "${c[end]}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}📦 Packages (Github)" "${c[end]}${iPackages_github}" "${c[end]}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}📦 Architectures" "${c[end]}${iPackages_arch}" "${c[end]}"

    # #
    #  Section > Variables
    # #

    echo -e
    echo -e
    echo -e "  ${c[yellow]}${c[bold]}[ Variables ]${c[end]}"

    local bExists_env_sudo_passwd=$([ -z "${CSI_SUDO_PASSWD}" ] && echo "Missing" || echo "${CSI_SUDO_PASSWD}")
    local bExists_env_pat_github=$([ -z "${CSI_PAT_GITHUB}" ] && echo "Missing" || echo "${CSI_PAT_GITHUB}")
    local bExists_env_pat_gitlab=$([ -z "${CSI_PAT_GITLAB}" ] && echo "Missing" || echo "${CSI_PAT_GITLAB}")
    local bExists_env_gpg_passwd=$([ -z "${CSI_GPG_PASSWD}" ] && echo "Missing" || echo "${CSI_GPG_PASSWD}")
    local bExists_env_gpg_key=$([ -z "${CSI_GPG_KEY}" ] && echo "Missing" || echo "${CSI_GPG_KEY}")
    local bExists_env_github_name=$([ -z "${CSI_GITHUB_NAME}" ] && echo "Missing" || echo "${CSI_GITHUB_NAME}")
    local bExists_env_github_email=$([ -z "${CSI_GITHUB_EMAIL}" ] && echo "Missing" || echo "${CSI_GITHUB_EMAIL}")
    local bExists_env_tang_server=$([ -z "${CSI_TANG_SERVER}" ] && echo "Missing" || echo "${CSI_TANG_SERVER}")

    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}✎ CSI_SUDO_PASSWD" "${c[end]}${bExists_env_sudo_passwd}" "${c[end]}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}✎ CSI_PAT_GITHUB" "${c[end]}${bExists_env_pat_github}" "${c[end]}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}✎ CSI_PAT_GITLAB" "${c[end]}${bExists_env_pat_gitlab}" "${c[end]}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}✎ CSI_GPG_PASSWD" "${c[end]}${bExists_env_gpg_passwd}" "${c[end]}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}✎ CSI_GPG_KEY" "${c[end]}${bExists_env_gpg_key}" "${c[end]}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}✎ CSI_GITHUB_NAME" "${c[end]}${bExists_env_github_name}" "${c[end]}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}✎ CSI_GITHUB_EMAIL" "${c[end]}${bExists_env_github_email}" "${c[end]}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}✎ CSI_TANG_SERVER" "${c[end]}${bExists_env_tang_server}" "${c[end]}"
    echo -e

    # #
    #  Section > Paths
    # #

    echo -e
    echo -e "  ${c[yellow]}${c[bold]}[ Paths - Clevis Mode]${c[end]}"

    local bExists_dir_secrets=$([ ! -d "${app_dir_secrets}" ] && echo "Missing" || echo "${app_dir_secrets}")
    local bExists_file_base=$([ ! -f "${path_file_secret_base}" ] && echo "Missing" || echo "${path_file_secret_base}")
    local bExists_file_sudo_passwd=$([ ! -f "${path_file_secret_sudo_passwd}" ] && echo "Missing" || echo "${path_file_secret_sudo_passwd}")
    local bExists_file_pat_github=$([ ! -f "${path_file_secret_pat_github}" ] && echo "Missing" || echo "${path_file_secret_pat_github}")
    local bExists_file_pat_gitlab=$([ ! -f "${path_file_secret_pat_gitlab}" ] && echo "Missing" || echo "${path_file_secret_pat_gitlab}")
    local bExists_file_gpg_passwd=$([ ! -f "${path_file_secret_gpg_passwd}" ] && echo "Missing" || echo "${path_file_secret_gpg_passwd}")
    local bExists_file_gpg_key=$([ ! -f "${path_file_secret_gpg_key}" ] && echo "Missing" || echo "${path_file_secret_gpg_key}")
    local bExists_file_gh_name=$([ ! -f "${path_file_secret_gh_name}" ] && echo "Missing" || echo "${path_file_secret_name_name}")
    local bExists_file_gh_email=$([ ! -f "${path_file_secret_gh_email}" ] && echo "Missing" || echo "${path_file_secret_name_email}")

    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}📁 ${app_dir_secrets}" "${c[end]}${bExists_dir_secrets}" "${c[grey3]}${secrets_mode}${c[end]}"
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}📄 ${app_file_secret_base}" "${c[end]}${bExists_file_base}${c[end]}" ""
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}📄 ${app_file_secret_sudo_passwd}" "${c[end]}${bExists_file_sudo_passwd}${c[end]}" ""
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}📄 ${app_file_secret_pat_github}" "${c[end]}${bExists_file_pat_github}${c[end]}" ""
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}📄 ${app_file_secret_pat_gitlab}" "${c[end]}${bExists_file_pat_gitlab}${c[end]}" ""
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}📄 ${app_file_secret_gpg_passwd}" "${c[end]}${bExists_file_gpg_passwd}${c[end]}" ""
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}📄 ${app_file_secret_gpg_key}" "${c[end]}${bExists_file_gpg_key}${c[end]}" ""
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}📄 ${app_file_secret_gh_name}" "${c[end]}${bExists_file_gh_name}${c[end]}" ""
    printf "%-5s %-37s %-40s %-40s\n" "" "${c[blue2]}📄 ${app_file_secret_gh_email}" "${c[end]}${bExists_file_gh_email}${c[end]}" ""
    echo -e

    # #
    #  Section > Dependencies 
    # #

    echo -e
    echo -e "  ${c[yellow]}${c[bold]}[ Dependencies ]${c[end]}"

    local bInstalled_aptmove=$([ ! -x "$(command -v apt-move)" ] && echo "Missing" || echo 'Installed')
    local bInstalled_git=$([ ! -x "$(command -v git)" ] && echo "Missing" || echo 'Installed')
    local bInstalled_clevis=$([ ! -x "$(command -v clevis)" ] && echo "Missing" || echo 'Installed')
    local bInstalled_reprepro=$([ ! -x "$(command -v reprepro)" ] && echo "Missing" || echo 'Installed')
    local bInstalled_gpg=$([ ! -x "$(command -v gpg)" ] && echo "Missing" || echo 'Installed')
    local bInstalled_wget=$([ ! -x "$(command -v wget)" ] && echo "Missing" || echo 'Installed')
    local bInstalled_curl=$([ ! -x "$(command -v curl)" ] && echo "Missing" || echo 'Installed')
    local bInstalled_tree=$([ ! -x "$(command -v tree)" ] && echo "Missing" || echo 'Installed')

    printf "%-5s %-38s %-40s\n" "" "${c[blue2]}🗔  apt-move" "${c[end]}${bInstalled_aptmove}${c[end]}"
    printf "%-5s %-38s %-40s\n" "" "${c[blue2]}🗔  git" "${c[end]}${bInstalled_git}${c[end]}"
    printf "%-5s %-38s %-40s\n" "" "${c[blue2]}🗔  clevis" "${c[end]}${bInstalled_clevis}${c[end]}"
    printf "%-5s %-38s %-40s\n" "" "${c[blue2]}🗔  reprepro" "${c[end]}${bInstalled_reprepro}${c[end]}"
    printf "%-5s %-38s %-40s\n" "" "${c[blue2]}🗔  gPG" "${c[end]}${bInstalled_gpg}${c[end]}"
    printf "%-5s %-38s %-40s\n" "" "${c[blue2]}🗔  wget" "${c[end]}${bInstalled_wget}${c[end]}"
    printf "%-5s %-38s %-40s\n" "" "${c[blue2]}🗔  curl" "${c[end]}${bInstalled_curl}${c[end]}"
    printf "%-5s %-38s %-40s\n" "" "${c[blue2]}🗔  tree" "${c[end]}${bInstalled_tree}${c[end]}"

    # #
    #  Section > gpg-agent.conf 
    # #

    echo -e
    echo -e "  ${c[yellow]}${c[bold]}[ gpg-agent.conf ]${c[end]}"

    gpgagent_cfg_file="${HOME}/.gnupg/gpg-agent.conf"
    if [ -f ${gpgagent_cfg_file} ]; then
        sed "s/^/      /" ${gpgagent_cfg_file}
    fi

    # #
    #  Section > Footer
    # #

    echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
    echo -e
    echo -e

    exit 1
}

# #
#   secrets > load
#   
#   this process obtains the secrets needed for this script to continue. 
#   secrets can be obtained through multiple different means outlined below:
#   
#       - Bitwarden CLI             gets your secret's from Bitwarden's CLI website
#       - Clevis & Tang             decrypts secrets from a file into plain-text
#                                       /server/.secrets/CSI_BASE
#                                       /server/.secrets/CSI_SUDO_PASSWD
#                                       /server/.secrets/CSI_GPG_PASSWD
#                                       /server/.secrets/CSI_PAT_GITHUB
#                                       /server/.secrets/CSI_PAT_GITLAB
#                                       /server/.secrets/CSI_GPG_KEY
#                                       /server/.secrets/CSI_GITHUB_NAME
#       - GPG Encrypt Mode          secrets are encrypted using gpg key, and decrypted when needed
#                                       /home/$USER/.CSI_BASE
#                                       /home/$USER/.CSI_SUDO_PASSWD
#                                       /home/$USER/.CSI_GPG_PASSWD
#                                       /home/$USER/.CSI_PAT_GITHUB
#                                       /home/$USER/.CSI_PAT_GITLAB
# #

function load_secrets
{
    set +o history

    app_tang_domain="${CSI_TANG_SERVER}"        # tang server domain

    # #
    #   SECRETS > METHOD > BITWARDEN                            found       bitwarden binary
    #                                                           found       bws token
    # #

    if [ -f "$path_file_bin_bws" ] && [ -n "${BWS_ACCESS_TOKEN}" ]; then
        echo -e "  ${c[green]}OK           ${c[green]}Bitwarden CLI Mode Activated${c[end]}"
        echo -e "  ${c[green]}OK           ${c[end]}Found ${c[green]}\$BWS_ACCESS_TOKEN${c[end]} and ${c[green]}$path_file_bin_bws${c[end]}"

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > BITWARDEN                            not found       CSI_SUDO_PASSWD_ID
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        CSI_SUDO_PASSWD_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_SUDO_PASSWD\").id)[0]")
        if [ -z "${CSI_SUDO_PASSWD_ID}" ] || [ "${CSI_SUDO_PASSWD_ID}" == "null" ]; then
            printf '%-28s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[grey1]}Could not find var ${c[orange]}\$CSI_SUDO_PASSWD_ID${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]} - trying another method"
        elif [ "${argDevEnabled}" = true ]; then
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_SUDO_PASSWD_ID${c[grey1]} with value ${c[navy]}${CSI_SUDO_PASSWD_ID}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
        fi

        # #
        #   SECRETS > METHOD > BITWARDEN                            not found       CSI_SUDO_PASSWD
        # #

        if [ -n "${CSI_SUDO_PASSWD_ID}" ] && [ "${CSI_SUDO_PASSWD_ID}" != "null" ] && [ "${CSI_SUDO_PASSWD_ID}" != null ]; then
            CSI_SUDO_PASSWD=$(bws secret get $CSI_SUDO_PASSWD_ID | jq -r ".value")
            if [ -z "${CSI_SUDO_PASSWD}" ]; then
                printf '%-28s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[grey1]}Could not find var ${c[orange]}\$CSI_SUDO_PASSWD${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]} - trying another method"
            else
                if [ "${argDevEnabled}" = true ]; then
                    printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_SUDO_PASSWD${c[grey1]} with value ${c[navy]}${CSI_SUDO_PASSWD}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
                fi
            fi
        else
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Could not find var ${c[navy]}\$CSI_SUDO_PASSWD${c[grey1]}, because of empty id ${c[navy]}\$CSI_SUDO_PASSWD_ID${c[grey1]} from ${c[navy]}Bitwarden CLI${c[grey1]} - trying another method${c[end]}"
            fi
        fi

        # #
        #   SECRETS > METHOD > BITWARDEN                            elevate sudo CSI_SUDO_PASSWD
        # #

        if [ -n "${CSI_SUDO_PASSWD}" ]; then
            echo "$CSI_SUDO_PASSWD" | echo | sudo -S su
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Elevating script with ${c[navy]}sudo${c[grey1]} using passwd ${c[navy]}${CSI_SUDO_PASSWD}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
            fi
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > BITWARDEN                            not found       CSI_PAT_GITHUB_ID
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        CSI_PAT_GITHUB_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_PAT_GITHUB\").id)[0]")
        if [ -z "${CSI_PAT_GITHUB_ID}" ] || [ "${CSI_PAT_GITHUB_ID}" == "null" ]; then
            printf '%-28s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[grey1]}Could not find var ${c[orange]}\$CSI_PAT_GITHUB_ID${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]} - trying another method"
        elif [ "${argDevEnabled}" = true ]; then
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_PAT_GITHUB_ID${c[grey1]} with value ${c[navy]}${CSI_PAT_GITHUB_ID}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
        fi

        # #
        #   SECRETS > METHOD > BITWARDEN                            not found       CSI_PAT_GITHUB
        # #

        if [ -n "${CSI_PAT_GITHUB_ID}" ] && [ "${CSI_PAT_GITHUB_ID}" != "null" ] && [ "${CSI_PAT_GITHUB_ID}" != null ]; then
            CSI_PAT_GITHUB=$(bws secret get $CSI_PAT_GITHUB_ID | jq -r ".value")
            if [ -z "${CSI_PAT_GITHUB}" ]; then
                printf '%-28s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[grey1]}Could not find var ${c[orange]}\$CSI_PAT_GITHUB${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]} - trying another method"
            else
                export GITHUB_API_TOKEN=${CSI_PAT_GITHUB}
                if [ "${argDevEnabled}" = true ]; then
                    printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_PAT_GITHUB${c[grey1]} with value ${c[navy]}${CSI_PAT_GITHUB}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
                fi
            fi
        else
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Could not find var ${c[navy]}\$CSI_PAT_GITHUB${c[grey1]}, because of empty id ${c[navy]}\$CSI_PAT_GITHUB_ID${c[grey1]} from ${c[navy]}Bitwarden CLI${c[grey1]} - trying another method${c[end]}"
            fi
        fi

        # #
        #   SECRETS > METHOD > BITWARDEN                            not found       CSI_PAT_GITHUB
        #                                                           action          check for Gitlab Token
        # #

        if [ -z "$CSI_PAT_GITHUB" ]; then
            CSI_PAT_GITLAB_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_PAT_GITLAB\").id)[0]")
            if [ -z "${CSI_PAT_GITLAB_ID}" ] || [ "${CSI_PAT_GITLAB_ID}" == "null" ]; then
                printf '%-28s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[grey1]}Could not find var ${c[orange]}\$CSI_PAT_GITLAB_ID${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]} - trying another method"
            elif [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_PAT_GITLAB_ID${c[grey1]} with value ${c[navy]}${CSI_PAT_GITLAB_ID}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
            fi

            # #
            #   SECRETS > METHOD > BITWARDEN                        check           CSI_PAT_GITLAB
            # #

            if [ -n "${CSI_PAT_GITLAB_ID}" ] && [ "${CSI_PAT_GITLAB_ID}" != "null" ] && [ "${CSI_PAT_GITLAB_ID}" != null ]; then
                CSI_PAT_GITLAB=$(bws secret get $CSI_PAT_GITLAB_ID | jq -r ".value")
                if [ -z "${CSI_PAT_GITLAB}" ]; then
                    printf '%-28s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[grey1]}Could not find var ${c[orange]}\$CSI_PAT_GITLAB${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]} - trying another method"
                else
                    export GITLAB_PA_TOKEN=${CSI_PAT_GITLAB}
                    if [ "${argDevEnabled}" = true ]; then
                        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_PAT_GITLAB${c[grey1]} with value ${c[navy]}${CSI_PAT_GITLAB}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
                    fi
                fi
            else
                if [ "${argDevEnabled}" = true ]; then
                    printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Could not find var ${c[navy]}\$CSI_PAT_GITLAB${c[grey1]}, because of empty id ${c[navy]}\$CSI_PAT_GITLAB_ID${c[grey1]} from ${c[navy]}Bitwarden CLI${c[grey1]} - trying another method${c[end]}"
                fi
            fi
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > BITWARDEN                            not found       CSI_GPG_PASSWD_ID
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        CSI_GPG_PASSWD_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_GPG_PASSWD\").id)[0]")
        if [ -z "${CSI_GPG_PASSWD_ID}" ] || [ "${CSI_GPG_PASSWD_ID}" == "null" ]; then
            printf '%-28s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[grey1]}Could not find var ${c[orange]}\$CSI_GPG_PASSWD_ID${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]} - trying another method"
        elif [ "${argDevEnabled}" = true ]; then
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_GPG_PASSWD_ID${c[grey1]} with value ${c[navy]}${CSI_GPG_PASSWD_ID}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
        fi

        # #
        #   SECRETS > METHOD > BITWARDEN                            not found       CSI_GPG_PASSWD
        # #

        if [ -n "${CSI_GPG_PASSWD_ID}" ] && [ "${CSI_GPG_PASSWD_ID}" != "null" ] && [ "${CSI_GPG_PASSWD_ID}" != null ]; then
            CSI_GPG_PASSWD=$(bws secret get $CSI_GPG_PASSWD_ID | jq -r ".value")
            if [ -z "${CSI_GPG_PASSWD}" ]; then
                printf '%-28s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[grey1]}Could not find var ${c[orange]}\$CSI_GPG_PASSWD${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]} - trying another method"
            else
                if [ "${argDevEnabled}" = true ]; then
                    printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_GPG_PASSWD${c[grey1]} with value ${c[navy]}${CSI_GPG_PASSWD}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
                fi
            fi
        else
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Could not find var ${c[navy]}\$CSI_GPG_PASSWD${c[grey1]}, because of empty id ${c[navy]}\$CSI_GPG_PASSWD_ID${c[grey1]} from ${c[navy]}Bitwarden CLI${c[grey1]} - trying another method${c[end]}"
            fi
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > BITWARDEN                            not found       CSI_GPG_KEY_ID
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        CSI_GPG_KEY_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_GPG_KEY\").id)[0]")
        if [ -z "${CSI_GPG_KEY_ID}" ] || [ "${CSI_GPG_KEY_ID}" == "null" ]; then
            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}Could not find var ${c[orange]}\$CSI_GPG_KEY_ID${c[end]} from ${c[orange]}Bitwarden CLI${c[end]} - trying another method"
        elif [ "${argDevEnabled}" = true ]; then
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_GPG_KEY_ID${c[grey1]} with value ${c[navy]}${CSI_GPG_KEY_ID}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
        fi

        # #
        #   SECRETS > METHOD > BITWARDEN                            not found       CSI_GPG_KEY
        # #

        if [ -n "${CSI_GPG_KEY_ID}" ] && [ "${CSI_GPG_KEY_ID}" != "null" ] && [ "${CSI_GPG_KEY_ID}" != null ]; then
            CSI_GPG_KEY=$(bws secret get $CSI_GPG_KEY_ID | jq -r ".value")
            if [ -z "${CSI_GPG_KEY}" ]; then
                printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[orange]}Could not find var ${c[orange]}\$CSI_GPG_KEY${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]} - trying another method"
            else
                if [ "${argDevEnabled}" = true ]; then
                    printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_GPG_KEY${c[grey1]} with value ${c[navy]}${CSI_GPG_KEY}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
                fi
            fi
        else
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Could not find var ${c[navy]}\$CSI_GPG_KEY${c[grey1]}, because of empty id ${c[navy]}\$CSI_GPG_KEY_ID${c[grey1]} from ${c[navy]}Bitwarden CLI${c[grey1]} - trying another method${c[end]}"
            fi
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > BITWARDEN                            not found       CSI_GITHUB_NAME_ID
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        CSI_GITHUB_NAME_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_GITHUB_NAME\").id)[0]")
        if [ -z "${CSI_GITHUB_NAME_ID}" ] || [ "${CSI_GITHUB_NAME_ID}" == "null" ]; then
            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}Could not find var ${c[orange]}\$CSI_GITHUB_NAME_ID${c[end]} from ${c[orange]}Bitwarden CLI${c[end]} - trying another method"
        elif [ "${argDevEnabled}" = true ]; then
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_GITHUB_NAME_ID${c[grey1]} with value ${c[navy]}${CSI_GITHUB_NAME_ID}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
        fi

        # #
        #   SECRETS > METHOD > BITWARDEN                            not found       CSI_GITHUB_NAME
        # #

        if [ -n "${CSI_GITHUB_NAME_ID}" ] && [ "${CSI_GITHUB_NAME_ID}" != "null" ] && [ "${CSI_GITHUB_NAME_ID}" != null ]; then
            CSI_GITHUB_NAME=$(bws secret get $CSI_GITHUB_NAME_ID | jq -r ".value")
            if [ -z "${CSI_GITHUB_NAME}" ]; then
                printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[orange]}Could not find var ${c[orange]}\$CSI_GITHUB_NAME${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]} - trying another method"
            else
                if [ "${argDevEnabled}" = true ]; then
                    printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_GITHUB_NAME${c[grey1]} with value ${c[navy]}${CSI_GITHUB_NAME}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
                fi
            fi
        else
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Could not find var ${c[navy]}\$CSI_GITHUB_NAME${c[grey1]}, because of empty id ${c[navy]}\$CSI_GITHUB_NAME_ID${c[grey1]} from ${c[navy]}Bitwarden CLI${c[grey1]} - trying another method${c[end]}"
            fi
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > BITWARDEN                            not found       CSI_GITHUB_EMAIL_ID
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        CSI_GITHUB_EMAIL_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_GITHUB_EMAIL\").id)[0]")
        if [ -z "${CSI_GITHUB_EMAIL_ID}" ] || [ "${CSI_GITHUB_EMAIL_ID}" == "null" ]; then
            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}Could not find var ${c[orange]}\$CSI_GITHUB_EMAIL_ID${c[end]} from ${c[orange]}Bitwarden CLI${c[end]} - trying another method"
        elif [ "${argDevEnabled}" = true ]; then
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_GITHUB_EMAIL_ID${c[grey1]} with value ${c[navy]}${CSI_GITHUB_EMAIL_ID}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
        fi

        # #
        #   SECRETS > METHOD > BITWARDEN                            not found       CSI_GITHUB_EMAIL
        # #

        if [ -n "${CSI_GITHUB_EMAIL_ID}" ] && [ "${CSI_GITHUB_EMAIL_ID}" != "null" ] && [ "${CSI_GITHUB_EMAIL_ID}" != null ]; then
            CSI_GITHUB_EMAIL=$(bws secret get $CSI_GITHUB_EMAIL_ID | jq -r ".value")
            if [ -z "${CSI_GITHUB_EMAIL}" ]; then
                printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[orange]}Could not find var ${c[orange]}\$CSI_GITHUB_EMAIL${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]} - trying another method"
            else
                if [ "${argDevEnabled}" = true ]; then
                    printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_GITHUB_EMAIL${c[grey1]} with value ${c[navy]}${CSI_GITHUB_EMAIL}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
                fi
            fi
        else
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Could not find var ${c[navy]}\$CSI_GITHUB_EMAIL${c[grey1]}, because of empty id ${c[navy]}\$CSI_GITHUB_EMAIL_ID${c[grey1]} from ${c[navy]}Bitwarden CLI${c[grey1]} - trying another method${c[end]}"
            fi
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > BITWARDEN                            not found       CSI_TANG_SERVER_ID
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        CSI_TANG_SERVER_ID=$(bws secret list | jq -r ". | map(select(.key == \"CSI_TANG_SERVER\").id)[0]")
        if [ -z "${CSI_TANG_SERVER_ID}" ] || [ "${CSI_TANG_SERVER_ID}" == "null" ]; then
            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}Could not find var ${c[orange]}\$CSI_TANG_SERVER_ID${c[end]} from ${c[orange]}Bitwarden CLI${c[end]} - trying another method"
        elif [ "${argDevEnabled}" = true ]; then
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_TANG_SERVER_ID${c[grey1]} with value ${c[navy]}${CSI_TANG_SERVER_ID}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
        fi

        # #
        #   SECRETS > METHOD > BITWARDEN                            not found       CSI_TANG_SERVER
        # #

        if [ -n "${CSI_TANG_SERVER_ID}" ] && [ "${CSI_TANG_SERVER_ID}" != "null" ] && [ "${CSI_TANG_SERVER_ID}" != null ]; then
            CSI_TANG_SERVER=$(bws secret get $CSI_TANG_SERVER_ID | jq -r ".value")
            if [ -z "${CSI_TANG_SERVER}" ]; then
                printf '%-28s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[orange]}Could not find var ${c[orange]}\$CSI_TANG_SERVER${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]} - trying another method"
            else
                if [ "${argDevEnabled}" = true ]; then
                    printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_TANG_SERVER${c[grey1]} with value ${c[navy]}${CSI_TANG_SERVER}${c[grey1]} from ${c[navy]}Bitwarden CLI${c[end]}"
                fi
            fi
        else
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Could not find var ${c[navy]}\$CSI_TANG_SERVER${c[grey1]}, because of empty id ${c[navy]}\$CSI_TANG_SERVER_ID${c[grey1]} from ${c[navy]}Bitwarden CLI${c[grey1]} - trying another method${c[end]}"
            fi
        fi

    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
    #   SECRETS > METHOD > BITWARDEN                                not found       bitwarden binary
    #                                                               found           bitwarden token
    #                                                               action          install lastversion && bws
    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

    elif [ ! -f "$path_file_bin_bws" ] && [ -n "${BWS_ACCESS_TOKEN}" ]; then

        if ! [ -x "$(command -v lastversion)" ]; then
            echo
            echo -e "  ${c[orange]}WARNING      ${c[end]}Missing Bitwarden Secrets CLI & LastVersion${c[end]}"
            echo -e "               Missing Bitwarden Secrets CLI. In order to automatically install the Secrets Manager, this script requires LastVersion,${c[end]}"
            echo -e "               which you do not have.${c[end]}"
            echo -e
            echo -e "               Script will now try other ways of obtaining your secrets${c[end]}"
            echo
        elif [ "${argDevEnabled}" = true ]; then
            echo -e "  ${c[navy]}DEV          ${c[grey2]}Package ${c[grey1]}LastVersion${c[grey2]} already installed${c[end]}"
        fi

        echo -e "  ${c[green]}OK           ${c[end]}Installing Bitwarden Secrets Manager CLI${c[end]}"
        bws_download=$(lastversion "bitwarden/sdk-sm" --assets --having-asset "~bws-x86_64-unknown-linux-gnu-(.+).(.+).(.+).zip")
        bws_filename=$(basename ${bws_download})

        echo -e "  ${c[green]}OK           ${c[end]}Creating folder ${c[fuchsia1]}${path_tmp}${c[end]}"
        mkdir -p "${path_tmp}"

        echo -e "  ${c[green]}OK           ${c[end]}Downloading Bitwarden Secrets Manager CLI from ${c[fuchsia1]}${bws_download}${c[end]}"
        sudo wget -O "${path_tmp}/${bws_filename}" -q "${bws_download}"

        echo -e "  ${c[green]}OK           ${c[end]}Unzipping to current folder ${c[fuchsia1]}${app_dir}${c[end]}"
        unzip "${path_tmp}/${bws_filename}" -d ./           #  unzip to /server/gitea folder

        echo -e "  ${c[green]}OK           ${c[end]}Setting permission u+x on ${c[fuchsia1]}${bws_filename}${c[end]}"
        sudo chmod u+x "${bws_filename}"

        echo -e "  ${c[green]}OK           ${c[end]}Moving ${c[fuchsia1]}${bws_filename}${c[end]} to ${c[fuchsia1]}${path_usr_local_bin}/${bws_filename}${c[end]}"
        sudo cp "${bws_filename}" "${path_usr_local_bin}"   #  move /server/gitea/bws to /usr/local/bin/bws

        if [ "${cfg_Storage_BwsCLI}" = true ] && [ ! -f "${path_usr_local_bin}/${bws_filename}" ]; then
            echo -e "  ${c[green]}OK           ${c[end]}Successfully installed package ${c[fuchsia1]}${path_usr_local_bin}/${bws_filename}${c[end]}"
        fi

        echo -e "  ${c[green]}OK           ${c[end]}Creating symbolic link ${c[fuchsia1]}${path_usr_local_bin}/${bws_filename}${c[end]} to ${c[fuchsia1]}/bin/${bws_filename}${c[end]}"
        sudo ln -s "${path_usr_local_bin}/${bws_filename}" "/bin/${bws_filename}"

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > BITWARDEN                            found           bitwarden binary
        #                                                           found           bitwarden token
        #                                                           action          re-run secrets function
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -f "$path_file_bin_bws" ] && [ -n "${BWS_ACCESS_TOKEN}" ]; then
            load_secrets
        else
            echo
            echo -e "  ${c[orange]}WARNING      ${c[end]}Still Could Not Find Bitwarden Binary of BWS_TOKEN${c[end]}"
            echo -e "               After an attempt to install the Bitwarden Secret's Manager CLI and find the BWS_TOKEN, we still could not.${c[end]}"
            echo -e
            echo -e "               Script will now try other ways of obtaining your secrets${c[end]}"
            echo
        fi

    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
    #   SECRETS > METHOD > BITWARDEN                                found           bws binary
    #                                                               not found       bws token
    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

    elif [ -f "$path_file_bin_bws" ] && [ -z "${BWS_ACCESS_TOKEN}" ]; then
        echo
        echo -e "  ${c[orange]}WARNING      ${c[end]}Found Bitwarden CLI but missing env var \$BWS_ACCESS_TOKEN${c[end]}"
        echo -e "               The Bitwarden CLI binary was found, but you are missing the \$BWS_ACCESS_TOKEN:${c[end]}"
        echo -e "                    ${c[grey2]}${c[green]}BWS_ACCESS_TOKEN=${c[end]}0.cdf2c081-XXXX-XX-XXXX-b1d10066acb7.sabZWAV0xIEnLYsdvgUpuXXXXXXXXX:XXXX/XXXXXXXXXXXXXXXXX==${c[end]}"
        echo -e
        echo -e "               Script will now try other ways of obtaining your secrets${c[end]}"
        echo
    fi

    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
    #   SECRETS > METHOD > CLEVIS                               clevis not found AND ( GPG pass or Sudo pass missing )
    #                                                           install clevis and proceed
    #   
    #                                                           Bitwarden Secrets Manager CLI failed to locate secrets.
    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

    if [ ! -x "$(command -v clevis)" ] && ([ -z "${CSI_GPG_PASSWD}" ] || [ -z "${CSI_SUDO_PASSWD}" ]); then
        echo
        echo -e "  ${c[orange]}WARNING      ${c[end]}Could not find needed env variables using Bitwarden Secrets Manager CLI${c[end]}"
        echo -e "               Script will now attempt to use Clevis to find encrypted files in the folder:${c[end]}"
        echo -e "                    ${c[grey2]}${app_dir_secrets}${c[end]}"
        echo

        echo -e "  ${c[green]}OK           ${c[end]}Installing package ${c[blue2]}Clevis${c[end]}"
        sudo apt-get update -y -q >/dev/null 2>&1
        sudo apt --fix-broken install >/dev/null 2>&1
        sudo apt-get install clevis clevis-udisks2 clevis-tpm2 -y -qq >/dev/null 2>&1
    fi

    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
    #   SECRETS > METHOD > CLEVIS                                   found           clevis 
    #                                                               missing         GPG pass or Sudo pass
    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
#
    if [ -x "$(command -v clevis)" ] && ([ -z "${CSI_SUDO_PASSWD}" ] || [ -z "${CSI_PAT_GITHUB}" ] || [ -z "${CSI_GPG_PASSWD}" ] || [ -z "${CSI_GPG_KEY}" ] || [ -z "${CSI_GITHUB_NAME}" ] || [ -z "${CSI_GITHUB_EMAIL}" ] || [ -z "${CSI_TANG_SERVER}" ]); then
        echo -e "  ${c[green]}OK           ${c[green]}Clevis Mode Activated${c[end]}"

        [ -z "${CSI_SUDO_PASSWD}" ] && [ "${argDevEnabled}" = true ] && printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Miss ${c[navy]}\$CSI_SUDO_PASSWD${c[end]}"
        [ -z "${CSI_PAT_GITHUB}" ] && [ "${argDevEnabled}" = true ] && printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Miss ${c[navy]}\$CSI_PAT_GITHUB${c[end]}"
        [ -z "${CSI_GPG_PASSWD}" ] && [ "${argDevEnabled}" = true ] && printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Miss ${c[navy]}\$CSI_GPG_PASSWD${c[end]}"
        [ -z "${CSI_GPG_KEY}" ] && [ "${argDevEnabled}" = true ] && printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Miss ${c[navy]}\$CSI_GPG_KEY${c[end]}"
        [ -z "${CSI_GITHUB_NAME}" ] && [ "${argDevEnabled}" = true ] && printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Miss ${c[navy]}\$CSI_GITHUB_NAME${c[end]}"
        [ -z "${CSI_GITHUB_EMAIL}" ] && [ "${argDevEnabled}" = true ] && printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Miss ${c[navy]}\$CSI_GITHUB_EMAIL${c[end]}"
        [ -z "${CSI_TANG_SERVER}" ] && [ "${argDevEnabled}" = true ] && printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Miss ${c[navy]}\$CSI_TANG_SERVER${c[end]}"

        tang_status=`curl -Is "${app_tang_domain}" | tac | grep -o "^HTTP.*" | cut -f 2 -d' ' | head -1`
        if [ "$tang_status" == "307" ]; then
            echo
            echo -e "  ${c[orange]}WARNING      ${c[end]}Could Not Communicate With Tang Server${c[end]}"
            echo -e "               Tang server returned a redirect. Tang server may not be online.${c[end]}"
            echo -e "                    ${c[grey2]}${app_tang_domain}${c[end]}"
            echo

            skip_clevis=true
        fi

        # #
        #   Clevis could not get secrets; try another method
        #   if clevis was detected, proceed
        # #

        if [ "$skip_clevis" = false ]; then

            # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
            #   SECRETS > METHOD > CLEVIS                               no folder /server/.secrets/
            # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

            if [ ! -d "${app_dir_secrets}" ]; then

                echo
                echo -e "  ${c[orange]}WARNING      ${c[end]}Could not find ${c[fuchsia1]}${app_dir_secrets} - Creating new secrets folder${c[end]}"
                echo -e "               Additional files will be created which you must open and add your Clevis encrypted secrets to.${c[end]}"
                echo -e "               Relaunch Gitea Backup when you are finished.${c[end]}"
                echo

                mkdir -p "${app_dir_secrets}"
                touch "${path_file_secret_base}"
                touch "${path_file_secret_sudo_passwd}"
                touch "${path_file_secret_pat_github}"
                touch "${path_file_secret_pat_gitlab}"
                touch "${path_file_secret_gpg_passwd}"
                touch "${path_file_secret_gpg_key}"
                touch "${path_file_secret_gh_name}"
                touch "${path_file_secret_gh_email}"
                touch "${path_file_secret_tang_server}"

                printf "  Press any key to abort ... ${c[end]}"
                read -n 1 -s -r -p ""
                echo
                echo

                set +m
                trap "kill -9 ${app_pid} 2> /dev/null" `seq 0 15`
                kill ${app_pid}
                set -m

            # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
            #   SECRETS > METHOD > CLEVIS                               found folder /server/.secrets/
            # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

            else
                echo -e "  ${c[green]}OK           ${c[end]}Found folder ${c[green]}${app_dir_secrets}${c[end]}"

                # #
                #   SECRETS > METHOD > CLEVIS
                #   
                #       loads clevis secret strings from files:
                #           /server/.secrets/CSI_BASE
                #           /server/.secrets/CSI_SUDO_PASSWD
                #           /server/.secrets/CSI_PAT_GITHUB
                #           /server/.secrets/CSI_PAT_GITLAB
                #           /server/.secrets/CSI_GPG_PASSWD
                #           /server/.secrets/CSI_GPG_KEY
                #           /server/.secrets/CSI_GITHUB_NAME
                #           /server/.secrets/CSI_GITHUB_EMAIL
                #           /server/.secrets/CSI_TANG_SERVER
                #   
                #       the contents of the files should be encrypted using Clevis, either tpm or a tang server.
                #   
                #       clevis encrypt tang '{"url": "https://tang1.domain.lan"}' <<< 'github_pat_XXXXXX' > /server/.secrets/CSI_PAT_GITHUB
                #       clevis decrypt < /server/.secrets/CSI_PAT_GITHUB
                # #

                bMissingSecret=false

                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
                #   SECRETS > METHOD > CLEVIS                               found file /server/.secrets/CSI_SUDO_PASSWD
                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

                if [ -z "${CSI_SUDO_PASSWD}" ] || [ "${CSI_SUDO_PASSWD}" == "null" ] || [ "${CSI_SUDO_PASSWD}" == null ]; then
                    if [ -f ${path_file_secret_sudo_passwd} ]; then
                        CSI_SUDO_PASSWD=$(cat ${path_file_secret_sudo_passwd} | clevis decrypt 2>/dev/null)

                        # #
                        #   SECRETS > METHOD > CLEVIS                           valid var CSI_SUDO_PASSWD
                        # #

                        if [ -n "${CSI_SUDO_PASSWD}" ]; then
                            if [ "${argDevEnabled}" = true ]; then
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_SUDO_PASSWD${c[end]} with value ${c[green]}${CSI_SUDO_PASSWD}${c[end]} from ${c[green]}Clevis${c[end]}"
                            else
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_SUDO_PASSWD${c[end]} with value  ${c[green]}***********${CSI_SUDO_PASSWD:(-8)}${c[end]} from ${c[green]}Clevis${c[end]}"
                            fi
                            
                            echo "$CSI_SUDO_PASSWD" | sudo -S su 2> /dev/null
                            if [ "${argDevEnabled}" = true ]; then
                                echo -e "  ${c[navy]}DEV          ${c[grey2]}Elevating script with ${c[grey1]}SUDO${c[grey2]} using passwd ${c[grey1]}${CSI_SUDO_PASSWD}${c[end]}"
                            fi
                        else
                            # #
                            #   SECRETS > METHOD > CLEVIS                       empty var CSI_SUDO_PASSWD
                            # #

                            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_SUDO_PASSWD${c[end]} not declared in ${c[orange]}${path_file_secret_sudo_passwd}${c[end]}"
                            bMissingSecret=true
                        fi
                    else
                        # #
                        #   SECRETS > METHOD > CLEVIS                           missing file /server/.secrets/CSI_SUDO_PASSWD
                        # #

                        echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${path_file_secret_sudo_passwd}${c[end]}"
                        mkdir -p "${app_dir_secrets}"
                        touch "${path_file_secret_sudo_passwd}"
                    fi
                else
                    if [ "${argDevEnabled}" = true ]; then
                        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_SUDO_PASSWD${c[end]}"
                    fi
                fi

                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
                #   SECRETS > METHOD > CLEVIS                               found file /server/.secrets/CSI_PAT_GITHUB
                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

                if [ -z "${CSI_PAT_GITHUB}" ] || [ "${CSI_PAT_GITHUB}" == "null" ] || [ "${CSI_PAT_GITHUB}" == null ]; then
                    if [ -f ${path_file_secret_pat_github} ]; then
                        CSI_PAT_GITHUB=$(cat ${path_file_secret_pat_github} | clevis decrypt 2>/dev/null)

                        # #
                        #   SECRETS > METHOD > CLEVIS                           valid var CSI_PAT_GITHUB
                        # #

                        if [ -n "${CSI_PAT_GITHUB}" ]; then
                            if [ "${argDevEnabled}" = true ]; then
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_PAT_GITHUB${c[end]} with value ${c[green]}${CSI_PAT_GITHUB}${c[end]} from ${c[green]}Clevis${c[end]}"
                            else
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_PAT_GITHUB${c[end]} with value  ${c[green]}***********${CSI_PAT_GITHUB:(-8)}${c[end]} from ${c[green]}Clevis${c[end]}"
                            fi

                            export GITHUB_API_TOKEN=${CSI_PAT_GITHUB}
                        else
                            # #
                            #   SECRETS > METHOD > CLEVIS                       empty var CSI_PAT_GITHUB
                            # #

                            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_PAT_GITHUB${c[end]} not declared in ${c[orange]}${path_file_secret_pat_github}${c[end]}"
                            bMissingSecret=true
                        fi
                    else
                        # #
                        #   SECRETS > METHOD > CLEVIS                           missing file /server/.secrets/CSI_PAT_GITHUB
                        # #

                        echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${path_file_secret_pat_github}${c[end]}"
                        mkdir -p "${app_dir_secrets}"
                        touch "${path_file_secret_pat_github}"
                    fi
                else
                    if [ "${argDevEnabled}" = true ]; then
                        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_PAT_GITHUB${c[end]}"
                    fi
                fi

                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
                #   SECRETS > METHOD > CLEVIS                               found file /server/.secrets/CSI_PAT_GITLAB
                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

                if [ -z "${CSI_PAT_GITLAB}" ] || [ "${CSI_PAT_GITLAB}" == "null" ] || [ "${CSI_PAT_GITLAB}" == null ]; then
                    if [ -f ${path_file_secret_pat_gitlab} ]; then
                        echo -e "  ${c[green]}OK           ${c[end]}Found file ${c[blue2]}${path_file_secret_pat_gitlab}${c[end]}"
                        CSI_PAT_GITLAB=$(cat ${path_file_secret_pat_gitlab} | clevis decrypt 2>/dev/null)

                        # #
                        #   SECRETS > METHOD > CLEVIS                           valid var CSI_PAT_GITLAB
                        # #

                        if [ -n "${CSI_PAT_GITLAB}" ]; then
                            if [ "${argDevEnabled}" = true ]; then
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_PAT_GITLAB${c[end]} with value ${c[green]}${CSI_PAT_GITLAB}${c[end]} from ${c[green]}Clevis${c[end]}"
                            else
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_PAT_GITLAB${c[end]} with value  ${c[green]}***********${CSI_PAT_GITLAB:(-8)}${c[end]} from ${c[green]}Clevis${c[end]}"
                            fi

                            export GITLAB_PA_TOKEN=${CSI_PAT_GITLAB}
                        else
                            # #
                            #   SECRETS > METHOD > CLEVIS                       empty var CSI_PAT_GITLAB
                            # #

                            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_PAT_GITLAB${c[end]} not declared in ${c[orange]}${path_file_secret_pat_gitlab}${c[end]}"

                            # #
                            #   Only mark the Gitlab one as missing and show the error if they also havent specified one for Github.
                            # #

                            if [ -z "${CSI_PAT_GITHUB}" ] || [ "${CSI_PAT_GITHUB}" == "!" ]; then
                                bMissingSecret=true
                            fi
                        fi
                    else
                        # #
                        #   SECRETS > METHOD > CLEVIS                           missing file /server/.secrets/CSI_PAT_GITLAB
                        # #

                        echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${path_file_secret_pat_gitlab}${c[end]}"
                        mkdir -p "${app_dir_secrets}"
                        touch "${path_file_secret_pat_gitlab}"
                    fi
                else
                    if [ "${argDevEnabled}" = true ]; then
                        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_PAT_GITLAB${c[end]}"
                    fi
                fi

                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
                #   SECRETS > METHOD > CLEVIS                               found file /server/.secrets/CSI_GPG_PASSWD
                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

                if [ -z "${CSI_GPG_PASSWD}" ] || [ "${CSI_GPG_PASSWD}" == "null" ] || [ "${CSI_GPG_PASSWD}" == null ]; then
                    if [ -f ${path_file_secret_gpg_passwd} ]; then
                        CSI_GPG_PASSWD=$(cat ${path_file_secret_gpg_passwd} | clevis decrypt 2>/dev/null)

                        # #
                        #   SECRETS > METHOD > CLEVIS                           valid var CSI_GPG_PASSWD
                        # #

                        if [ -n "${CSI_GPG_PASSWD}" ]; then
                            if [ "${argDevEnabled}" = true ]; then
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GPG_PASSWD${c[end]} with value ${c[green]}${CSI_GPG_PASSWD}${c[end]} from ${c[green]}Clevis${c[end]}"
                            else
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GPG_PASSWD${c[end]} with value  ${c[green]}***********${CSI_GPG_PASSWD:(-8)}${c[end]} from ${c[green]}Clevis${c[end]}"
                            fi

                            echo "${CSI_GPG_PASSWD}" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 --output /dev/null --sign >> /dev/null 2>&1
                        else
                            # #
                            #   SECRETS > METHOD > CLEVIS                       empty var CSI_GPG_PASSWD
                            # #

                            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GPG_PASSWD${c[end]} not declared in ${c[orange]}${path_file_secret_gpg_passwd}${c[end]}"
                            bMissingSecret=true
                        fi
                    else
                        # #
                        #   SECRETS > METHOD > CLEVIS                           missing file /server/.secrets/CSI_GPG_PASSWD
                        # #

                        echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${path_file_secret_gpg_passwd}${c[end]}"
                        mkdir -p "${app_dir_secrets}"
                        touch "${path_file_secret_gpg_passwd}"
                    fi
                else
                    if [ "${argDevEnabled}" = true ]; then
                        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_GPG_PASSWD${c[end]}"
                    fi
                fi

                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
                #   SECRETS > METHOD > CLEVIS                               found file /server/.secrets/CSI_GPG_KEY
                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

                if [ -z "${CSI_GPG_KEY}" ] || [ "${CSI_GPG_KEY}" == "null" ] || [ "${CSI_GPG_KEY}" == null ]; then
                    if [ -f ${path_file_secret_gpg_key} ]; then
                        CSI_GPG_KEY=$(cat ${path_file_secret_gpg_key} | clevis decrypt 2>/dev/null)

                        # #
                        #   SECRETS > METHOD > CLEVIS                           valid var CSI_GPG_KEY
                        # #

                        if [ -n "${CSI_GPG_KEY}" ]; then
                            if [ "${argDevEnabled}" = true ]; then
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GPG_KEY${c[end]} with value ${c[green]}${CSI_GPG_KEY}${c[end]} from ${c[green]}Clevis${c[end]}"
                            else
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GPG_KEY${c[end]} with value  ${c[green]}***********${CSI_GPG_KEY:(-8)}${c[end]} from ${c[green]}Clevis${c[end]}"
                            fi

                            echo "${CSI_GPG_KEY}" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 --output /dev/null --sign >> /dev/null 2>&1
                        else
                            # #
                            #   SECRETS > METHOD > CLEVIS                       empty var CSI_GPG_KEY
                            # #

                            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GPG_KEY${c[end]} not declared in ${c[orange]}${path_file_secret_gpg_key}${c[end]}"
                            bMissingSecret=true
                        fi
                    else
                        # #
                        #   SECRETS > METHOD > CLEVIS                           missing file /server/.secrets/CSI_GPG_KEY
                        # #

                        echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${path_file_secret_gpg_key}${c[end]}"
                        mkdir -p "${app_dir_secrets}"
                        touch "${path_file_secret_gpg_key}"
                    fi
                else
                    if [ "${argDevEnabled}" = true ]; then
                        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_GPG_KEY${c[end]}"
                    fi
                fi

                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
                #   SECRETS > METHOD > CLEVIS                               found file /server/.secrets/CSI_GITHUB_NAME
                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

                if [ -z "${CSI_GITHUB_NAME}" ] || [ "${CSI_GITHUB_NAME}" == "null" ] || [ "${CSI_GITHUB_NAME}" == null ]; then
                    if [ -f ${path_file_secret_gh_name} ]; then
                        CSI_GITHUB_NAME=$(cat ${path_file_secret_gh_name} | clevis decrypt 2>/dev/null)

                        # #
                        #   SECRETS > METHOD > CLEVIS                           valid var CSI_GITHUB_NAME
                        # #

                        if [ -n "${CSI_GITHUB_NAME}" ]; then
                            if [ "${argDevEnabled}" = true ]; then
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GITHUB_NAME${c[end]} with value ${c[green]}${CSI_GITHUB_NAME}${c[end]} from ${c[green]}Clevis${c[end]}"
                            else
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GITHUB_NAME${c[end]} with value  ${c[green]}***********${CSI_GITHUB_NAME:(-8)}${c[end]} from ${c[green]}Clevis${c[end]}"
                            fi

                            echo "${CSI_GITHUB_NAME}" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 --output /dev/null --sign >> /dev/null 2>&1
                        else
                            # #
                            #   SECRETS > METHOD > CLEVIS                       empty var CSI_GITHUB_NAME
                            # #

                            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GITHUB_NAME${c[end]} not declared in ${c[orange]}${path_file_secret_gh_name}${c[end]}"
                            bMissingSecret=true
                        fi
                    else
                        # #
                        #   SECRETS > METHOD > CLEVIS                           missing file /server/.secrets/CSI_GITHUB_NAME
                        # #

                        echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${path_file_secret_gh_name}${c[end]}"
                        mkdir -p "${app_dir_secrets}"
                        touch "${path_file_secret_gh_name}"
                    fi
                else
                    if [ "${argDevEnabled}" = true ]; then
                        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_GITHUB_NAME${c[end]}"
                    fi
                fi

                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
                #   SECRETS > METHOD > CLEVIS                               found file /server/.secrets/CSI_GITHUB_EMAIL
                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

                if [ -z "${CSI_GITHUB_EMAIL}" ] || [ "${CSI_GITHUB_EMAIL}" == "null" ] || [ "${CSI_GITHUB_EMAIL}" == null ]; then
                    if [ -f ${path_file_secret_gh_email} ]; then
                        CSI_GITHUB_EMAIL=$(cat ${path_file_secret_gh_email} | clevis decrypt 2>/dev/null)

                        # #
                        #   SECRETS > METHOD > CLEVIS                           valid var CSI_GITHUB_EMAIL
                        # #

                        if [ -n "${CSI_GITHUB_EMAIL}" ]; then
                            if [ "${argDevEnabled}" = true ]; then
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GITHUB_EMAIL${c[end]} with value ${c[green]}${CSI_GITHUB_EMAIL}${c[end]} from ${c[green]}Clevis${c[end]}"
                            else
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GITHUB_EMAIL${c[end]} with value  ${c[green]}***********${CSI_GITHUB_EMAIL:(-8)}${c[end]} from ${c[green]}Clevis${c[end]}"
                            fi

                            echo "${CSI_GITHUB_EMAIL}" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 --output /dev/null --sign >> /dev/null 2>&1
                        else
                            # #
                            #   SECRETS > METHOD > CLEVIS                       empty var CSI_GITHUB_EMAIL
                            # #

                            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GITHUB_EMAIL${c[end]} not declared in ${c[orange]}${path_file_secret_gh_email}${c[end]}"
                            bMissingSecret=true
                        fi
                    else
                        # #
                        #   SECRETS > METHOD > CLEVIS                           missing file /server/.secrets/CSI_GITHUB_EMAIL
                        # #

                        echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${path_file_secret_gh_email}${c[end]}"
                        mkdir -p "${app_dir_secrets}"
                        touch "${path_file_secret_gh_email}"
                    fi
                else
                    if [ "${argDevEnabled}" = true ]; then
                        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_GITHUB_EMAIL${c[end]}"
                    fi
                fi

                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
                #   SECRETS > METHOD > CLEVIS                               found file /server/.secrets/CSI_TANG_SERVER
                # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

                if [ -z "${CSI_TANG_SERVER}" ] || [ "${CSI_TANG_SERVER}" == "null" ] || [ "${CSI_TANG_SERVER}" == null ]; then
                    if [ -f ${path_file_secret_tang_server} ]; then
                        CSI_TANG_SERVER=$(cat ${path_file_secret_gh_email} | clevis decrypt 2>/dev/null)

                        # #
                        #   SECRETS > METHOD > CLEVIS                           valid var CSI_TANG_SERVER
                        # #

                        if [ -n "${CSI_TANG_SERVER}" ]; then
                            if [ "${argDevEnabled}" = true ]; then
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_TANG_SERVER${c[end]} with value ${c[green]}${CSI_TANG_SERVER}${c[end]} from ${c[green]}Clevis${c[end]}"
                            else
                                echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_TANG_SERVER${c[end]} with value  ${c[green]}***********${CSI_TANG_SERVER:(-8)}${c[end]} from ${c[green]}Clevis${c[end]}"
                            fi

                            echo "${CSI_TANG_SERVER}" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 --output /dev/null --sign >> /dev/null 2>&1
                        else
                            # #
                            #   SECRETS > METHOD > CLEVIS                       empty var CSI_TANG_SERVER
                            # #

                            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_TANG_SERVER${c[end]} not declared in ${c[orange]}${path_file_secret_tang_server}${c[end]}"
                            bMissingSecret=true
                        fi
                    else
                        # #
                        #   SECRETS > METHOD > CLEVIS                           missing file /server/.secrets/CSI_TANG_SERVER
                        # #

                        echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${path_file_secret_tang_server}${c[end]}"
                        mkdir -p "${app_dir_secrets}"
                        touch "${path_file_secret_tang_server}"
                    fi
                else
                    if [ "${argDevEnabled}" = true ]; then
                        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_TANG_SERVER${c[end]}"
                    fi
                fi


                #  where bMissingSecret and skip_clevis
            fi
        fi
    else
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > CLEVIS                               Clevis could not get secrets; try another method
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        if [ "${argDevEnabled}" = true ]; then
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Skip ${c[navy]}Clevis Mode${c[grey1]}, already have ${c[navy]}\$CSI_SUDO_PASSWD${c[grey1]} and ${c[navy]}\$CSI_GPG_PASSWD${c[end]}"
        fi
    fi

    # #
    #   SECRETS > METHOD > GPG Encrypted
    #   
    #   See if an encrypted file is in /home/username/ folder.
    #   Looking for any of the files:
    #       ~/.CSI_SUDO_PASSWD
    #       ~/.CSI_GPG_PASSWD
    #       ~/.CSI_PAT_GITHUB
    #       ~/.CSI_PAT_GITLAB
    # #

    if ([ -z "${CSI_SUDO_PASSWD}" ] || [ -z "${CSI_PAT_GITHUB}" ] || [ -z "${CSI_GPG_PASSWD}" ] || [ -z "${CSI_GPG_KEY}" ] || [ -z "${CSI_GITHUB_NAME}" ] || [ -z "${CSI_GITHUB_EMAIL}" ] || [ -z "${CSI_TANG_SERVER}" ]); then
        echo -e "  ${c[green]}OK           ${c[green]}GPG Encrypted Mode Activated${c[end]}"

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > GPG ENCRYPTED                            empty var CSI_SUDO_PASSWD
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_SUDO_PASSWD}" ] || [ "${CSI_SUDO_PASSWD}" == "null" ] || [ "${CSI_SUDO_PASSWD}" == null ]; then
            if [ -f "${HOME}/.${app_file_secret_sudo_passwd}" ]; then
                CSI_SUDO_PASSWD=$(gpg --decrypt "${HOME}/.${app_file_secret_sudo_passwd}" 2>/dev/null)

                # #
                #   SECRETS > METHOD > GPG                              valid var CSI_SUDO_PASSWD
                # #

                if [ -n "${CSI_SUDO_PASSWD}" ]; then
                    if [ "${argDevEnabled}" = true ]; then
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_SUDO_PASSWD${c[end]} with value ${c[green]}${CSI_SUDO_PASSWD}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    else
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_SUDO_PASSWD${c[end]} with value  ${c[green]}***********${CSI_SUDO_PASSWD:(-8)}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    fi

                    echo "$CSI_SUDO_PASSWD" | sudo -S su 2> /dev/null
                    if [ "${argDevEnabled}" = true ]; then
                        echo -e "  ${c[navy]}DEV          ${c[grey2]}Elevating script with ${c[grey1]}SUDO${c[grey2]} using passwd ${c[grey1]}${CSI_SUDO_PASSWD}${c[end]}"
                    fi
                else
                    # #
                    #   SECRETS > METHOD > GPG                          empty var CSI_SUDO_PASSWD
                    # #

                    printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_SUDO_PASSWD${c[end]} not declared in ${c[orange]}${app_file_secret_sudo_passwd}${c[end]}"
                fi
            else
                # #
                #   SECRETS > METHOD > GPG                              missing file /home/user/.CSI_SUDO_PASSWD
                # #

                echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${HOME}/.${app_file_secret_sudo_passwd}${c[end]}"
            fi
        else
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_SUDO_PASSWD${c[end]}"
            fi
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > GPG ENCRYPTED                            empty var CSI_PAT_GITHUB
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_PAT_GITHUB}" ] || [ "${CSI_PAT_GITHUB}" == "null" ] || [ "${CSI_PAT_GITHUB}" == null ]; then
            if [ -f "${HOME}/.${app_file_secret_pat_github}" ]; then
                CSI_PAT_GITHUB=$(gpg --decrypt "${HOME}/.${app_file_secret_pat_github}" 2>/dev/null)

                # #
                #   SECRETS > METHOD > GPG                              valid var CSI_PAT_GITHUB
                # #

                if [ -n "${CSI_PAT_GITHUB}" ]; then
                    if [ "${argDevEnabled}" = true ]; then
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_PAT_GITHUB${c[end]} with value ${c[green]}${CSI_PAT_GITHUB}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    else
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_PAT_GITHUB${c[end]} with value  ${c[green]}***********${CSI_PAT_GITHUB:(-8)}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    fi

                    export GITHUB_API_TOKEN=${CSI_PAT_GITHUB}
                else
                    # #
                    #   SECRETS > METHOD > GPG                          empty var CSI_PAT_GITHUB
                    # #

                    printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_PAT_GITHUB${c[end]} not declared in ${c[orange]}${app_file_secret_pat_github}${c[end]}"
                fi
            else
                # #
                #   SECRETS > METHOD > GPG                              missing file /home/user/.CSI_PAT_GITHUB
                # #

                echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${HOME}/.${app_file_secret_pat_github}${c[end]}"
            fi
        else
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_PAT_GITHUB${c[end]}"
            fi
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > GPG ENCRYPTED                            empty var CSI_PAT_GITLAB
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_PAT_GITLAB}" ] || [ "${CSI_PAT_GITLAB}" == "null" ] || [ "${CSI_PAT_GITLAB}" == null ]; then
            if [ -f "${HOME}/.${app_file_secret_pat_gitlab}" ]; then
                CSI_PAT_GITLAB=$(gpg --decrypt "${HOME}/.${app_file_secret_pat_gitlab}" 2>/dev/null)

                # #
                #   SECRETS > METHOD > GPG                              valid var CSI_PAT_GITLAB
                # #

                if [ -n "${CSI_PAT_GITLAB}" ]; then
                    if [ "${argDevEnabled}" = true ]; then
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_PAT_GITLAB${c[end]} with value ${c[green]}${CSI_PAT_GITLAB}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    else
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_PAT_GITLAB${c[end]} with value  ${c[green]}***********${CSI_PAT_GITLAB:(-8)}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    fi

                    export GITLAB_PA_TOKEN=${CSI_PAT_GITLAB}
                else
                    # #
                    #   SECRETS > METHOD > GPG                          empty var CSI_PAT_GITLAB
                    # #

                    printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_PAT_GITLAB${c[end]} not declared in ${c[orange]}${app_file_secret_pat_gitlab}${c[end]}"
                fi
            else
                # #
                #   SECRETS > METHOD > GPG                              missing file /home/user/.CSI_PAT_GITLAB
                # #

                echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${HOME}/.${app_file_secret_pat_gitlab}${c[end]}"
            fi
        else
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_PAT_GITLAB${c[end]}"
            fi
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > GPG ENCRYPTED                            empty var CSI_GPG_PASSWD
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_GPG_PASSWD}" ] || [ "${CSI_GPG_PASSWD}" == "null" ] || [ "${CSI_GPG_PASSWD}" == null ]; then
            if [ -f "${HOME}/.${app_file_secret_gpg_passwd}" ]; then
                CSI_GPG_PASSWD=$(gpg --decrypt "${HOME}/.${app_file_secret_gpg_passwd}" 2>/dev/null)

                # #
                #   SECRETS > METHOD > GPG                              valid var CSI_GPG_PASSWD
                # #

                if [ -n "${CSI_GPG_PASSWD}" ]; then
                    if [ "${argDevEnabled}" = true ]; then
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GPG_PASSWD${c[end]} with value ${c[green]}${CSI_GPG_PASSWD}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    else
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GPG_PASSWD${c[end]} with value  ${c[green]}***********${CSI_GPG_PASSWD:(-8)}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    fi

                else
                    # #
                    #   SECRETS > METHOD > GPG                          empty var CSI_GPG_PASSWD
                    # #

                    printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GPG_PASSWD${c[end]} not declared in ${c[orange]}${app_file_secret_gpg_passwd}${c[end]}"
                fi
            else
                # #
                #   SECRETS > METHOD > GPG                              missing file /home/user/.CSI_GPG_PASSWD
                # #

                echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${HOME}/.${app_file_secret_gpg_passwd}${c[end]}"
            fi
        else
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_GPG_PASSWD${c[end]}"
            fi
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > GPG ENCRYPTED                            empty var CSI_GPG_KEY
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_GPG_KEY}" ] || [ "${CSI_GPG_KEY}" == "null" ] || [ "${CSI_GPG_KEY}" == null ]; then
            if [ -f "${HOME}/.${app_file_secret_gpg_key}" ]; then
                CSI_GPG_KEY=$(gpg --decrypt "${HOME}/.${app_file_secret_gpg_key}" 2>/dev/null)

                # #
                #   SECRETS > METHOD > GPG                              valid var CSI_GPG_KEY
                # #

                if [ -n "${CSI_GPG_KEY}" ]; then
                    if [ "${argDevEnabled}" = true ]; then
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GPG_KEY${c[end]} with value ${c[green]}${CSI_GPG_KEY}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    else
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GPG_KEY${c[end]} with value  ${c[green]}***********${CSI_GPG_KEY:(-8)}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    fi

                else
                    # #
                    #   SECRETS > METHOD > GPG                          empty var CSI_GPG_KEY
                    # #

                    printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GPG_KEY${c[end]} not declared in ${c[orange]}${app_file_secret_gpg_key}${c[end]}"
                fi
            else
                # #
                #   SECRETS > METHOD > GPG                              missing file /home/user/.CSI_GPG_KEY
                # #

                echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${HOME}/.${app_file_secret_gpg_key}${c[end]}"
            fi
        else
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_GPG_KEY${c[end]}"
            fi
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > GPG ENCRYPTED                            empty var CSI_GITHUB_NAME
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_GITHUB_NAME}" ] || [ "${CSI_GITHUB_NAME}" == "null" ] || [ "${CSI_GITHUB_NAME}" == null ]; then
            if [ -f "${HOME}/.${app_file_secret_gh_name}" ]; then
                CSI_GITHUB_NAME=$(gpg --decrypt "${HOME}/.${app_file_secret_gh_name}" 2>/dev/null)

                # #
                #   SECRETS > METHOD > GPG                              valid var CSI_GITHUB_NAME
                # #

                if [ -n "${CSI_GITHUB_NAME}" ]; then
                    if [ "${argDevEnabled}" = true ]; then
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GITHUB_NAME${c[end]} with value ${c[green]}${CSI_GITHUB_NAME}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    else
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GITHUB_NAME${c[end]} with value  ${c[green]}***********${CSI_GITHUB_NAME:(-8)}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    fi

                else
                    # #
                    #   SECRETS > METHOD > GPG                          empty var CSI_GITHUB_NAME
                    # #

                    printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GITHUB_NAME${c[end]} not declared in ${c[orange]}${HOME}/.${app_file_secret_gh_name}${c[end]}"
                fi
            else
                # #
                #   SECRETS > METHOD > GPG                              missing file /home/user/.CSI_GITHUB_NAME
                # #

                echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${HOME}/.${app_file_secret_gh_name}${c[end]}"
            fi
        else
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_GITHUB_NAME${c[end]}"
            fi
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > GPG ENCRYPTED                            empty var CSI_GITHUB_EMAIL
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_GITHUB_EMAIL}" ] || [ "${CSI_GITHUB_EMAIL}" == "null" ] || [ "${CSI_GITHUB_EMAIL}" == null ]; then
            if [ -f "${HOME}/.${app_file_secret_gh_email}" ]; then
                CSI_GITHUB_EMAIL=$(gpg --decrypt "${HOME}/.${app_file_secret_gh_email}" 2>/dev/null)

                # #
                #   SECRETS > METHOD > GPG                              valid var CSI_GITHUB_EMAIL
                # #

                if [ -n "${CSI_GITHUB_EMAIL}" ]; then
                    if [ "${argDevEnabled}" = true ]; then
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GITHUB_EMAIL${c[end]} with value ${c[green]}${CSI_GITHUB_EMAIL}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    else
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_GITHUB_EMAIL${c[end]} with value  ${c[green]}***********${CSI_GITHUB_EMAIL:(-8)}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    fi

                else
                    # #
                    #   SECRETS > METHOD > GPG                          empty var CSI_GITHUB_EMAIL
                    # #

                    printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GITHUB_EMAIL${c[end]} not declared in ${c[orange]}${HOME}/.${app_file_secret_gh_email}${c[end]}"
                fi
            else
                # #
                #   SECRETS > METHOD > GPG                              missing file /home/user/.CSI_GITHUB_EMAIL
                # #

                echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${HOME}/.${app_file_secret_gh_email}${c[end]}"
            fi
        else
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_GITHUB_EMAIL${c[end]}"
            fi
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > GPG ENCRYPTED                            empty var CSI_TANG_SERVER
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_TANG_SERVER}" ] || [ "${CSI_TANG_SERVER}" == "null" ] || [ "${CSI_TANG_SERVER}" == null ]; then
            if [ -f "${HOME}/.${app_file_secret_tang_server}" ]; then
                CSI_TANG_SERVER=$(gpg --decrypt "${HOME}/.${app_file_secret_tang_server}" 2>/dev/null)

                # #
                #   SECRETS > METHOD > GPG                              valid var CSI_TANG_SERVER
                # #

                if [ -n "${CSI_TANG_SERVER}" ]; then
                    if [ "${argDevEnabled}" = true ]; then
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_TANG_SERVER${c[end]} with value ${c[green]}${CSI_TANG_SERVER}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    else
                        echo -e "  ${c[green]}OK           ${c[end]}+ var ${c[green]}\$CSI_TANG_SERVER${c[end]} with value  ${c[green]}***********${CSI_TANG_SERVER:(-8)}${c[end]} from ${c[green]}GPG Encryption${c[end]}"
                    fi

                else
                    # #
                    #   SECRETS > METHOD > GPG                          empty var CSI_TANG_SERVER
                    # #

                    printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_TANG_SERVER${c[end]} not declared in ${c[orange]}${HOME}/.${app_file_secret_tang_server}${c[end]}"
                fi
            else
                # #
                #   SECRETS > METHOD > GPG                              missing file /home/user/.CSI_TANG_SERVER
                # #

                echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${HOME}/.${app_file_secret_tang_server}${c[end]}"
            fi
        else
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}! var already exists ${c[navy]}\$CSI_TANG_SERVER${c[end]}"
            fi
        fi
    fi

    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
    #   SECRETS > METHOD > CSI_BASE                             found file /server/proteus/CSI_BASE
    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

    if [ -f "${path_file_secret_base}" ]; then
        echo -e "  ${c[green]}OK           ${c[green]}CSI_BASE Mode Activated${c[end]}"

        if [ "${argDevEnabled}" = true ]; then
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ file ${c[navy]}${path_file_secret_base}${c[grey1]}, loading ${c[navy]}CSI_BASE${c[grey1]} secrets${c[end]}"
        fi

        # #
        #   SECRETS > BASE
        #       load /server/.secrets/CSI_BASE
        #   
        #       this mean tries to load all remaining env variables if any are missing.
        #       you could put your Github / Gitlab tokens in here, but they would be plain-text and dangerous.
        #   
        #       this set of instructions need to be ran last.
        #   
        #       do not put any env variables in the /server./secrets/CSI_BASE that youwant loaded from anywhere
        #       else
        # #

        source "${path_file_secret_base}"

        # #
        #   alternative aliases
        #   
        #   this is used in case any of the env vars defined in /server/.secrets/CSI_BASE do not start with CSI_
        # #

        if [ -n "${GPG_KEY}" ]; then
            export CSI_GPG_KEY="${GPG_KEY}"
        fi

        if [ -n "${GITHUB_NAME}" ]; then
            export CSI_GITHUB_NAME="${GITHUB_NAME}"
        fi

        if [ -n "${GITHUB_EMAIL}" ]; then
            export CSI_GITHUB_EMAIL="${GITHUB_EMAIL}"
        fi

        if [ -n "${TANG_SERVER}" ]; then
            export CSI_TANG_SERVER="${TANG_SERVER}"
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > CSI_BASE                             var found CSI_SUDO_PASSWD
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_SUDO_PASSWD}" ]; then
            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_SUDO_PASSWD${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
        else
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_SUDO_PASSWD${c[grey1]} with value ${c[navy]}${CSI_SUDO_PASSWD}${c[grey1]} from ${c[navy]}${path_file_secret_base}${c[end]}"
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > CSI_BASE                             var found CSI_PAT_GITHUB
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_PAT_GITHUB}" ]; then
            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_PAT_GITHUB${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
        else
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_PAT_GITHUB${c[grey1]} with value ${c[navy]}${CSI_PAT_GITHUB}${c[grey1]} from ${c[navy]}${path_file_secret_base}${c[end]}"
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > CSI_BASE                             var found CSI_PAT_GITLAB
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_PAT_GITLAB}" ]; then
            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_PAT_GITLAB${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
        else
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_PAT_GITLAB${c[grey1]} with value ${c[navy]}${CSI_PAT_GITLAB}${c[grey1]} from ${c[navy]}${path_file_secret_base}${c[end]}"
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > CSI_BASE                             var found CSI_GPG_PASSWD
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_GPG_PASSWD}" ]; then
            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GPG_PASSWD${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
        else
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_GPG_PASSWD${c[grey1]} with value ${c[navy]}${CSI_GPG_PASSWD}${c[grey1]} from ${c[navy]}${path_file_secret_base}${c[end]}"
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > CSI_BASE                             var found CSI_GPG_KEY
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_GPG_KEY}" ]; then
            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GPG_KEY${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
        elif [ "${CSI_GPG_KEY}" == "!" ]; then
            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GPG_KEY${c[end]} invalid key !${c[end]}"
        else
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_GPG_KEY${c[grey1]} with value ${c[navy]}${CSI_GPG_KEY}${c[grey1]} from ${c[navy]}${path_file_secret_base}${c[end]}"
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > CSI_BASE                             var found CSI_GITHUB_NAME
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_GITHUB_NAME}" ]; then
            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GITHUB_NAME${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
        else
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_GITHUB_NAME${c[grey1]} with value ${c[navy]}${CSI_GITHUB_NAME}${c[grey1]} from ${c[navy]}${path_file_secret_base}${c[end]}"
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > CSI_BASE                             var found CSI_GITHUB_EMAIL
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_GITHUB_EMAIL}" ]; then
            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GITHUB_EMAIL${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
        else
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_GITHUB_EMAIL${c[grey1]} with value ${c[navy]}${CSI_GITHUB_EMAIL}${c[grey1]} from ${c[navy]}${path_file_secret_base}${c[end]}"
        fi

        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > CSI_BASE                             var found CSI_TANG_SERVER
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        if [ -z "${CSI_TANG_SERVER}" ]; then
            printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_TANG_SERVER${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
        else
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}+ var ${c[navy]}\$CSI_TANG_SERVER${c[grey1]} with value ${c[navy]}${CSI_TANG_SERVER}${c[grey1]} from ${c[navy]}${path_file_secret_base}${c[end]}"
        fi

    else
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
        #   SECRETS > METHOD > CSI_BASE                             missing file /server/proteus/CSI_BASE
        #                                                           create BASE file, and throw error, then exit
        # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

        echo -e "  ${c[red]}ERROR        ${c[end]}Missing file ${c[red2]}${path_file_secret_base}${c[end]}"
        mkdir -p "${app_dir_secrets}"
        touch "${path_file_secret_base}"

        error_missing_file_base
    fi

    echo -e "  ${c[green]}OK           ${c[green]}Summary${c[end]}"

    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
    #   SECRETS > METHOD > FINALIZE                             var found CSI_SUDO_PASSWD
    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

    if [ -z "${CSI_SUDO_PASSWD}" ]; then
        printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_SUDO_PASSWD${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
    else
        printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}+ var ${c[green]}\$CSI_SUDO_PASSWD${c[end]} with value ${c[green]}${CSI_SUDO_PASSWD}${c[end]} from ${c[green]}${path_file_secret_base}${c[end]}"
    fi

    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
    #   SECRETS > METHOD > FINALIZE                             var found CSI_PAT_GITHUB
    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

    if [ -z "${CSI_PAT_GITHUB}" ]; then
        printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_PAT_GITHUB${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
    else
        printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}+ var ${c[green]}\$CSI_PAT_GITHUB${c[end]} with value ${c[green]}${CSI_PAT_GITHUB}${c[end]} from ${c[green]}${path_file_secret_base}${c[end]}"
    fi

    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
    #   SECRETS > METHOD > FINALIZE                             var found CSI_PAT_GITLAB
    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

    if [ -z "${CSI_PAT_GITLAB}" ]; then
        printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_PAT_GITLAB${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
    else
        printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}+ var ${c[green]}\$CSI_PAT_GITLAB${c[end]} with value ${c[green]}${CSI_PAT_GITLAB}${c[end]} from ${c[green]}${path_file_secret_base}${c[end]}"
    fi

    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
    #   SECRETS > METHOD > FINALIZE                             var found CSI_GPG_PASSWD
    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

    if [ -z "${CSI_GPG_PASSWD}" ]; then
        printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GPG_PASSWD${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
    else
        printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}+ var ${c[green]}\$CSI_GPG_PASSWD${c[end]} with value ${c[green]}${CSI_GPG_PASSWD}${c[end]} from ${c[green]}${path_file_secret_base}${c[end]}"
    fi

    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
    #   SECRETS > METHOD > FINALIZE                             var found CSI_GPG_KEY
    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

    if [ -z "${CSI_GPG_KEY}" ]; then
        printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GPG_KEY${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
    elif [ "${CSI_GPG_KEY}" == "!" ]; then
        printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GPG_KEY${c[end]} invalid key !${c[end]}"
    else
        printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}+ var ${c[green]}\$CSI_GPG_KEY${c[end]} with value ${c[green]}${CSI_GPG_KEY}${c[end]} from ${c[green]}${path_file_secret_base}${c[end]}"
    fi

    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
    #   SECRETS > METHOD > FINALIZE                             var found CSI_GITHUB_NAME
    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

    if [ -z "${CSI_GITHUB_NAME}" ]; then
        printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GITHUB_NAME${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
    else
        printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}+ var ${c[green]}\$CSI_GITHUB_NAME${c[end]} with value ${c[green]}${CSI_GITHUB_NAME}${c[end]} from ${c[green]}${path_file_secret_base}${c[end]}"
    fi

    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
    #   SECRETS > METHOD > FINALIZE                             var found CSI_GITHUB_EMAIL
    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

    if [ -z "${CSI_GITHUB_EMAIL}" ]; then
        printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_GITHUB_EMAIL${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
    else
        printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}+ var ${c[green]}\$CSI_GITHUB_EMAIL${c[end]} with value ${c[green]}${CSI_GITHUB_EMAIL}${c[end]} from ${c[green]}${path_file_secret_base}${c[end]}"
    fi

    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
    #   SECRETS > METHOD > FINALIZE                             var found CSI_TANG_SERVER
    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

    if [ -z "${CSI_TANG_SERVER}" ]; then
        printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}! var ${c[orange]}\$CSI_TANG_SERVER${c[end]} not declared in ${c[orange]}${path_file_secret_base}${c[end]}"
    else
        printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}+ var ${c[green]}\$CSI_TANG_SERVER${c[end]} with value ${c[green]}${CSI_TANG_SERVER}${c[end]} from ${c[green]}${path_file_secret_base}${c[end]}"
    fi

    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
    #   ENV > CSI_GPG_KEY                                           env missg CSI_GPG_KEY
    #                                                           create BASE file, and throw error, then exit
    # # ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――

    if [ -z "${CSI_GPG_KEY}" ] || [ "${CSI_GPG_KEY}" == "!" ]; then
        error_missing_value_gpg
    fi

    set -o history

}

# #
#   DEFINE > App repo paths and commands
# #

app_repo_script="proteus-git"
app_repo_branch="main"
app_repo_apt="proteus-apt-repo"
app_repo_apt_pkg="aetherinox-${app_repo_apt}-archive"
app_repo_url="https://github.com/${CSI_GITHUB_NAME}/${app_repo_script}"
app_repo_apt_url="https://github.com/${CSI_GITHUB_NAME}/${app_repo_apt}"
app_repo_mnfst="https://raw.githubusercontent.com/${CSI_GITHUB_NAME}/${app_repo_script}/${app_repo_branch}/manifest.json"
app_repo_script="https://raw.githubusercontent.com/${CSI_GITHUB_NAME}/${app_repo_script}/BRANCH/setup.sh"

# #
#   DEV > Show Arguments
# #

if [ "${argDevEnabled}" = true ]; then
    echo -e
    echo -e "  ${c[yellow]}${c[bold]}[ Arguments ]${c[end]}"

    [ "${argDevEnabled}" = true ] && printf "%-3s %-15s %-10s\n" "" "--dev" "${c[green]}${argDevEnabled}${c[end]}"
    [ "${argOnlyGithub}" = true ] && printf "%-3s %-15s %-10s\n" "" "--onlyGithub" "${c[green]}${argOnlyGithub}${c[end]}"
    [ "${argOnlyAptget}" = true ] && printf "%-3s %-15s %-10s\n" "" "--onlyAptget" "${c[green]}${argOnlyAptget}${c[end]}"
    [ "${argDryRun}" = true ] && printf "%-3s %-15s %-10s\n" "" "--nullrun" "${c[green]}${argDryRun}${c[end]}"
    [ "${argNoLogs}" = true ] && printf "%-3s %-15s %-10s\n" "" "--quiet" "${c[green]}${argNoLogs}${c[end]}"
    [ -n "${argDistribution}" ] && printf "%-3s %-15s %-10s\n" "" "--dist" "${c[green]}${argDistribution}${c[end]}"
    [ -n "${argBranch}" ] && printf "%-3s %-15s %-10s\n" "" "--branch" "${c[green]}${argBranch}${c[end]}"
    echo -e
fi

# #
#   upload to github > precheck
# #

app_run_github_precheck( )
{
    
    printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Configuring git config${c[end]}"

    # #
    #   delete lock
    # #

    rm -f "${app_dir}.git/index.lock"
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}rm -f ${app_dir}.git/index.lock${c[end]}"
    fi

    # #
    #   set credential.helper
    # #

    git config --global credential.helper store
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git config --global credential.helper store${c[end]}"
    fi

    # #
    #   set default action for conflicts
    # #

    git config pull.rebase false
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git config pull.rebase false${c[end]}"
    fi

    # #
    #   turn off lfs locksverify
    # #

    git config lfs.https://github.com.locksverify false
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git config lfs.https://github.com.locksverify false${c[end]}"
    fi

    git config --global lfs.https://github.com.locksverify false
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git config --global lfs.https://github.com.locksverify false${c[end]}"
    fi

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
        if [ "${argDevEnabled}" = true ]; then
            printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git config --global --add safe.directory ${app_dir}${c[end]}"
        fi
    fi

    # #
    #   default branch > main
    # #

    git config --global init.defaultBranch ${app_repo_branch}
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git config --global init.defaultBranch ${app_repo_branch}${c[end]}"
    fi

    # #
    #   username / email
    # #

    git config --global user.name ${CSI_GITHUB_NAME}
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git config --global user.name ${CSI_GITHUB_NAME}${c[end]}"
    fi

    git config --global user.email ${CSI_GITHUB_EMAIL}
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git config --global user.email ${CSI_GITHUB_EMAIL}${c[end]}"
    fi

    # #
    #   init
    # #

    git config --global init.defaultBranch ${app_repo_branch}
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git config --global init.defaultBranch ${app_repo_branch}${c[end]}"
    fi

    # #
    #   http
    # #

    git config --global http.postBuffer 524288000
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git config --global http.postBuffer 524288000${c[end]}"
    fi

    git config --global http.lowSpeedLimit 0
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git config --global http.lowSpeedLimit 0${c[end]}"
    fi
}

# #
#   check if GPG key defined in git config user.signingKey
# #

checkgit_signing=$( git config --global --get-all user.signingKey )
if [ -z "${checkgit_signing}" ] || [ "${checkgit_signing}" == "!" ]; then
    echo
    echo -e "  ${c[bold]}${c[orange]}WARNING  ${c[end]}Missing ${c[yellow]}user.signingKey${c[end]} in ${c[yellow]}${HOME}/.gitconfig${c[end]}"
    echo -e "  ${c[bold]}${c[end]}You should have the below entries in your ${c[fuchsia1]}.gitconfig${c[end]}:${c[end]}"
    echo
    echo -e "  ${c[bold]}${c[end]}    ${c[grey2]}[user]${c[end]}"
    echo -e "  ${c[bold]}${c[end]}         ${c[blue]}signingKey${c[end]} = ${CSI_GPG_KEY}${c[end]}"
    echo
    echo -e "  ${c[bold]}${c[end]}    ${c[grey2]}[commit]${c[end]}"
    echo -e "  ${c[bold]}${c[end]}         ${c[blue]}gpgsign${c[end]} = true${c[end]}"
    echo
    echo -e "  ${c[bold]}${c[end]}    ${c[grey2]}[gpg]${c[end]}"
    echo -e "  ${c[bold]}${c[end]}         ${c[blue]}program${c[end]} = gpg${c[end]}"
    echo
    echo -e "  ${c[bold]}${c[end]}    ${c[grey2]}[tag]${c[end]}"
    echo -e "  ${c[bold]}${c[end]}         ${c[blue]}forceSignAnnotated${c[end]} = true${c[end]}"
    echo
    echo -e "  ${c[bold]}${c[end]}    ${c[grey2]}[init]${c[end]}"
    echo -e "  ${c[bold]}${c[end]}         ${c[blue]}defaultBranch${c[end]} = main${c[end]}"
    echo
    echo -e "  ${c[bold]}${c[end]}    ${c[grey2]}[http]${c[end]}"
    echo -e "  ${c[bold]}${c[end]}         ${c[blue]}postBuffer${c[end]} = 524288000${c[end]}"
    echo -e "  ${c[bold]}${c[end]}         ${c[blue]}lowSpeedLimit${c[end]} = 0${c[end]}"
    echo

    git config --global gpg.program gpg
    git config --global commit.gpgsign true
    git config --global tag.forceSignAnnotated true
    git config --global user.signingkey ${CSI_GPG_KEY}!
    git config --global credential.helper store
    git config --global init.defaultBranch ${app_repo_branch}
    git config --global http.postBuffer 524288000
    git config --global http.lowSpeedLimit 0

    echo -e "  ${c[bold]}${c[end]}Automatically adding these values to your ${c[fuchsia1]}.gitconfig${c[end]}:${c[end]}"

    # #
    #   run the same check as above to double confirm that user.signingKey
    #   has been defined.
    # #

    checkgit_signing=$( git config --global --get-all user.signingKey )
    if [ -z "${checkgit_signing}" ]; then
        echo
        echo -e "  ${c[orange]}WARNING      ${c[end]}Could not add the above entries to ${c[yellow]}${HOME}/.gitconfig${c[end]}"
        echo -e "               You will need to manually add these entries.${c[end]}"
        echo
    else
        echo
        echo -e "  ${c[green]}SUCCESS      ${c[end]}Entries added to ${c[yellow]}${HOME}/.gitconfig${c[end]}"
        echo
    fi
fi

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
    if [ "$argNoLogs" = true ] ; then
        echo -e
        echo -e
        printf '%-50s %-5s' "    Logging for this package has been disabled." ""
        echo -e
        echo -e
        sleep 1
    else
        mkdir -p "$LOGS_DIR"
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
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Assigning log / tee ${c[navy]}PID ${app_pid_tee}${c[end]}"
        exec 1>$LOGS_PIPE
        PIPE_OPENED=1

        printf "%-50s %-5s\n" "${TIME}      Logging to ${LOGS_OBJ}" | tee -a "${LOGS_FILE}" >/dev/null

        printf "%-50s %-5s\n" "${TIME}      Software  : ${app_title}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-50s %-5s\n" "${TIME}      Version   : v$(get_version)" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-50s %-5s\n" "${TIME}      Process   : $$" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-50s %-5s\n" "${TIME}      OS        : ${sys_os_name}" | tee -a "${LOGS_FILE}" >/dev/null
        printf "%-50s %-5s\n" "${TIME}      OS VER    : ${sys_os_ver}" | tee -a "${LOGS_FILE}" >/dev/null

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
        ps --pid "${app_pid_tee}" &>/dev/null
        if [ $? -eq 0 ] ; then
            # using $(wait $app_pid_tee) would be better
            # however, some commands leave file descriptors open
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
#   
#   @note           this has been deprecated as of 2025
#                   it is being replaced by normal outputs
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
    if ps -p ${app_pid_spin} &>/dev/null
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
#   echo -e "  ${c[bold]}${c[fuchsia1]}ATTENTION  ${c[end]}This is a question${c[end]}"
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
                printf '%4d. \e[1m\e[33m %s\t\e[0m\n' $i "${c[yellow]}  ${CHOICES[$i]}  "
                tput sgr0
            else
                printf '\e[1;33m'
                printf '%4d. \e[1m\e[33m %s\t\e[0m\n' $i "${c[yellow]}  ${CHOICES[$i]}  "
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

        #  printf '%-60s %13s %-5s' "    $1 " "${c[yellow]}[$syntax]${c[end]}" ""
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
    # spin &

    # spinner PID
    # app_pid_spin=$!

    # printf "%-50s %-5s\n\n" "${TIME}      NEW Spinner: PID (${app_pid_spin})" | tee -a "${LOGS_FILE}" >/dev/null

    # kill spinner on any signal
    # trap "kill -9 ${app_pid_spin} 2> /dev/null" `seq 0 15`

    printf '%-50s %-5s' "  ${1}" ""
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

terminate()
{
    finish
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
    echo -e

    printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Downloading new copy of ${c[blue]}${path_file_bin_binary}${c[end]} from ${c[blue]}${branch_uri}${c[end]}"
    if [ "${argDryRun}" = false ]; then
        sudo wget -O "${path_file_bin_binary}" -q "${branch_uri}" >> ${LOGS_FILE} 2>&1
    fi

    printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Set ownership for ${c[blue]}${path_file_bin_binary}${c[end]} to ${c[blue]}${USER}:${USER}${c[end]}"
    if [ "${argDryRun}" = false ]; then
        sudo chgrp ${USER} ${path_file_bin_binary} >> ${LOGS_FILE} 2>&1
        sudo chown ${USER} ${path_file_bin_binary} >> ${LOGS_FILE} 2>&1
    fi

    printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Set permissions for ${c[blue]}${path_file_bin_binary}${c[end]} to ${c[blue]}u+x${c[end]}"
    if [ "${argDryRun}" = false ]; then
        sudo chmod u+x ${path_file_bin_binary} >> ${LOGS_FILE} 2>&1
    fi
    echo -e

    echo -e "  ${c[bold]}${c[green]}Update Complete!${c[end]}" >&2

    finish
}

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
    echo -e "  ${c[orange]}Error${c[end]}"
    echo -e "  "
    echo -e "  ${c[end]}Folder ${c[yellow]}.git${c[end]} does not exist."
    echo -e "  ${c[end]}Must clone ${c[yellow]}${app_repo_apt_url}${c[end]} first."
    echo -e
    echo -e "  Couldn't find .git folder in ${app_dir}"
    echo -e

    app_run_github_precheck

    # git clone -b main https://github.com/Aetherinox/proteus-apt-repo.git
    git init --initial-branch=${app_repo_branch}
    git remote add origin https://github.com/${CSI_GITHUB_NAME}/${app_repo_apt}.git
    git fetch
    git checkout origin/main -b main

    git add .

    # #
    #   
    #   -m <msg>, --message=<msg> 
    #   -s, --signoff 
    # #

    git commit -S -m "New Server Addition"
    git pull https://${CSI_GITHUB_NAME}:${CSI_PAT_GITHUB}@github.com/${CSI_GITHUB_NAME}/${app_repo_apt}.git

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
    #           sudo add-apt-repository -y "deb [arch=amd64] https://raw.githubusercontent.com/${CSI_GITHUB_NAME}/${app_repo_apt}/master focal main" >> $LOGS_FILE 2>&1
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
    if [ "$bMissingAptMove" = true ] || [ "$bMissingAptUrl" = true ] || [ "$bMissingCurl" = true ] || [ "$bMissingWget" = true ] || [ "$bMissingTree" = true ] || [ "$bMissingGPG" = true ] ||  [ "$bMissingGChrome" = true ]  || [ "$bMissingMFirefox" = true ] || [ "$bMissingRepo" = true ] || [ "$bMissingReprepro" = true ]; then
        echo
        title "Addressing Dependencies ..."
        echo
        sleep 1
    fi

    # #
    #   find a gpg key that can be imported
    #   maybe later add a loop to check for multiple.
    #
    #   PATH CSI_GPG_KEY missing from secrets.sh
    # #

    if [ -z "${CSI_GPG_KEY}" ]; then
        echo
        echo -e "  ${c[orange]}WARNING      ${c[yellow]}CSI_GPG_KEY${c[end]} Not Specified${c[end]}"
        echo -e "               Must create ${c[fuchsia1]}${path_file_secret_base}${c[end]} file and define your GPG key.${c[end]}"
        echo -e
        echo -e "                    ${c[grey2]}${c[red]}export ${c[green]}CSI_GPG_KEY=${c[end]}XXXXXXXX${c[end]}"
        echo

        printf "  Press any key to abort ... ${c[end]}"
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
        gpg_id=$( gpg --list-secret-keys --keyid-format=long | grep "$CSI_GPG_KEY" )
    
        echo -e "  ${c[green]}OK           ${c[end]}Found GPG key ${c[blue2]}${gpg_id}${c[end]}"
    
        if [[ $? == 0 ]]; then 
            echo -e "  ${c[green]}OK           ${c[end]}Loading GPG key ${c[blue2]}${gpg_id}${c[end]}"

            bGPGLoaded=true
        else
            echo -e
            echo -e "  ${c[orange]}Error${c[end]}"
            echo -e "  "
            echo -e "  ${c[end]}Specified GPG key ${c[yellow]}${CSI_GPG_KEY}${c[end]} not found in GnuPG key store."
            echo -e "  ${c[end]}Searching ${c[yellow]}${app_dir}/${app_dir_gpg}/${c[end]} for a GPG key to import."
            echo -e

            # #
            #   find *.gpg
            # #

            if [ -f $app_dir/.gpg/*.gpg ]; then
                gpg_file=$app_dir/${app_dir_gpg}/*.gpg
                gpg --import "$gpg_file"
                bGPGLoaded=true

                echo -e
                echo -e "  ${c[green]}OK           ${c[end]}Found ${c[yellow]}${app_dir}/${app_dir_gpg}/${gpg_file}${c[end]} to import.${c[end]}"
                echo -e

            # #
            #   find *.asc
            # #

            elif [ -f $app_dir/.gpg/*.asc ]; then
                gpg_file=${app_dir}/${app_dir_gpg}/*.asc
                gpg --import "$gpg_file"
                bGPGLoaded=true

                echo -e
                echo -e "  ${c[green]}OK           ${c[end]}Found ${c[yellow]}${app_dir}/${app_dir_gpg}/${gpg_file}${c[end]} to import.${c[end]}"
                echo -e

            # #
            #   no .gpg, .asc keys found
            # #

            else
                echo -e
                printf '%-29s %-65s\n' "  ${c[orange]}WARN${c[end]}" "${c[end]}No GPG keys found to import. Since you are in ${c[yellow]}--onlyTest${c[end]} mode, ${c[yellow]}Skipping}${c[end]}"
                echo -e
            fi

            printf "  Press any key to continue ... ${c[end]}"
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

    if [ "$bGPGLoaded" = false ]; then

        echo -e 
        echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
        echo
        echo -e "  ${c[orange]}WARNING      ${c[end]}Missing Private GPG Key${c[end]}"
        echo -e "               You must have a private GPG key imported to use this program.${c[end]}"
        echo -e "               Your private GPG key is used to sign commits and the deb package${c[end]}"
        echo -e "               repositories that you upload.${c[end]}"
        echo -e
        echo -e "               You must either add a private .gpg keyfile to the folder:${c[end]}"
        echo -e "                    ${c[grey2]}${c[yellow]}${app_dir}/${app_dir_gpg}/${c[end]}"
        echo -e
        echo -e "               Or manually import a GPG key to your system's GPG keyring${c[end]}"
        echo
        echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
        echo -e

        printf "  Press any key to abort ... ${c[end]}"
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

    if [ "$bMissingCurl" = true ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing curl package" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Adding curl package" ""

        if [ "${argDryRun}" = false ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install curl -y -qq >> /dev/null 2>&1
        fi
    fi

    # #
    #   missing wget
    # #

    if [ "$bMissingWget" = true ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing wget package" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Adding wget package" ""

        if [ "${argDryRun}" = false ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install wget -y -qq >> /dev/null 2>&1
        fi
    fi

    # #
    #   missing tree
    # #

    if [ "$bMissingTree" = true ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing tree package" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Adding tree package" ""

        if [ "${argDryRun}" = false ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install tree -y -qq >> /dev/null 2>&1
        fi
    fi

    # #
    #   missing gpg trusted file
    #
    #   bMissingGPG     File /usr/share/keyrings/${app_repo_apt_pkg}.gpg not found
    # #

    if [ "$bMissingGPG" = true ]; then
        printf "%-50s %-5s\n" "${TIME}      Adding ${CSI_GITHUB_NAME} GPG key: [https://github.com/${CSI_GITHUB_NAME}.gpg]" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Adding github.com/${CSI_GITHUB_NAME}.gpg" ""

        if [ "${argDryRun}" = false ]; then
            sudo wget -qO - "https://github.com/${CSI_GITHUB_NAME}.gpg" | sudo gpg --batch --yes --dearmor -o "/usr/share/keyrings/${app_repo_apt_pkg}.gpg" >/dev/null
        fi
    fi

    # #
    #   missing google chrome
    #
    #   add google source repo so that chrome can be downloaded using apt-get
    # #

    if [ "$bMissingGChrome" = true ]; then
        printf "%-50s %-5s\n" "${TIME}      Registering Chrome: /etc/apt/sources.list.d/google-chrome.list" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Registering Chrome" ""

        sudo install -d -m 0755 /etc/apt/keyrings

        if [ "${argDryRun}" = false ]; then
            sudo wget -qO - "https://dl-ssl.google.com/linux/linux_signing_key.pub" | sudo gpg --batch --yes --dearmor -o "/etc/apt/keyrings/dl.google.com.gpg" >/dev/null
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/dl.google.com.gpg] http://dl.google.com/linux/chrome/deb/ stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list >/dev/null
        fi

        # change priority
        echo 'Package: * Pin: origin dl.google.com Pin-Priority: 1000' | sudo tee /etc/apt/preferences.d/google-chrome >/dev/null
        printf "%-50s %-5s\n" "${TIME}      Updating user repo list with apt-get update" | tee -a "${LOGS_FILE}" >/dev/null

        if [ "${argDryRun}" = false ]; then
            sudo apt-get update -y -q >/dev/null
        fi
    fi

    # #
    #   missing mozilla repo
    #
    #   add mozilla source repo so that firefox can be downloaded using apt-get
    #   instructions via:
    #       https://support.mozilla.org/en-US/kb/install-firefox-linux#w_install-firefox-deb-package-for-debian-based-distributions
    # #

    if [ "$bMissingMFirefox" = true ]; then
        printf "%-50s %-5s\n" "${TIME}      Registering Mozilla: /etc/apt/sources.list.d/mozilla.list" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Registering Mozilla" ""

        sudo install -d -m 0755 /etc/apt/keyrings
        sudo wget -qO - "https://packages.mozilla.org/apt/repo-signing-key.gpg" | sudo tee /etc/apt/keyrings/packages.mozilla.org.asc > /dev/null

        if [ "${argDryRun}" = false ]; then
            echo "deb [signed-by=/etc/apt/keyrings/packages.mozilla.org.asc] https://packages.mozilla.org/apt mozilla main" | sudo tee /etc/apt/sources.list.d/mozilla.list >/dev/null
        fi

        # change priority
        echo 'Package: * Pin: origin packages.mozilla.org Pin-Priority: 1000' | sudo tee /etc/apt/preferences.d/mozilla >/dev/null
        printf "%-50s %-5s\n" "${TIME}      Updating user repo list with apt-get update" | tee -a "${LOGS_FILE}" >/dev/null

        if [ "${argDryRun}" = false ]; then
            sudo apt-get update -y -q >/dev/null
        fi
    fi

    # #
    #   missing proteus apt repo
    # #

    if [ "$bMissingRepo" = true ]; then
        printf "%-50s %-5s\n" "${TIME}      Registering ${app_repo_apt}: https://raw.githubusercontent.com/${CSI_GITHUB_NAME}/${app_repo_apt}/${app_repo_branch}" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Registering ${app_repo_apt}" ""

        if [ "${argDryRun}" = false ]; then
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/${app_repo_apt_pkg}.gpg] https://raw.githubusercontent.com/${CSI_GITHUB_NAME}/${app_repo_apt}//${app_repo_branch} $(lsb_release -cs) ${app_repo_branch}" | sudo tee /etc/apt/sources.list.d/${app_repo_apt_pkg}.list >/dev/null
        fi

        printf "%-50s %-5s\n" "${TIME}      Updating user repo list with apt-get update" | tee -a "${LOGS_FILE}" >/dev/null
        
        if [ "${argDryRun}" = false ]; then
            sudo apt-get update -y -q >/dev/null
        fi
    fi

    # #
    #   install proteus binary in ${HOME}/bin/proteus
    # #

    if ! [ -f "$path_file_bin_binary" ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing ${app_title}" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Installing ${app_title}" ""

        if [ "${argDryRun}" = false ]; then
            mkdir -p "$app_dir_bin"

            local branch_uri="${app_repo_script/BRANCH/"$app_repo_branch_sel"}"
            sudo wget -O "${path_file_bin_binary}" -q "$branch_uri" >> $LOGS_FILE 2>&1
            sudo chgrp ${USER} ${path_file_bin_binary} >> $LOGS_FILE 2>&1
            sudo chown ${USER} ${path_file_bin_binary} >> $LOGS_FILE 2>&1
            sudo chmod u+x ${path_file_bin_binary} >> $LOGS_FILE 2>&1
        fi
    fi

    # #
    #   missing apt-move
    # #

    if [ "$bMissingAptMove" = true ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing apt-move package" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Adding apt-move package" ""

        if [ "${argDryRun}" = false ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install apt-move -y -qq >> /dev/null 2>&1
        fi
    fi

    # #
    #   missing apt-url
    # #

    if [ "$bMissingAptUrl" = true ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing apt-url package" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Adding apt-url package" ""

        if [ "${argDryRun}" = false ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install apt-url -y -qq >> /dev/null 2>&1
        fi
    fi

    # #
    #   missing reprepro
    # #

    if [ "$bMissingReprepro" = true ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing reprepro package" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Adding reprepro package" ""

        if [ "${argDryRun}" = false ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install reprepro -y -qq >> /dev/null 2>&1
        fi
    fi

    # #
    #   add env path ${HOME}/bin/
    # #

    envpath_add_proteus '${HOME}/bin'

    # #
    #   missing lastversion
    # #

    if [ "$bMissingLastVersion" = true ]; then
        printf "%-50s %-5s\n" "${TIME}      Installing LastVersion" | tee -a "${LOGS_FILE}" >/dev/null
        printf '%-50s %-5s' "    |--- Adding LastVersion package" ""

        if [ "${argDryRun}" = false ]; then
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
            cp "${HOME}/.local/bin/lastversion ${HOME}/bin/"
            sudo touch "/etc/profile.d/lastversion.sh"

            envpath_add_lastversion '${HOME}/bin'

            echo 'export PATH="${HOME}/bin:$PATH"' | sudo tee /etc/profile.d/lastversion.sh

            . ~/.bashrc
            . ~/.profile

            source ${HOME}/.profile # not executing for some reason
        fi
    fi

    # #
    #   modify gpg-agent.conf
    #
    #   first check if GPG installed (usually on Ubuntu it is)
    #   then modify user's gpg-agent.conf file
    # #

    gpgconfig_file="${HOME}/.gnupg/gpg-agent.conf"

    if ! [ -x "$(command -v gpg)" ]; then
        printf '%-57s' "    |--- Installing GPG"

        if [ "${argDryRun}" = false ]; then
            sudo apt-get update -y -q >> /dev/null 2>&1
            sudo apt-get install gpg -y -qq >> /dev/null 2>&1
        fi
    fi

    printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Import GPG config to ${c[yellow]}${gpgconfig_file}${c[end]}${c[end]}"
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

    printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Set ownership for ${c[yellow]}${gpgconfig_file}${c[end]} to ${c[yellow]}${USER}:${USER}${c[end]}"
    if [ "${argDryRun}" = false ]; then
        sudo chgrp ${USER} "${gpgconfig_file}" >> $LOGS_FILE 2>&1
        sudo chown ${USER} "${gpgconfig_file}" >> $LOGS_FILE 2>&1
    fi

    printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Restart ${c[yellow]}GPG Agent${c[end]}"
    gpgconf --kill gpg-agent

    # #
    #   SECRETS > GPG precache
    # #

    if [ -f ${path_file_secret_gpg_passwd} ]; then
        CSI_GPG_PASSWD=$(cat ${path_file_secret_gpg_passwd} | clevis decrypt 2>/dev/null)

        # #
        #   SECRETS > METHOD > CLEVIS
        #       CSI_GPG_PASSWD valid (not empty)
        # #

        if [ -n "${CSI_GPG_PASSWD}" ]; then
            echo "${CSI_GPG_PASSWD}" | gpg --batch --yes --pinentry-mode loopback --passphrase-fd 0 --output /dev/null --sign
        fi
    fi
}

# #
#   output some logging
# #

[ "${argDevEnabled}" = true ] && printf "%-50s %-5s\n" "${TIME}      Notice: Dev Mode Enabled" | tee -a "${LOGS_FILE}" >/dev/null
[ "${argDevEnabled}" = false ] && printf "%-50s %-5s\n" "${TIME}      Notice: Dev Mode Disabled" | tee -a "${LOGS_FILE}" >/dev/null

[ "${argDryRun}" = true ] && printf "%-50s %-5s\n\n" "${TIME}      Notice: Dev Option: 'No Actions' Enabled" | tee -a "${LOGS_FILE}" >/dev/null
[ "${argDryRun}" = false ] && printf "%-50s %-5s\n\n" "${TIME}      Notice: Dev Option: 'No Actions' Disabled" | tee -a "${LOGS_FILE}" >/dev/null

# #
#   header
# #

show_header()
{
    echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
    echo -e " ${c[green]}${c[bold]} ${app_title} - v$(get_version)${c[end]}${c[magenta]}"
    echo -e "  This app downloads the latest version of numerous packages and posts them to the Proteus Apt Repo."

    echo -e

    if [ "${argDryRun}" = true ]; then
        printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "${c[yellow]}${c[blink]}Nullrun${c[end]} has been enabled${c[end]}"
    fi

    if [ "${argDevEnabled}" = true ]; then
        printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "${c[yellow]}${c[blink]}Developer mode${c[end]} has been enabled${c[end]}"
    fi

    echo -e
    printf '%-29s %-65s\n' "  ${c[grey3]}GPG KEY${c[end]}" "${c[fuchsia1]}$CSI_GPG_KEY${c[end]}"
    printf '%-29s %-65s\n' "  ${c[grey3]}DISTRO${c[end]}" "${c[fuchsia1]}$app_repo_dist_sel${c[end]}"
    printf '%-29s %-65s\n' "  ${c[grey3]}BRANCH${c[end]}" "${c[fuchsia1]}$app_repo_branch_sel${c[end]}"
    if [ "${argDryRun}" = true ]; then
        printf '%-29s %-65s\n' "  ${c[grey3]}APP PID${c[end]}" "${c[fuchsia1]}$$${c[end]}"
        printf '%-29s %-65s\n' "  ${c[grey3]}TEE PID${c[end]}" "${c[fuchsia1]}$app_pid_tee${c[end]}"
        printf '%-29s %-65s\n' "  ${c[grey3]}USER${c[end]}" "${c[fuchsia1]}$USER${c[end]}"
        printf '%-29s %-65s\n' "  ${c[grey3]}APPS${c[end]}" "${c[fuchsia1]}$app_count${c[end]}"
        printf '%-29s %-65s\n' "  ${c[grey3]}DEV${c[end]}" "${c[fuchsia1]}$([ "${argDevEnabled}" = true ] && echo "Enabled" || echo "Disabled" )${c[end]}"
        echo
    fi

    echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
    echo

    printf "%-50s %-5s\n" "${TIME}      Successfully loaded ${app_count} packages" | tee -a "${LOGS_FILE}" >/dev/null
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

    echo -e
    begin "Aptget Packages [ $count ]"
    echo -e

    # #
    #   Create main folders for architecture
    #   all, amd64, arm54, i386
    # #

    mkdir -p $app_dir/$app_dir_incoming/{all,amd64,arm64,i386}

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
                echo -e "     ${c[grey2]}|--- ${c[yellow]}[ ${count} ]${c[fuchsia1]}${c[bold]} ${pkg_arch:0:35}${c[end]}"
            else
                echo -e "               ${c[fuchsia1]}${c[bold]} ${pkg_arch:0:35}${c[end]}"
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

            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Package${c[end]}" "${c[fuchsia2]}${pkg_arch}${c[end]}"
            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}File${c[end]}" "${c[fuchsia2]}${app_filename}${c[end]}"

            # #
            #   output > architecture doesn't exist for this package
            # #

            if echo "$apturl_query" | grep --quiet --ignore-case "find package" ; then
                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "🔍 ${c[orange]}${arch:0:35}${c[end]} doesn't exist for this package${c[end]}"
            fi

            # #
            #   output > apt-url cannot be run because apt get is held up by another process
            # #

            if echo "$apturl_query" | grep --quiet --ignore-case "It is held by process" ; then
                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "🗔 ${c[orange]}${pkg_arch:0:35}${c[end]} held up by process${c[end]}"
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
                    printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Download${c[end]}" "${c[fuchsia2]}${app_url}${c[end]}"

                    # #
                    #   architecture > all
                    #   move package to its final location inside the reprepro directory
                    #       move    ${HOME}/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
                    #       to      ${HOME}/proteus/incoming/packages/jammy/all/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
                    # #

                    if [ -f $app_dir/$app_filename ]; then
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Move${c[end]}" "${c[fuchsia2]}${app_dir}/${app_filename}${c[end]} to ${c[fuchsia2]}$app_dir/$app_dir_incoming/all/${c[end]}"
                        mv "${app_dir}/${app_filename}" "$app_dir/$app_dir_incoming/all/"
                    fi

                    # #
                    #   architecture > all > full package path
                    #
                    #       deb_package             incoming/proteus-git/jammy/all/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
                    # #

                    deb_package="${app_dir_incoming}/${arch}/${app_filename}"

                    # #
                    #   architecture > all > reprepro
                    #   add package to reprepro database
                    #
                    #       app_repo_dist_sel       jammy
                    #       deb_package             incoming/packages/jammy/all/networkd-dispatcher_2.1-2ubuntu0.22.04.2_all.deb
                    # #

                    printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Reprepro${c[end]}" "${c[fuchsia2]}${deb_package}${c[end]} for dist ${c[fuchsia2]}${app_repo_dist_sel}${c[end]}"
                    printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Command${c[end]}" "${c[grey1]}reprepro -V --section utils --component main --priority 0 includedeb ${app_repo_dist_sel} ${deb_package}${c[end]}"

                    if [ -n "${bRepreproInstalled}" ] && [ "${argDryRun}" = false ]; then
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
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
                        fi

                        # #
                        #   aptget > architecture > all > reprepro
                        #
                        #   output > package already added but checksums are different
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "Already existing files" ; then
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists; bad checksums. Removing ${c[yellow]}${app_filename}${c[end]} from ${c[yellow]}Reprepro${c[end]} and re-adding${c[end]}"
                            reprepro remove "${app_repo_dist_sel}" "${app_filename}"

                            reprepro_exit_code="0"
                            reprepro_output="$(reprepro -V \
                                --section utils \
                                --component main \
                                --priority 0 \
                                includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                "$@" 2>&1)" \
                                || { reprepro_exit_code="$?" ; true; };
                        fi

                        # #
                        #   architecture > all > reprepro
                        #
                        #   output > new package added
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "✅ New package added (${c[green]}${deb_package}${c[end]}) for ${c[green]}${app_repo_dist_sel}${c[end]}"
                        fi
                    else
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Skip addition; reprepro not installed or in dryrun mode (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
                    fi

                    bNewPackage=false

                # #
                #   architecture > amd64
                #   file must end with 'amd64.deb'
                # #

                elif [[ "${arch}" == "amd64" ]] && [[ ${app_filename} == *amd64.deb ]]; then
                    printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Download${c[end]}" "${c[fuchsia2]}${app_url}${c[end]}"

                    # #
                    #   architecture > amd64
                    #   move package to its final location inside the reprepro directory
                    #       move    ${HOME}/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.2_amd64.deb
                    #       to      ${HOME}/proteus/incoming/packages/jammy/amd64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_amd64.deb
                    # #

                    if [ -f $app_dir/$app_filename ]; then
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Move${c[end]}" "${c[fuchsia2]}${app_dir}/${app_filename}${c[end]} to ${c[fuchsia2]}$app_dir/$app_dir_incoming/amd64/${c[end]}"
                        mv "${app_dir}/${app_filename}" "$app_dir/$app_dir_incoming/amd64/"
                    fi

                    # #
                    #   architecture > amd64 > full package path
                    #   
                    #       deb_package             incoming/packages/jammy/amd64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_amd64.deb
                    # #

                    deb_package="${app_dir_incoming}/${arch}/${app_filename}"

                    # #
                    #   architecture > amd64 > reprepro
                    #   add package to reprepro database
                    #   
                    #       app_repo_dist_sel       jammy
                    #       deb_package             incoming/packages/jammy/amd64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_amd64.deb
                    # #

                    printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Reprepro${c[end]}" "${c[fuchsia2]}${deb_package}${c[end]} for dist ${c[fuchsia2]}${app_repo_dist_sel}${c[end]}"
                    printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Command${c[end]}" "${c[grey1]}reprepro -V --section utils --component main --priority 0 --architecture $arch includedeb ${app_repo_dist_sel} ${deb_package}${c[end]}"

                    if [ -n "${bRepreproInstalled}" ] && [ "${argDryRun}" = false ]; then
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
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
                        fi

                        # #
                        #   aptget > architecture > amd64 > reprepro
                        #
                        #   output > package already added but checksums are different
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "Already existing files" ; then
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists; bad checksums. Removing ${c[yellow]}${app_filename}${c[end]} from ${c[yellow]}Reprepro${c[end]} and re-adding${c[end]}"
                            reprepro remove "${app_repo_dist_sel}" "${app_filename}"

                            reprepro_exit_code="0"
                            reprepro_output="$(reprepro -V \
                                --section utils \
                                --component main \
                                --priority 0 \
                                --architecture ${arch} \
                                includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                "$@" 2>&1)" \
                                || { reprepro_exit_code="$?" ; true; };
                        fi

                        # #
                        #   architecture > amd64 > reprepro
                        #
                        #   output > new package added
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "✅ New package added (${c[green]}${deb_package}${c[end]}) for ${c[green]}${app_repo_dist_sel}${c[end]}"
                        fi
                    else
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Skip addition; reprepro not installed or in dryrun mode (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
                    fi

                    bNewPackage=false

                # #
                #   architecture > arm64
                #   file must end with 'arm64.deb'
                # #

                elif [[ "${arch}" == "arm64" ]] && [[ ${app_filename} == *arm64.deb ]]; then
                    printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Download${c[end]}" "${c[fuchsia2]}${app_url}${c[end]}"

                    # #
                    #   architecture > arm64
                    #   move package to its final location inside the reprepro directory
                    #       move    ${HOME}/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.2_arm64.deb
                    #       to      ${HOME}/proteus/incoming/packages/jammy/arm64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_arm64.deb
                    # #

                    if [ -f $app_dir/$app_filename ]; then
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Move${c[end]}" "${c[fuchsia2]}${app_dir}/${app_filename}${c[end]} to ${c[fuchsia2]}$app_dir/$app_dir_incoming/arm64/${c[end]}"
                        mv "${app_dir}/${app_filename}" "$app_dir/$app_dir_incoming/arm64/"
                    fi

                    # #
                    #   architecture > arm64 > full package path
                    #
                    #       deb_package             incoming/packages/jammy/arm64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_arm64.deb
                    # #

                    deb_package="${app_dir_incoming}/${arch}/${app_filename}"

                    # #
                    #   architecture > arm64 > reprepro
                    #   add package to reprepro database
                    #
                    #       app_repo_dist_sel       jammy
                    #       deb_package             incoming/packages/jammy/arm64/networkd-dispatcher_2.1-2ubuntu0.22.04.2_arm64.deb
                    # #

                    printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Reprepro${c[end]}" "${c[fuchsia2]}${deb_package}${c[end]} for dist ${c[fuchsia2]}${app_repo_dist_sel}${c[end]}"
                    printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Command${c[end]}" "${c[grey1]}reprepro -V --section utils --component main --priority 0 --architecture $arch includedeb ${app_repo_dist_sel} ${deb_package}${c[end]}"

                    if [ -n "${bRepreproInstalled}" ] && [ "${argDryRun}" = false ]; then
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
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
                        fi

                        # #
                        #   aptget > architecture > arm64 > reprepro
                        #
                        #   output > package already added but checksums are different
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "Already existing files" ; then
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists; bad checksums. Removing ${c[yellow]}${app_filename}${c[end]} from ${c[yellow]}Reprepro${c[end]} and re-adding${c[end]}"
                            reprepro remove "${app_repo_dist_sel}" "${app_filename}"

                            reprepro_exit_code="0"
                            reprepro_output="$(reprepro -V \
                                --section utils \
                                --component main \
                                --priority 0 \
                                --architecture ${arch} \
                                includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                "$@" 2>&1)" \
                                || { reprepro_exit_code="$?" ; true; };
                        fi

                        # #
                        #   architecture > arm64 > reprepro
                        #
                        #   output > new package added
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "✅ New package added (${c[green]}${deb_package}${c[end]}) for ${c[green]}${app_repo_dist_sel}${c[end]}"
                        fi
                    else
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Skip addition; reprepro not installed or in dryrun mode (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
                    fi

                    bNewPackage=false

                # #
                #   architecture > i386
                #   file must end with 'i386.deb'
                # #

                elif [[ "$arch" == "i386" || "$arch" == "386" ]] && [[ $app_filename == *i386.deb || $app_filename == *i386*.deb || $app_filename == *386.deb || $app_filename == *386*.deb ]]; then
                    printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Download${c[end]}" "${c[fuchsia2]}${app_url}${c[end]}"

                    # #
                    #   architecture > i386
                    #   move package to its final location inside the reprepro directory
                    #       move    ${HOME}/proteus/networkd-dispatcher_2.1-2ubuntu0.22.04.i386.deb
                    #       to      ${HOME}/proteus/incoming/packages/jammy/i386/networkd-dispatcher_2.1-2ubuntu0.22.04.i386.deb
                    # #

                    if [ -f $app_dir/$app_filename ]; then
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Move${c[end]}" "${c[fuchsia2]}${app_dir}/${app_filename}${c[end]} to ${c[fuchsia2]}$app_dir/$app_dir_incoming/i386/${c[end]}"
                        mv "${app_dir}/${app_filename}" "$app_dir/$app_dir_incoming/i386/"
                    fi

                    # #
                    #   architecture > i386 > full package path
                    #
                    #       deb_package             incoming/packages/jammy/i386/networkd-dispatcher_2.1-2ubuntu0.22.04.i386.deb
                    # #

                    deb_package="${app_dir_incoming}/${arch}/${app_filename}"

                    # #
                    #   architecture > i386 > reprepro
                    #   add package to reprepro database
                    #
                    #       app_repo_dist_sel       jammy
                    #       deb_package             incoming/packages/jammy/i386/networkd-dispatcher_2.1-2ubuntu0.22.04.i386.deb
                    # #

                    printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Reprepro${c[end]}" "${c[fuchsia2]}${deb_package}${c[end]} for dist ${c[fuchsia2]}${app_repo_dist_sel}${c[end]}"
                    printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Command${c[end]}" "${c[grey1]}reprepro -V --section utils --component main --priority 0 --architecture $arch includedeb ${app_repo_dist_sel} ${deb_package}${c[end]}"

                    if [ -n "${bRepreproInstalled}" ] && [ "${argDryRun}" = false ]; then
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
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
                        fi

                        # #
                        #   aptget > architecture > i386 > reprepro
                        #
                        #   output > package already added but checksums are different
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "Already existing files" ; then
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists; bad checksums. Removing ${c[yellow]}${app_filename}${c[end]} from ${c[yellow]}Reprepro${c[end]} and re-adding${c[end]}"
                            reprepro remove "${app_repo_dist_sel}" "${app_filename}"

                            reprepro_exit_code="0"
                            reprepro_output="$(reprepro -V \
                                --section utils \
                                --component main \
                                --priority 0 \
                                --architecture ${arch} \
                                includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                "$@" 2>&1)" \
                                || { reprepro_exit_code="$?" ; true; };
                        fi

                        # #
                        #   architecture > i386 > reprepro
                        #
                        #   output > new package added
                        # #

                        if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "✅ New package added (${c[green]}${deb_package}${c[end]}) for ${c[green]}${app_repo_dist_sel}${c[end]}"
                        fi
                    else
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Skip addition; reprepro not installed or in dryrun mode (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
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
                    printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "⭕ Already exists under different architecture ${c[orange]}${app_dir}/${app_filename}${c[end]}"
                fi
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

    mkdir -p "$app_dir/$app_dir_incoming/{all,amd64,arm64,i386}"

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
                echo -e "     ${c[grey2]}|--- ${c[yellow]}[ ${count} ]${c[fuchsia1]}${c[bold]} ${app_filename:0:100}${c[end]}"
            else
                echo -e "               ${c[fuchsia1]}${c[bold]} ${app_filename:0:100}${c[end]}"
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
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Package${c[end]}" "${c[fuchsia2]}${arch}${c[end]}"
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}File${c[end]}" "${c[fuchsia2]}${app_filename}${c[end]}"
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Download${c[end]}" "${c[fuchsia2]}${repo_file_url}${c[end]}"

                        # #
                        #   architecture > all
                        #   move package to its final location inside the reprepro directory
                        #       move    ${HOME}/Repos/GitHubDesktop-linux-all-3.4.2-linux1.deb
                        #       to      ${HOME}/Repos/incoming/packages/jammy/all/
                        # #

                        if [ -f $app_dir/$app_filename ]; then
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Move${c[end]}" "${c[fuchsia2]}${app_dir}/${app_filename}${c[end]} to ${c[fuchsia2]}$app_dir/$app_dir_incoming/all/${c[end]}"
                            mv "$app_dir/$app_filename" "$app_dir/$app_dir_incoming/all/"
                        fi

                        # #
                        #   architecture > all > full package path
                        #
                        #       deb_package             incoming/packages/jammy/all/GitHubDesktop-linux-all-3.4.2-linux1.deb
                        # #

                        deb_package="$app_dir_incoming/${arch}/${app_filename}"

                        # #
                        #   architecture > all > reprepro
                        #   add package to reprepro database
                        #
                        #       app_repo_dist_sel       jammy
                        #       deb_package             incoming/packages/jammy/all/GitHubDesktop-linux-all-3.4.2-linux1.deb
                        # #

                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Reprepro${c[end]}" "${c[fuchsia2]}${deb_package}${c[end]} for dist ${c[fuchsia2]}${app_repo_dist_sel}${c[end]}"
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Command${c[end]}" "${c[grey1]}reprepro -V --section utils --component main --priority 0 includedeb ${app_repo_dist_sel} ${deb_package}${c[end]}"

                        if [ -n "${bRepreproInstalled}" ] && [ "${argDryRun}" = false ]; then
                            reprepro_exit_code="0"
                            reprepro_output="$(reprepro -V \
                                --section utils \
                                --component main \
                                --priority 0 \
                                includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                "$@" 2>&1)" \
                                || { reprepro_exit_code="$?" ; true; };

                                reprepro_output=${reprepro_output//$'\n'/}          # Remove all newlines.
                                reprepro_output=${reprepro_output%$'\n'}            # Remove a trailing newline.

                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Response${c[end]}" "${c[grey1]}${reprepro_output}${c[end]}"

                            # #
                            #   architecture > all > reprepro
                            #
                            #   output > package already added to reprepro
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "exists" ; then
                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
                            fi

                            # #
                            #   github > architecture > all > reprepro
                            #
                            #   output > package already added but checksums are different
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "Already existing files" ; then
                                local pkgRemove=${lst_github[0]}        #  Aetherinox/opengist-debian
                                pkgRemove="${pkgRemove##*/}"            #  opengist-debian
                                pkgRemove="${pkgRemove%-*}"             #  opengist
                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists; bad checksums. Removing ${c[yellow]}${app_filename}${c[end]} from ${c[yellow]}Reprepro${c[end]} and re-adding${c[end]}"
                                reprepro remove "${app_repo_dist_sel}" "${pkgRemove}"

                                reprepro_exit_code="0"
                                reprepro_output="$(reprepro -V \
                                    --section utils \
                                    --component main \
                                    --priority 0 \
                                    includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                    "$@" 2>&1)" \
                                    || { reprepro_exit_code="$?" ; true; };
                            fi

                            # #
                            #   architecture > all > reprepro
                            #
                            #   output > new package added
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "✅ New package added (${c[green]}${deb_package}${c[end]}) for ${c[green]}${app_repo_dist_sel}${c[end]}"
                            fi
                        else
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Skip addition; reprepro not installed or in dryrun mode (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
                        fi

                        echo -e
                        bNewPackage=false

                    elif [[ "$arch" == "amd64" ]] && [[ $app_filename == *amd64.deb || $app_filename == *amd64*.deb ]]; then
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Package${c[end]}" "${c[fuchsia2]}${arch}${c[end]}"
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}File${c[end]}" "${c[fuchsia2]}${app_filename}${c[end]}"
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Download${c[end]}" "${c[fuchsia2]}${repo_file_url}${c[end]}"

                        # #
                        #   architecture > amd64
                        #   move package to its final location inside the reprepro directory
                        #       move    /home/aetherx/Repos/GitHubDesktop-linux-amd64-3.4.2-linux1.deb
                        #       to      /home/aetherx/Repos/incoming/packages/jammy/amd64/
                        # #

                        if [ -f $app_dir/$app_filename ]; then
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Move${c[end]}" "${c[fuchsia2]}${app_dir}/${app_filename}${c[end]} to ${c[fuchsia2]}$app_dir/$app_dir_incoming/amd64/${c[end]}"
                            mv "$app_dir/$app_filename" "$app_dir/$app_dir_incoming/amd64/"
                        fi

                        # #
                        #   architecture > amd64 > full package path
                        #
                        #       deb_package             incoming/packages/jammy/amd64/GitHubDesktop-linux-amd64-3.4.2-linux1.deb
                        # #

                        deb_package="$app_dir_incoming/$arch/$app_filename"

                        # #
                        #   architecture > amd64 > reprepro
                        #   add package to reprepro database
                        #
                        #       app_repo_dist_sel       jammy
                        #       deb_package             incoming/packages/jammy/amd64/GitHubDesktop-linux-amd64-3.4.2-linux1.deb
                        # #

                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Reprepro${c[end]}" "${c[fuchsia2]}${deb_package}${c[end]} for dist ${c[fuchsia2]}${app_repo_dist_sel}${c[end]}"
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Command${c[end]}" "${c[grey1]}reprepro -V --section utils --component main --priority 0 --architecture $arch includedeb ${app_repo_dist_sel} ${deb_package}${c[end]}"

                        if [ -n "${bRepreproInstalled}" ] && [ "${argDryRun}" = false ]; then
                            reprepro_exit_code="0"
                            reprepro_output="$(reprepro -V \
                                --section utils \
                                --component main \
                                --priority 0 \
                                --architecture $arch \
                                includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                "$@" 2>&1)" \
                                || { reprepro_exit_code="$?" ; true; };

                                reprepro_output=${reprepro_output//$'\n'/}          # Remove all newlines.
                                reprepro_output=${reprepro_output%$'\n'}            # Remove a trailing newline.

                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Response${c[end]}" "${c[grey1]}${reprepro_output}${c[end]}"

                            # #
                            #   architecture > amd64 > reprepro
                            #
                            #   output > package already added to reprepro
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "exists" ; then
                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
                            fi

                            # #
                            #   github > architecture > amd64 > reprepro
                            #
                            #   output > package already added but checksums are different
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "Already existing files" ; then
                                local pkgRemove=${lst_github[0]}        #  Aetherinox/opengist-debian
                                pkgRemove="${pkgRemove##*/}"            #  opengist-debian
                                pkgRemove="${pkgRemove%-*}"             #  opengist
                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists; bad checksums. Removing ${c[yellow]}${app_filename}${c[end]} from ${c[yellow]}Reprepro${c[end]} and re-adding${c[end]}"
                                reprepro remove "${app_repo_dist_sel}" "${pkgRemove}"

                                reprepro_exit_code="0"
                                reprepro_output="$(reprepro -V \
                                    --section utils \
                                    --component main \
                                    --priority 0 \
                                    --architecture $arch \
                                    includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                    "$@" 2>&1)" \
                                    || { reprepro_exit_code="$?" ; true; };
                            fi

                            # #
                            #   architecture > amd64 > reprepro
                            #
                            #   output > new package added
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "✅ New package added (${c[green]}${deb_package}${c[end]}) for ${c[green]}${app_repo_dist_sel}${c[end]}"
                            fi
                        else
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Skip addition; reprepro not installed or in dryrun mode (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
                        fi

                        echo -e
                        bNewPackage=false
 
                    elif [[ "$arch" == "arm64" ]] && [[ $app_filename == *arm64.deb || $app_filename == *arm64*.deb ]]; then
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Package${c[end]}" "${c[fuchsia2]}${arch}${c[end]}"
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}File${c[end]}" "${c[fuchsia2]}${app_filename}${c[end]}"
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Download${c[end]}" "${c[fuchsia2]}${repo_file_url}${c[end]}"

                        # #
                        #   architecture > arm64
                        #   move package to its final location inside the reprepro directory
                        #       move    /home/aetherx/Repos/GitHubDesktop-linux-arm64-3.4.2-linux1.deb
                        #       to      /home/aetherx/Repos/incoming/packages/jammy/arm64/
                        # #

                        if [ -f $app_dir/$app_filename ]; then
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Move${c[end]}" "${c[fuchsia2]}${app_dir}/${app_filename}${c[end]} to ${c[fuchsia2]}$app_dir/$app_dir_incoming/arm64/${c[end]}"
                            mv "$app_dir/$app_filename" "$app_dir/$app_dir_incoming/arm64/"
                        fi

                        # #
                        #   architecture > arm64 > full package path
                        #
                        #       deb_package             incoming/packages/jammy/arm64/GitHubDesktop-linux-arm64-3.4.2-linux1.deb
                        # #

                        deb_package="$app_dir_incoming/$arch/$app_filename"

                        # #
                        #   architecture > arm64 > reprepro
                        #   add package to reprepro database
                        #
                        #       app_repo_dist_sel       jammy
                        #       deb_package             incoming/packages/jammy/arm64/GitHubDesktop-linux-arm64-3.4.2-linux1.deb
                        # #

                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Reprepro${c[end]}" "${c[fuchsia2]}${deb_package}${c[end]} for dist ${c[fuchsia2]}${app_repo_dist_sel}${c[end]}"
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Command${c[end]}" "${c[grey1]}reprepro -V --section utils --component main --priority 0 --architecture $arch includedeb ${app_repo_dist_sel} ${deb_package}${c[end]}"

                        if [ -n "${bRepreproInstalled}" ] && [ "${argDryRun}" = false ]; then
                            reprepro_exit_code="0"
                            reprepro_output="$(reprepro -V \
                                --section utils \
                                --component main \
                                --priority 0 \
                                --architecture $arch \
                                includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                "$@" 2>&1)" \
                                || { reprepro_exit_code="$?" ; true; };

                                reprepro_output=${reprepro_output//$'\n'/}          # Remove all newlines.
                                reprepro_output=${reprepro_output%$'\n'}            # Remove a trailing newline.

                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Response${c[end]}" "${c[grey1]}${reprepro_output}${c[end]}"

                            # #
                            #   architecture > arm64 > reprepro
                            #
                            #   output > package already added to reprepro
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "exists" ; then
                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
                            fi

                            # #
                            #   github > architecture > arm64 > reprepro
                            #
                            #   output > package already added but checksums are different
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "Already existing files" ; then
                                local pkgRemove=${lst_github[0]}        #  Aetherinox/opengist-debian
                                pkgRemove="${pkgRemove##*/}"            #  opengist-debian
                                pkgRemove="${pkgRemove%-*}"             #  opengist
                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists; bad checksums. Removing ${c[yellow]}${app_filename}${c[end]} from ${c[yellow]}Reprepro${c[end]} and re-adding${c[end]}"
                                reprepro remove "${app_repo_dist_sel}" "${pkgRemove}"

                                reprepro_exit_code="0"
                                reprepro_output="$(reprepro -V \
                                    --section utils \
                                    --component main \
                                    --priority 0 \
                                    --architecture $arch \
                                    includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                    "$@" 2>&1)" \
                                    || { reprepro_exit_code="$?" ; true; };
                            fi

                            # #
                            #   architecture > arm64 > reprepro
                            #
                            #   output > new package added
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "✅ New package added (${c[green]}${deb_package}${c[end]}) for ${c[green]}${app_repo_dist_sel}${c[end]}"
                            fi
                        else
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Skip addition; reprepro not installed or in dryrun mode (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
                        fi

                        echo -e
                        bNewPackage=false

                    elif [[ "$arch" == "i386" || "$arch" == "386" ]] && [[ $app_filename == *i386.deb || $app_filename == *i386*.deb || $app_filename == *386.deb || $app_filename == *386*.deb ]]; then
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Package${c[end]}" "${c[fuchsia2]}${arch}${c[end]}"
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}File${c[end]}" "${c[fuchsia2]}${app_filename}${c[end]}"
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Download${c[end]}" "${c[fuchsia2]}${repo_file_url}${c[end]}"

                        # #
                        #   architecture > i386
                        #   move package to its final location inside the reprepro directory
                        #       move    /home/aetherx/Repos/GitHubDesktop-linux-i386-3.4.2-linux1.deb
                        #       to      /home/aetherx/Repos/incoming/packages/jammy/i386/
                        # #

                        if [ -f $app_dir/$app_filename ]; then
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Move${c[end]}" "${c[fuchsia2]}${app_dir}/${app_filename}${c[end]} to ${c[fuchsia2]}$app_dir/$app_dir_incoming/i386/${c[end]}"
                            mv "$app_dir/$app_filename" "$app_dir/$app_dir_incoming/i386/"
                        fi

                        # #
                        #   architecture > i386 > full package path
                        #
                        #       deb_package             incoming/packages/jammy/i386/GitHubDesktop-linux-i386-3.4.2-linux1.deb
                        # #

                        deb_package="$app_dir_incoming/$arch/$app_filename"

                        # #
                        #   architecture > i386 > reprepro
                        #   add package to reprepro database
                        #
                        #       app_repo_dist_sel       jammy
                        #       deb_package             incoming/packages/jammy/i386/GitHubDesktop-linux-i386-3.4.2-linux1.deb
                        # #

                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Reprepro${c[end]}" "${c[fuchsia2]}${deb_package}${c[end]} for dist ${c[fuchsia2]}${app_repo_dist_sel}${c[end]}"
                        printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Command${c[end]}" "${c[grey1]}reprepro -V --section utils --component main --priority 0 --architecture $arch includedeb ${app_repo_dist_sel} ${deb_package}${c[end]}"

                        if [ -n "${bRepreproInstalled}" ] && [ "${argDryRun}" = false ]; then
                            reprepro_exit_code="0"
                            reprepro_output="$(reprepro -V \
                                --section utils \
                                --component main \
                                --priority 0 \
                                --architecture $arch \
                                includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                "$@" 2>&1)" \
                                || { reprepro_exit_code="$?" ; true; };

                                reprepro_output=${reprepro_output//$'\n'/}          # Remove all newlines.
                                reprepro_output=${reprepro_output%$'\n'}            # Remove a trailing newline.

                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Response${c[end]}" "${c[grey1]}${reprepro_output}${c[end]}"

                            # #
                            #   architecture > i386 > reprepro
                            #
                            #   output > package already added to reprepro
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "exists" ; then
                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
                            fi

                            # #
                            #   github > architecture > i386 > reprepro
                            #
                            #   output > package already added but checksums are different
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "Already existing files" ; then
                                local pkgRemove=${lst_github[0]}        #  Aetherinox/opengist-debian
                                pkgRemove="${pkgRemove##*/}"            #  opengist-debian
                                pkgRemove="${pkgRemove%-*}"             #  opengist
                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists; bad checksums. Removing ${c[yellow]}${app_filename}${c[end]} from ${c[yellow]}Reprepro${c[end]} and re-adding${c[end]}"
                                reprepro remove "${app_repo_dist_sel}" "${pkgRemove}"

                                reprepro_exit_code="0"
                                reprepro_output="$(reprepro -V \
                                    --section utils \
                                    --component main \
                                    --priority 0 \
                                    --architecture $arch \
                                    includedeb "${app_repo_dist_sel}" "${deb_package}" \
                                    "$@" 2>&1)" \
                                    || { reprepro_exit_code="$?" ; true; };
                            fi

                            # #
                            #   architecture > i386 > reprepro
                            #
                            #   output > new package added
                            # #

                            if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "✅ New package added (${c[green]}${deb_package}${c[end]}) for ${c[green]}${app_repo_dist_sel}${c[end]}"
                            fi
                        else
                            printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Skip addition; reprepro not installed or in dryrun mode (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
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

    cd ${app_dir}

    #   ensure git config is updated
    app_run_github_precheck

    #   add origin
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git remote add origin https://github.com/${CSI_GITHUB_NAME}/${app_repo_apt}.git${c[end]}"
    fi
    if [ "${argDryRun}" = false ] && [ "${argSkipGitCommit}" = false ]; then
        git remote add origin https://github.com/${CSI_GITHUB_NAME}/${app_repo_apt}.git
    fi


    #   remove all changes and sync with remote repo
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git fetch --prune${c[end]}"
    fi
    if [ "${argDryRun}" = false ] && [ "${argSkipGitCommit}" = false ]; then
        git fetch --prune
    fi

    #   force head to match with remote repo
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git reset --hard origin/${app_repo_branch}${c[end]}"
    fi
    if [ "${argDryRun}" = false ] && [ "${argSkipGitCommit}" = false ]; then
        git reset --hard origin/${app_repo_branch}
    fi

    # #
    #   must have at least one commit for this to work
    #   -m / --move flag to rename a branch in our local repository
    # #

    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git branch -m ${app_repo_branch}${c[end]}"
    fi
    if [ "${argDryRun}" = false ] && [ "${argSkipGitCommit}" = false ]; then
        git branch -m ${app_repo_branch}
    fi

    # #
    #   .app folder
    # #

    local manifest_dir="${app_dir}/.app"
    mkdir -p "${manifest_dir}"

    # #
    #   .app folder > create .json
    # #

    printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Creating ${c[yellow]}${manifest_dir}/${app_repo_dist_sel}.json${c[end]}"

sudo tee ${manifest_dir}/${app_repo_dist_sel}.json >/dev/null <<EOF
{
"name":             "${app_title}",
"version":          "$(get_version)",
"author":           "${CSI_GITHUB_NAME}",
"description":      "${app_about}",
"distrib":          "${app_repo_dist_sel}",
"url":              "${app_repo_url}",
"last_duration":    "...........",
"last_update":      "Running ...............",
"last_update_ts":   "${DATE_TS}"
}
EOF

    echo -e
    echo -e "              ${c[grey2]}" "\"name\": ${c[fuchsia2]}\"${app_title}\"${c[end]}"
    echo -e "              ${c[grey2]}" "\"version\": ${c[fuchsia2]}\"$(get_version)\"${c[end]}"
    echo -e "              ${c[grey2]}" "\"author\": ${c[fuchsia2]}\"${CSI_GITHUB_NAME}\"${c[end]}"
    echo -e "              ${c[grey2]}" "\"description\": ${c[fuchsia2]}\"${app_about}\"${c[end]}"
    echo -e "              ${c[grey2]}" "\"distrib\": ${c[fuchsia2]}\"${app_repo_dist_sel}\"${c[end]}"
    echo -e "              ${c[grey2]}" "\"url\": ${c[fuchsia2]}\"${app_repo_url}\"${c[end]}"
    echo -e "              ${c[grey2]}" "\"last_duration\": ${c[fuchsia2]}\"...........\"${c[end]}"
    echo -e "              ${c[grey2]}" "\"last_update\": ${c[fuchsia2]}\"Running ...............\"${c[end]}"
    echo -e "              ${c[grey2]}" "\"last_update_ts\": ${c[fuchsia2]}\"${DATE_TS}\"${c[end]}"

    echo -e

    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git pull origin ${app_repo_branch} --allow-unrelated-histories${c[end]}"
    fi
    if [ "${argDryRun}" = false ] && [ "${argSkipGitCommit}" = false ]; then
        git_pull=$( git pull origin ${app_repo_branch} --allow-unrelated-histories )
    else
        git_pull="In Devnull Run"
    fi

    echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
    echo -e "  ${c[end]}Git Pull: ${c[yellow]}${git_pull}${c[end]}"
    echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
    echo

    # #
    #   git add -A, --all     stages all changes
    #   git add .             stages new files and modifications, without deletions (on the current directory and its subdirectories).
    #   git add -u            stages modifications and deletions, without new files
    # #

    printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Committing new packages to git branch ${c[yellow]}${app_repo_branch}${c[end]}"
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git add --all${c[end]}"
    fi
    if [ "${argDryRun}" = false ] && [ "${argSkipGitCommit}" = false ]; then
        git add --all
    fi

    # #
    #   github > commit > start message
    # #

    local NOW=$(date -u '+%m.%d.%Y %H:%M:%S')
    local app_repo_commit="build(start): \`️📦 auto-update 📦\` \`${app_repo_dist_sel} | ${NOW} UTC\`"
    if [ -n "${argAptPackage}" ]; then
        local pkg=${lst_packages[0]}
        app_repo_commit="build(start): \`📦 pkg-update (apt-get) : ${pkg} 📦\` \`${app_repo_dist_sel} | ${NOW} UTC\`"
    fi
    if [ -n "${argGithubPackage}" ]; then
        local pkg=${lst_github[0]}
        app_repo_commit="build(start): \`📦 pkg-update (github) : ${pkg} 📦\` \`${app_repo_dist_sel} | ${NOW} UTC\`"
    fi

    # #
    #   github > commit > start > run
    #   
    #   The command below can throw the following errors:
    #   
    #       error: gpg failed to sign the data:
    #       gpg: skipped "!": No secret key
    #       [GNUPG:] INV_SGNR 9 !
    #       [GNUPG:] FAILURE sign 17
    #       gpg: signing failed: No secret key
    # #

    printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Git commit message: ${c[yellow]}${app_repo_commit}${c[end]}"
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git commit -S -m ${app_repo_commit}${c[end]}"
    fi
    if [ "${argDryRun}" = false ] && [ "${argSkipGitCommit}" = false ]; then
        git commit -S -m "${app_repo_commit}"
    fi

    printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Pushing changes to git repo ${c[yellow]}${app_repo_branch}${c[end]}"
    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git push https://${CSI_PAT_GITHUB}@github.com/${CSI_GITHUB_NAME}/${app_repo_apt}${c[end]}"
    fi
    if [ "${argDryRun}" = false ] && [ "${argSkipGitCommit}" = false ]; then
        git push https://${CSI_PAT_GITHUB}@github.com/${CSI_GITHUB_NAME}/${app_repo_apt}
    fi

}

# #
#   Github > End
#   
#   push all packages / upload to proteus apt repo
# #

app_run_gh_end()
{

    cd ${app_dir}

    # #
    #   originally to delete left-behind .deb files; we used compgen
    #       if compgen -G "${app_dir}/*.deb" > /dev/null; then
    #           echo -e "  ${c[grey2]}Cleaning up left-over .deb: ${c[yellow]}${app_dir}/*.deb${c[end]}"
    #           rm ${app_dir}/*.deb >/dev/null
    #       fi
    #   
    #   alternative method:
    #       test command:       find . -maxdepth 1 -name "*.deb*" -type f
    #       delete command:     find . -maxdepth 1 -name "*.deb*" -type f -delete
    #   
    # #

    if compgen -G "${app_dir}/*.deb*" > /dev/null; then
        echo -e "  ${c[grey2]}Cleaning up left-over .deb: ${c[yellow]}${app_dir}/*.deb${c[end]}"
        rm ${app_dir}/*.deb* >/dev/null
    fi

    app_run_github_precheck

    echo
    echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
    echo -e "  ${c[grey2]}Updating Github: $app_repo_branch${c[end]}"
    echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
    echo

    # #
    #   must have at least one commit for this to work
    #   -m / --move flag to rename a branch in our local repository
    # #

    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git branch -m ${app_repo_branch}${c[end]}"
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git add --all${c[end]}"
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git add -u${c[end]}"
    fi
    if [ "${argDryRun}" = false ] && [ "${argSkipGitCommit}" = false ]; then
        git branch -m ${app_repo_branch}
        git add --all
        git add -u
    fi

    # #
    #   github > commit > end message
    # #

    local NOW=$(date -u '+%m.%d.%Y %H:%M:%S')
    local app_repo_commit="build(end): \`📦 auto-update 📦\` \`${app_repo_dist_sel} | ${NOW} UTC\`"
    if [ -n "${argAptPackage}" ]; then
        local pkg=${lst_packages[0]}
        app_repo_commit="build(end): \`📦 pkg-update (apt-get) : ${pkg} 📦\` \`${app_repo_dist_sel} | ${NOW} UTC\`"
    fi
    if [ -n "${argGithubPackage}" ]; then
        local pkg=${lst_github[0]}
        app_repo_commit="build(end): \`📦 pkg-update (github) : ${pkg} 📦\` \`${app_repo_dist_sel} | ${NOW} UTC\`"
    fi

    # #
    #   github > commit > end > run
    #   
    #   The command below can throw the following errors:
    #   
    #       error: gpg failed to sign the data:
    #       gpg: skipped "!": No secret key
    #       [GNUPG:] INV_SGNR 9 !
    #       [GNUPG:] FAILURE sign 17
    #       gpg: signing failed: No secret key
    # #

    if [ "${argDevEnabled}" = true ]; then
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git commit -S -m \"$app_repo_commit\"${c[end]}"
        printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git push https://${CSI_PAT_GITHUB}@github.com/${CSI_GITHUB_NAME}/${app_repo_apt}${c[end]}"
    fi
    if [ "${argDryRun}" = false ] && [ "${argSkipGitCommit}" = false ]; then
        git commit -S -m "$app_repo_commit"
        # can use -u, --set-upstream
        git push https://${CSI_PAT_GITHUB}@github.com/${CSI_GITHUB_NAME}/${app_repo_apt}
    fi
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
    mkdir -p "${manifest_dir}"

    # #
    #   duration elapsed
    # #

    duration=${SECONDS}
    elapsed="$((${duration} / 60))m $(( ${duration} % 60 ))s"

    # #
    #   .app folder > create .json
    # #

sudo tee "${manifest_dir}/${app_repo_dist_sel}.json" >/dev/null <<EOF
{
    "name":             "${app_title}",
    "version":          "$(get_version)",
    "author":           "${CSI_GITHUB_NAME}",
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

    if [ ! -d "${app_dir}/.app" ]; then
        printf '%-29s %-65s\n' "  ${c[red]}ERROR${c[end]}" "Skipping tree generation; folder ${c[red]}${app_dir}/.app${c[end]} does not exist${c[end]}"
        return
    fi

    sudo chown -R "${USER}:${USER}" "${app_dir}/.app" >> ${LOGS_FILE} 2>&1

    tree_output=$( sudo tree -a -I ".git" -I "logs" -I "docs" -I ".gpg" -I "incoming" --dirsfirst )
    sudo tree -a -I ".git" --dirsfirst -J > ${manifest_dir}/tree.json

    # #
    #   useful for Gitea with HTML rendering plugin, not useful for Github
    #   tree -a --dirsfirst -I '.git' -H https://github.com/${CSI_GITHUB_NAME}/${app_repo_script}/src/branch/$app_repo_branch/ -o $app_dir/.data/tree.html
    # #

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
        echo -e "  ${c[bold]}${c[orange]}WARNING  ${c[end]}Reprepro Missing${c[end]}"
        echo -e "  ${c[bold]}${c[end]}It appears the package ${c[fuchsia1]}Reprepro${c[end]} is missing.${c[end]}"
        echo
        echo -e "  ${c[bold]}${c[end]}Try installing the package with:${c[end]}"
        echo -e "  ${c[bold]}${c[end]}     sudo apt-get update${c[end]}"
        echo -e "  ${c[bold]}${c[end]}     sudo apt-get install reprepro${c[end]}"
        echo

        printf "  Press any key to abort ... ${c[end]}"
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

    if [ -n "${argOnlyGithub}" ]; then
        app_run_gh_start
        if [ -z "${argAptPackage}" ]; then
            app_run_dl_lastver                          #   fetch github packages only if we haven't specified a apt-get package manually
        fi
        app_run_tree_update
        app_run_gh_end
    elif [ -n "${argOnlyAptget}" ]; then
        app_run_gh_start
        if [ -z "${argGithubPackage}" ]; then
            app_run_dl_aptget                           #   fetch aptget packages only if we haven't specified a github package manually
        fi
        app_run_tree_update
        app_run_gh_end
    else
        app_run_gh_start
        if [ -z "${argGithubPackage}" ]; then
            app_run_dl_aptget                           #   fetch aptget packages only if we haven't specified a github package manually
        fi
        if [ -z "${argAptPackage}" ]; then
            app_run_dl_lastver                          #   fetch github packages only if we haven't specified a apt-get package manually
        fi
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
    echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
    echo -e "  ${c[grey2]}Total Execution Time: $elapsed${c[end]}"
    echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
    echo

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

# #
#   command-line options
#   
#   reminder that any functions which need executed must be defined BEFORE this point. Bash sucks like that.
#   
#   -A, --only-apt                    only download pkgs from apt-get; do not download packages from github using lastversion
#   -G, --only-git                    only download pkgs from github using lastversion; do not download from apt-get
#   -p, --apt-package                 add new pkg from apt-get for distro you are currently running
#                                     cannot specify different distro (jammy, noble, etc)
#                                     does not add pkg to bash script list (it is a one-time update)
#   -g, --git-package                 add new pkg from github for distro you are currently running
#                                     cannot specify different distro (jammy, noble, etc)
#                                     does not add pkg to bash script list (it is a one-time update)
#   -l, --local-package               add new local .deb package in root folder of proteus
#                                     can specify different distro (jammy, noble, etc) using --dist "jammy"
#                                     can specify different arch (amd64, arm64, i386) using --arch "amd64"
#                                         proteus --dist "jammy" --arch "amd64" --local-package "reprepro_5.4.7-1_amd64.deb"
#   -U, --url-package                 get online repo url that a package is hosted from
#   -L, --list-packages               list installed apt-get packages
#   -O, --list-packages-local         list local manually installed packages; usually installed using dpkg -i "packagename.deb"
#   -f, --fixperms                    fix permissions and owner for script proteus; optional owner arg root ($argChownOwner)
#   -R, --reset                       reset local repo files to state of remote git branch by performing git reset --hard origin/main; optional git branch arg
#   -t, --dist                        specifies a specific distribution out of box, this script finds the distribution
#                                     of the machine you are running. you may override it with this option.
#                                         jammy, lunar, focal, noble, etc
#   -a, --arch                        specify architecture for pkgs when used with  -l, --local-package to add pkg to different dist; <default> amd64
#                                         amd64, arm64, i386 
#   -S,  --skip-commit                runs script; but only registers new pkgs with reprepro; no github commits
#   -D,  --dryrun                     runs script; does not download pkgs; does not add pkg to reprepro; does not commit to git
#   -k,  --kill                       force running instances of script to be killed
#   -r,  --report                     show stats about pkgs, variables, etc.
#   -c,  --clean                      remove lingering .deb files from file structure left behind
#   -s,  --setup                      runs initial setup; installs any pkgs required by script
#                                         apt-move, apt-url, curl, wget, tree, reprepro, lastversion
#   -u,  --update <string>            download new version of script from github
#   -b,  --branch <string>            specifies update branch; used with option -u, --update <default> main
#   -d,  --dev                        developer mode; verbose logging     
#   -h,  --help                       show this help menu   
# #

while [ $# -gt 0 ]; do
    case "$1" in

        # #
        #   runs the script but only downloads packages from apt-get
        #   
        #   @usage              proteus -A
        #                       proteus --only-apt
        # #

        -A|--onlyAptget|--onlyApt|--only-apt)
            argOnlyAptget=true
            ;;

        # #
        #   runs the script but only downloads packages from github
        #   
        #   @usage              proteus -G
        #                       proteus --only-git
        # #

        -G|--onlyGithub|--onlygit|--only-git|--only-github)
            argOnlyGithub=true
            ;;

        # #
        #   downloads a package directly from apt-get using apt-move and apt-url
        #   
        #   @usage              proteus -p package-name
        #                       proteus --apt-package reprepro
        # #

        -p|-ap|--package|--add-package|--add-apt-package|--apt-package|--package-apt|--package-aptget|--package-apt-get|--package-apt)
            if [[ "$1" != *=* ]]; then shift; fi
            argAptPackage="${1#*=}"

            lst_packages=(
                "${argAptPackage}"
            )
            ;;

        # #
        #   downloads a package directly from a github repo.
        #   package names are usually the username/repo-name of the Github repository.
        #   
        #   @usage              proteus -g package-name
        #                       proteus --add-github-package shiftkey/desktop
        # #

        -g|-gp|--add-github-package|--github-package|--add-git-package|--git-package|--github-package|--package-git|--package-github)
            if [[ "$1" != *=* ]]; then shift; fi
            argGithubPackage="${1#*=}"

            lst_github=(
                "${argGithubPackage}"
            )
            ;;

        # #
        #   adds a local .deb file without downloading it from github or apt-get
        #   
        #   @usage              proteus --dev --dist "jammy" --arch "arm64" --add-local-package "reprepro_5.4.7-1_amd64.deb"
        #                       proteus --dryrun --dev --dist "jammy" --arch "arm64" --add-local-package "reprepro_5.4.7-1_amd64.deb"
        #                       proteus -d -t "focal" -a "amd64" -l "reprepro_5.4.7-1_amd64.deb"
        # #

        -l|-lp|--add-local-package|--local-package|--package-local)
            if [[ "$1" != *=* ]]; then shift; fi
            argLocalPackage="${1#*=}"
            ;;

        # #
        #   resets the local repo files back to the state of the remote proteus repo (git reset --hard origin/main)
        #   
        #   @usage              proteus -R main
        #                       proteus --reset main
        # #

        -R|--reset)
            if [[ "$1" != *=* ]]; then shift; fi
            argBranchReset="${1#*=}"
            if [ -z "${argBranchReset}" ]; then
                argBranchReset="${app_repo_branch}"
                printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "${c[end]}Did not specify a branch; defaulting to ${c[yellow]}${argBranchReset}${c[end]}"
                printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "Example Usage${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} --reset ${c[yellow]}\"${argBranchReset}\"${c[grey2]}${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} -R ${c[yellow]}\"main\"${c[grey2]}${c[end]}"
            fi

            printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Resetting local repository back to remote status for branch ${c[yellow]}${argBranchReset}${c[end]}"
            git reset --hard origin/${argBranchReset}
            exit 1
            ;;

        # #
        #   fixes permissions on proteus.sh and sets +x
        #   
        #   @usage              proteus -f
        #                       proteus --fixperms root
        # #

        -f|-fp|--fixperms|--fix-perms)
            if [[ "$1" != *=* ]]; then shift; fi
            argChownOwner="${1#*=}"
            if [ -z "${argChownOwner}" ]; then
                argChownOwner=root
                printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "${c[end]}Did not specify an owner; defaulting to ${c[yellow]}${argChownOwner}${c[end]}"
                printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "Example Usage${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} --fixperms ${c[yellow]}\"${argChownOwner}\"${c[grey2]}${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} -f ${c[yellow]}\"username\"${c[grey2]}${c[end]}"
            fi

            sudo chown -R "${argChownOwner}:${argChownOwner}" "${app_dir}/${app_file_this}" >> ${LOGS_FILE} 2>&1
            sudo chmod +x "${app_dir}/${app_file_this}" >> ${LOGS_FILE} 2>&1

            printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Set perms on ${c[yellow]}${app_dir}/${app_file_this}${c[end]}; chown ${c[yellow]}${argChownOwner}:${argChownOwner}${c[end]}"
            echo -e

            exit 1
            ;;

        # #
        #   sets the arch for the file
        #       amd64, arm64, i386
        #   
        #   @usage              proteus -a amd64
        #                       proteus --arch arm64
        # #

        -a|--arch|--architecture)
            if [[ "$1" != *=* ]]; then shift; fi
            argArchitecture="${1#*=}"
            if [ -z "${argArchitecture}" ]; then
                printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "${c[end]}Did not specify an architecture; must specify one to continue${c[end]}"
                printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "Example Usage${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} --architecture ${c[yellow]}\"amd64\"${c[grey2]}${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} -a ${c[yellow]}\"arm64\"${c[grey2]}${c[end]}"
                echo -e
                printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "Options${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}amd64, arm64, i386${c[end]}"

                exit 1
            fi
            ;;

        # #
        #   sets the distribution for the file
        #       focal, jammy, lunar, noble
        #   
        #   @usage              proteus -t jammy
        #                       proteus --dist lunar
        # #

        -t|--dist|--distro)
            if [[ "$1" != *=* ]]; then shift; fi
            argDistribution="${1#*=}"
            if [ -z "${argDistribution}" ]; then
                printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "${c[end]}Did not specify an architecture; must specify one to continue${c[end]}"
                printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "Example Usage${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} --distro ${c[yellow]}\"${sys_code}\"${c[grey2]}${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} -t ${c[yellow]}\"jammy\"${c[grey2]}${c[end]}"
                echo -e
                printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "Options${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}focal, jammy, lunar, noble${c[end]}"

                exit 1
            fi
            ;;

        # #
        #   runs through the process of doing all of the script actions, but doesn't actually commit to github repo
        #   and doesn't register any new packages with Reprepro
        #   
        #   @usage              proteus -D
        #                       proteus --dryrun
        # #
    
        -D|--dryrun|--dry)
            argDryRun=true
            ;;

        # #
        #   kills any instances / processes of this script currently running
        #
        #   @usage              proteus -k
        #                       proteus --kill
        # #

        -k|--kill)
            kill -9 `pgrep ${app_file_bin}`
            exit 1
            ;;

        # #
        #   gives a report to the user about set variables, paths, etc.
        #   
        #   @usage              proteus -r
        #                       proteus --report
        # #

        -r|--report)
            opt_report
            ;;

        # #
        #   originally to delete left-behind .deb files; we used compgen
        #       if compgen -G "${app_dir}/*.deb" > /dev/null; then
        #           echo -e "  ${c[grey2]}Cleaning up left-over .deb: ${c[yellow]}${app_dir}/*.deb${c[end]}"
        #           rm ${app_dir}/*.deb >/dev/null
        #       fi
        #   
        #   alternative method:
        #       test command:       find . -maxdepth 1 -name "*.deb*" -type f
        #       delete command:     find . -maxdepth 1 -name "*.deb*" -type f -delete
        #   
        # #

        -c|--clean)
            if compgen -G "${app_dir}/*.deb*" > /dev/null; then
                printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "${c[end]}Cleaning up left-over .deb: ${c[yellow]}${app_dir}/*.deb${c[end]}"
                rm ${app_dir}/*.deb* >/dev/null
            fi
            exit 1
            ;;

        # #
        #   specifies a branch to fetch Proteus updates from
        #   
        #   @usage              proteus -b main
        #                       proteus --branch dev
        # #

        -b|--branch)
            if [[ "$1" != *=* ]]; then shift; fi
            argBranch="${1#*=}"
            if [ -z "${argBranch}" ]; then
                printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "${c[end]}Did not specify a branch; must specify one to continue${c[end]}"
                printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "Example Usage${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} --branch ${c[yellow]}\"${app_repo_branch}\"${c[grey2]}${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} -b ${c[yellow]}\"dev\"${c[grey2]}${c[end]}"

                exit 1
            fi
            ;;

        # #
        #   enables developer mode; this outputs special debug prints when actions are performed.
        #   
        #   @usage              proteus -d
        #                       proteus --dev
        # #

        -d|--dev)
            argDevEnabled=true
            ;;

        # #
        #   lists all installed packages through `apt`
        #   
        #   @usage              proteus -L
        #                       proteus --list-packages
        # #

        -L|--list-packages|--package-list|--packages-list)
            apt list --installed
            exit 1
            ;;

        # #
        #   lists all manually installed packages through `apt`
        #   
        #   @usage              proteus -O
        #                       proteus --list-packages-local
        # #

        -O|--list-local|--list-local-packages|--list-local-package|--list-packages-local|--packages-local)
            comm -23 <(apt-mark showmanual | sort -u) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u)
            exit 1
            ;;

        # #
        #   gets the url to where a package originates from.
        #   gets package url from two sources:
        #       1. apt-get
        #       2. apt-url
        #   
        #   @usage              proteus -U "neofetch"
        #                       proteus --url-package "neofetch"
        # #

        -U|-pu|--url-package|--package-where|--package-url|--list-package-url|--get-package-url)
            if [[ "$1" != *=* ]]; then shift; fi
            argLocalPackage="${1#*=}"
            if [ -z "${argLocalPackage}" ]; then
                printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "${c[end]}Did not specify a package to get the URL for; must specify one to continue${c[end]}"
                printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "Example Usage${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} --url-package ${c[yellow]}\"neofetch\"${c[grey2]}${c[end]}"
                printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} -U ${c[yellow]}\"neofetch\"${c[grey2]}${c[end]}"

                exit 1
            fi

            echo -e
            printf '%-29s %-65s\n' "  ${c[yellow]}apt-url${c[end]}" "――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"

            aptget_output=
            aptget_exit_code="0"
            aptget_output="$(apt-get download \
                --print-uris \
                ${argLocalPackage} \
                "$@" 2>&1)" \
                || { aptget_exit_code="$?" ; true; };

            # #
            #   break the apt get values up into separate variables
            #       pkgName         neofetch_7.1.0-3_all.deb
            #       pkgUrl          http://us.archive.ubuntu.com/ubuntu/pool/universe/n/neofetch/neofetch_7.1.0-3_all.deb
            # #

            IFS=' ' read -r pkgUrl pkgName <<< "$aptget_output"
            pkgUrl=(${pkgUrl[@]//\'/})
            pkgName=(${pkgName[@]//\'/})

            printf '%-13s %-29s %-65s\n' " " "  ${c[grey2]}Name${c[end]}" "${c[green]}${pkgName}${c[end]}"
            printf '%-13s %-29s %-65s\n' " " "  ${c[grey2]}URL${c[end]}" "${c[green]}${pkgUrl}${c[end]}"

            echo -e

            printf '%-29s %-65s\n' "  ${c[yellow]}apt-move${c[end]}" "――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
            if [ -x "$(command -v apt-url)" ]; then
                apturl_exit_code="0"
                apturl_query="$(sudo apt-url "${argLocalPackage}" \
                    "$@" 2>&1)" \
                    || { apturl_exit_code="$?" ; true; };
    
                # #
                #   break the two apturl values up into separate variables
                #       pkgName         neofetch_7.1.0-3_all.deb
                #       pkgUrl          http://us.archive.ubuntu.com/ubuntu/pool/universe/n/neofetch/neofetch_7.1.0-3_all.deb
                # #

                pkgName=$( echo "${apturl_query}" | head -n 1; )
                pkgUrl=$( echo "${apturl_query}" | tail -n 1; )

                printf '%-13s %-29s %-65s\n' " " "  ${c[grey2]}Name${c[end]}" "${c[green]}${pkgName}${c[end]}"
                printf '%-13s %-29s %-65s\n' " " "  ${c[grey2]}URL${c[end]}" "${c[green]}${pkgUrl}${c[end]}"

            else
                printf '%-13s %-29s %-65s\n' " " "  ${c[red]}ERROR${c[end]}" "${c[end]}Package ${c[orange]}apt-url${c[end]} not installed; skipping${c[end]}"
            fi

            echo -e
            exit 1
            ;;

        # #
        #   runs everything, but skips anything related to git.
        #   no commits at all, but adds reprepro package
        #   
        #   @usage              proteus -S
        #                       proteus --skip-commit
        # #

        -S|--skip-commit|--skip-git)
            argSkipGitCommit=true
            echo -e "  ${c[fuchsia1]}${c[blink]}Adding packages to Rerepro, but no commitsd{END}"
            ;;

        # #
        #   runs app normally; but does not run logs
        #   
        #   @usage              proteus -q
        #                       proteus --quiet
        # #

        -q|--quiet)
            argNoLogs=true
            echo -e "  ${c[fuchsia1]}${c[blink]}Logging Disabled{END}"
            ;;

        -s|--setup)
            app_setup
            ;;

        -u|--update)
            argForceUpdate=true
            ;;

        # #
        #   shows version inforrmation about this script
        #
        #   @usage              proteus -v
        #                       proteus --version
        # #

        -v|--version)
            echo
            echo -e "  ${c[green]}${c[bold]}${app_title}${c[end]} - v$(get_version)${c[end]}"
            echo -e "  ${c[grey2]}${c[bold]}${app_repo_url}${c[end]}"
            echo -e "  ${c[grey2]}${c[bold]}${sys_os_name} | ${sys_os_ver}${c[end]}"
            echo
            exit 1
            ;;

        # #
        #   shows help menu
        #
        #   @usage              proteus -h
        #                       proteus --help
        # #

        -h|--help)
            opt_usage
            ;;

        # #
        #   default action if invalid flag specified. shows the help menu if the flag specified by the user
        #   does not really exist.
        #
        #   @usage              proteus -Z
        #                       proteus --afgfsdg
        # #

        *)
            opt_usage
            ;;
    esac
    shift
done

# #
#   vars > active repo branch
#   typically "main"
# #

app_repo_branch_sel=$( [[ -n "$argBranch" ]] && echo "$argBranch" || echo "$app_repo_branch"  )

# #
#   distribution
#   jammy, lunar, focal, noble, etc
# #

app_repo_dist_sel=$( [[ -n "$argDistribution" ]] && echo "$argDistribution" || echo "$sys_code"  )

# #
#   start app
# #

load_secrets

# #
#   add local packages
#   
#   local packages being added must be placed inside
#       /incoming/packages/jammy/amd64/package_name.deb
#       /incoming/packages/jammy/arm64/package_name.deb
#       /incoming/packages/jammy/i386/package_name.deb
#   
#   Add Local Package           ./proteus.sh --dist "jammy" --arch "amd64" --add-local-package "reprepro_5.4.7-1_amd64.deb"
#   Dryrun Local Package        ./proteus.sh --dryrun --dev --dist "focal" --arch "amd64" --add-local-package "reprepro_5.4.7-1_amd64.deb"
# #

if [ -n "$argLocalPackage" ]; then
    app_repo_dist_sel=$( [[ -n "$argDistribution" ]] && echo "$argDistribution" || echo "$sys_code"  )

    if [ -z "${argArchitecture}" ]; then
        printf '%-29s %-65s\n' "  ${c[red]}ERROR${c[end]}" "${c[end]}Must specify an ${c[orange]}architecture${c[end]} for the package to be categorized under${c[end]}"
        printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "Use the following command:${c[end]}"
        printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} --dist ${c[yellow]}\"jammy\"${c[grey2]} --arch ${c[yellow]}\"amd64\"${c[grey2]} --add-local-package ${c[yellow]}\"reprepro_5.4.7-1_amd64.deb\"${c[end]}"
        printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} --dryrun --dev --dist ${c[yellow]}\"jammy\"${c[grey2]} --arch ${c[yellow]}\"amd64\"${c[grey2]} --add-local-package ${c[yellow]}\"reprepro_5.4.7-1_amd64.deb\"${c[end]}"
        echo -e
        exit 1
    fi

    if [ -z "${argDistribution}" ]; then
        printf '%-29s %-65s\n' "  ${c[red]}ERROR${c[end]}" "${c[end]}Must specify an ${c[orange]}distribution${c[end]} for the package to be categorized under${c[end]}"
        printf '%-29s %-65s\n' "  ${c[yellow]}${c[end]}" "Use the following command:${c[end]}"
        printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} --dist ${c[yellow]}\"jammy\"${c[grey2]} --arch ${c[yellow]}\"amd64\"${c[grey2]} --add-local-package ${c[yellow]}\"reprepro_5.4.7-1_amd64.deb\"${c[end]}"
        printf '%-34s %-65s\n' "  ${c[yellow]}${c[end]}" "${c[grey2]}./${app_file_this} --dryrun --dev --dist ${c[yellow]}\"jammy\"${c[grey2]} --arch ${c[yellow]}\"amd64\"${c[grey2]} --add-local-package ${c[yellow]}\"reprepro_5.4.7-1_amd64.deb\"${c[end]}"
        echo -e
        exit 1
    fi

    # #
    #   check if the local package specified is a url / link, instead of a filename.
    #   if so, download and process
    # #

    regex='(https?|ftp|file)://[-[:alnum:]\+&@#/%?=~_|!:,.;]*[-[:alnum:]\+&@#/%=~_|]'
    argLocalPackageUrl=${argLocalPackage}
    argLocalPackage=${argLocalPackage##*/}

    if [[ $argLocalPackageUrl =~ $regex ]]; then 
        printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Valid link specified instead of local package ${c[yellow]}$argLocalPackage${c[end]} from ${c[yellow]}$argLocalPackageUrl${c[end]}${c[end]}"
        if [[ "${argLocalPackage##*.}" == "deb" ]] ; then
            printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Valid link contains file ${c[yellow]}$argLocalPackage${c[end]} with correct detected extension ${c[yellow]}.deb${c[end]}"
            if [ -f "${app_dir_this_dir}/${argLocalPackage}" ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Requested ${c[navy]}.deb${c[grey1]} file already exists; skipping download${c[end]}"
            else
                printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Downloading package ${c[yellow]}${argLocalPackage}${c[end]} from ${c[yellow]}${argLocalPackageUrl}${c[end]} to ${c[yellow]}${app_dir_this_dir}/${argLocalPackage}${c[end]}"
                curl --remote-name "${argLocalPackageUrl}" >> /dev/null 2>&1
            fi
        fi

        if [ -f "${app_dir_this_dir}/${argLocalPackage}" ]; then
            printf '%-27s %-65s\n' "  ${c[green]}OK${c[end]}" "${c[end]}Successfully downloaded package ${c[green]}${app_dir_this_dir}/${argLocalPackage}${c[end]} from ${c[green]}${argLocalPackageUrl}${c[end]}"
        else
            printf '%-29s %-65s\n' "  ${c[red]}ERROR${c[end]}" "${c[end]}Failed to download package ${c[red2]}${app_dir_this_dir}/${argLocalPackage}${c[end]} from ${c[yellow]}${argLocalPackageUrl}${c[end]}"
            exit 1
        fi
    fi

    printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Adding Local Package ${c[yellow]}$argLocalPackage${c[end]} to distribution ${c[yellow]}$app_repo_dist_sel${c[end]} for arch ${c[yellow]}$argArchitecture${c[end]} ${c[end]}"

    # #
    #   reprepro > add package
    #   
    #       deb_package_location_1          incoming/packages/jammy/amd64/reprepro_5.4.7-1_amd64.deb
    #       deb_package_location_2          /server/proteus/reprepro_5.4.7-1_amd64.deb
    # #

    deb_package=false
    deb_package_location_1="$app_dir_incoming/$argArchitecture/$argLocalPackage"
    deb_package_location_2="$app_dir_this_dir/$argLocalPackage"

    printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Checking package location ${c[navy]}\$deb_package_location_1${c[grey1]} with value ${c[navy]}${deb_package_location_1}${c[end]}"
    printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}Checking package location ${c[navy]}\$deb_package_location_2${c[grey1]} with value ${c[navy]}${deb_package_location_2}${c[end]}"

    if [ -f "${deb_package_location_1}" ]; then
        printf '%-29s %-65s\n' "  ${c[blue]}REPREPRO${c[end]}" "Found local package ${c[blue]}${deb_package_location_1}${c[end]} for distribution ${c[blue]}${app_repo_dist_sel}${c[end]} and arch ${c[blue]}$argArchitecture${c[end]}"
        deb_package="${deb_package_location_1}"
    elif [ -f "${deb_package_location_2}" ]; then
        printf '%-29s %-65s\n' "  ${c[blue]}REPREPRO${c[end]}" "Found local package ${c[blue]}${deb_package_location_2}${c[end]} for distribution ${c[blue]}${app_repo_dist_sel}${c[end]} and arch ${c[blue]}$argArchitecture${c[end]}"
        deb_package="${deb_package_location_2}"
    else
        printf '%-29s %-65s\n' "  ${c[red2]}REPREPRO${c[end]}" "❌ Local package does not exist in ${c[red2]}$deb_package_location_1${c[end]}"
        printf '%-29s %-65s\n' "  ${c[red2]}REPREPRO${c[end]}" "❌ Local package does not exist in ${c[red2]}$deb_package_location_2${c[end]}"
        deb_package=false
    fi

    # #
    #   commit new package to github repository
    # #

    if [ "$deb_package" != false ] && [ -f "$deb_package" ]; then
        export SECONDS=0

        # #
        #   check for reprepro
        # #

        if [ -x "$(command -v reprepro)" ]; then
            bRepreproInstalled=true
        fi

        if [ "${argDevEnabled}" = true ]; then
            printf '%-29s %-65s\n' "  ${c[blue]}${c[end]}" "${c[grey2]}reprepro -V --section ${c[blue]}utils${c[grey2]} --component ${c[blue]}main${c[grey2]} --priority ${c[blue]}0${c[grey2]} --architecture ${c[blue]}$argArchitecture${c[grey2]} includedeb ${c[blue]}${app_repo_dist_sel}${c[grey2]} ${c[blue]}${deb_package}${c[end]}"
        fi

        if [ -n "${bRepreproInstalled}" ]; then
            reprepro_output=
            if [ "${argDryRun}" = false ]; then
                printf '%-29s %-65s\n' "  ${c[yellow]}REPREPRO${c[end]}" "Adding new reprepro file ${c[yellow]}$deb_package${c[end]} for dist ${c[yellow]}$app_repo_dist_sel${c[end]} and arch ${c[yellow]}$argArchitecture${c[end]}"
                reprepro_exit_code="0"
                reprepro_output="$(reprepro -V \
                    --section utils \
                    --component main \
                    --priority 0 \
                    --architecture $argArchitecture \
                    includedeb ${app_repo_dist_sel} "${deb_package}" \
                    "$@" 2>&1)" \
                    || { reprepro_exit_code="$?" ; true; };

                    reprepro_output=${reprepro_output//$'\n'/}          # Remove all newlines.
                    reprepro_output=${reprepro_output%$'\n'}            # Remove a trailing newline.

                    printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Response${c[end]}" "${c[grey1]}${reprepro_output}${c[end]}"
            fi

            # #
            #   architecture > i386 > reprepro
            #
            #   output > package already added to reprepro
            # #

            if echo "$reprepro_output" | grep --quiet --ignore-case "exists" ; then
                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists (${c[yellow]}${deb_package}${c[end]}) for ${c[yellow]}${app_repo_dist_sel}${c[end]}"
            fi

            # #
            #   local package > architecture > i386 > reprepro
            #
            #   output > package already added but checksums are different
            # #

            if echo "$reprepro_output" | grep --quiet --ignore-case "Already existing files" ; then
                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "💡 Already exists; bad checksums. Removing ${c[yellow]}${argLocalPackage}${c[end]} from ${c[yellow]}Reprepro${c[end]} and re-adding${c[end]}"
                reprepro remove "${app_repo_dist_sel}" "${argLocalPackage}"

                reprepro_exit_code="0"
                reprepro_output="$(reprepro -V \
                    --section utils \
                    --component main \
                    --priority 0 \
                    --architecture $argArchitecture \
                    includedeb ${app_repo_dist_sel} "${deb_package}" \
                    "$@" 2>&1)" \
                    || { reprepro_exit_code="$?" ; true; };
            fi

            # #
            #   architecture > i386 > reprepro
            #
            #   output > new package added
            # #

            if echo "$reprepro_output" | grep --quiet --ignore-case "Successfully created" ; then
                printf '%-15s %-25s %-65s\n' "" "  ${c[end]}Status${c[end]}" "✅ New package added (${c[green]}${deb_package}${c[end]}) for ${c[green]}${app_repo_dist_sel}${c[end]}"
            fi

            # #
            #   update tree and README
            # #

            app_run_tree_update

            # #
            #   git add -A, --all     stages all changes
            #   git add .             stages new files and modifications, without deletions (on the current directory and its subdirectories).
            #   git add -u            stages modifications and deletions, without new files
            # #

            printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Committing new packages to git branch ${c[yellow]}${app_repo_branch}${c[end]}"
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git add --all${c[end]}"
            fi
            if [ "${argDryRun}" = false ] && [ "${argSkipGitCommit}" = false ]; then
                git add --all
            fi

            # #
            #   git > commit > start message
            # #

            NOW=$(date -u '+%m.%d.%Y %H:%M:%S')
            app_repo_commit="build(run): \`️📦 pkg-add (local): ${argLocalPackage} 📦\` \`${app_repo_dist_sel} | ${NOW} UTC\`"

            # #
            #   git > commit
            #   
            #   The command below can throw the following errors:
            #   
            #       error: gpg failed to sign the data:
            #       gpg: skipped "!": No secret key
            #       [GNUPG:] INV_SGNR 9 !
            #       [GNUPG:] FAILURE sign 17
            #       gpg: signing failed: No secret key
            # #

            printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Git commit message: ${c[yellow]}${app_repo_commit}${c[end]}"
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git commit -S -m ${app_repo_commit}${c[end]}"
            fi
            if [ "${argDryRun}" = false ] && [ "${argSkipGitCommit}" = false ]; then
                git commit -S -m "${app_repo_commit}"
            fi

            # #
            #   git > push
            # #

            printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Pushing changes to git repo ${c[yellow]}${app_repo_branch}${c[end]}"
            if [ "${argDevEnabled}" = true ]; then
                printf '%-28s %-65s\n' "  ${c[navy]}DEV${c[end]}" "${c[grey1]}git push https://${CSI_PAT_GITHUB}@github.com/${CSI_GITHUB_NAME}/${app_repo_apt}${c[end]}"
            fi
            if [ "${argDryRun}" = false ] && [ "${argSkipGitCommit}" = false ]; then
                git push https://${CSI_PAT_GITHUB}@github.com/${CSI_GITHUB_NAME}/${app_repo_apt}
            fi

            # #
            #   move .deb file from root project folder to incoming/ if it's not already there
            # #

            if [ ! -f "$app_dir_incoming/$argArchitecture/$argLocalPackage" ]; then
                printf '%-29s %-65s\n' "  ${c[yellow]}STATUS${c[end]}" "Moving ${c[yellow]}${deb_package}${c[end]} to ${c[yellow]}$app_dir_incoming/$argArchitecture/$argLocalPackage${c[end]}"
                mv "$deb_package" "$app_dir_incoming/$argArchitecture/"
            fi
        else
            printf '%-29s %-65s\n' "  ${c[blue]}${c[end]}" "${c[yellow]}💡 Skip addition: reprepro not installed or running dryrun mode${c[end]}"
        fi

        # #
        #   duration elapsed
        # #

        duration=${SECONDS}
        elapsed="$((${duration} / 60)) minutes and $(( ${duration} % 60 )) seconds elapsed."

        echo
        echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
        echo -e "  ${c[grey2]}Total Execution Time: $elapsed${c[end]}"
        echo -e " ${c[grey1]}―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――${c[end]}"
        echo
    else
        printf '%-29s %-65s\n' "  ${c[red2]}REPREPRO${c[end]}" "❌ Local package not found; aborting without making changes${c[end]}"
    fi

    if compgen -G "${app_dir}/*.deb*" > /dev/null; then
        echo -e "  ${c[grey2]}Cleaning up left-over .deb: ${c[yellow]}${app_dir}/*.deb${c[end]}"
        rm ${app_dir}/*.deb* >/dev/null
    fi

    echo -e
    exit 1
fi

if [ "${argForceUpdate}" = true ]; then
    app_update ${app_repo_branch_sel}
fi

app_setup
app_start
