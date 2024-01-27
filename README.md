# nsh-c-icap
c-icap container image with Squid ClamAV integration

**ICAP support for the popular Open Source ClamAV virus scanner**


This project provides an easy to use container image to provide [ICAP](https://datatracker.ietf.org/doc/html/rfc3507) support for the Open Source standard virus scanner [ClamAV](https://www.clamav.net/).
ClamAV provides it's own protocol, which can be consumed leveraging a UNIX socket or TCP/IP connection.

The [SquidClamav](https://squidclamav.darold.net/) project provides the bride between ClamAV and ICAP.
ICAP itself is the standard used by Proxies like Squid. But ICAP as a protocol is also supported by appliances and products like [HCL Domino CScan](https://help.hcltechsw.com/domino/14.0.0/admin/conf_scanningattachmentsforviruses.html).


## Get repository

The easiest way to consume GitHub repositories is to use an installed [git](https://git-scm.com/) client.
Cloning a repository also allows to consume changes in the GitHub repository.


### Create a directory and switch to it

```
mkdir -p /local/github
cd /local/github
```

### Clone the repository and switch to it

```
git clone https://github.com/nashcom/nsh-c-icap.git

cd nsh-c-icap
```

## Build the image

Building the image is implemented using a multi-stage dockerfile.
The first build step builds the [SquidClam](https://squidclamav.darold.net/) integration.
The second build step consumes the resulting lib and builds a [c-icap](c-icap.sourceforge.net) image.


```
./build.sh
```

## Run the image

The project contains an easy to consume [docker-compose.yml](https://docs.docker.com/compose/compose-file/) file to bring up the ClamAV and c-icap container.

If [docker-compose](https://docs.docker.com/compose/) is installed run:

```
docker-compose up -d
```

Current Docker versions provide a plugin can provide the [compose command](https://docs.docker.com/compose/reference/) and don't need a separate installation:


```
docker compose up -d
```
