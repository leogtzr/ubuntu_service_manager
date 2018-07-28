#!/bin/bash

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

list_all_services
list_dead_services
list_running_services

exit 0