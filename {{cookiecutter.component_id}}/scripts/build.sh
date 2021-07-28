#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

jfrog='jfrog-cli'

echo 
echo "Installing ${jfrog}..."
brew install "${jfrog}"
echo "${jfrog} installation complete."
echo
jfrog_config_show_output=$(jfrog c show)
echo "${jfrog_config_show_output}"
echo

config_name='artifactory'
config_name_pattern="Server ID:[[:space:]]*${config_name}"

if ! [[ ${jfrog_config_show_output} =~ ${config_name_pattern} ]]; then
    echo "Configuring ${jfrog}..."
    jfrog c add "${config_name}" \
        --url="${artifactory_base_url}" \
        --user="${artifactory_username}" \
        --access-token="${artifactory_password}" \
        --artifactory-url="${artifactory_base_url}/artifactory" \
        --interactive=false
    echo "${jfrog} configured."
    echo
fi

echo "Building with ${jfrog}..."
jfrog rt \
    gradle clean \
    artifactoryPublish -b build.gradle \
    --build-name={{cookiecutter.component_id}} \
    --build-number=1 \
    -Pversion=1.1.0
echo "Build complete."
echo
