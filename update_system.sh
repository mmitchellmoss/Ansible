#!/usr/bin/env bash

declare -r __author="Mitch Moss"
declare -r __version="1.0.0"

set -o errexit
set -o pipefail
set -o nounset

declare hosts_group="all_servers" # Default hosts_group for the Ansible file.

# File & directory variables.
declare -r __dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
declare -r __file="${__dir}/$(basename "${BASH_SOURCE[0]}")"
declare -r __base="$(basename ${__file})"
declare -r __root="$(cd "$(dirname "${__dir}")" && pwd)"



# Check to see if a piped data exists on stdin.
declare pipe_data=""
if [ -p /dev/stdin ]; then
    pipe_data=$(cat)
fi


# Parse all options and arguments passed into the script.
declare params=""
declare second_argument=""
declare option_help=false
declare option_version=false
while (( "$#" )); do
    case "$1" in
        --help)
            option_help=true
            shift
            ;;

        --version)
            option_version=true
            shift
            ;;

        -*|--*=) # Unsupported flags.
            echo "Error: Unsupported flag $1" >&2
            exit 1
            ;;

        *) # Preserve positional arguments.
            params="$params $1"
            shift
            ;;
    esac
done
# Set positional arguments in their proper place.
eval set -- "$params"







###################################################
# Main function where all the action happens.
###################################################
function main() {
    # Print usage information if requested.
    if [ $option_help = true ]; then
        printUsage
        exit 0
    fi

    # Print version information if requested.
    if [ $option_version = true ]; then
        printVersion
        exit 0
    fi
    
    
    # If data was piped in then we will assume that it should be the hosts_group.
    if [ -n "$pipe_data" ]; then
        hosts_group="$pipe_data"
    # Else if $1 has data then we will assume that it should be the hosts_group.
    elif [ $# -eq 1 ]; then
       hosts_group="$1"
    # Else if there are no arguments then we will use the default hosts_group.
    elif [ $# -eq 0 ]; then
        true
    # Else the proper piped data or arugment was not passed in. Show an error.
    else
        echo "expected 0 or 1 argument or piped data." >&2
        exit 2
    fi

    # Run the Ansible playbook.
    ansible-playbook -i inventory update_system.yml -K -e hosts_group=$hosts_group
    print_color green "Ansible playbook has completed."

}






#######################################
# Print a message in a given color.
# Arguments:
#   Color       eg: green, red
#   Message
#######################################
function print_color() {
    local -r color_none='\033[0m'
    local -r color_green='\033[0;32m'
    local -r color_red='\033[0;31m'

    # Ensure the correct number of arguments were passed in.
    if [ $# -ne 2 ]; then
        echo "2 arguments, color and message, are required." >&2
        exit 1
    fi

    local -r color="$1"
    local -r message="$2"
    local color_formatted=""

    case "$color" in
        "green")    color_formatted=${color_green}    ;;
        "red")      color_formatted=${color_red}      ;;
        "*")        color_formatted=${color_none}     ;;
    esac

    echo -e "${color_formatted}${message}${color_none}"
}



#####################################################################
# Print the usage information for this script
# Arguments:
#   [hosts_group]   group name as defined in the inventory file
#####################################################################
function printUsage() {
    echo -e "Usage: ${__base} [hosts_group]"
    echo -e "Update system software on the supplied hosts_group. If not supplied "
    echo -e "as an argument or via pipe then hosts_group will default to 'all_servers'."
    echo -e
    echo -e "Options:"
    echo -e "  --help     Print this help information and exit."
    echo -e "  --version  Print software version and exit."
    echo -e
}


###################################################
# Print the version information for this script
# Arguments:
#   none
###################################################
function printVersion() {
    echo -e
    echo -e "${__base} ${__version}"
    echo -e
    echo -e "Copyright (C) 2020 Free Software Foundation, Inc."
    echo -e "License GPLv3+: GNU GPL version 3 or later <https://gnu.org/licenses/gpl.html>."
    echo -e "This is free software: you are free to change and redistribute it."
    echo -e "There is NO WARRANTY, to the extent permitted by law."
    echo -e
    echo -e "Written by ${__author}."
    echo -e
}


# Kick off the script.
main "${@}"

