#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

echo
echo "Determining if the template has been initialized..."
echo

template_branch_name='template'
git_branches=$(git branch)
default_branch="${default_branch:=unspecified}"

echo "Branches:"
echo "${git_branches}"
echo

if ! [[ ${git_branches} =~ ${template_branch_name} ]]; then
    echo "${template_branch_name} branch doesn't exist."
    echo

    checkout_output=$(git checkout ${template_branch_name} 2>&1 || true)
    error_pattern="error: pathspec '${template_branch_name}' did not match any file(s) known to git"

    echo "checkout_output:"
    echo "${checkout_output}"
    echo "end checkout_output."
    echo

    if [[ "${checkout_output}" == "${error_pattern}" ]]; then
        echo "Template needs to be initialized, initializing..."
        template_url=https://github.com/fp-mt-test-org/template-v2-test ./.ngif/initialize-template.sh
    else
        echo "${template_branch_name} branch exists, switching to it."
        git checkout "${template_branch_name}"
    fi

    git checkout "${default_branch}"
else
    echo "Template has been previously initialized."
fi
