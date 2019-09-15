# Development Environment

```clair-cicd``` users [dev-env](https://github.com/simonsdave/dev-env)
to create development and CI environments. Below are the instructions
for spinning up a development environment and running unit the unit tests.
These instructions have been tested on various flavors of macOS.

```bash
~> cd $HOME
~>
```

```bash
~> git clone git@github.com:simonsdave/clair-cicd.git
Cloning into 'clair-cicd'...
remote: Enumerating objects: 57, done.
remote: Counting objects: 100% (57/57), done.
remote: Compressing objects: 100% (38/38), done.
remote: Total 1127 (delta 20), reused 43 (delta 12), pack-reused 1070
Receiving objects: 100% (1127/1127), 156.72 KiB | 641.00 KiB/s, done.
Resolving deltas: 100% (666/666), done.
~>
```

```bash
~> cd clair-cicd
~>
```

```bash
~> source cfg4dev
New python executable in /Users/simonsdave/clair-cicd/env/bin/python
Installing setuptools, pip, wheel...
done.
.
<<<cut>>>
.
---> 1d222e22dc4e
Successfully built 1d222e22dc4e
Successfully tagged simonsdave/clair-cicd-xenial-dev-env:build
(env) ~>
```

```bash
(env) ~> run-unit-tests.sh
Coverage.py warning: --include is ignored because --source is set (include-ignored)
.......................
Name                     Stmts   Miss Branch BrPart  Cover
----------------------------------------------------------
clair_cicd/__init__.py       2      2      0      0     0%
clair_cicd/assessor.py      10      0      4      0   100%
clair_cicd/io.py            42      0     10      1    98%
clair_cicd/models.py        30      0      0      0   100%
----------------------------------------------------------
TOTAL                       84      2     14      1    97%
----------------------------------------------------------------------
Ran 23 tests in 0.032s

OK
(env) ~>
```
