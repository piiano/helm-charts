#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

if [ $# -ne 2 ]; then
  echo "Incorrect Usage: $0 <NEW_VAULT_VERSION> <BUMP_CHART_TYPE>"
  exit 1
fi

# Save the arguments to variables
NEW_VAULT_VERSION=$1
BUMP_CHART_TYPE=$2

LINE="This package is compatible with Vault version"
DIR=./charts/pvault-server
README=${DIR}/README.md
VALUES=${DIR}/values.yaml
CHART=${DIR}/Chart.yaml

set -x

OLD_VAULT_VERSION=$(helm show values --jsonpath '{.image.tag}' ${DIR})

# replace supported vault version message in readme
sed --in-place -e "s|$LINE \`$OLD_VAULT_VERSION\`|$LINE \`$NEW_VAULT_VERSION\`|g" ${README}

# replace image tag in readme
sed --in-place -e "s|\`$OLD_VAULT_VERSION\`|\`$NEW_VAULT_VERSION\`|g" ${README}
sed --in-place -e "s|piiano/pvault-cli:$OLD_VAULT_VERSION\"|piiano/pvault-cli:$NEW_VAULT_VERSION\"|g" ${README}

# replace tag in vaules.yaml
sed --in-place -e "s|tag: $OLD_VAULT_VERSION|tag: $NEW_VAULT_VERSION|g" ${VALUES}

# find and generate new helm chart version
# use ^ to find the version starting at the beginning of a line to not confuse with psql version
CUR_HELM_VER=$(grep '^version' ${CHART} | sed 's/version: //g' | sed 's/"//g')
NEW_HELM_VER=$(npx --yes semver -i "${BUMP_CHART_TYPE}" "${CUR_HELM_VER}")

# bump main chart version and appversion
sed --in-place -E "s|version: [0-9]+\.[0-9]+\.[0-9]+|version: ${NEW_HELM_VER}|g" ${CHART}
sed --in-place -E "s|appVersion: [0-9]+\.[0-9]+\.[0-9]+|appVersion: ${NEW_VAULT_VERSION}|g" ${CHART}
