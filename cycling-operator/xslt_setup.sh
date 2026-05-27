#!/usr/bin/env bash
set -e

LIBS_DIR="libs"

if [ -d "$LIBS_DIR" ] && [ -f "$LIBS_DIR/saxon-he-12.4.jar" ] && [ -f "$LIBS_DIR/xmlresolver-5.1.1.jar" ]; then
  echo "XSLT libraries already present in '$LIBS_DIR/'. Nothing to do."
  exit 0
fi

mkdir -p "$LIBS_DIR"
echo "Downloading Saxon HE and XML Resolver into '$LIBS_DIR/'..."

curl -Lo "$LIBS_DIR/saxon-he-12.4.jar" \
  https://repo1.maven.org/maven2/net/sf/saxon/Saxon-HE/12.4/Saxon-HE-12.4.jar

curl -Lo "$LIBS_DIR/xmlresolver-5.1.1.jar" \
  https://repo1.maven.org/maven2/org/xmlresolver/xmlresolver/5.1.1/xmlresolver-5.1.1.jar

echo "Done. Libraries ready in '$LIBS_DIR/'."
