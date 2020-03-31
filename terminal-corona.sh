#!/bin/bash
# ujo.guru corona status viewer - a linux shell script to view current corona infection status per country
# data source is CSSE at Johns Hopkins University COVID-19 git database
# casa@ujo.guru 2020

country_selected="Finland"
country_list=("Finland" "Sweden" "Estonia" "Russia" "Norway" "Germany" "Spain" "France" "Italy" "Kingdom" "US" "China" "Thailand" "Vietnam")
source_url="https://github.com/CSSEGISandData/COVID-19/blob/web-data/data/cases_country.csv"

# quick decorations from deco.sh for standalone
export RED='\033[0;31m'
export GRN='\033[0;32m'
export WHT='\033[1;37m'
export NC='\033[0m'
export UPDATED="${GRN}UPDATED${NC}\n"
export FAILED="${RED}FAILED${NC}\n"
FAILED () {  [ "$1" ] && printf "${WHT}$1:${NC} $FAILED" || printf "$FAILED"  ; }
UPDATED () { [ "$1" ] && printf "$1: $UPDATED"           || printf "$UPDATED" ; }


corona.main () {

    case ${1,,} in
             status|all)  corona.status                         ;;
                  short)  corona.update ; corona.short "$2"     ;;
            markdown|md)  corona.markdown                       ;;
           view|display)  corona.view "$2"                      ;;
                   help)  corona.help                           ;;
                    web)  firefox "$source_url"                 ;;
                      *)  corona.status                         ;;
    esac
}


corona.help() {
    printf "${WHT}-- ujo.guru - terminal-corona - help -----------------------------------${NC}\n"
    printf "a linux shell script to view current corona infection status per country\n"
    printf "${WHT}usage:${NC}\t terminal-corona [command|Country] \n"
    printf "${WHT}commands:${NC}\n"
    printf "  status|all            all countries in interesting list \n"
    printf "  short <Country>       one line of statistics or country  \n"
    printf "  web                   open web view in source github page \n"
    printf "  markdown              table of intrest in markdown format  \n"
    printf "  view|display <intrv>  table vie of all countries, updates \n"
    printf "                        hourly (or input amount of seconds) \n"
    printf "${WHT}flags:${NC}\n"
    printf "  -t                    activate timestamps \n"
    printf "${WHT}examples:${NC} "
    printf "\t terminal-corona status \n"
    printf "\t\t terminal-corona Estonia \n"
    printf "\t\t terminal-corona view 10 \n"
    return 0
}


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


corona.markdown () {
    corona.update >/dev/null
    echo
    printf "Country | Confirmed | Deaths | Recovered | Active | Updated \n"
    printf " --- | --- | --- | --- | ---\n"
        for _country in ${country_list[@]}; do
            corona.get_data "$_country"
            printf "%s | %s | %s | %s | %s | %s \n" "${data_list[0]}" "${data_list[4]}" "${data_list[5]}" "${data_list[6]}" "${data_list[7]}" "${data_list[1]}"
        done
    printf "\n*corona status at %s*\n" "$(date)"
    echo
}


corona.short () {
    [ "$1" ] && country_selected="$1"
    _last_time="$HOME/corona" ; [ -d "$_last_time" ] || mkdir "$_last_time"
    _last_time="$_last_time/$country_selected.last" ; [ -f "$_last_time" ] || touch "$_last_time"

    corona.get_data "$country_selected"

    declare -a _last_list=($(cat $_last_time))
    declare -a _current_list=(${data_list[4]} ${data_list[5]} ${data_list[6]})
    local _change=""
    local _time=$(cut -d "_" -f2  <<< ${data_list[1]})
    local _country="$(cut -c -15 <<< ${data_list[0]})"
    _country="${_country//'_'/' '}"

    [[ "$timestamp" ]] && printf "%s," "$_time"
    printf "${NC}%15s,${CRY}%7s,${RED}%7s,${GRN}%s,${NC}" "$_country" "${data_list[4]}" "${data_list[5]}" "${data_list[6]}"

    if ! ((_current_list[0]==_last_list[0])) ; then
            _change=$((_current_list[0]-_last_list[0]))

            ((_current_list[0]>_last_list[0])) && _sing="+" || _sing=""
            printf "${CRY}%s%s ${NC}" "$_sing" "$_change"
        fi

    if ! ((_current_list[1]==_last_list[1])) ; then
            _change=$((_current_list[1]-_last_list[1]))

            ((_current_list[1]>_last_list[1])) && _sing="+" || _sing=""
            printf "${RED}%s%s ${NC}" "$_sing" "$_change"
        fi

    if ! ((_current_list[2]==_last_list[2])) ; then
            _change=$((_current_list[2]-_last_list[2]))

            ((_current_list[2]>_last_list[2])) && _sing="+" || _sing=""
            printf "${GRN}%s%s ${NC}" "$_sing" "$_change"
        fi

    printf "\n"
    printf "%s %s %s" "${_current_list[0]}" "${_current_list[1]}" "${_current_list[2]}" > "$_last_time"
}


corona.status () {
    corona.update
    [[ "$timestamp" ]] && printf "${WHT}Updated   "
    printf "${WHT}%15s,%7s,%7s,%s\t%s ${NC}(since last check)\n" "Country" "Infect" "Death" "Recov" "Change" | column -t -s$','
    for _country in ${country_list[@]}; do
           corona.short "$_country" | column -t -s$','
        done
}


corona.view () {
    local _sleep_time=3600 ; [ "$1" ] && _sleep_time=$1
    while : ; do
            corona.status
            sleep "$_sleep_time"
        done
}


if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

    while getopts 't' flag; do
        case "${flag}" in
            t)  export timestamp=true ; shift ;;
        esac
    done

    corona.main $@
    exit 0
fi

