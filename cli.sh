#!/bin/bash
##
# @license MPL-2.0
# @author William Desportes <williamdes@wdes.fr>
##

set -e

FORMAT_VERSION='0.1.0'
LOG_LEVEL=3

#              0       Emergency: system is unusable
#              1       Alert: action must be taken immediately
#              2       Critical: critical conditions
#              3       Error: error conditions
#              4       Warning: warning conditions
#              5       Notice: normal but significant condition
#              6       Informational: informational messages
#              7       Debug: debug-level messages

# -- CLI handling -- #

# Source: https://stackoverflow.com/a/46793269/5155484 and https://stackoverflow.com/a/28466267/5155484
optspec="hv-:"
while getopts "$optspec" OPTCHAR; do

    if [ "$OPTCHAR" = "-" ]; then   # long option: reformulate OPT and OPTARG
        OPTCHAR="${OPTARG%%=*}"     # extract long option name
        OPTARG="${OPTARG#$OPT}"   # extract long option argument (may be empty)
        OPTARG="${OPTARG#=}"      # if long option argument, remove assigning `=`
    fi

    OPTARG=${OPTARG#*=}

    # echo "OPTARG:  ${OPTARG[*]}"
    # echo "OPTIND:  ${OPTIND[*]}"
    # echo "OPTCHAR:  ${OPTCHAR}"
    case "${OPTCHAR}" in
        h|help)
            SHOW_HELP=1
        ;;
        v|version)
            SHOW_VERSION=1
        ;;
        vcs-url)
            VCS_URL="${OPTARG}"
        ;;
        vcs-revision)
            VCS_REVISION="${OPTARG}"
        ;;
        n|tag-name)
            TAG_NAME="${OPTARG}"
        ;;
        source-url)
            SOURCE_URL="${OPTARG}"
        ;;
        log-level)
            LOG_LEVEL=${OPTARG}
        ;;
        *)
            if [ "$OPTERR" != 1 ] || [ "${optspec:0:1}" = ":" ]; then
                echo "Non-option argument: '-${OPTARG}'" >&2
            fi
        ;;
    esac
done

shift $((OPTIND-1)) # remove parsed options and args from $@ list

if [ ! -z "${SHOW_HELP}" ]; then
    echo 'Usage:'
    echo 'cli.sh --vcs-url=https://github.com/manifest-software/example --vcs-revision=11e7540a303f6c368b408327396b0f948d48a79a'
    echo 'POSIX options:		long options:'
    echo '  -h                      --help          To have some help'
    echo '                          --vcs-url=      The Vcs-Url field'
    echo '                          --vcs-revision= The Vcs-Revision field'
    echo '                          --source-url    The Source-Url field'
    echo '                          --log-level     The RFC 5424 (https://tools.ietf.org/html/rfc5424#page-11) log levels, 7 is for debug'
    exit 0;
fi

if [ ! -z "${SHOW_VERSION}" ]; then
    printf '%s' "${FORMAT_VERSION}"
    exit 0;
fi

# -- Functions -- #

checkBinary () {
    if ! command -v ${1} &> /dev/null
    then
        quitError "${1} could not be found"
    fi
}

quitError () {
    if [ ${LOG_LEVEL} -gt 2 ]; then
        echo -e "\033[0;31m[ERROR] ${1}\033[0m" >&2
    fi
    exit ${2:-1}
}

logDebug () {
    if [ ${LOG_LEVEL} -eq 7 ]; then
        echo -e "\033[1;35m[DEBUG] ${1}\033[0m" >&2
    fi
}

logInfo () {
    if [ ${LOG_LEVEL} -qt 4 ]; then
        echo -e "\033[1;35m[INFO] ${1}\033[0m" >&2
    fi
}

makeField() {
    local fieldName="$1"
    local fieldValue="$2"
    if [ ! -z "${fieldName}" ] && [ ! -z "${fieldValue}" ]; then
        printf '%s: %s\n' "${fieldName}" "${fieldValue}"
    fi
}

outputVcs() {
    makeField 'Vcs-Url' "${VCS_URL}"
    makeField 'Vcs-Revision' "${VCS_REVISION}"
}

outputSource() {
    makeField 'Source-Url' "${SOURCE_URL}"
}

initGlobals() {
    ROOT_DIR="${PWD}"

    OUTPUT="Format-version: ${FORMAT_VERSION}"
    OUTPUT+='\n'
}

checkBinaries () {
    checkBinary 'printf'
}

# -- The code -- #

logDebug 'Starting...'

checkBinaries

logDebug 'Init...'

initGlobals

logDebug 'Make output...'

OUTPUT+="$(outputVcs)"
OUTPUT+="$(outputSource)"

logDebug 'Finished.'

echo -e "${OUTPUT}"
