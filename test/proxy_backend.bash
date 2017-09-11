#!/bin/bash

set -e
. ${srcdir}/common.bash

if [ -z "${BACKEND_HOST}" ]; then
    export BACKEND_HOST="localhost"
fi
if [ -z "${BACKEND_PORT}" ]; then
    export BACKEND_PORT="9934"
fi
: ${BACKEND_PID:="backend.pid"}
: ${srcdir:="."}
: ${APACHE2:="apache2"}
: ${TEST_LOCK_WAIT:="30"}

function backend_apache
{
    # needed for start and stop
    dir="${1}"
    conf="${2}"
    action="${3}"
    # needed only for start
    lockfile="${4}"

    TEST_NAME="$(basename "${dir}")"
    (
	export TEST_NAME
	export TEST_PORT="${BACKEND_PORT}"
	export srcdir="$(realpath ${srcdir})"
	local flock_cmd=""
	case ${action} in
	    start)
		if [ -n "${USE_TEST_NAMESPACE}" ]; then
		    echo "Using namespaces to isolate tests, no need for" \
			 "locking."
		elif [ -n "${FLOCK}" ]; then
		    flock_cmd="${FLOCK} -w ${TEST_LOCK_WAIT} ${lockfile}"
		else
		    echo "Locking disabled, using wait based on proxy PID file."
		    wait_pid_gone "${BACKEND_PID}"
		fi
		${flock_cmd} \
		    ${APACHE2} -f "$(realpath ${testdir}/${conf})" -k start || return 1
		;;
	    stop)
		${APACHE2} -f "$(realpath ${testdir}/${conf})" -k stop || return 1
		;;
	    *)
		echo "${FUNCNAME[0]}: Invalid action \"${action}\"." >&2
		exit 1
		;;
	esac
    )
}
