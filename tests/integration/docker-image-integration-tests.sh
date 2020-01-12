#!/usr/bin/env bash

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

assert_appears_in_output() {
    STDOUT=${1:-}
    PATTERN=${2:-}

    if grep --quiet "${PATTERN}" "${STDOUT}"; then
        return 0
    fi

    echo ""
    echo "${FUNCNAME[1]} assert_appears_in_output failed - >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>"
    echo "Pattern not found >>>${PATTERN}<<<"
    echo "${FUNCNAME[1]} assert_appears_in_output failed - >>>>>>>>>>>>>>>>>>>>>>"
    cat "${STDOUT}"
    echo "${FUNCNAME[1]} assert_appears_in_output failed - <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<"

    return 1
}

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

        assert_appears_in_output "${STDOUT}" "Assessment ends - pass"
        EXIT_CODE=$?
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

        assert_appears_in_output "${STDOUT}" "Assessment ends - pass"
        EXIT_CODE=$?
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
        --whitelist "file://${SCRIPT_DIR_NAME}/data/whitelists/ignore-medium.json" \
        alpine:3.4 \
        >& "${STDOUT}"; then

        assert_appears_in_output "${STDOUT}" "Assessment ends - pass"
        EXIT_CODE=$?
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

        assert_appears_in_output "${STDOUT}" "Usage: assess-vulnerabilities-risk.py"
        EXIT_CODE=$?
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
    VULNERABILITIES_AND_WHITELISTS_CONTAINER=${2:-}

    # :ODD: Normally you'd expect the line below to be something like
    # "STDOUT=$(mktemp)" but when that was used the error "The path /var/<something>
    # is not shared from OS X and is not known to Docker" was generated
    # and could not figure out what the problem and hence the current
    # implementation.
    STDOUT=${SCRIPT_DIR_NAME}/stdout.txt

    if docker run \
        --rm \
        --volumes-from "${VULNERABILITIES_AND_WHITELISTS_CONTAINER}" \
        --entrypoint assess-vulnerabilities-risk.py \
        "${CLAIR_DOCKER_IMAGE}" \
        "/vulnerabilities/contains-high-severity" --log info --whitelist 'json://{"ignoreSevertiesAtOrBelow": "high"}' \
        >& "${STDOUT}"; then

        assert_appears_in_output "${STDOUT}" "Vulnerability CVE-2016-4074 @ severity high less than or equal to whitelist severity @ high - pass"
        EXIT_CODE=$?
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

test_assess_vulnerabilities_risk_dot_py_high_risk_file_whitelist_high_ignore() {
    CLAIR_DOCKER_IMAGE=${1:-}
    VULNERABILITIES_AND_WHITELISTS_CONTAINER=${2:-}

    # :ODD: Normally you'd expect the line below to be something like
    # "STDOUT=$(mktemp)" but when that was used the error "The path /var/<something>
    # is not shared from OS X and is not known to Docker" was generated
    # and could not figure out what the problem and hence the current
    # implementation.
    STDOUT=${SCRIPT_DIR_NAME}/stdout.txt

    if docker run \
        --rm \
        --volumes-from "${VULNERABILITIES_AND_WHITELISTS_CONTAINER}" \
        --entrypoint assess-vulnerabilities-risk.py \
        "${CLAIR_DOCKER_IMAGE}" \
        "/vulnerabilities/contains-high-severity" --log info --whitelist 'file:///whitelists/ignore-high.json' \
        >& "${STDOUT}"; then

        assert_appears_in_output "${STDOUT}" "Vulnerability CVE-2016-4074 @ severity high less than or equal to whitelist severity @ high - pass"
        EXIT_CODE=$?
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
    VULNERABILITIES_AND_WHITELISTS_CONTAINER=${2:-}

    # :ODD: Normally you'd expect the line below to be something like
    # "STDOUT=$(mktemp)" but when that was used the error "The path /var/<something>
    # is not shared from OS X and is not known to Docker" was generated
    # and could not figure out what the problem and hence the current
    # implementation.
    STDOUT=${SCRIPT_DIR_NAME}/stdout.txt

    if ! docker run \
        --rm \
        --volumes-from "${VULNERABILITIES_AND_WHITELISTS_CONTAINER}" \
        --entrypoint assess-vulnerabilities-risk.py \
        "${CLAIR_DOCKER_IMAGE}" \
        "/vulnerabilities/contains-high-severity" --log info --whitelist 'json://{"ignoreSevertiesAtOrBelow": "medium"}' \
        >& "${STDOUT}"; then

        assert_appears_in_output "${STDOUT}" "Vulnerability CVE-2016-4074 @ severity high greater than whitelist severity @ medium - fail"
        EXIT_CODE=$?
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

test_assess_vulnerabilities_risk_dot_py_high_risk_file_whitelist_medium_ignore() {
    CLAIR_DOCKER_IMAGE=${1:-}
    VULNERABILITIES_AND_WHITELISTS_CONTAINER=${2:-}

    # :ODD: Normally you'd expect the line below to be something like
    # "STDOUT=$(mktemp)" but when that was used the error "The path /var/<something>
    # is not shared from OS X and is not known to Docker" was generated
    # and could not figure out what the problem and hence the current
    # implementation.
    STDOUT=${SCRIPT_DIR_NAME}/stdout.txt

    if ! docker run \
        --rm \
        --volumes-from "${VULNERABILITIES_AND_WHITELISTS_CONTAINER}" \
        --entrypoint assess-vulnerabilities-risk.py \
        "${CLAIR_DOCKER_IMAGE}" \
        "/vulnerabilities/contains-high-severity" --log info --whitelist 'file:///whitelists/ignore-medium.json' \
        >& "${STDOUT}"; then

        assert_appears_in_output "${STDOUT}" "Vulnerability CVE-2016-4074 @ severity high greater than whitelist severity @ medium - fail"
        EXIT_CODE=$?
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

test_assess_vulnerabilities_risk_dot_py_high_risk_file_whitelist_medium_ignore_plus_ignore_specific_vulnerability() {
    CLAIR_DOCKER_IMAGE=${1:-}
    VULNERABILITIES_AND_WHITELISTS_CONTAINER=${2:-}

    # :ODD: Normally you'd expect the line below to be something like
    # "STDOUT=$(mktemp)" but when that was used the error "The path /var/<something>
    # is not shared from OS X and is not known to Docker" was generated
    # and could not figure out what the problem and hence the current
    # implementation.
    STDOUT=${SCRIPT_DIR_NAME}/stdout.txt

    if docker run \
        --rm \
        --volumes-from "${VULNERABILITIES_AND_WHITELISTS_CONTAINER}" \
        --entrypoint assess-vulnerabilities-risk.py \
        "${CLAIR_DOCKER_IMAGE}" \
        "/vulnerabilities/contains-high-severity" --log info --whitelist 'file:///whitelists/ignore-medium-and-below-plus-ignore-CVE-2016-4074.json' \
        >& "${STDOUT}"; then

        assert_appears_in_output "${STDOUT}" "Vulnerability CVE-2016-4074 in whitelist - pass"
        EXIT_CODE=$?
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
VULNERABILITIES_AND_WHITELISTS_CONTAINER=vul-and-wl-$(openssl rand -hex 8)
# explict pull to create opportunity to swallow stdout
docker pull alpine:3.4 > /dev/null
docker create \
    -v /vulnerabilities \
    -v /whitelists \
    --name "${VULNERABILITIES_AND_WHITELISTS_CONTAINER}" \
    alpine:3.4 \
    mkdir /bin/true \
    > /dev/null

if ! docker cp -a "${SCRIPT_DIR_NAME}/data/vulnerabilities" "${VULNERABILITIES_AND_WHITELISTS_CONTAINER}:/"; then
    echo "error"
    exit 1
fi

if ! docker cp -a "${SCRIPT_DIR_NAME}/data/whitelists" "${VULNERABILITIES_AND_WHITELISTS_CONTAINER}:/"; then
    echo "error"
    exit 1
fi

#
# test_wrapper function will update these environment variables
# so we can generate a reasonable status message after running
# all the integration tests
#
NUMBER_TESTS_RUN=0
NUMBER_TEST_SUCCESSES=0
NUMBER_TEST_FAILURES=0

#
# all the setup is done - time to run some tests!
#
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
    "${VULNERABILITIES_AND_WHITELISTS_CONTAINER}"

test_wrapper test_assess_vulnerabilities_risk_dot_py_high_risk_file_whitelist_high_ignore \
    "${CLAIR_DOCKER_IMAGE}" \
    "${VULNERABILITIES_AND_WHITELISTS_CONTAINER}"

test_wrapper test_assess_vulnerabilities_risk_dot_py_high_risk_inline_whitelist_medium_ignore \
    "${CLAIR_DOCKER_IMAGE}" \
    "${VULNERABILITIES_AND_WHITELISTS_CONTAINER}"

test_wrapper test_assess_vulnerabilities_risk_dot_py_high_risk_file_whitelist_medium_ignore \
    "${CLAIR_DOCKER_IMAGE}" \
    "${VULNERABILITIES_AND_WHITELISTS_CONTAINER}"

test_wrapper test_assess_vulnerabilities_risk_dot_py_high_risk_file_whitelist_medium_ignore_plus_ignore_specific_vulnerability \
    "${CLAIR_DOCKER_IMAGE}" \
    "${VULNERABILITIES_AND_WHITELISTS_CONTAINER}"

#
# all the tests are complete - generate a reasonable status message
#
echo ""
echo "Successfully completed ${NUMBER_TESTS_RUN} integration tests. ${NUMBER_TEST_SUCCESSES} successes. ${NUMBER_TEST_FAILURES} failures."

#
# cleanup ...  :TRICKY: see comment above
#
docker kill "${VULNERABILITIES_AND_WHITELISTS_CONTAINER}" >& /dev/null
docker rm "${VULNERABILITIES_AND_WHITELISTS_CONTAINER}" >& /dev/null

#
# and we're done:-)
#
if [[ "${NUMBER_TEST_FAILURES}" != "0" ]]; then
    exit 1
fi

exit 0
