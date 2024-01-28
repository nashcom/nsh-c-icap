
# TLS certificate and key for ICAP server

The container image supports two different modes.

## Provide your own certificate and key

Add the following files to this directory to use an existing TLS certificate and key

The following two files are automatically used if present

- cert.pem
- key.pem


## Automatically generate a local CA, key and certificate


If no certificate is specified, a CA and TLS certificate is created automatically.  
This directory is the default volume configured to store the CA key and certificate.

- The CA is vaild for 10 yeary
- The server certifcate is valid for 1 year and is re-created on every server start

The CA root certificate can be exported and trusted by your ICAP server.  
Domino CScan configuration can automatically import the root CA certificate in cscancfg.nsf.


