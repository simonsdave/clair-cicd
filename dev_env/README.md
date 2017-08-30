# Development Environment

To increase predicability, it is recommended
that ```clair-database``` development be done on a [Vagrant](http://www.vagrantup.com/) provisioned
[VirtualBox](https://www.virtualbox.org/)
VM running [Ubuntu 14.04](http://releases.ubuntu.com/14.04/).
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


vagrant@vagrant-ubuntu-trusty-64:~$
```

Clone the ecs repo.

```bash
vagrant@vagrant-ubuntu-trusty-64:~$ git clone https://github.com/simonsdave/clair-database.git
Cloning into 'clair-database'...
remote: Counting objects: 3, done.
remote: Compressing objects: 100% (2/2), done.
remote: Total 3 (delta 0), reused 0 (delta 0), pack-reused 0
Unpacking objects: 100% (3/3), done.
Checking connectivity... done.
vagrant@vagrant-ubuntu-trusty-64:~$ cd clair-database/
vagrant@vagrant-ubuntu-trusty-64:~/clair-database$
```

All done:-)
