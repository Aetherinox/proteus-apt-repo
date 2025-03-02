---
title: Changelog
tags:
  - changelog
---

# Changelog

<p align="center" markdown="1">

![Version](https://img.shields.io/github/v/tag/Aetherinox/proteus-apt-repo?logo=GitHub&label=version&color=ba5225)
![Downloads](https://img.shields.io/github/downloads/Aetherinox/proteus-apt-repo/total)
![Repo Size](https://img.shields.io/github/repo-size/Aetherinox/proteus-apt-repo?label=size&color=59702a)
![Last Commit)](https://img.shields.io/github/last-commit/Aetherinox/proteus-apt-repo?color=b43bcc)

</p>

### <!-- md:version stable- --> 2.0.0 <small>Jul 27, 2024</small> { id="2.0.0" }

- `add`: package `clevis`
- `add`: package `apt-url`
- `add`: package `opengist`
- `change`: integrated new secrets system utilizing clevis
- `change`: script now cleans up any left behind packages prior to exiting
- `change`: now cleans up `.git/index.lock`
- `change`: modify how `app_dir` is defined to get the current script path
- `dep`: bump `reprepro` to 5.4.4
- `fix`: tracker time not reporting correctly
- `fix`: script should no longer get stuck when initializing a new upset
- `deprecate`: secrets.sh system

<br />

---

<br />

### <!-- md:version stable- --> 1.1.0 <small>Jul 22, 2024</small> { id="1.1.0" }

- `added`: ubuntu noble package updates

<br />

---

<br />

### <!-- md:version stable- --> 1.0.0 <small>Feb 19, 2024</small> { id="1.0.0" }

- Initial release

<br />

---

<br />