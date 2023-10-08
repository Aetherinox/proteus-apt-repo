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
Information on how to utilize the packages in this repo for your own device

<br />

## Add Repo To Sources
If you wish to add the Zorin repo to your list of sources, the command below will create a new file located at `/etc/apt/sources.list.d/aetherinox-zorin-apt-repo-archive.list`

<br />

Open `Terminal` and add the GPG key for the developer to your keyring
```bash
wget -qO - https://github.com/Aetherinox.gpg | sudo gpg --dearmor -o /usr/share/keyrings/aetherinox-zorin-apt-repo-archive.gpg
```

Then execute the command below to receive our package list:
```shell
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/aetherinox-zorin-apt-repo-archive.gpg] https://raw.githubusercontent.com/Aetherinox/zorin-apt-repo/master $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/aetherinox-zorin-apt-repo-archive.list
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