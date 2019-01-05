# Unifi Controller - Let's Encrypt

## Overview

The unifi_le.sh script basically provide a simple way to get Let's Encrypt going on a UCK via [ACME.sh](https://github.com/Neilpang/acme.sh)-with the assumption that you're using Cloudflare for your DNS provider as it offers an API which ACME.sh can use to insert TXT records to support [DNS verification](https://github.com/Neilpang/acme.sh#8-automatic-dns-api-integration) with Let's Encrypt.

## How does it work?

This script is still a work in progress-so bear with me.  It requires currently that you make a directory at `/root` called `scripts` (so `/root/scripts`).

You have to run `chmod +x unifi_le.sh` to make the file executable.  From there to get started, just run it `./unifi_le.sh` and the default with no arguments is to set everything up from scratch.  This script will grab acme.sh, prompt you for your FQDN for your controller, if you don't have an alternative FQDN for your guest portal, you can skip that and then it will prompt for your cloudflare API key and email address.  After that, it will leverage acme.sh to request the certificates.

### Is that it?

Well, no, actually.  The script creates a cron job that *should* run 10 minutes after the acme script runs daily-so that when acme.sh renews the certificate, this script will automatically update the certificates used by nginx and unifi on the UCK.

### What are the command flags?

#### -s | --setup

This is an alternative to running the script without any flags-it doesn't make a difference though.

#### -r | --repair

This will re-install the acme certificates and cron jobs after performing a Unifi SDN update.  Since the SDN update doesn't wipe the `/root/` directory, `/root/.acme.sh` will still be intact-so we should only need to install the cron tasks-but we reinstall the certificates for good measure.

#### -c | --cron

This simply reinstalls the cron jobs for ACME.sh and for this script to ensure renewals continue normally.

#### -h | --help

This one doesn't do anything-the flags are new so I haven't had a chance to write the procedure for this one yet.
