#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

jfrog rt bp {{cookiecutter.component_id}} 1
