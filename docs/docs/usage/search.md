---
title: Search for Packages
tags:
  - usage
---
To view information about packages and repositories; view the list of commands below.

<br />

---

<br />

## View Package Info
To see which repository is distributing a package; pick any of the commands listed below; they do similar things:

=== "Command"

    ```shell
    apt policy <package>
    ```

    ```shell
    apt-cache <package>
    ```

    <br />

    An example would be

    ```shell
    apt policy apt-url
    ```

    ```shell
    apt-cache showpkg apt-url
    ```

=== "Output"

    ```shell
    $ apt policy apt-url

    apt-url:
      Installed: 1.0.0-2
      Candidate: 1.0.0-2
      Version table:
    *** 1.0.0-2 500
            500 https://raw.githubusercontent.com/Aetherinox/proteus-apt-repo//main mantic/main amd64 Packages
            100 /var/lib/dpkg/status

    ```

<br />
<br />

## List of Repositories
To see a full list of your registered repositories and info about them:

=== "Command"
    ```shell
    apt-cache policy 
    ```

=== "Output"
    ```shell
    500 https://raw.githubusercontent.com/Aetherinox/proteus-apt-repo//main mantic/main amd64 Packages
        release o=Aetherx,a=stable,n=mantic,l=Mantic Minotaur 23.10,c=main,b=amd64
        origin raw.githubusercontent.com
    ```

<br />
<br />

## List of Packages by Repository
To view a list of packages being distributed by this repo, pick either of the commands below:

=== "Command"
    ```shell
    grep ^Package: /var/lib/apt/lists/*proteus*_Packages
    ```

    ```shell
    grep -h -P -o "^Package: \K.*" /var/lib/apt/lists/*proteus*_Packages | sort -u 
    ```

=== "Output"

    ```
    Package: adduser
    Package: app-outlet
    Package: apt-move
    Package: apt-transport-https
    Package: apt-url
    Package: apt-utils
    Package: argon2
    Package: clevis
    Package: clevis-dracut
    Package: clevis-tpm2
    Package: clevis-udisks2
    Package: dialog
    ```

<br />

---

<br />