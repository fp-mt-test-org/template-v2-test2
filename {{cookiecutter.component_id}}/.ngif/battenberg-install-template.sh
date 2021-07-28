#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# Purpose of this file is to execute the battenberg install command
# and feed in the values previously configured in the context file.

template_context_file='.cookiecutter.json'
template_context_path="./${template_context_file}"

echo "template_context_file:"
cat "${template_context_path}"
echo "end template_context_file."
echo

template_url="${github_base_url}/${template_name}"

echo "Installing ${template_url}"
echo

# This codeblock answers the prompts issued by battenberg below.
{
    if [[ -d "$HOME/.cookiecutters" ]]; then
        # You've downloaded ... before.
        # Is it okay to delete and re-download it? [yes]:
        echo "1";
        sleep 1;
    fi

    # template []:
    echo # accept the default
    sleep 1;

    # component_id []:
    jq -r '.component_id' ${template_context_path}
    sleep 1;

    # repo_owner []:
    jq -r '.repo_owner' ${template_context_path}
    sleep 1;

    # artifact_id [javakotlinlibtest*****]:
    jq -r '.artifact_id' ${template_context_path}
    sleep 1;

    # storePath [javakotlinlibtest*****]:
    jq -r '.storePath' ${template_context_path}
    sleep 1;

    # java_package_name [javakotlinlibtest*****]:
    jq -r '.java_package_name' ${template_context_path}
    sleep 1;

    # java_package_name [javakotlinlibtest*****]:
    jq -r '.description' ${template_context_path}
    sleep 1;

    # java_package_name [javakotlinlibtest*****]:
    jq -r '.secrets_artifactory_base_url' ${template_context_path}
    sleep 1;

    # java_package_name [javakotlinlibtest*****]:
    jq -r '.secrets_artifactory_username' ${template_context_path}
    sleep 1;

    # java_package_name [javakotlinlibtest*****]:
    jq -r '.secrets_artifactory_password' ${template_context_path}
    sleep 1;

} | battenberg install "${template_url}"
