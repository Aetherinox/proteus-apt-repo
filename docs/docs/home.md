---
title: Home
tags:
  - home
---

<p align="center"><img src="https://raw.githubusercontent.com/Aetherinox/proteus-app-manager/main/docs/images/readme/banner_02.png" width="860"></p>
<h1 align="center"><b>Proteus Apt Repo</b></h1>

<p align="center" markdown="1">

![Version](https://img.shields.io/github/v/tag/Aetherinox/proteus-apt-repo?logo=GitHub&label=version&color=ba5225)
![Downloads](https://img.shields.io/github/downloads/Aetherinox/proteus-apt-repo/total)
![Repo Size](https://img.shields.io/github/repo-size/Aetherinox/proteus-apt-repo?label=size&color=59702a)
![Last Commit)](https://img.shields.io/github/last-commit/Aetherinox/proteus-apt-repo?color=b43bcc)

</p>

The <a href="https://github.com/Aetherinox/proteus-apt-repo">Proteus Apt Repo</a> is a repository similar to others that store packages which can be downloaded using commands such as `apt install` or `apt-get install`. It supports all flavours of Ubuntu as far back as Focal, as well as ZorinOS. 

Along with popular packages; the Proteus Apt Repo also scans some of the most popular Github repos for linux releases and makes them available to install using the **APT Package Manager** (`apt-get install`); instead of having to manually download the associated `.deb` and installing it yourself. Packages are updated daily, and updates can be pushed to your system by simply running `apt-get update`.

Utilizing Proteus is as simple as adding the official repository to your system's **sources.list** file.

<br />

**Supported Distributions**:

<br />

<p align="center"><img src="https://res.cloudinary.com/canonical/image/fetch/f_auto,q_auto,fl_sanitize,w_518,h_173/https://assets.ubuntu.com/v1/8527100a-ubuntu-flavours-23.png" width="300"></p>

- [Edubuntu](https://edubuntu.org/)
- [Kubuntu](https://kubuntu.org/)
- [Lubuntu](https://lubuntu.me/)
- [Ubuntu](https://ubuntu.com/)
- [Xubuntu](https://xubuntu.org/)
- [Ubuntu Budgie](https://ubuntubudgie.org/)
- [Ubuntu Cinnamon](https://ubuntucinnamon.org/)
- [Ubuntu Kylin](https://ubuntukylin.com/)
- [Ubuntu MATE](https://ubuntu-mate.org/)
- [Ubuntu Unity](https://ubuntuunity.org/)

<p align="center"><img src="https://static-00.iconduck.com/assets.00/distributor-logo-zorin-icon-1024x1024-05nfhdjg.png" width="45"></p>

- [ZorinOS](https://zorin.com/os/)

<br />

**Supported Codenames**:

<br />

| Version | Codename | Release | End of Life | ZorinOS Version |
| --- | --- | --- | --- | --- |
| [Noble Numbat](https://wiki.ubuntu.com/NobleNumbat) | Ubuntu 24.04 LTS | April 25, 2024 | April 2036 | Zorin OS 18 |
| [Mantic Minotaur](https://wiki.ubuntu.com/ManticMinotaur) | Ubuntu 23.10 | October 12, 2023 | July 11, 2024 | - |
| [Lunar Lobster](https://wiki.ubuntu.com/LunarLobster) | Ubuntu 23.04 | April 20, 2023 | January 25, 2024 | - |
| [Jammy Jellyfish](https://wiki.ubuntu.com/JammyJellyfish) | Ubuntu 22.04 LTS | February 22, 2024 | April 2034 | Zorin OS 17 |
| [Focal Fossa](https://wiki.ubuntu.com/FocalFossa) | Ubuntu 20.04 LTS | March 23, 2023 | April 2032 | Zorin OS 16 |

<br />

---

<br />

## Status
Time of last update for each release's packages

<br />

<p align="center" markdown="1">

![Noble-Title](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Fnoble.json&query=distrib&style=for-the-badge&label=&color=363738&logo=debian&logoWidth=41)
![Noble-Badge](https://img.shields.io/badge/-24.04-%23363738?style=for-the-badge)
![Noble-LastUpdate](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Fnoble.json&query=last_update&style=for-the-badge&label=updated&color=595894&labelColor=%23363738)
![Noble-Elapsed](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Fnoble.json&query=last_duration&style=for-the-badge&label=elapsed&color=595894&labelColor=%23363738)

<br />

![Mantic-Title](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Fmantic.json&query=distrib&style=for-the-badge&label=&color=363738&logo=debian&logoWidth=30)
![Mantic-Badge](https://img.shields.io/badge/-23.10-%23363738?style=for-the-badge)
![Mantic-LastUpdate](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Fmantic.json&query=last_update&style=for-the-badge&label=updated&color=0c8838&labelColor=%23363738)
![Mantic-Elapsed](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Fmantic.json&query=last_duration&style=for-the-badge&label=elapsed&color=0c8838&labelColor=%23363738)

<br />

![Lunar-Title](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Flunar.json&query=distrib&style=for-the-badge&label=&color=363738&logo=debian&logoWidth=40)
![Lunar-Badge](https://img.shields.io/badge/-23.04-%23363738?style=for-the-badge)
![Lunar-LastUpdate](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Flunar.json&query=last_update&style=for-the-badge&label=updated&color=e60b51&labelColor=%23363738)
![Lunar](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Flunar.json&query=last_duration&style=for-the-badge&label=elapsed&color=e60b51&labelColor=%23363738)

<br />

![Jammy-Title](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Fjammy.json&query=distrib&style=for-the-badge&label=&color=363738&logo=debian&logoWidth=36)
![Jammy Badge](https://img.shields.io/badge/-22.04-%23363738?style=for-the-badge)
![Jammy-LastUpdate](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Fjammy.json&query=last_update&style=for-the-badge&label=updated&color=0b7ae6&labelColor=%23363738 )
![Jammy-Elapsed](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Fjammy.json&query=last_duration&style=for-the-badge&label=elapsed&color=0b7ae6&labelColor=%23363738 )

<br />

![Focal-Title](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Ffocal.json&query=distrib&style=for-the-badge&label=&color=363738&logo=debian&logoWidth=40)
![Focal Badge](https://img.shields.io/badge/-20.04-%23363738?style=for-the-badge)
![Focal-LastUpdate](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Ffocal.json&query=last_update&style=for-the-badge&label=updated&color=e65a0b&labelColor=%23363738)
![Focal-Elapsed](https://img.shields.io/badge/dynamic/json?url=https%3A%2F%2Fraw.githubusercontent.com%2FAetherinox%2Fproteus-apt-repo%2Fmain%2F.app%2Ffocal.json&query=last_duration&style=for-the-badge&label=elapsed&color=e65a0b&labelColor=%23363738)

</p>

<br />

---

<br />
