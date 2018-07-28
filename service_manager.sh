#!/bin/bash

readonly ERROR_CONFLICTING_OPTIONS=80
readonly ERROR_CREATING_TEMPORARY_FILES=81
readonly ERROR_NOT_RUNNING_AS_ROOT=82

readonly DMENU_OPTIONS="-b -l 50 -nb "#100" -nf "#b9c0af" -sb "#000" -sf "#afff2f" -i"

list_all_services() {
	systemctl --no-pager --full --type service --all | awk '$1 ~ /\.service$/ {print}'
}


list_dead_services() {
	systemctl --no-pager --full --type service --all | \
		awk '$4 ~ /dead/ {print}'
}

list_running_services() {
	systemctl --no-pager --full --type service --all | \
		awk '$4 ~ /running/ {print}'	
}

show_help() {
cat <<HELP_TEXT

    ${0} [-l|--list] | [-h|--help] | [-d|--disable] | [-e|--enable] | [-a|--all]

    -l|--list 			List running services.
    -e|--enable 		Shows a menu to enable disabled services.
    -d|--disable 		Shows a menu to disable running services.
    -a|--all 			List all services.
    -h|--help           Show this help.

HELP_TEXT
}

validate_flags() {
	local -r FLAGS_SUMMARY=$((enable_flag + disable_flag + list_flag + all_flag))
	# FLAGS_SUMMARY == 0 when there are no options ... 
	(((FLAGS_SUMMARY == 0) || (FLAGS_SUMMARY == 1)))
}

ask() {
	local ans
    echo -n "${@}" '[y/n] '
    read ans
    case "${ans}" in
        y*|Y*)
            return 0 
            ;;
        *) 
            return 1 
            ;;
    esac
}

handle_dead_services() {
	local -r DEAD_SERVICES_FILE='/tmp/dead.services'
	local user_option
	list_dead_services > "${DEAD_SERVICES_FILE}"
	if [[ ! -f "${DEAD_SERVICES_FILE}" ]]; then
		echo "${0}: unable to show dead services."
		exit ${ERROR_CREATING_TEMPORARY_FILES}
	fi
	user_option=$(dmenu ${DMENU_OPTIONS} < "${DEAD_SERVICES_FILE}")
	if [[ -z "${user_option}" ]]; then
		return 0
	fi
	user_option=$(awk '{print $1}' <<< "${user_option}")
	ask "Do you want to enable '${user_option}'" && {
		sudo systemctl start "${user_option}"
		rm --force "${DEAD_SERVICES_FILE}" > /dev/null 2>&1
	}
}

handle_enabled_services() {
	local -r ENABLED_SERVICES_FILE='/tmp/enabled.services'
	local user_option
	list_running_services > "${ENABLED_SERVICES_FILE}"
	if [[ ! -f "${ENABLED_SERVICES_FILE}" ]]; then
		echo "${0}: unable to show dead services."
		exit ${ERROR_CREATING_TEMPORARY_FILES}
	fi
	user_option=$(dmenu ${DMENU_OPTIONS} < "${DEAD_SERVICES_FILE}")
	if [[ -z "${user_option}" ]]; then
		return 0
	fi
	user_option=$(awk '{print $1}' <<< "${user_option}")
	ask "Do you want to disable '${user_option}'" && {
		sudo systemctl stop "${user_option}"
		rm --force "${ENABLED_SERVICES_FILE}" > /dev/null 2>&1
	}
}

is_running_as_root() {
	((EUID == 0));
}

readonly OPTS=$(getopt -o h,l,e,d,a --long list,all,enable,disable,help -- "${@}" 2> /dev/null)

eval set -- "${OPTS}"
list_flag=0
enable_flag=0
disable_flag=0
all_flag=0

while true; do
    case "${1}" in

        -l|--list)
            list_flag=1
            shift
            ;;

        -a|--all)
            all_flag=1
            shift
            ;;

        -h|--help)
            show_help
            exit 0
            shift
            ;;

        -d|--disable)
            disable_flag=1
            shift
            ;;

        -e|--enable)
            enable_flag=1
            shift
            ;;

        --)
            shift
            break
            ;;
        *)
            break
            ;;
    esac
done

if ! validate_flags; then
	echo "${0}: error, conflicting options."
	exit ${ERROR_CONFLICTING_OPTIONS}
fi

if ((list_flag == 1)); then
	list_running_services
elif ((all_flag == 1)); then
	list_all_services
elif ((enable_flag == 1)); then
	if ! is_running_as_root; then
		echo "${0}: run it as root"
		exit ${ERROR_NOT_RUNNING_AS_ROOT}
	fi
	
	handle_dead_services

elif ((disable_flag == 1)); then
	if ! is_running_as_root; then
		echo "${0}: run it as root"
		exit ${ERROR_NOT_RUNNING_AS_ROOT}
	fi

	handle_enabled_services

fi

exit 0
