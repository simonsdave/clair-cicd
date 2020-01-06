#!/usr/bin/env bash

SCRIPT_DIR_NAME="$( cd "$( dirname "$0" )" && pwd )"

test_assess_vulnerabilities_risk_dot_py_no_command_line_args() {
    DOCKER_IMAGE=${1:-}

    # :ODD: Normally you'd expect the line below to be something like
    # "STDOUT=$(mktemp)" but when that was used the error "The path /var/<something>
    # is not shared from OS X and is not known to Docker" was generated
    # and could not figure out what the problem and hence the current
    # implementation.
    STDOUT=${SCRIPT_DIR_NAME}/stdout.txt

    if ! docker run \
        --rm \
        --entrypoint assess-vulnerabilities-risk.py \
        "${DOCKER_IMAGE}" \
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
    DOCKER_IMAGE=${1:-}

    # :ODD: Normally you'd expect the line below to be something like
    # "STDOUT=$(mktemp)" but when that was used the error "The path /var/<something>
    # is not shared from OS X and is not known to Docker" was generated
    # and could not figure out what the problem and hence the current
    # implementation.
    STDOUT=${SCRIPT_DIR_NAME}/stdout.txt

    if docker run \
        --rm \
        -v "${SCRIPT_DIR_NAME}/vulnerabilities/contains-high-severity:/vulnerabilities" \
        --entrypoint assess-vulnerabilities-risk.py \
        "${DOCKER_IMAGE}" \
        "/vulnerabilities" --log info --whitelist '{"ignoreSevertiesAtOrBelow": "high"}' \
        >& "${STDOUT}"; then
        EXIT_CODE=0

        echo ""
        echo "${FUNCNAME[0]} success - >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
        ls -la "${SCRIPT_DIR_NAME}/vulnerabilities/contains-high-severity"
        echo "${FUNCNAME[0]} success - >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
        cat "${STDOUT}"
        echo "${FUNCNAME[0]} success - <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" 
    else
        EXIT_CODE=1

        echo ""
        echo "${FUNCNAME[0]} success - >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
        ls -la "${SCRIPT_DIR_NAME}/vulnerabilities/contains-high-severity"
        echo "${FUNCNAME[0]} failed - >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
        cat "${STDOUT}"
        echo "${FUNCNAME[0]} failed - <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" 
    fi

    rm -f "${STDOUT}"

    return "${EXIT_CODE}"
}

test_assess_vulnerabilities_risk_dot_py_high_risk_inline_whitelist_medium_ignore() {
    DOCKER_IMAGE=${1:-}

    # :ODD: Normally you'd expect the line below to be something like
    # "STDOUT=$(mktemp)" but when that was used the error "The path /var/<something>
    # is not shared from OS X and is not known to Docker" was generated
    # and could not figure out what the problem and hence the current
    # implementation.
    STDOUT=${SCRIPT_DIR_NAME}/stdout.txt

    if ! docker run \
        --rm \
        -v "${SCRIPT_DIR_NAME}/vulnerabilities/contains-high-severity:/vulnerabilities" \
        --entrypoint assess-vulnerabilities-risk.py \
        "${DOCKER_IMAGE}" \
        "/vulnerabilities" --log info --whitelist '{"ignoreSevertiesAtOrBelow": "medium"}' \
        >& "${STDOUT}"; then
        EXIT_CODE=0

        echo ""
        echo "${FUNCNAME[0]} success - >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
        ls -la "${SCRIPT_DIR_NAME}/vulnerabilities/contains-high-severity"
        echo "${FUNCNAME[0]} success - >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
        cat "${STDOUT}"
        echo "${FUNCNAME[0]} success - <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<" 
    else
        EXIT_CODE=1

        echo ""
        echo "${FUNCNAME[0]} success - >>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>" 
        ls -la "${SCRIPT_DIR_NAME}/vulnerabilities/contains-high-severity"
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

if [ $# != 1 ]; then
    echo "usage: $(basename "$0") <docker image>" >&2
    exit 1
fi

DOCKER_IMAGE=${1:-}

NUMBER_TESTS_RUN=0
NUMBER_TEST_SUCCESSES=0
NUMBER_TEST_FAILURES=0
test_wrapper test_assess_vulnerabilities_risk_dot_py_no_command_line_args "${DOCKER_IMAGE}"
test_wrapper test_assess_vulnerabilities_risk_dot_py_high_risk_inline_whitelist_high_ignore "${DOCKER_IMAGE}"
test_wrapper test_assess_vulnerabilities_risk_dot_py_high_risk_inline_whitelist_medium_ignore "${DOCKER_IMAGE}"
echo ""
echo "Successfully completed ${NUMBER_TESTS_RUN} integration tests. ${NUMBER_TEST_SUCCESSES} successes. ${NUMBER_TEST_FAILURES} failures."

if [[ "${NUMBER_TEST_FAILURES}" != "0" ]]; then
    exit 1
fi

exit 0
