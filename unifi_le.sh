#!/bin/bash
# Bash script to simplify setup of Let's Encrypt certificates on a Unifi Cloud Key
# TODO:
# - automate creation of /root/scripts
# - Add in automatic download of copy of this script to /root/scripts

ACMEDIR="/root/.acme.sh"
DOMAINFILE="$ACMEDIR/unifidomain.txt"

setup() {
  # Get acme script and install
  wget -O - https://get.acme.sh | sh

  # Get FQDN for controller
  echo -e "Please type the Fully Qualified Domain Name for your Unifi Controller followed by [ENTER]:"
  echo -e "This can be something as simple as unifi.mydomain.com-just ensure you substitute"
  echo -e "mydomain.com for a domain you actually own with a registrar."

  read -r FQDN
  
  echo "$FQDN" >> $DOMAINFILE

  # Get alternate FQDN for guest portal
  echo -e "Type the Fully Qualified Domain Name for your Guest Portal to be used by your Unifi Controller followed by [ENTER]:"
  echo -e "\nThis can be something like portal.<mydomain>.com. Note: If your primary FQDN is unifi.homelab.mydomain.com,"
  echo -e "your portal domain should be something like portal.homelab.mydomain.com.  To skip, just press [ENTER]"

  read -r FQDN_ALT

  # Get CloudFlare API Key
  echo "Type the CloudFlare API Key to use, followed by [ENTER] - Note, the API key will not be displayed on your screen:"

  read -r -s CLOUDFLARE_KEY

  # Get CloudFlare Email Address
  echo "Type the email address for the previously entered CloudFlare API Key, followed by [ENTER]:"

  read -r CLOUDFLARE_EMAIL

  # Export the credentials to the shell-acme will save them to a file when done
  export CF_Key="$CLOUDFLARE_KEY"
  export CF_Email="$CLOUDFLARE_EMAIL"

  # Generate cert (this depends on using a Dynamic DNS-compatible provider
  if [ -z "$DOMAIN_ALT" ]
  then
    $ACMEDIR/acme.sh --issue --dns dns_cf -d "$FQDN" --force
  else
    $ACMEDIR/acme.sh --issue --dns dns_cf -d "$FQDN" -d "$FQDN_ALT" --force
  fi
}
installcerts() {
  # Read in text for domain used in setup
  read -r DOMAIN < "$DOMAINFILE"
  
  rm $ACMEDIR/"$DOMAIN"/{Cert.tar,cert.tar,unifi.p12,unifi.keystore.jks,cloudkey.cer,cloudkey.key}
  
  # Generate pkcs12 cert from acme output
  openssl pkcs12 -export -in ~/.acme.sh/"$DOMAIN"/fullchain.cer -inkey \
  $ACMEDIR/"$DOMAIN"/"$DOMAIN".key \
  -out $ACMEDIR/"$DOMAIN"/unifi.p12 -name unifi -password pass:aircontrolenterprise

  # Generate Java Keystore
  keytool -importkeystore -srckeystore $ACMEDIR/"$DOMAIN"/unifi.p12 \
  -srcstoretype PKCS12 -srcstorepass aircontrolenterprise -destkeystore \
  $ACMEDIR/"$DOMAIN"/unifi.keystore.jks -storepass aircontrolenterprise

  # Verify Java Keystore
  #keytool -list -v -keystore $ACMEDIR/"$DOMAIN"/unifi.keystore.jks

  # Create cloudkey.cer
  cat $ACMEDIR/"$DOMAIN"/fullchain.cer >> $ACMEDIR/"$DOMAIN"/cloudkey.cer

  # Create copy of cer with different extension for NGINX to use
  cp $ACMEDIR/"$DOMAIN"/cloudkey.cer $ACMEDIR/"$DOMAIN"/cloudkey.crt

  # Create cloudkey.key
  cp $ACMEDIR/"$DOMAIN"/"$DOMAIN".key $ACMEDIR/"$DOMAIN"/cloudkey.key

  # Create TAR file
  cd $ACMEDIR/"$DOMAIN" || return

  tar cf Cert.tar -C $ACMEDIR/"$DOMAIN" cloudkey.crt cloudkey.cer \
  cloudkey.key unifi.keystore.jks

  # We have to create a duplicate due to an odd behavior with the controller (at least in my experience).
  # cert.tar is used when the firmware is updated to replace the default self-signed certs.  However,
  # the verification script looks for Cert.tar-so we have to ensure we include both case-sensitive forms of the file
  cp Cert.tar cert.tar

  cd || return

  # Fix permissions
  chown root:ssl-cert $ACMEDIR/"$DOMAIN"/{cloudkey.crt,cloudkey.cer,cloudkey.key,unifi.keystore.jks,Cert.tar,cert.tar}

  # Additional sleep for good measure
  sleep 2

  chmod 640 $ACMEDIR/"$DOMAIN"/{cloudkey.crt,cloudkey.cer,cloudkey.key,unifi.keystore.jks,Cert.tar,cert.tar}

  sleep 2

  # Copy the new certificates to the location
  cp -p $ACMEDIR/"$DOMAIN"/{Cert.tar,cert.tar,cloudkey.crt,cloudkey.cer,cloudkey.key,unifi.keystore.jks} \
  /etc/ssl/private/

  # Restart nginx and unifi
  echo "Reloading Nginx and Unifi to complete updating of the certificates"
  systemctl reload nginx; systemctl restart unifi
}

installcron() {
  # Install the crontab for Acme
  $ACMEDIR/acme.sh installcronjob

  # Install our Unifi crontab
  UPDATE_SCRIPT="/root/scripts/unifi_le.sh  --cron"

  _CRONTAB="crontab"
  if ! $_CRONTAB -l | grep "$UPDATE_SCRIPT"; then
    $_CRONTAB -l | {
          cat
          echo "10 0 * * * \"$UPDATE_SCRIPT\" > /dev/null"
        } | $_CRONTAB -
  else
    echo "Entry exists"
  fi
}

while [ "$1" != "" ]; do
    case $1 in
        -s | --setup )          setup
                                installcerts
                                installcron
                                exit
                                ;;
        -c | --cron )           installcerts
                                exit
                                ;;
        -r | --repair )         installcerts
                                installcron
                                exit
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

if [ "$1" == "" ]; then
  setup
  installcerts
  installcron
  exit
fi
