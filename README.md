# docsys

Document build system based on GNU Make

## Setting up

### Add to new project or no-vcs project

```bash
$ mkdir your-project
$ cd your-project
$ git clone https://github.com/yasuo-ozu/docsys.git .docsys
$ make -C .docsys install
```

### Add to a vcs project

```bash
$ cd your-project
$ git submodule add https://github.com/yasuo-ozu/docsys.git .docsys
$ make -C .docsys install
```

## Use sample

```bash
$ cp -r .docsys/sample/simple/* .
```
