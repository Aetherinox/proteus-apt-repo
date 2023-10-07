<p align="center"><img src="docs/images/readme/banner.jpg" width="860"></p>
<h1 align="center"><b>ZorinOS Repository</b></h1>

<br />
<br />

## About
This is a ZorinOS apt repository that is associated to the [ZorinOS App Manager](https://github.com/Aetherinox/zorin-app-manager).

<br />

---

<br />

## Usage
Open `Terminal` and execute:

```shell
dpkg --print-architecture
```

One of the following will be printed in terminal:
- `amd64`
- `arm64`
- `i386`

Paste the result below to the right of `[arch=]`. If your terminal printed `amd64`, then leave the line below alone.

```shell
sudo add-apt-repository -y "deb [arch=amd64] https://raw.githubusercontent.com/Aetherinox/zorin-apt-repo/master focal main"
```

After you've copied the line above in terminal, execute it to add the repo to your `/etc/apt/sources.list` file.

If you wish to remove it later, execute
```shell
sudo add-apt-repository -r "deb [arch=amd64] https://raw.githubusercontent.com/Aetherinox/zorin-aabd-repo/master focal main"
```

In your terminal, enter
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
        500 https://raw.githubusercontent.com/Aetherinox/zorin-apt-repo/master focal/main amd64 Packages
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
grep -h -P -o "^Package: \K.*" /var/lib/apt/lists/*zorin-apt-repo*_Packages | sort -u 
```