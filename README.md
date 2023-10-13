<p align="center"><img src="https://raw.githubusercontent.com/Aetherinox/proteus-app-manager/main/docs/images/readme/banner_02.png" width="860"></p>
<h1 align="center"><b>Proteus Apt Repository</b></h1>

<div align="center">

![GitHub repo size](https://img.shields.io/github/repo-size/Aetherinox/proteus-apt-repo?label=size&color=59702a) ![GitHub last commit (by committer)](https://img.shields.io/github/last-commit/Aetherinox/proteus-apt-repo?color=b43bcc) [![View Apt Repo](https://img.shields.io/badge/Repo%20-%20View%20-%20%23f00e7f?logo=Linux&logoColor=FFFFFF&label=Repo)](https://github.com/Aetherinox/proteus-apt-repo/)

</div>

<br />
<br />

## About
This is a Proteus apt repository that is associated to the [Proteus App Manager](https://github.com/Aetherinox/proteus-app-manager). It can however, be added by any user running Ubuntu, ZorinOS, or similar Linux distributions. All packages contained within this repository are automatically updated when developers release new reivisons of their packages. The user simply needs to run `apt update` or `apt-get update` in terminal.

The repository currently contains the following packages:
```
app-outlet
deb-pacman
github-desktop
ocs-url
qubes-gpg-split
qubes-gpg-split-dbgsym
qubes-gpg-split-tests
qubes-thunderbird
qubes-utils
zorin-pro-layouts
```

<br />

---

<br />

## Usage
Information on how to utilize the packages in this repo for your own device

<br />

## Add Repo To Sources
If you wish to add the Proteus repo to your list of sources, the command below will create a new file located at `/etc/apt/sources.list.d/aetherinox-proteus-apt-repo-archive.list`

<br />

Open `Terminal` and add the GPG key for the developer to your keyring
```bash
wget -qO - https://github.com/Aetherinox.gpg | sudo gpg --dearmor -o /usr/share/keyrings/aetherinox-proteus-apt-repo-archive.gpg
```

Then execute the command below to receive our package list:
```shell
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/aetherinox-proteus-apt-repo-archive.gpg] https://raw.githubusercontent.com/Aetherinox/proteus-apt-repo/master $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/aetherinox-proteus-apt-repo-archive.list
```

Be aware that most packages hosted in this repo are for `amd64`, so your desired package may not be available if you're running any other.

<br />

Finally, run in terminal
```shell
sudo apt update
```

Your new repository is now available to use.

<br />

---

<br />

## Search Packages

To see which repo is distributing a package, enter:

```shell
apt policy <package>
```

An example would be
```shell
apt policy ocs-url
```

Which outputs the following:
```
ocs-url:
  Installed: 3.1.0-0ubuntu1
  Candidate: 3.1.0-0ubuntu1
  Version table:
 *** 3.1.0-0ubuntu1 500
        500 https://raw.githubusercontent.com/Aetherinox/proteus-apt-repo/master focal/main amd64 Packages
        100 /var/lib/dpkg/status
```

Or you can use
```shell
apt-cache showpkg ocs-url
```

To see a full list of your registered repos and info about them:
```shell
apt-cache policy 
```

To view a list of packages being distributed by the repo
```shell
grep -h -P -o "^Package: \K.*" /var/lib/apt/lists/*proteus-apt-repo*_Packages | sort -u 
```