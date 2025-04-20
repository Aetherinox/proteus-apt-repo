---
title: Install Packages
tags:
  - usage
---
This section explains how to install packages using the Proteus Apt repository.

<br />

---

<br />

## Prerequisites
Before you can install packages distributed by the Proteus Apt repository, you must ensure you have completed the steps on the [Setup page](../../setup/add).

<br />

---

<br />

## Update Packages
Once you have added Proteus to your list of sources, you must run the `apt update` command first so that it can fetch a list of the latest packages available for install.

=== "Command"

    ```shell
    sudo apt update
    ```

=== "Output"

    ```shell
    $ sudo apt update

    Hit:1 https://download.docker.com/linux/ubuntu mantic InRelease
    Hit:2 http://us.archive.ubuntu.com/ubuntu mantic InRelease                                                                     
    Hit:3 http://us.archive.ubuntu.com/ubuntu mantic-updates InRelease                                                             
    Get:4 http://dl.google.com/linux/chrome/deb stable InRelease [1,825 B]                                                         
    Hit:5 http://security.ubuntu.com/ubuntu mantic-security InRelease                                                              
    Hit:7 http://us.archive.ubuntu.com/ubuntu mantic-backports InRelease                                     
    Get:8 https://packages.mozilla.org/apt mozilla InRelease [1,528 B]
    Get:6 https://raw.githubusercontent.com/Aetherinox/proteus-apt-repo//main mantic InRelease [5,840 B]
    Get:9 http://dl.google.com/linux/chrome/deb stable/main amd64 Packages [1,093 B]
    Get:10 https://packages.mozilla.org/apt mozilla/main amd64 Packages [248 kB]
    Get:11 https://packages.mozilla.org/apt mozilla/main all Packages [14.1 MB]
    Fetched 14.3 MB in 3s (5,667 kB/s)  
    Reading package lists... Done
    Building dependency tree... Done
    Reading state information... Done
    ```

<br />

---

<br />

## Install Packages
After you've completed the previous steps; you can now install packages from the Proteus Apt repository. Run the following command and include the name of the package you wish to install:

=== "Command"
    ```shell
    sudo apt install opengist
    ```

=== "Output"
    ```shell
    $ sudo apt install opengist

    Reading package lists... Done
    Building dependency tree... Done
    Reading state information... Done
    The following NEW packages will be installed:
    opengist
    0 upgraded, 1 newly installed, 0 to remove and 77 not upgraded.
    Need to get 20.2 MB of archives.
    After this operation, 0 B of additional disk space will be used.
    Get:1 https://raw.githubusercontent.com/Aetherinox/proteus-apt-repo//main mantic/main amd64 opengist amd64 1.7.3 [20.2 MB]
    Fetched 20.2 MB in 2s (8,205 kB/s)  
    Selecting previously unselected package opengist.
    (Reading database ... 156769 files and directories currently installed.)
    Preparing to unpack .../opengist_1.7.3_amd64.deb ...
    Unpacking opengist (1.7.3) ...
    Setting up opengist (1.7.3) ...
    info: The home dir /var/lib/opengist you specified can't be accessed: No such file or directory

    info: Selecting UID from range 100 to 999 ...

    info: Selecting GID from range 100 to 999 ...
    info: Adding system user `opengist' (UID 127) ...
    info: Adding new group `opengist' (GID 131) ...
    info: Adding new user `opengist' (UID 127) with group `opengist' ...
    info: Not creating home directory `/var/lib/opengist'.
    Starting service
    ```

<br />

---

<br />