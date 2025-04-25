<p align="center"><img src="https://raw.githubusercontent.com/Aetherinox/proteus-app-manager/main/docs/images/readme/banner_02.png" width="860"></p>
<h1 align="center"><b>Proteus Apt Repository</b></h1>

<div align="center">

![GitHub repo size](https://img.shields.io/github/repo-size/Aetherinox/proteus-apt-repo?label=size&color=59702a) ![GitHub last commit (by committer)](https://img.shields.io/github/last-commit/Aetherinox/proteus-apt-repo?color=b43bcc) [![View Apt Repo](https://img.shields.io/badge/Repo%20-%20View%20-%20%23f00e7f?logo=Linux&logoColor=FFFFFF&label=Repo)](https://github.com/Aetherinox/proteus-apt-repo/)

</div>

<br />

This apt repository works similarly to other official repos such as http://xx.archive.ubuntu.com/ubuntu. To utilize this repository, you will add this repo to your Ubuntu sources list, which will then allow you to install packages just as you normally would using `apt` or `apt-get`.

<br />

This repo includes several types of packages:
- Official ubuntu packages
- Github hosted linux packages that are normally installed manually, but can now be accessed by `apt`
- Access to different versions of packages not available using the traditional method, without the need to manually find them.

<br />

Packages in this repo are automatically fetched and constantly checked for updates using several servers that remain online.

<br />

View the instructions below to add this repo to your sources list, and how to install packages from this repo.

<br />
<br />

## Status
Time of last package update for each release

<br />

<div align="center">

| Codename | Status |
| --- | --- |
| ![Noble-Title](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Fnoble.json&query=distrib&style=for-the-badge&label=&color=363738&logo=debian&logoWidth=41) ![Noble Badge](https://img.shields.io/badge/-24.04-%23363738?style=for-the-badge) | ![Noble-LastUpdate](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Fnoble.json&query=last_update&style=for-the-badge&label=updated&color=595894&labelColor=%23363738) ![Noble-Elapsed](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Fnoble.json&query=last_duration&style=for-the-badge&label=elapsed&color=595894&labelColor=%23363738) |
| ![Jammy-Title](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Fjammy.json&query=distrib&style=for-the-badge&label=&color=363738&logo=debian&logoWidth=36) ![Jammy Badge](https://img.shields.io/badge/-22.04-%23363738?style=for-the-badge) | ![Jammy-LastUpdate](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Fjammy.json&query=last_update&style=for-the-badge&label=updated&color=0b7ae6&labelColor=%23363738 ) ![Jammy-Elapsed](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Fjammy.json&query=last_duration&style=for-the-badge&label=elapsed&color=0b7ae6&labelColor=%23363738 ) | 
| ![Focal-Title](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Ffocal.json&query=distrib&style=for-the-badge&label=&color=363738&logo=debian&logoWidth=40) ![Focal Badge](https://img.shields.io/badge/-20.04-%23363738?style=for-the-badge) | ![Focal-LastUpdate](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Ffocal.json&query=last_update&style=for-the-badge&label=updated&color=e65a0b&labelColor=%23363738) ![Focal-Elapsed](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Ffocal.json&query=last_duration&style=for-the-badge&label=elapsed&color=e65a0b&labelColor=%23363738) |

</div>

<br />

---

<br />

## About
This is a Proteus apt repository that is associated to the [Proteus App Manager](https://github.com/Aetherinox/proteus-app-manager). It can however, be added by any user running Ubuntu, ZorinOS, or similar Linux distributions. All packages contained within this repository are automatically updated when developers release new reivisons of their packages. The user simply needs to run `apt update` or `apt-get update` in terminal.

<br />

The following packages are part of this repository:

- [AppOutlet](https://github.com/AppOutlet/AppOutlet)
- [Bitwarden](https://github.com/bitwarden/clients/releases)
- [deb-apt-url](https://github.com/aetherinox/debian-apt-url/releases)
- [Freetube](https://github.com/FreeTubeApp/FreeTube/releases)
- [Github Desktop](https://github.com/shiftkey/desktop/releases)
- [makedeb](https://github.com/makedeb/makedeb/releases)
- [Obsidian.md](https://github.com/obsidianmd/obsidian-releases/releases)
- [Opengist](https://github.com/thomiceli/opengist/releases)

<br />

---

<br />

## Usage
Information on how to utilize the packages in this repo for your own device

<br />

## Add Repo To Sources
If you wish to add the Proteus repo to your list of sources, the command below will create a new file located at `/etc/apt/sources.list.d/aetherinox-proteus-archive.list`

<br />

Open `Terminal` and add the GPG key to your keyring
```bash
wget -qO - https://github.com/Aetherinox.gpg | sudo gpg --dearmor -o /usr/share/keyrings/aetherinox-proteus-archive.gpg
```

<br />

Fetch the repo package list:
```shell
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/aetherinox-proteus-archive.gpg] https://raw.githubusercontent.com/Aetherinox/proteus-apt-repo/master $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/aetherinox-proteus-archive.list
```

<br />

(Optional): To test if the correct GPG key was added:
```shell
gpg -n -q --import --import-options import-show /usr/share/keyrings/aetherinox-proteus-archive.gpg | awk '/pub/{getline; gsub(/^ +| +$/,""); if($0 == "BCA07641EE3FCD7BC5585281488D518ABD3DC629") print "\nGPG fingerprint matches ("$0").\n"; else print "\GPG verification failed: Fngerprint ("$0") does not match the expected one.\n"}'
```

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

<br />

An example would be
```shell
apt policy ocs-url
```

<br />

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

<br />

Or you can use
```shell
apt-cache showpkg ocs-url
```

<br />

To see a full list of your registered repos and info about them:
```shell
apt-cache policy 
```

<br />

To view a list of packages being distributed by this repo
```shell
grep -h -P -o "^Package: \K.*" /var/lib/apt/lists/*proteus-apt-repo*_Packages | sort -u 
```

