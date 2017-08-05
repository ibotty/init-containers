#!/bin/bash
#
# A logfmt-emitting logging lib for bash
#
# There are the following log functions.
#   log::emerg, log::alert, log::crit, log::err, log::warn, log::notice,
#   log::info, log::debug
# They correspond to the syslog(2) levels.
# They accept a free-form message ("a message"), a variable to be expanded (\$var), and key=value parts.
# e.g. `log::info "doing something" with=some_thing \$PWD
# will emit
# level="info" msg="doing something" PWD="/path/I/am/in" with="some_thing"

# as syslog(2)
declare -A LOG_LEVEL
LOG_LEVEL[emerg]=0
LOG_LEVEL[alert]=1
LOG_LEVEL[crit]=2
LOG_LEVEL[err]=3
LOG_LEVEL[warning]=4
LOG_LEVEL[notice]=5
LOG_LEVEL[info]=6
LOG_LEVEL[debug]=7

# default verbosity is INFO
LOG_VERBOSITY="${LOG_VERBOSITY-info}"

alias log::emerg="log::with_level emerg"
alias log::alert="log::with_level alert"
alias log::crit="log::with_level crit"
alias log::err="log::with_level err"
alias log::warning="log::with_level warning"
alias log::notice="log::with_level notice"
alias log::info="log::with_level info"
alias log::debug="log::with_level debug"
alias log::emergency=log::emerg
alias log::critical=log::crit
alias log::error=log::err

log::join() {
    local IFS="$1"
    shift
    echo "$*"
}

log::escape() {
    echo "${1/\"/\\\"}"
}

log::with_level() {
    local loglevel key val
    local -A args
    local -a msg out
    loglevel="$1"; shift

    if [ "${LOG_LEVEL[$LOG_VERBOSITY]}" -ge "${LOG_LEVEL["$loglevel"]}" ]; then
        args['level']="$loglevel"

        while [ "$#" -ge 1 ]; do

            # \$var will expand to var="$var"
            if [ "${1:0:1}" = '$' ]; then
                # delete first character
                local var="${1:1}"
                args["$var"]="${!var}"
                shift
                continue
            fi

            # key=val case
            IFS='=' read -r key val <<< "$1"
            if [ -n "$val" ]; then
                args["$key"]="$val"
                shift
                continue
            fi

            # regular string `str` expands to msg="$str"
            msg+=( "$1" )
            shift
        done
        
        # collect msg
        if [ "${#msg[@]}" -ge 1 ]; then
            args['msg']="$(log::join " " "${msg[*]}")"
        fi
        
        # generate key="$val" array
        for key in "${!args[@]}"; do
            out+=( "$key=\"$(log::escape "${args["$key"]}")\"" )
        done

        log::join ' ' "${out[*]}"
    fi
}
