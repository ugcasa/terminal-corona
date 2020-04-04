#!/bin/bash
# ujo.guru corona status viewer - a linux shell script to view current corona infection status per country. casa@ujo.guru 2020
# data source is CSSE at Johns Hopkins University COVID-19 git database

COUNTRY_LIST="Finland Estonia Sweden Russia Norway Latvia Lithuania Denmark Iceland Netherlands Belarus Poland Belgium Germany France Spain Italy Portugal Kingdom Ireland Ukraine Greece Tunisia Turkey Egypt Iraq Iran Brazil Canada US Mexico Cuba Jamaica Bahamas Ecuador Chile India Thailand Vietnam Japan Nepal China"
COUNTRY_LIST_ALL="Australia Austria Canada China Denmark Finland France Germany Iceland Ireland Italy Netherlands Norway Russia Sweden Switzerland US Afghanistan Albania Algeria Andorra Angola Antigua Argentina Armenia Azerbaijan Bahamas Bahrain Bangladesh Barbados Belarus Belgium Belize Benin Bhutan Bolivia Bosnia Botswana Brazil Brunei Bulgaria Burkina Burma Burundi Cabo Cambodia Cameroon Central Chad Chile Colombia Congo Costa Cote Croatia Cuba Cyprus Czechia Diamond Djibouti Dominica Dominican Ecuador Egypt Equatorial Eritrea Estonia Eswatini Ethiopia Fiji Gabon Gambia Georgia Ghana Greece Grenada Guatemala Guinea Guinea-Bissau Guyana Haiti Honduras Hungary India Indonesia Iran Iraq Israel Jamaica Japan Jordan Kazakhstan Kenya Kosovo Kuwait Kyrgyzstan Laos Latvia Lebanon Liberia Libya Liechtenstein Lithuania Luxembourg Zaandam Madagascar Malaysia Maldives Mali Malta Mauritania Mauritius Mexico Moldova Monaco Mongolia Montenegro Morocco Mozambique Namibia Nepal Nicaragua Niger Nigeria Macedonia Oman Pakistan Panama Papua Paraguay Peru Philippines Poland Portugal Qatar Romania Rwanda Lucia Grenadines Marino Arabia Senegal Serbia Seychelles Sierra Singapore Slovakia Slovenia Somalia Spain Lanka Sudan Suriname Syria Taiwan Tanzania Thailand Timor-Leste Togo Trinidad Tunisia Turkey Uganda Ukraine Uruguay Uzbekistan US Kingdom Venezuela Vietnam Zambia Zimbabwe"

declare -a country_list=($COUNTRY_LIST)
country_selected="${country_list[0]}"
source_url="https://github.com/CSSEGISandData/COVID-19/blob/web-data/data/cases_country.csv"
clone_location="/tmp/terminal-corona"
current_source_file="$clone_location/COVID-19/data/$current_source_file/cases_country.csv"
history_source_file="$clone_location/COVID-19/data/$history_source_file/cases_time.csv"

# quick decorations from deco.sh for standalone
export RED='\033[0;31m'
export GRN='\033[0;32m'
export WHT='\033[1;37m'
export CRY='\033[0;37m'
export NC='\033[0m'
export UPDATED="${GRN}UPDATED${NC}\n"
export FAILED="${RED}FAILED${NC}\n"
export DONE="${GRN}DONE${NC}\n"
FAILED () { [ "$1" ] && printf "$1: $FAILED" || printf "$FAILED" ; }
UPDATED () { [ "$1" ] && printf "$1: $UPDATED" || printf "$UPDATED" ; }
DONE () { [ "$1" ] && printf "$1: $DONE" || printf "$DONE" ; }



# User interface

corona.main () {

    local _cmd="$1" ; shift

    case $_cmd in
          history|status|\
        view|raw|md|help)  corona.$_cmd "$@"                    ;;
                     all)  country_list=($COUNTRY_LIST_ALL)
                           corona.update
                           corona.status "$@"                   ;;
                     csv)  corona.raw ';' "$@"                  ;;
                     txt)  corona.raw ' ' "$@"                  ;;
                  rebase)  rm $clone_location/* >/dev/null 2>&1 ;;
                     web)  firefox "$source_url"                ;;
                       *)  corona.update

                           corona.status "$_cmd" "$@"           ;;
        esac
}

corona.help() {
    printf "${WHT}COVID-19 status viewer - help ----------------- casa@ujo.guru   ҉ ${NC}\n"
    printf "a Linux shell script to view current corona infection status worldwide\n"
    printf "\n${WHT}usage:${NC}\t terminal-corona -t|h [output] all|Country List \n"
    printf "\n${WHT}output:${NC}\n"
    printf "  status [all|List Of Country]   current table view \n"
    printf "  history [Country]              table of history with changes \n"
    printf "  txt                            tight text output \n"
    printf "  csv                            csv output \n"
    printf "  md                             markdown table \n"
    printf "  raw 'separator'                raw output with selectable separator \n"
    printf "  web                            open web view in source github page \n"
    printf "  view -i 'sec'                  status loop, updates hourly or input (s) \n"
    printf "                                 loop commands:\n"
    printf "                                   n|p   jump to next or previous day \n"
    printf "                                   h     headers on or off toggle \n"
    printf "                                   t     time stamp toggle \n"
    printf "                                   q     quit from loop \n"
    printf "  help                           help view \n\n"
    printf "${WHT}flags:${NC}\n"
    printf "  -d                             date in format YYYYMMDD \n\n"
    printf "All except view history can take argument 'all' to list all countries status \n"
    printf "or list of country typed with capital first letter. If left blanc county \n"
    printf "of interest is used. Flags are place oriented and cannot be combined. \n"
    printf "\n${WHT}examples:${NC} "
    printf "\t ./terminal-corona.sh -t Estonia Sweden Russia \n"
    printf "\t\t ./terminal-corona.sh -h csv Germany France Egypt \n"
    printf "\t\t ./terminal-corona.sh raw '_' Barbuda Dominican Kyrgyzstan \n"
    printf "\t\t ./terminal-corona.sh -h view -i 300 \n"
    printf "\t\t ./terminal-corona.sh md all \n"
    printf "\t\t ./terminal-corona.sh -d 20200122 view \n"
    printf "\t\t ./terminal-corona.sh history Finland 20200122 20200310 \n"
    return 0

}


## Functional

corona.update() {
    #printf "updating git data.. "

    if ! [[ -d "$clone_location" ]] ; then
            mkdir -p "$clone_location"
            cd "$clone_location"
            git clone -b web-data https://github.com/CSSEGISandData/COVID-19.git
        fi

    cd "$clone_location/COVID-19"
    if git pull >/dev/null 2>&1 ; then
            UPDATED $(date '+%H:%M:%S')
            echo >/dev/null
        else
            FAILED "git database update"
            return 10
        fi

    if [[ -f "$current_source_file" ]] && [[ -f "$history_source_file" ]] ; then
            return 0
        else
            FAILED "$current_source_file or $history_source_file not found"
            return 10
        fi
}

corona.get_history () {
    #printf "analyzing history.. "
    local _stamp=""
    local _location="$1"
    local _output_file="$clone_location/$_location.history"
    local _temp_file="$clone_location/history.temp"
    local _data="$(cat $history_source_file | grep $_location)"

    #_data="${_data//', '/'_'}"
    _data="${_data//' '/'_'}"
    _data=${_data//','/' '}
    echo "${_data[@]}" | cut -f 2-5 -d ' '> "$_temp_file"

    if [[ -f $_output_file ]] ; then rm "$_output_file" ; fi

    while IFS= read -r line ; do
            _stamp="$(echo $line | cut -f 1 -d ' ')"
            _data="$(echo $line | cut -f 2-4 -d ' ')"
            echo "$(date -d $_stamp '+%Y%m%d') $_data" >> "$_output_file"
        done < "$_temp_file"
    sort "$_output_file" -o "$_output_file"
    #UPDATED "$_location"
}


corona.get_data () {
    local _data=""
    local _location="$1"

    if ! ((target_date==current_date)) ; then

            if ! [[ -f "$clone_location/$_location.history" ]] ; then
                    corona.get_history "$_location"
                fi

            local _date_modified=$(date -d $(stat "$clone_location/$_location.history" | grep Modify | cut -f2 -d ' ') +'%Y%m%d')

            if ((_date_modified<current_date)) ; then
                    corona.get_history "$_location"
                fi

            local _history_file="$clone_location/$_location.history"

            if ! grep "$target_date" "$_history_file" >>/dev/null; then
                    #echo "no $target_date data published yet"
                    local _no_data="no $target_date data published yet"
                    target_date=$(date -d "$target_date -1 days" '+%Y%m%d')
                fi

            #local _name="$(cat $current_source_file | grep $_location | cut -f1 -d ',')"
            _data="$(grep $target_date $_history_file)"
            _data="$_location 0 $_data "
            current_data_list=($_data)

        else

            _data="$(cat $current_source_file | grep $_location | head -1)"

            # _data="${_data//', '/'_'}"
            _data="${_data//' '/'_'}"
            _data=${_data//,/ }
            local _data_list=($_data)
            _data_list[1]=$(date -d $(cut -f2 -d '_' <<< ${_data_list[1]}) '+%H:%M:%S')
            _data_list[2]=$(date -d $(cut -f1 -d '_' <<< ${_data_list[1]}) '+%Y%m%d')

            current_data_list=(${_data_list[0]} ${_data_list[1]} ${_data_list[2]} \
                               ${_data_list[4]} ${_data_list[5]} ${_data_list[6]})
        fi
}



## Print out

corona.country () {
    [ "$1" ] && country_selected="$1"

    _last_time="$clone_location" ; [ -d "$_last_time" ] || mkdir "$_last_time"
    _last_time="$_last_time/$country_selected.last" ; [ -f "$_last_time" ] || touch "$_last_time"

    corona.get_data "$country_selected"

    local _change=""
    declare -a _last_list=($(cat $_last_time))
    declare -a _current_list=(${current_data_list[3]} ${current_data_list[4]} ${current_data_list[5]})

    if ((target_date==current_date)); then
            _time="${current_data_list[1]}  "
        else
            _time=$(date -d ${current_data_list[2]} '+%d.%m.%Y')
        fi

    local _country="$(cut -c -18 <<< ${current_data_list[0]})"
    _country="${_country//'_'/' '}"

    [[ $timestamp ]] && printf "%8s," "$_time"

    for _i in {3..5}; do
            (( current_data_list[$_i] == 0 )) && current_data_list[$_i]="-"
        done

    printf "${NC}%18s,${CRY}%7s,${RED}%7s,${GRN}%7s,${NC}" \
           "$_country" "${current_data_list[3]}" "${current_data_list[4]}" "${current_data_list[5]}"

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

    if [[ $header ]]; then
            [[ $timestamp ]] && printf "${WHT}Updated        "
            [[ $timestamp ]] && _header_date="$(printf '%15s' 'Country')" || _header_date=$(printf "%15s" "$(date -d $target_date +'%Y.%m.%d') Country")
            printf "${WHT}%s,%7s,%7s,%7s,%7s ${NC} \n" "$_header_date" "Infect" "Death" "Recov" "Change" | column -t -s$','
        else
            _header_date=$(printf "%s" "$(date -d $target_date +'%Y.%m.%d')")
            printf "${WHT}  ҉ terminal-corona $_header_date %s${NC}\n" "- linux shell COVID-19 tracker - casa@ujo.guru 2020"
        fi
    if [[ "$1" ]]; then country_list=("$@") ; fi

    for _country in ${country_list[@]} ; do
            corona.country "$_country" | column -t -s$','
        done

}


corona.history () {
    corona.update

    local _country="Finland" ; [[ "$1" ]] &&_country="$1" ; shift
    local _from=$(date -d 20200122 +'%Y%m%d') ; [[ "$1" ]] &&_from=$(date -d $1 +'%Y%m%d') ; shift
    local _to=$(date -d "$current_date -1 days" +'%Y%m%d') ; [[ "$1" ]] &&_to=$(date -d $1 +'%Y%m%d') ; shift
    local _last_time="$clone_location/$_country.last"

    [[ -f $_last_time ]] && rm $_last_time

    if [[ $header ]]; then
            [[ $timestamp ]] && printf "${WHT}Updated     "
            [[ $timestamp ]] || printf ""
            printf "${WHT}%15s,%7s,%7s,%7s,%7s ${NC} \n" " Country" "Infect" "Death" "Recov" "Change" | column -t -s$','
        fi

    while [[ $_from -le $_to ]] ; do
            _from=$(date -d "$_from + 1 day" +"%Y%m%d")
            target_date=$_from
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

            read -n1 -t $_sleep_time -p "" _cmd
            case $_cmd in
                    q)  break                                                           ;;
                    t)  [[ $timestamp ]] && timestamp="" || timestamp=true              ;;
                    h)  [[ $header ]]  && unset header || header=true                   ;;
                  p|b)  target_date=$(date -d "$target_date - 1 days" +'%Y%m%d')
                        ((target_date<20200122)) && target_date=20200122                ;;
                    n)  target_date=$(date -d "$target_date + 1 days" +'%Y%m%d')
                        ((target_date>current_date)) && target_date=${current_date}     ;;
                   "")  corona.update
                        target_date=$(date +'%Y%m%d')                                   ;;

                esac
            clear

        done
}


corona.md () {

    corona.update

    if [[ "$1" ]] ; then country_list=("$@") ; fi
    if [[ "${1,,}" == "all" ]] ; then country_list=("$COUNTRY_LIST_ALL") ; fi

    echo
    printf "Country | Confirmed | Deaths | Recovered | Updated \n"
    printf " --- | --- | --- | --- | ---\n"

    for _country in ${country_list[@]} ; do
            corona.get_data "$_country"
            printf "%s | %s | %s | %s |  %s \n" \
            "${current_data_list[0]}" "${current_data_list[3]}" "${current_data_list[4]}" "${current_data_list[5]}" "${current_data_list[2]}_${current_data_list[1]}"
        done

    printf "\n*corona status at %s*\n" "$(date)"
    echo
}


corona.raw () {

    corona.update

    local _output=""
    local _separator=" "

    if [[ "$1" ]] ; then _separator="$1" ; shift ; fi
    if [[ "$1" ]] ; then country_list=("$@") ; fi
    if [[ "${1,,}" == "all" ]] ; then country_list=("$COUNTRY_LIST_ALL") ; fi
    if [[ $header ]] ; then printf "Country%sConfirmed%sDeaths%sRecovered%sUpdated\n" \
                                   "$_separator" "$_separator" "$_separator" "$_separator" ; fi

    for _country in ${country_list[@]}; do
            corona.get_data "$_country"
            printf "%s$_separator%s$_separator%s$_separator%s$_separator%s\n" \
            "${current_data_list[0]}" "${current_data_list[3]}" "${current_data_list[4]}" "${current_data_list[5]}" "${current_data_list[2]}_${current_data_list[1]}"
        done
    return 0
}

## Flags, requirements, calling and errors

target_date=$(date '+%Y%m%d')
current_date=$(date '+%Y%m%d')

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then

    while getopts 'di' flag; do
            case "${flag}" in
                d)  target_date=$(date -d ${2} '+%Y%m%d')
                    if ((target_date<20200122)) || ((target_date>current_date)); then
                            target_date=${current_date}
                        fi ; shift ; shift ;;
            esac
        done

    timestamp=true
    header=true

    if ! which git >/dev/null; then
        echo "plase install git first!"
        echo "debian based systems: 'sudo apt update && sudo apt install git'"
        exit 123
        fi

    corona.main $@
    exit 0
fi



# tc  ҉19
# C ҉VID-19
# c ҉o҉r ҈o ҉n ҈a ҉
#   ҉ COVID-19
#Status shows on header
    # spreading
    # printf "  ҉" | hexdump # 0000000 2020 89d2 0000004
    # weakening
    # printf "  ҈" | hexdump # 0000000 2020 88d2 0000004
    # still there
    # printf "_"
    # gone
    # printf " "