#!/usr/bin/env bash

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

test_assess_image_risk_dot_sh_no_command_line_args() {
    CLAIR_DOCKER_IMAGE=${1:-}
    CLAIR_DATABASE_DOCKER_IMAGE=${2:-}

    # :ODD: Normally you'd expect the line below to be something like
    # "STDOUT=$(mktemp)" but when that was used the error "The path /var/<something>
    # is not shared from OS X and is not known to Docker" was generated
    # and could not figure out what the problem and hence the current
    # implementation.
    STDOUT=${SCRIPT_DIR_NAME}/stdout.txt

    if "$(repo-root-dir.sh)/bin/assess-image-risk.sh" \
        -v \
        --no-pull \
        --clair-docker-image "${CLAIR_DOCKER_IMAGE}" \
        --clair-database-docker-image "${CLAIR_DATABASE_DOCKER_IMAGE}" \
        alpine:3.4 \
        >& "${STDOUT}"; then
        EXIT_CODE=0
    else
        EXIT_CODE=1

        echo ""
        echo "${FUNCNAME[0]} failed - >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
        cat "${STDOUT}"
        echo "${FUNCNAME[0]} failed - <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" 
    fi

    rm -f "${STDOUT}"

    return "${EXIT_CODE}"
}

test_assess_image_risk_dot_sh_inline_whitelist_command_line_args() {
    CLAIR_DOCKER_IMAGE=${1:-}
    CLAIR_DATABASE_DOCKER_IMAGE=${2:-}

    # :ODD: Normally you'd expect the line below to be something like
    # "STDOUT=$(mktemp)" but when that was used the error "The path /var/<something>
    # is not shared from OS X and is not known to Docker" was generated
    # and could not figure out what the problem and hence the current
    # implementation.
    STDOUT=${SCRIPT_DIR_NAME}/stdout.txt

    if "$(repo-root-dir.sh)/bin/assess-image-risk.sh" \
        -v \
        --no-pull \
        --clair-docker-image "${CLAIR_DOCKER_IMAGE}" \
        --clair-database-docker-image "${CLAIR_DATABASE_DOCKER_IMAGE}" \
        --whitelist 'json://{"ignoreSevertiesAtOrBelow": "medium"}' \
        alpine:3.4 \
        >& "${STDOUT}"; then
        EXIT_CODE=0
    else
        EXIT_CODE=1

        echo ""
        echo "${FUNCNAME[0]} failed - >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
        cat "${STDOUT}"
        echo "${FUNCNAME[0]} failed - <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" 
    fi

    rm -f "${STDOUT}"

    return "${EXIT_CODE}"
}

test_assess_image_risk_dot_sh_file_whitelist_command_line_args() {
    CLAIR_DOCKER_IMAGE=${1:-}
    CLAIR_DATABASE_DOCKER_IMAGE=${2:-}

    # :ODD: Normally you'd expect the line below to be something like
    # "STDOUT=$(mktemp)" but when that was used the error "The path /var/<something>
    # is not shared from OS X and is not known to Docker" was generated
    # and could not figure out what the problem and hence the current
    # implementation.
    STDOUT=${SCRIPT_DIR_NAME}/stdout.txt

    if "$(repo-root-dir.sh)/bin/assess-image-risk.sh" \
        -v \
        --no-pull \
        --clair-docker-image "${CLAIR_DOCKER_IMAGE}" \
        --clair-database-docker-image "${CLAIR_DATABASE_DOCKER_IMAGE}" \
        --whitelist "file://${SCRIPT_DIR_NAME}/data/whitelist-ignore-medium.json" \
        alpine:3.4 \
        >& "${STDOUT}"; then
        EXIT_CODE=0
    else
        EXIT_CODE=1

        echo ""
        echo "${FUNCNAME[0]} failed - >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
        cat "${STDOUT}"
        echo "${FUNCNAME[0]} failed - <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" 
    fi

    rm -f "${STDOUT}"

    return "${EXIT_CODE}"
}

test_assess_vulnerabilities_risk_dot_py_no_command_line_args() {
    CLAIR_DOCKER_IMAGE=${1:-}

    # :ODD: Normally you'd expect the line below to be something like
    # "STDOUT=$(mktemp)" but when that was used the error "The path /var/<something>
    # is not shared from OS X and is not known to Docker" was generated
    # and could not figure out what the problem and hence the current
    # implementation.
    STDOUT=${SCRIPT_DIR_NAME}/stdout.txt

    if ! docker run \
        --rm \
        --entrypoint assess-vulnerabilities-risk.py \
        "${CLAIR_DOCKER_IMAGE}" \
        >& "${STDOUT}"; then
        EXIT_CODE=0
    else
        EXIT_CODE=1

        echo ""
        echo "${FUNCNAME[0]} failed - >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
        cat "${STDOUT}"
        echo "${FUNCNAME[0]} failed - <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" 
    fi

    rm -f "${STDOUT}"

    return "${EXIT_CODE}"
}

test_assess_vulnerabilities_risk_dot_py_high_risk_inline_whitelist_high_ignore() {
    CLAIR_DOCKER_IMAGE=${1:-}
    VULNERABILITIES_CONTAINER=${2:-}

    # :ODD: Normally you'd expect the line below to be something like
    # "STDOUT=$(mktemp)" but when that was used the error "The path /var/<something>
    # is not shared from OS X and is not known to Docker" was generated
    # and could not figure out what the problem and hence the current
    # implementation.
    STDOUT=${SCRIPT_DIR_NAME}/stdout.txt

    if docker run \
        --rm \
        --volumes-from "${VULNERABILITIES_CONTAINER}" \
        --entrypoint assess-vulnerabilities-risk.py \
        "${CLAIR_DOCKER_IMAGE}" \
        "/vulnerabilities" --log info --whitelist 'json://{"ignoreSevertiesAtOrBelow": "high"}' \
        >& "${STDOUT}"; then
        EXIT_CODE=0
    else
        EXIT_CODE=1

        echo ""
        echo "${FUNCNAME[0]} failed - >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
        cat "${STDOUT}"
        echo "${FUNCNAME[0]} failed - <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" 
    fi

    rm -f "${STDOUT}"

    return "${EXIT_CODE}"
}

test_assess_vulnerabilities_risk_dot_py_high_risk_inline_whitelist_medium_ignore() {
    CLAIR_DOCKER_IMAGE=${1:-}
    VULNERABILITIES_CONTAINER=${2:-}

    # :ODD: Normally you'd expect the line below to be something like
    # "STDOUT=$(mktemp)" but when that was used the error "The path /var/<something>
    # is not shared from OS X and is not known to Docker" was generated
    # and could not figure out what the problem and hence the current
    # implementation.
    STDOUT=${SCRIPT_DIR_NAME}/stdout.txt

    if ! docker run \
        --rm \
        --volumes-from "${VULNERABILITIES_CONTAINER}" \
        --entrypoint assess-vulnerabilities-risk.py \
        "${CLAIR_DOCKER_IMAGE}" \
        "/vulnerabilities" --log info --whitelist 'json://{"ignoreSevertiesAtOrBelow": "medium"}' \
        >& "${STDOUT}"; then
        EXIT_CODE=0
    else
        EXIT_CODE=1

        echo ""
        echo "${FUNCNAME[0]} failed - >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
        cat "${STDOUT}"
        echo "${FUNCNAME[0]} failed - <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" 
    fi

    rm -f "${STDOUT}"

    return "${EXIT_CODE}"
}

test_wrapper() {
    TEST_FUNCTION_NAME=${1:-}
    shift
    NUMBER_TESTS_RUN=$((NUMBER_TESTS_RUN+1))
    echo -n "."
    if "${TEST_FUNCTION_NAME}" "$@"; then
        NUMBER_TEST_SUCCESSES=$((NUMBER_TEST_SUCCESSES+1))
    else
        NUMBER_TEST_FAILURES=$((NUMBER_TEST_FAILURES+1))
    fi
}

if [ $# != 2 ]; then
    echo "usage: $(basename "$0") <clair docker image> <clair database docker image>" >&2
    exit 1
fi

CLAIR_DOCKER_IMAGE=${1:-}
CLAIR_DATABASE_DOCKER_IMAGE=${2:-}

#
# :TRICKY: creating vulnerability container so the integration
# tests will work on CircleCI - see link below for pattern overview
# https://circleci.com/docs/2.0/building-docker-images/#mounting-folders
#
VULNERABILITIES_CONTAINER=vulnerabilities-$(openssl rand -hex 8)
# explict pull to create opportunity to swallow stdout
docker pull alpine:3.4 > /dev/null
docker create \
    -v /vulnerabilities \
    --name "${VULNERABILITIES_CONTAINER}" \
    alpine:3.4 \
    /bin/true \
    > /dev/null
find "${SCRIPT_DIR_NAME}/data/vulnerabilities/contains-high-severity" -name '*.json' | while IFS='' read -r FILENAME; do
    docker cp -a "${FILENAME}" "${VULNERABILITIES_CONTAINER}:/vulnerabilities"
done

NUMBER_TESTS_RUN=0
NUMBER_TEST_SUCCESSES=0
NUMBER_TEST_FAILURES=0

test_wrapper test_assess_image_risk_dot_sh_no_command_line_args \
    "${CLAIR_DOCKER_IMAGE}" \
    "${CLAIR_DATABASE_DOCKER_IMAGE}"

test_wrapper test_assess_image_risk_dot_sh_inline_whitelist_command_line_args \
    "${CLAIR_DOCKER_IMAGE}" \
    "${CLAIR_DATABASE_DOCKER_IMAGE}"

test_wrapper test_assess_image_risk_dot_sh_file_whitelist_command_line_args \
    "${CLAIR_DOCKER_IMAGE}" \
    "${CLAIR_DATABASE_DOCKER_IMAGE}"

test_wrapper test_assess_vulnerabilities_risk_dot_py_no_command_line_args \
    "${CLAIR_DOCKER_IMAGE}"

test_wrapper test_assess_vulnerabilities_risk_dot_py_high_risk_inline_whitelist_high_ignore \
    "${CLAIR_DOCKER_IMAGE}" \
    "${VULNERABILITIES_CONTAINER}"

test_wrapper test_assess_vulnerabilities_risk_dot_py_high_risk_inline_whitelist_medium_ignore \
    "${CLAIR_DOCKER_IMAGE}" \
    "${VULNERABILITIES_CONTAINER}"

echo ""
echo "Successfully completed ${NUMBER_TESTS_RUN} integration tests. ${NUMBER_TEST_SUCCESSES} successes. ${NUMBER_TEST_FAILURES} failures."

# :TRICKY: see comment above
docker kill "${VULNERABILITIES_CONTAINER}" >& /dev/null
docker rm "${VULNERABILITIES_CONTAINER}" >& /dev/null

if [[ "${NUMBER_TEST_FAILURES}" != "0" ]]; then
    exit 1
fi

exit 0
