#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

# These tests are based on the steps outlined in the README.
# The purpose is to perform the same actions the README is asking
# people to do so we can catch any regressions with it.

github_owner='fp-mt-test-org'

# generate_project_name() {
#     random_string=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 5 ; echo)
#     project_name="java-kotlin-lib-test-${random_string}"

#     echo "${project_name}"
# }

# create_from_template() {
#     template_name="${1}"
#     project_name_to_create="${2}"

#     get_actions_curl_command="curl -sH \"Accept: application/vnd.github.v3+json\" -H \"authorization: Bearer ${GITHUB_TOKEN}\" \"https://api.github.com/repos/${github_owner}/${project_name}/actions/runs\""
#     echo
#     echo "Submit Create Request to Maker Portal"
#     template_name="${template_name}" project_name="${project_name_to_create}" ./scripts/create-project.sh
#     echo
#     echo "Wait for GitHub Repo to be Created..."
#     counter=0
#     max_tries=10
#     seconds_between_tries=5
#     while true; do
#         echo "${counter} Checking..."
#         response=$(eval "${get_actions_curl_command}")

#         if [[ "${response}" =~ "Not Found" ]]; then
#             echo "${project_name} not yet found."
#         else
#             echo "${project_name} repo found!"
#             break
#         fi

#         if [[ "${max_tries}" == "${counter}" ]]; then
#             echo "Giving up after ${max_tries}, test failed!"
#             exit 1
#         fi

#         counter=$((counter+1))
#         sleep "${seconds_between_tries}"
#     done
#     echo
# }

i=0 # Step counter
github_base_url="https://github.com/${github_owner}"
template_name="v1beta2-demo-2"
flex='./flex.sh'

echo "=================================="
echo "TEST: Create library from template"
echo "=================================="
echo "Step $((i=i+1)): Generate Unique Project Name"
random_string=$(LC_ALL=C tr -dc 'A-Za-z0-9' </dev/urandom | head -c 5 ; echo)
project_name="${template_name}-${random_string}"
repository_path="${github_base_url}/${project_name}"
echo "Project Name: ${project_name}"

get_actions_curl_command="curl -sH \"Accept: application/vnd.github.v3+json\" -H \"authorization: Bearer ${GITHUB_TOKEN}\" \"https://api.github.com/repos/fp-mt-test-org/${project_name}/actions/runs\""
echo
echo "Step $((i=i+1)): Submit Create Request to Maker Portal"
template_name="${template_name}" project_name="${project_name}" ./scripts/create-library.sh
echo 
echo
echo "Step $((i=i+1)): Wait for GitHub Repo to be Created"
counter=0
max_tries=20
seconds_between_tries=5
while true; do
    echo "${counter} Checking..."
    response=$(eval "${get_actions_curl_command}")

    if [[ "${response}" =~ "Not Found" ]]; then
        echo "${project_name} not yet found."
    else
        echo "Repo found!"
        break
    fi

    if [[ "${max_tries}" == "${counter}" ]]; then
        echo "Giving up after ${max_tries}, test failed!"
        exit 1
    fi

    counter=$((counter+1))
    sleep "${seconds_between_tries}"
done
echo 
echo "Step $((i=i+1)): Verify CI Build is Successful"
counter=0
max_tries=100
seconds_between_tries=5
while true; do
    echo "${counter} Checking for build result..."
    response=$(eval "$get_actions_curl_command")

    if [[ "${response}" =~ \"status\"\:[[:space:]]+\"([A-Za-z_]+)\" ]]; then
        status="${BASH_REMATCH[1]}"
        echo "status: ${status}"
    else
        status="unknown"
        echo "Result unknown:"
        echo "${response}"
        echo
    fi

    if [[ "${response}" =~ \"conclusion\"\:[[:space:]]+\"*([A-Za-z_]+)\"* ]]; then
        conclusion="${BASH_REMATCH[1]}"
        echo "conclusion: ${conclusion}"
    else
        conclusion="unknown"
    fi

    if [[ "${status}" == "completed" ]]; then
        if [[ "${conclusion}" != "success" ]]; then
            echo "Build was not successful, test failed!"
            exit 1
        else
            break
        fi
    fi

    if [[ "${max_tries}" == "${counter}" ]]; then
        echo "Giving up after ${max_tries}, test failed!"
        exit 1
    fi

    counter=$((counter+1))
    sleep "${seconds_between_tries}"

    echo
done
echo

echo "Step $((i=i+1)): Verify Artifact was Published"
artifact_url="${artifactory_base_url}/artifactory/${project_name}-mvn-dev-local/${project_name}/1.1.0/${project_name}-1.1.0.jar"
echo "Attempting to download:"
echo "${artifact_url}"
curl \
    "${artifact_url}" \
    --output "${project_name}-1.1.0.jar"
echo "Artifact download successful!"
echo
echo "Step $((i=i+1)): Clone repo locally"
git clone "${repository_path}.git"
cd "${project_name}"
echo
echo "Step $((i=i+1)): Verify Local Build is Successful"
"${flex}" build
echo
echo "Step $((i=i+1)): Attempting update-template..."
git fetch --all # Make sure we have latest version from source.

# Temporary hack:
# Merging here to simulate a developer merging this change....
git merge origin/initialize-template

echo
"${flex}" update-template
echo
echo "Passed!"
echo "Step $((i=i+1)): Cleanup"
cd ..
echo "Deleteing ${project_name} locally..."
rm -fdr "${project_name}"
echo "Deleteing ${project_name} remotely..."
curl \
  -X DELETE \
  -H "Accept: application/vnd.github.v3+json" \
  -H "Authorization: token ${GITHUB_TOKEN}" \
   "https://api.github.com/repos/${github_owner}/${project_name}"
echo
echo "Done!"
echo

# echo "=================================="
# echo "TEST: Update library from template"
# echo "=================================="
# i=0
# expected_flex_version_initial='0.5.0'
# expected_flex_version_upgrade='0.5.1'
# repo_name='template-java-kotlin-library-test-template-update'

# if [[ -d "${repo_name}" ]]; then
#     rm -fdr "${repo_name}"
# fi

# echo "Step $((i=i+1)): Clone repo that was created from template"
# git clone "${github_base_url}/${repo_name}.git"
# cd "${repo_name}"
# echo ""
# echo "Step $((i=i+1)): Check current flex version"
# "${flex}" -version
# flex_version=$("${flex}" -version)
# if [[ "${flex_version}" != "${expected_flex_version_initial}" ]]; then
#     echo "ERROR: flex_version is ${flex_version} but expected ${expected_flex_version_initial}"
#     exit 1
# fi

# echo ""
# echo "Step $((i=i+1)): Update repo from updated template"
# "${flex}" update-template
# echo ""
# echo "Step $((i=i+1)): Check the updated flex version"
# "${flex}" -version
# flex_version=$("${flex}" -version)
# echo ""
# if [[ "${flex_version}" != "${expected_flex_version_upgrade}" ]]; then
#     echo "ERROR: flex_version is ${flex_version} but expected ${expected_flex_version_upgrade}"
#     exit 1
# fi
# echo ""
# echo "Step $((i=i+1)): Cleanup"
# cd ..
# rm -fdr "${repo_name}"
# echo "Pass!"
# echo
# echo "======================"
# echo "TEST: Publish Library"
# echo "====================="
# i=0

# echo "Step $((i=i+1)): Generate Unique Project Name"
# project_name=generate_project_name
# echo "Project Name: ${project_name}"



# echo "Step $((i=i+1)): Clone repo that was created from template"
# git clone "${github_base_url}/${repo_name}.git"
# cd "${repo_name}"
# echo ""

# echo "Step $((i=i+1)): Build a Release"
# "${flex}" build

# echo "Step $((i=i+1)): Publish to Artifactory"
# "${flex}" publish

# echo "Step $((i=i+1)): Verify the Release"
# curl https://artifactory.flexport.io/artifactory/template-java-kotlin-library-mvn-sandbox-local/

echo "Step $((i=i+1)): Cleanup"
cd ..
rm -fdr "${project_name}"
