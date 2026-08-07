#!/bin/sh
# Every browser icon on this page is rendered from icon.svg, so the wrench is drawn once
# and the set cannot drift apart. Run it after editing icon.svg and commit what changes.
#
#   brew install librsvg imagemagick
set -e

png() { rsvg-convert -w "$1" -h "$1" "$3" -o "$2"; }

# iOS masks the home-screen icon itself, so that one is rendered square-cornered.
sed "s/rx='14'/rx='0'/" icon.svg > /tmp/jbr-square.svg

png 180 apple-touch-icon.png /tmp/jbr-square.svg
png 96 favicon-96x96.png icon.svg
png 192 web-app-manifest-192x192.png icon.svg
png 512 web-app-manifest-512x512.png icon.svg

# One .ico holding three sizes, each a PNG inside it, which is what a browser reaches for
# when it has been given no <link> — and what Windows and older Safari prefer regardless.
for size in 16 32 48; do png "$size" "/tmp/jbr-$size.png" icon.svg; done
magick /tmp/jbr-16.png /tmp/jbr-32.png /tmp/jbr-48.png favicon.ico
