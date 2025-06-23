# Installation Guide

This code should compile on any recent Linux distribution with a C++11/14/17-compatible compiler. Development and testing were performed on Ubuntu 24.04.2 LTS.

## Getting this repository
```bash
$ git clone --recursive https://github.com/KANGWEII/wiki.git
```

## Setup the environment
Run the following command to generate all necessary environment files, TLS certificates, and data directories.

When prompted for a hostname, you can:
- Enter the IP address of your host machine as assigned by your VPN (e.g., Tailscale, WireGuard) to access the Outline Wiki from any device on the same VPN network.
- Enter `localhost` if you're accessing it only from your local machine.
```bash
$ cd wiki
$ make install
```

After `public.crt` is generated, you can import the certificate into your browser (e.g., Google Chrome) to eliminate the “Not secure” warning when accessing the site. 