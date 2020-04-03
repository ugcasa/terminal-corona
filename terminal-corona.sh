#!/bin/bash
# ujo.guru corona status viewer - a linux shell script to view current corona infection status per country. casa@ujo.guru 2020
# data source is CSSE at Johns Hopkins University COVID-19 git database
source_url="https://github.com/CSSEGISandData/COVID-19/blob/web-data/data/cases_country.csv"

source list_of_countries.txt
declare -a country_list=($COUNTRY_LIST)
country_selected="${country_list[0]}"

# quick decorations from deco.sh for standalone
export RED='\033[0;31m'
export GRN='\033[0;32m'
export WHT='\033[1;37m'
export NC='\033[0m'
export UPDATED="${GRN}UPDATED${NC}\n"
export FAILED="${RED}FAILED${NC}\n"
FAILED () {  [ "$1" ] && printf "${WHT}$1:${NC} $FAILED" || printf "$FAILED"  ; }
UPDATED () { [ "$1" ] && printf "$1: $UPDATED"           || printf "$UPDATED" ; }


# User interface

corona.main () {

    local _cmd="$1" ; shift

    case $_cmd in
          status)   corona.status "$@"                  ;;
             all)   country_list=($COUNTRY_LIST_ALL)
                    corona.status "$@"                  ;;
            view)   corona.view "$@"                    ;;
             csv)   corona.raw ';' "$@"                 ;;
             txt)   corona.raw ' ' "$@"                 ;;
             raw)   corona.raw "$@"                     ;;
              md)   corona.md $@                        ;;
             web)   firefox "$source_url"               ;;
            help)   corona.help                         ;;
               *)   corona.status "$_cmd" "$@"          ;;
    esac
}


corona.help() {
    printf "${WHT}  ҉ terminal-corona help ---------------------------------------------- ${NC}\n"
    printf "a linux shell script to view current corona infection status worldwide\n"
    printf "\n${WHT}usage:${NC}\t terminal-corona -t|h [output] all|Country List \n"
    printf "\n${WHT}output:${NC}\n"
    printf "  status [all|List Of Country]  colorful table view \n"
    printf "  txt                           tight text output \n"
    printf "  csv                           csv output \n"
    printf "  md                            markdown table \n"
    printf "  raw 'separator'               raw output with selectable separator \n"
    printf "  web                           open web view in source github page \n"
    printf "  view -i 'sec'                 status loop, updates hourly or input\n"
    printf "                                amount of seconds \n"
    printf "  help                          help view \n\n"
    printf "${WHT}flags:${NC}\n"
    printf "  -t                            to activate timestamps \n"
    printf "  -h                            set headers on or off \n\n"
    printf "All except view can take argument 'all' to list all countries status \n"
    printf "or list of country typed with capital first letter. If left blanc county \n"
    printf "of interest is used. Flags are place oriented and cannot be combined. \n"
    printf "\n${WHT}examples:${NC} "
    printf "\t ./terminal-corona.sh -t Estonia Sweden Russia \n"
    printf "\t\t ./terminal-corona.sh -h csv Germany France Egypt \n"
    printf "\t\t ./terminal-corona.sh raw '_' Barbuda Dominican Kyrgyzstan \n"
    printf "\t\t ./terminal-corona.sh -h view -i 300 \n"
    printf "\t\t ./terminal-corona.sh md all \n"
    return 0
}


## Functional

corona.update() {
    printf "updating data.. "
    local _clone_location="/tmp/guru/corona"
    source_file="cases_country.csv"

    if ! [[ -d "$_clone_location" ]] ; then
            mkdir -p "$_clone_location"
            cd "$_clone_location"
            git clone -b web-data https://github.com/CSSEGISandData/COVID-19.git
        fi

    source_file="$_clone_location/COVID-19/data/$source_file"

    cd "$_clone_location/COVID-19"
    if git pull >/dev/null 2>&1 ; then
            UPDATED
        else
            FAILED "repository not found"
            return 10
        fi

    if [[ -f "$source_file" ]] ; then
            return 0
        else
            FAILED "$source_file not found"
            return 10
        fi
}


corona.get_data () {
    local _location="$1"
    _data="$(cat $source_file | grep $_location | head -1)"
    _data="${_data//'  '/'_'}"
    _data="${_data//' '/'_'}"
    _data=${_data//,/ }
    export data_list=($_data)

}

## Print out

corona.country () {
    [ "$1" ] && country_selected="$1"
    _last_time="$HOME/corona" ; [ -d "$_last_time" ] || mkdir "$_last_time"
    _last_time="$_last_time/$country_selected.last" ; [ -f "$_last_time" ] || touch "$_last_time"

    corona.get_data "$country_selected"

    declare -a _last_list=($(cat $_last_time))
    declare -a _current_list=(${data_list[4]} ${data_list[5]} ${data_list[6]})
    local _change=""
    local _time=$(cut -d "_" -f2 <<< ${data_list[1]})
    local _country="$(cut -c -15 <<< ${data_list[0]})"
    _country="${_country//'_'/' '}"

    [[ "$timestamp" ]] && printf "%s," "$_time"

    printf "${NC}%15s,${CRY}%7s,${RED}%7s,${GRN}%7s,${NC}" \
           "$_country" "${data_list[4]}" "${data_list[5]}" "${data_list[6]}"

    if ! ((_current_list[0]==_last_list[0])) ; then
            _change=$((_current_list[0]-_last_list[0]))

            ((_current_list[0]>_last_list[0])) && _sing="+" || _sing=""
            printf "${CRY} %s%s ${NC}" "$_sing" "$_change"
        fi

    if ! ((_current_list[1]==_last_list[1])) ; then
            _change=$((_current_list[1]-_last_list[1]))

            ((_current_list[1]>_last_list[1])) && _sing="+" || _sing=""
            printf "${RED} %s%s ${NC}" "$_sing" "$_change"
        fi

    if ! ((_current_list[2]==_last_list[2])) ; then
            _change=$((_current_list[2]-_last_list[2]))

            ((_current_list[2]>_last_list[2])) && _sing="+" || _sing=""
            printf "${GRN} %s%s ${NC}" "$_sing" "$_change"
        fi

    printf "\n"
    printf "%s %s %s" "${_current_list[0]}" "${_current_list[1]}" "${_current_list[2]}" > "$_last_time"
}


corona.status () {
    corona.update >/dev/null
    [[ $header ]] &&    printf "${WHT}  ҉ terminal-corona %40s${NC}\n" " linux shell COVID-19 status viewer 2020"
    [[ ! $header ]] && [[ $timestamp ]] && printf "${WHT}Updated   "
    [[ $header ]] ||    printf "${WHT}%15s,%7s,%7s,%7s,%7s ${NC}(since last check) \n" "Country" "Infect" "Death" "Recov" "Change" | column -t -s$','

    if [[ "$1" ]]; then country_list=("$@") ; fi

    for _country in ${country_list[@]} ; do
           corona.country "$_country" | column -t -s$','
        done
}


corona.view () {
    local _sleep_time=3600

    case "$1" in -i)    shift
                        if [[ "$1" ]] && [ ! -z "${1##*[!0-9]*}" ] ; then
                                _sleep_time="$1"
                                shift
                            fi
        esac

    if [[ "${1,,}" == "all" ]] ; then country_list=("$COUNTRY_LIST_ALL") ; fi
    if [[ "$1" ]] ; then country_list=("$@") ; fi

    while : ; do
            corona.status
            read -t $_sleep_time -p "" _cmd

            case $_cmd in
                    q|exit|quit) break ;;
                    t|timestamp) [[ $timestamp ]] && timestamp="" || timestamp=true ;;
                       h|header) [[ $header ]]  && header="" || header=true ;;
                esac
        done
}


corona.md () {
    corona.update >/dev/null
    if [[ "$1" ]] ; then country_list=("$@") ; fi
    if [[ "${1,,}" == "all" ]] ; then country_list=("$COUNTRY_LIST_ALL") ; fi

    echo
    printf "Country | Confirmed | Deaths | Recovered | Active | Updated \n"
    printf " --- | --- | --- | --- | ---\n"

    for _country in ${country_list[@]} ; do
            corona.get_data "$_country"
            printf "%s | %s | %s | %s | %s | %s \n" \
            "${data_list[0]}" "${data_list[4]}" "${data_list[5]}" "${data_list[6]}" "${data_list[7]}" "${data_list[1]}"
        done

    printf "\n*corona status at %s*\n" "$(date)"
    echo
}


corona.raw () {
    corona.update >/dev/null

    local _output=""
    local _separator=" "
    if [[ "$1" ]] ; then _separator="$1" ; shift ; fi
    if [[ "$1" ]] ; then country_list=("$@") ; fi
    if [[ "${1,,}" == "all" ]] ; then country_list=("$COUNTRY_LIST_ALL") ; fi
    if [[ $header ]] ; then printf "Country%sConfirmed%sDeaths%sRecovered%sActive%sUpdated\n" \
                                   "$_separator" "$_separator" "$_separator" "$_separator" "$_separator" ; fi

    for _country in ${country_list[@]}; do
            corona.get_data "$_country"
            printf "%s$_separator%s$_separator%s$_separator%s$_separator%s$_separator%s\n" \
            "${data_list[0]}" "${data_list[4]}" "${data_list[5]}" "${data_list[6]}" "${data_list[7]}" "${data_list[1]}"
        done
    #echo "1:'$1' | h:'$header' s:'$_separator' 'o:$_output' 'cl:$country_list'"
    return 0
}


## Flags, requirements, calling and errors

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

    while getopts 'tih' flag; do
            case "${flag}" in
                t)  export timestamp=true ; shift ;;
                h)  export header=true ; shift ;;
            esac
        done

    if ! which git >/dev/null; then
        echo "plase install git first!"
        echo "debian based systems: 'sudo apt update && sudo apt install git'"
        exit 123
        fi

    corona.main $@
    exit 0
fi

