#!/bin/bash
# Creates the "MacClipboard Code Signing" certificate in your login Keychain. Run once per machine.
#
# Signing every release with the same certificate keeps the app's code signature stable, so macOS
# remembers the Accessibility permission and Keychain access across updates.
#
# Back up the exported .p12 this prints: without it, future releases get a new signature and every
# user has to grant Accessibility again.
set -euo pipefail

NAME="MacClipboard Code Signing"
KEYCHAIN="$HOME/Library/Keychains/login.keychain-db"
BACKUP="$HOME/Desktop/MacClipboard-Code-Signing.p12"

if security find-identity -p codesigning "$KEYCHAIN" | grep -q "\"$NAME\""; then
  echo "\"$NAME\" already exists in your login Keychain."
  exit 0
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cd "$WORK"

openssl req -x509 -newkey rsa:3072 -sha256 -days 3650 -nodes -keyout key.pem -out cert.pem \
  -subj "/CN=$NAME" \
  -addext "basicConstraints=critical,CA:false" \
  -addext "keyUsage=critical,digitalSignature" \
  -addext "extendedKeyUsage=critical,codeSigning" 2>/dev/null

read -r -s -p "Choose a password for the backup file: " PASS; echo
# 3DES/SHA1 is the PKCS#12 encoding that macOS's security tool can import.
openssl pkcs12 -export -inkey key.pem -in cert.pem -name "$NAME" -out "$BACKUP" \
  -passout "pass:$PASS" -certpbe PBE-SHA1-3DES -keypbe PBE-SHA1-3DES -macalg sha1

security import "$BACKUP" -k "$KEYCHAIN" -P "$PASS" -T /usr/bin/codesign
echo "Trusting the certificate for code signing (macOS will ask for your password)..."
security add-trusted-cert -r trustRoot -p codeSign -k "$KEYCHAIN" cert.pem

security find-identity -v -p codesigning "$KEYCHAIN" | grep "$NAME"
echo
echo "Done. Backup saved to $BACKUP"
echo "Move it to a password manager or other safe place, then delete it from the Desktop."
