# Signing

Every build is signed with one self-signed certificate:
**Oleg Puchkov Local Code Signing**.

## Why

macOS remembers the Accessibility permission by the app's signing identity.
Ad-hoc signing (`codesign --sign -`) creates a new identity on every build, so
after each update the permission silently stops working and has to be granted
again. With a fixed certificate you grant it once and it survives updates.

This is not an Apple Developer ID. Other Macs will still show a Gatekeeper
warning on first open. Remove it with:

```bash
xattr -dr com.apple.quarantine /Applications/PinchZoom.app
```

## Where the certificate lives

- Installed in the login keychain (used by `codesign`).
- Backup: `~/.config/codesign/signing.p12`, password in
  `~/.config/codesign/p12-password.txt`. Never commit these.

If the certificate is lost, a new one means granting Accessibility once more.

## Set up on another Mac

```bash
security import ~/.config/codesign/signing.p12 \
  -k ~/Library/Keychains/login.keychain-db \
  -P "$(cat ~/.config/codesign/p12-password.txt)" -T /usr/bin/codesign
```

## Release

```bash
scripts/release.sh 1.2.0   # sets VERSION, builds, signs, tags, publishes
```

Releases are built locally because the signing key stays on this Mac.
