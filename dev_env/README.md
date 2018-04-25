# Development Environment

To increase predicability, it is recommended
that ```clair-cicd``` development be done on a [Vagrant](http://www.vagrantup.com/) provisioned
[VirtualBox](https://www.virtualbox.org/)
VM running [Ubuntu 16.04](http://releases.ubuntu.com/16.04/).
Below are the instructions for spinning up such a VM.

Spin up a VM using [create_dev_env.sh](create_dev_env.sh)
(instead of using ```vagrant up``` - this is the only step
that standard vagrant commands aren't used - after provisioning
the VM you will use ```vagrant ssh```, ```vagrant halt```,
```vagrant up```, ```vagrant status```, etc).

```bash
>./create_dev_env.sh simonsdave simonsdave@gmail.com ~/.ssh/id_rsa.pub ~/.ssh/id_rsa
Bringing machine 'default' up with 'virtualbox' provider...
==> default: Importing base box 'trusty'...
.
.
.
```

SSH into the VM.

```bash
>vagrant ssh
Welcome to Ubuntu 14.04 LTS (GNU/Linux 3.13.0-27-generic x86_64)

 * Documentation:  https://help.ubuntu.com/

 System information disabled due to load higher than 1.0

  Get cloud support with Ubuntu Advantage Cloud Guest:
    http://www.ubuntu.com/business/services/cloud

0 packages can be updated.
0 updates are security updates.

New release '16.04.3 LTS' available.
Run 'do-release-upgrade' to upgrade to it.

~>
```

Start the ssh-agent in the background.

```bash
~> eval "$(ssh-agent -s)"
Agent pid 25657
~>
```

Add SSH private key for github to the ssh-agent

```bash
~> ssh-add ~/.ssh/id_rsa_github
Enter passphrase for /home/vagrant/.ssh/id_rsa_github:
Identity added: /home/vagrant/.ssh/id_rsa_github (/home/vagrant/.ssh/id_rsa_github)
~>
```

Clone the repo.

```bash
~/> git clone git@github.com:simonsdave/clair-cicd.git
Cloning into 'clair-cicd'...
remote: Counting objects: 718, done.
remote: Compressing objects: 100% (73/73), done.
remote: Total 718 (delta 71), reused 109 (delta 53), pack-reused 582
Receiving objects: 100% (718/718), 104.36 KiB | 0 bytes/s, done.
Resolving deltas: 100% (396/396), done.
Checking connectivity... done.
~/>
```

Configure the dev environment

```bash
~> cd clair-cicd/
~/clair-cicd> source cfg4dev
New python executable in env/bin/python
Installing setuptools, pip...done.
.
.
.
Cleaning up...
(env)~/clair-cicd>
```

Run unit tests

```bash
(env)~/clair-cicd> nosetests --with-coverage --cover-branches --cover-erase --cover-package clair_cicd
.......................
Name                     Stmts   Miss Branch BrPart  Cover
----------------------------------------------------------
clair_cicd/__init__.py       1      0      0      0   100%
clair_cicd/assessor.py      10      0      4      0   100%
clair_cicd/io.py            42      0     10      1    98%
clair_cicd/models.py        31      0      0      0   100%
----------------------------------------------------------
TOTAL                       84      0     14      1    99%
----------------------------------------------------------------------
Ran 23 tests in 0.031s

OK
(env)~/clair-cicd>
```
