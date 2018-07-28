#!/bin/bash
set -x

readonly ERROR_CONFLICTING_OPTIONS=80

list_all_services() {
	systemctl --no-pager --full --type service --all
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

HELP_TEXT
}

validate_flags() {
	local -r FLAGS_SUMMARY=$((enable_flag + disable_flag + list_flag + all_flag))
	# FLAGS_SUMMARY == 0 when there are no options ... 
	(((FLAGS_SUMMARY == 0) || (FLAGS_SUMMARY == 1)))
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
fi

exit 0