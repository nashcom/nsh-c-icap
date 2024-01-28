# nsh-c-icap
c-icap container image with Squid ClamAV integration

**ICAP support for the popular Open Source ClamAV virus scanner**


This project provides an easy to use container image to provide [ICAP](https://datatracker.ietf.org/doc/html/rfc3507) support for the Open Source standard virus scanner [ClamAV](https://www.clamav.net/).
ClamAV provides it's own protocol, which can be consumed leveraging a UNIX socket or TCP/IP connection.

The [c-icap](https://github.com/c-icap/c-icap-server) project is a standard project included in many Linux distributions to provide the ICAP protocols for applications.


The [SquidClamav](https://squidclamav.darold.net/) project provides the bride between ClamAV and ICAP.
ICAP itself is the standard used by Proxies like Squid. But ICAP as a protocol is also supported by appliances and products like [HCL Domino CScan](https://help.hcltechsw.com/domino/14.0.0/admin/conf_scanningattachmentsforviruses.html).

This repository consumes both GitHub projects to build the container image based on a [Redhat Universal Base Image (UBI)](https://www.redhat.com/en/blog/introducing-red-hat-universal-base-image).
The RedHat UBI minimal based image provides a small footprint Linux container image.



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

The project contains an easy to consume [docker-compose.yml](https://docs.docker.com/compose/compose-file/) file to bring up the ClamAV and ##c-icap container.

If [docker-compose](https://docs.docker.com/compose/) is installed run:

```
docker-compose up -d
```

Current Docker versions provide a plugin can provide the [compose command](https://docs.docker.com/compose/reference/) and don't need a separate installation:


```
docker compose up -d
```


## Configuation

The project uses a docker-compose file with variables, which are defined in the **.env** environment file.


## Exposed ports

The containers expose the following ports.

### c-icap container

- **TCP 1344** standard ICAP port (unencrypted)
- **TCP 11344** standard ICAP TLS port (TLS protected)

### clamav container

Because the ClamAV protocol is unencryted and mainly used for local sockets and local TCP/IP connections, the port is not exposed and only used inside the container network.
In case the port should be used outside, TLS could be provided by NGINX. But this would require the consuming side to support TLS or offload TLS for the consuming side.

- **TCP 3310** clamd protocol (unencrypted)


## ICAP Service name

The following services are exposed

- **echo** mainly for testing connections
- **clamav** ClamAV service over ICAP


## TLS Certificate/Key

Certificates and keys are located in the **/certs** directory.
If no certificate/key is provided, the container creates it's own root CA and issues a new server certificate on start (valid for 365 days).
The root CA is valid for 10 years and is maintained in the **/certs** directory.
Therefore a volume mount is required to store the CA key and certificate permanently.

For custom certificates provide the following two files in the **/certs** directory in PEM format.

- cert.pem
- key.pem


## Tested environments

- Docker on Linux
- Podman on Linux
- Docker Desktop on Windows
- Docker Desktop on MacOS

On Linux ARM and Mac Apple Silicon (M1/M2) an Linux ARM image is created.  
The resulting image is always a Redhat UBI image.



## Testing and troubleshooting

The c-icap project offers a simple to use ICAP client in addition to the server components.
The command line client can be used to test the server. A basic test is to use the ICAP Options request.
The same client is also used inside the **c-icap** container for health checking the container.

Just invoking the client will query the **echo** service to check if the server is generally responding:


```
c-icap-client
```

To test the ClamAV service end point run the follwing command.


```
c-icap-client -s clamav
```

The project also contains the EICAR test virus, which is copied into the container image.


To scan the EICAR virus file specify the following command.


```
c-icap-client -s clamav -f eicar.txt -v
```

Encpryted connections on a remote server require the TLS option and the DNS name matching the certificate.
Because the certificate usually is issued by the internal CA, TLS verification should be disabled for this simple check.
A remote server should import and trust the CA certificate.


```
c-icap-client -s clamav -p 11344 icap.myserver.com -tls -tls-no-verify -f eicar.txt -v
```


### Example Output


```
ICAP server:localhost, ip:::1, port:1344

ICAP HEADERS:
        ICAP/1.0 200 OK
        Server: C-ICAP/0.6.0
        Connection: keep-alive
        ISTag: "CI0001-1-squidclamav-10"
        X-Virus-ID: Win.Test.EICAR_HDB-1 FOUND
        X-Infection-Found: Type=0; Resolution=2; Threat=Win.Test.EICAR_HDB-1 FOUND;
        Encapsulated: res-hdr=0, res-body=320

RESPMOD HEADERS:
        HTTP/1.1 403 Forbidden
        Server: C-ICAP
        Connection: close
        Content-Type: text/html
        X-Virus-ID: Win.Test.EICAR_HDB-1 FOUND
        X-Infection-Found: Type=0; Resolution=2; Threat=Win.Test.EICAR_HDB-1 FOUND;
        Content-Language: en
        Content-Length: 92
        Via: ICAP/1.0 c-icap_clamav (C-ICAP/0.6.0 SquidClamav/Antivirus service )
```
