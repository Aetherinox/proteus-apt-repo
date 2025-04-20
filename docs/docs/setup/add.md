---
title: Add Proteus Repo
tags:
  - install
---

# Adding Proteus
If you wish to add the Proteus repository to your list of sources and download packages; the command below will create a new file located at `/etc/apt/sources.list.d/aetherinox-proteus-archive.list`

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

Your new repository is now available to use. For a more detailed list of commands and how to use the Proteus repo, view the [Usage](../../usage/install) section.

<br />

---

<br />