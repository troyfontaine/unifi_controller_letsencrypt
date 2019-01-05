# Unifi Controller - Let's Encrypt

## Overview

This repository contains scripts intended to be used with a host that has the Unifi controller software installed.  It assumes that the host is actually a Unifi Cloudkey-so it may not work as desired on other hosts.

These scripts basically provide a simple way to get Let's Encrypt going on a UCK via [ACME.sh](https://github.com/Neilpang/acme.sh)-with the assumption that you're using Cloudflare for your DNS provider as it leverages [DNS authentication](https://github.com/Neilpang/acme.sh#8-automatic-dns-api-integration) with Let's Encrypt.

## How does it work?

This script is still a work in progress-so bear with me.  It requires currently that you make a directory at `/root` called `scripts` (so `/root/scripts`).

You have to run `chmod +x unifi_le.sh` to make the file executable.  From there to get started, just run it `./unifi_le.sh` and the default with no arguments is to set everything up from scratch.  This script will grab acme.sh, prompt you for your FQDN for your controller, if you don't have an alternative FQDN for your guest portal, you can skip that and then it will prompt for your cloudflare API key and email address.  After that, it will leverage acme.sh to request the certificates.
