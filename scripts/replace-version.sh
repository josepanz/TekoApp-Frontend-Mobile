#!/bin/bash
# Actualiza pubspec.yaml con la version que decide semantic-release.
# Uso: ./scripts/replace-version.sh <version-semver>
# El build number (segundo componente de la version de Flutter, X.Y.Z+N) sale de
# $GITHUB_RUN_NUMBER (monotonamente creciente por run, lo exporta el runner de Actions solo) -
# nunca del arg posicional, para evitar depender de que @semantic-release/exec expanda variables
# de shell dentro de su string de prepareCmd (execa no usa shell por default, "$VAR" ahi no se
# expande - leerla directo del entorno del proceso hijo si funciona, sin ese problema).
set -e

VERSION="$1"
BUILD_NUMBER="${GITHUB_RUN_NUMBER:-1}"

if [ -z "$VERSION" ]; then
  echo "Uso: $0 <version-semver>" >&2
  exit 1
fi

sed -i "s/^version: .*/version: ${VERSION}+${BUILD_NUMBER}/" pubspec.yaml
echo "pubspec.yaml -> version: ${VERSION}+${BUILD_NUMBER}"
