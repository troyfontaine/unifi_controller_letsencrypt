# Unifi Controller - Let's Encrypt

## Overview

This repository contains scripts intended to be used with a host that has the Unifi controller software installed.  It assumes that the host is actually a Unifi Cloudkey-so it may not work as desired on other hosts.

These scripts basically provide a simple way to get Let's Encrypt going on a UCK via [ACME.sh](https://github.com/Neilpang/acme.sh)-with the assumption that you're using Cloudflare for your DNS provider as it leverages [DNS authentication](https://github.com/Neilpang/acme.sh#8-automatic-dns-api-integration) with Let's Encrypt.

## Why two scripts?

My bash-fu isn't spectacular and I haven't had time to do things more idempotently-so it is what it is.
