#!/bin/bash
# ujo.guru corona status viewer - a linux shell script to view current corona infection status per country. casa@ujo.guru 2020
# data source is CSSE at Johns Hopkins University COVID-19 git database

COUNTRY_LIST="Finland Estonia Sweden Russia Norway Latvia Lithuania Denmark Iceland Netherlands Belarus Poland Belgium Germany France Spain Italy Portugal Kingdom Ireland Ukraine Greece Tunisia Turkey Egypt Iraq Iran Brazil Canada US Mexico Cuba Jamaica Bahamas Ecuador Chile India Thailand Vietnam Japan Nepal China"
COUNTRY_LIST_SHORT="Finland Estonia Sweden Russia Iceland Germany France Spain Italy Kingdom Iran Brazil Canada US India Thailand Vietnam China"
COUNTRY_LIST_ALL="Australia Austria Canada China Denmark Finland France Germany Iceland Ireland Italy Netherlands Norway Russia Sweden Switzerland US Afghanistan Albania Algeria Andorra Angola Antigua Argentina Armenia Azerbaijan Bahamas Bahrain Bangladesh Barbados Belarus Belgium Belize Benin Bhutan Bolivia Bosnia Botswana Brazil Brunei Bulgaria Burkina Burma Burundi Cabo Cambodia Cameroon Central Chad Chile Colombia Korea Kinshasa Brazzaville Costa Cote Croatia Cuba Cyprus Czechia Diamond Djibouti Dominica Dominican Ecuador Egypt Equatorial Eritrea Estonia Eswatini Ethiopia Fiji Gabon Gambia Georgia Ghana Greece Grenada Guatemala Guinea Guinea-Bissau Guyana Haiti Honduras Hungary India Indonesia Iran Iraq Israel Jamaica Japan Jordan Kazakhstan Kenya Kosovo Kuwait Kyrgyzstan Laos Latvia Lebanon Liberia Libya Liechtenstein Lithuania Luxembourg Zaandam Madagascar Malaysia Maldives Mali Malta Mauritania Mauritius Mexico Moldova Monaco Mongolia Montenegro Morocco Mozambique Namibia Nepal Nicaragua Niger Nigeria Macedonia Oman Pakistan Panama Papua Paraguay Peru Philippines Poland Portugal Qatar Romania Rwanda Lucia Grenadines Marino Arabia Senegal Serbia Seychelles Sierra Singapore Slovakia Slovenia Somalia Spain Lanka Sudan Suriname Syria Taiwan Tanzania Thailand Timor-Leste Togo Trinidad Tunisia Turkey Uganda Ukraine Uruguay Uzbekistan US Kingdom Venezuela Vietnam Zambia Zimbabwe"
UPDATE_METHOD="web"

declare -a country_list=("$COUNTRY_LIST")
declare country_selected="${country_list[0]}"
declare source_url="https://github.com/CSSEGISandData/COVID-19/blob/web-data/data/cases_country.csv"
declare clone_location="/tmp/terminal-corona"
declare current_source_file="$clone_location/COVID-19/data/cases_country.csv"
declare history_source_file="$clone_location/COVID-19/data/cases_time.csv"
declare total_death=0

# quick decorations from deco.sh for standalone
RED='\033[0;31m'
GRN='\033[0;32m'
WHT='\033[1;37m'
CRY='\033[0;37m'
NC='\033[0m'
UPDATED="${GRN}UPDATED${NC}\n"
FAILED="${RED}FAILED${NC}\n"
DONE="${GRN}DONE${NC}\n"
FAILED () { [ "$1" ] && printf "$1: $FAILED" || printf "$FAILED" ; }
UPDATED () { [ "$1" ] && printf "$1: $UPDATED" || printf "$UPDATED" ; }
DONE () { [ "$1" ] && printf "$1: $DONE" || printf "$DONE" ; }


# User interface

corona.main () {
    local _cmd="$1" ; shift
    case $_cmd in
          history|status|view|md|help)
                           corona.$_cmd "$@"                        ;;
                     raw)  corona.raw "$@"                          ;;
                     csv)  corona.raw ';' "$@"                      ;;
                     txt)  corona.raw ' ' "$@"                      ;;
                  rebase)  rm -f "$clone_location/*.history"
                           rm -f "$clone_location/*.last"           ;;
                  remove)  rm -fr "$clone_location"                 ;;
                     web)  firefox "$source_url"                    ;;
                   short)  country_list=($COUNTRY_LIST_SHORT)
                           unset timestamp
                           corona.update
                           corona.status "$@"                       ;;
                   phone)  unset timestamp header
                           #country_list=($COUNTRY_LIST_SHORT)
                           corona.view                              ;;
                     all)  country_list=($COUNTRY_LIST_ALL)
                           corona.update
                           corona.status "$@"                       ;;
                       *)  corona.update
                           corona.status "$_cmd" "$@"               ;;
        esac
}


corona.help() {

    printf "${WHT}COVID-19 status viewer   ҉ help ------------------------- casa@ujo.guru${NC}\n"
    printf "a Linux shell script to view current corona infection status worldwide\n"

    printf "\n${WHT}usage:${NC}\t terminal-corona -t|h [output] all|short|List Country\n"

    printf "\n${WHT}output:${NC}\n"
    printf "  status [all|short or list]     current table view \n"
    printf "  history [country]              table of history with changes \n"
    printf "  txt [all|short or list]        tight text output \n"
    printf "  csv [all|short or list]        csv output \n"
    printf "  md [all|short or list]         markdown table \n"
    printf "  raw 'separator'                raw output with selectable separator \n"
    printf "  web                            open web view in source github page \n"
    printf "  view -i 'sec'                  status loop, updates hourly or input) \n"
    printf "                                 loop commands:\n"
    printf "                                   n|p   jump to next or previous day \n"
    printf "                                   h     headers on or off toggle \n"
    printf "                                   t     time stamp toggle \n"
    printf "                                   q     quit from loop \n"
    printf "  rebase                         reset history data \n"
    printf "  remove                         remove database \n"
    printf "  help                           help view \n\n"

    printf "${WHT}flags:${NC}\n"
    printf "  -d                             date in format YYYYMMDD \n\n"
    printf "All except history can take argument 'all' or 'short' \n"
    printf "or list of countriesies typed with capital first letter. If country is \n"
    printf "left blank default country list is used. Flags are place oriented and \n"
    printf "cannot be combined. \n"

    printf "\n${WHT}examples:${NC}\n"
    printf "  %-40s\n\t${WHT}%s${NC}\n" \
           "current status of countries"             "./terminal-corona.sh Estonia Sweden Russia"
    printf "  %-40s\n\t${WHT}%s${NC}\n" \
           "printout current status in csv format"   "./terminal-corona.sh csv Germany France Egypt"
    printf "  %-40s\n\t${WHT}%s${NC}\n" \
           "printout with given separator '_'"       "./terminal-corona.sh raw '_' Barbuda Dominican Kyrgyzstan"
    printf "  %-40s\n\t${WHT}%s${NC}\n" \
           "update status in every 5 minutes"        "./terminal-corona.sh view -i 300"
    printf "  %-40s\n\t${WHT}%s${NC}\n" \
           "printout in markdown"                    "./terminal-corona.sh md all"
    printf "  %-40s\n\t${WHT}%s${NC}\n" \
           "to show day status in history"           "./terminal-corona.sh -d 20200122 status"
    printf "  %-40s\n\t${WHT}%s${NC}\n" \
           "to navigate history from first record"   "./terminal-corona.sh -d 20200122 view"
    printf "  %-40s\n\t${WHT}%s${NC}\n" \
           "history between given day stamps"        "./terminal-corona.sh history Spain 20200122 20200310"
    return 0
}

## get and update

corona.update_git () {
    [[ $timestamp ]] && printf "updating git data.. "

    if ! [[ -d "$clone_location" ]] ; then
            mkdir -p "$clone_location"
            cd "$clone_location"
            git clone -b web-data https://github.com/CSSEGISandData/COVID-19.git
        fi

    cd "$clone_location/COVID-19"

    if git pull >/dev/null 2>&1 ; then
            [[ $timestamp ]] && UPDATED $(date '+%H:%M:%S')
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


corona.update_web() {
    [[ $timestamp ]] && printf "updating web data.. "
    [[ -d "$clone_location/COVID-19/data" ]] || mkdir -p "$clone_location/COVID-19/data"
    [[ -f "$current_source_file" ]] && rm -f "$current_source_file"
    [[ -f "$history_source_file" ]] && rm -f "$history_source_file"

    cd "$clone_location/COVID-19/data"
    wget -q https://raw.githubusercontent.com/CSSEGISandData/COVID-19/web-data/data/cases_country.csv
    wget -q https://raw.githubusercontent.com/CSSEGISandData/COVID-19/web-data/data/cases_time.csv

    if ! [[ -f "$current_source_file" ]] ; then
        FAILED "$current_source_file not found"
        return 10
    fi

    if ! [[ -f "$history_source_file" ]] ; then
        FAILED "$history_source_file not found"
        return 11
    fi

    [[ $timestamp ]] && UPDATED $(date '+%H:%M:%S')
    return 0
}


corona.update () {
    corona.update_$UPDATE_METHOD "$@"
    return $?
}


corona.get_history () {
    #printf "analyzing history data.. "
    local _stamp=""
    local _location="$1"
    local _output_file="$clone_location/$_location.history"
    local _temp_file="$clone_location/history.temp"
    local _data="$(cat $history_source_file | grep $_location)"

    _data="${_data//',,'/',0,'}"
    _data="${_data//'*'/''}"
    _data="${_data//', '/'_'}"
    _data=${_data//'"'/''}
    _data="${_data//' ('/'_'}"
    _data="${_data//')'/''}"
    _data="${_data//' '/'_'}"
    _data=${_data//','/' '}

    echo "${_data[@]}" | cut -f 2-5 -d ' '> "$_temp_file"

    if [[ -f "$_output_file" ]] ; then rm "$_output_file" ; fi

    while IFS= read -r line ; do
            _stamp="$(echo $line | cut -f 1 -d ' ')"
            _data="$(echo $line | cut -f 2-4 -d ' ')"
            echo "$(date -d $_stamp '+%Y%m%d') $_data" >> "$_output_file"
        done < "$_temp_file"
    sort "$_output_file" -o "$_output_file"
    rm "$_temp_file"
    #DONE "$_location"
}


corona.get_data () {
    # get data from local base
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

            if ! grep "$target_date" "$_history_file" >/dev/null; then
                    #echo "no $target_date data published yet"
                    target_date=$(date -d "$target_date -1 days" '+%Y%m%d')
                fi

            _data="$(grep $target_date $_history_file)"
            _data="$_location 0 $_data "
            current_data_list=($_data)

        else
            _data="$(cat $current_source_file | grep $_location | head -1)"
            _data="${_data//',,'/',0,'}"
            _data="${_data//'*'/''}"
            _data="${_data//', '/'_'}"
            _data=${_data//'"'/''}
            _data="${_data//' ('/'_'}"
            _data="${_data//')'/''}"
            _data="${_data//' '/'_'}"
            _data="${_data//','/' '}"

            local _data_list=($_data)
            _data_list[1]=$(date -d $(cut -f2 -d '_' <<< ${_data_list[1]}) '+%H:%M:%S')
            _data_list[2]=$(date -d $(cut -f1 -d '_' <<< ${_data_list[1]}) '+%Y%m%d')

            current_data_list=(${_data_list[0]} ${_data_list[1]} ${_data_list[2]} \
                               ${_data_list[4]} ${_data_list[5]} ${_data_list[6]})
        fi
}


## Printouts

corona.country () {
    [ "$1" ] && country_selected="$1"                            # overwrites global if user input
    local _change=
    local _last_time="$clone_location" ; [ -d "$_last_time" ] || mkdir "$_last_time"
    local _last_time="$_last_time/$country_selected.last" ; [ -f "$_last_time" ] || touch "$_last_time"
    declare -a _list_temp
    declare -a _last_list=($(cat $_last_time))

    # parse data from local temp file, fill up global 'current_data_list'
    corona.get_data "$country_selected"
    declare -a _current_list=(${current_data_list[3]} ${current_data_list[4]} ${current_data_list[5]})

    # get nice country name
    _country_name="$(cut -c -18 <<< ${current_data_list[0]})"
    _country_name="${_country_name//'_'/' '}"                    # remove combiner

    # date stamp
    if ((target_date==current_date)); then                       # select date
            _time="${current_data_list[1]}  "                    # spaces to keep length same
        else
            _time=$(date -d ${current_data_list[2]} '+%d.%m.%Y') # date from data
        fi


    # printout timestamps column if active
    [[ $timestamp ]] && printf "%8s," "$_time"

    # replace zeros with "-", nicer to read.
    for _i in {3..5}; do
            (( current_data_list[$_i] == 0 )) && current_data_list[$_i]="-"
        done

    # printout data
    printf "${NC}%18s,${CRY}%9s,${RED}%9s,${GRN}%9s,${NC}   " \
           "$_country_name" "${current_data_list[3]}" "${current_data_list[4]}" "${current_data_list[5]}"

    # printout changes
    local _color_list=("${CRY}" "${RED}" "${GRN}")
    for _i in {0..2} ; do
        if ! ((_current_list[_i]==_last_list[_i])) ; then
                _change=$((_current_list[_i]-_last_list[_i]))
                ((_current_list[_i]>_last_list[_i])) && _sing="+" || _sing=""
                printf "${_color_list[$_i]}%s%s${NC} " "$_sing" "$_change"
        fi
    done
    printf "\n"

    # save last list to file
    printf "%s %s %s" "${_current_list[0]}" "${_current_list[1]}" "${_current_list[2]}" > "$_last_time"
}


corona.status () {
    # get and printout current status list with headers and summary
    declare -a total_count_list=()

    # if user input list of countries use it
    case "$1" in all|short) eval country_list=('$'"COUNTRY_LIST_${1^^}" ) ; shift ;; esac
    if [[ "$1" ]]; then country_list=("$@") ; fi

    # printout header
    if [[ $header ]]; then
            [[ $timestamp ]] && printf "${WHT}Updated        "
            [[ $timestamp ]] && _header_date="$(printf '%15s' 'Country')" || _header_date=$(printf "%15s" "$(date -d $target_date +'%d.%m.%Y') Country")
            printf "${WHT}%s,%9s,%9s,%9s,%9s ${NC} \n" \
                   "$_header_date" "Infect" "Death" "Recov" "Change" | column -t -s$','
        else
            _header_date=$(printf "%s" "$(date -d $target_date +'%d.%m.%Y')")
            printf "${WHT}terminal-corona - $_header_date %s${NC}\n" \
                   "   ҉  COVID-19 tracker - casa@ujo.guru"
        fi

    # get and printout country data and add to summary
    for _country in ${country_list[@]} ; do
            corona.country "$_country" | column -t -s$','

            # summary counter
            local _last_count_list=($(cat $clone_location/$_country.last))
            for _i in {0..2} ; do
                total_count_list[$_i]=$((total_count_list[$_i] + _last_count_list[$_i]))
                done
        done

    # printout summary
    [[ $timestamp ]] && printf "${WHT}%s" "$(date -d $target_date +'%d.%m.%Y')  "
    printf "${WHT}%18s %10s %10s %10s${NC}\n" "Summary" "${total_count_list[0]}" \
           "${total_count_list[1]}" "${total_count_list[2]}"
}


corona.history () {
    # history browser
    local _country="Finland" ; [[ "$1" ]] &&_country="$1" ; shift
    local _from=$(date -d 20200122 +'%Y%m%d') ; [[ "$1" ]] &&_from=$(date -d $1 +'%Y%m%d') ; shift
    local _to=$(date -d "$current_date -1 days" +'%Y%m%d') ; [[ "$1" ]] &&_to=$(date -d $1 +'%Y%m%d') ; shift
    local _last_time="$clone_location/$_country.last"

    [[ -f $_last_time ]] && rm $_last_time

    if [[ $header ]]; then
            [[ $timestamp ]] && printf "${WHT}Updated        "
            [[ $timestamp ]] || printf ""
            printf "${WHT}%15s,%9s,%9s,%9s,%9s ${NC} \n" " Country" "Infect" "Death" "Recov" "Change" | column -t -s$','
        fi

    while [[ $_from -le $_to ]] ; do
            target_date=$_from
            corona.country "$_country" | column -t -s$','
            _from=$(date -d "$_from + 1 day" +"%Y%m%d")
        done
}


corona.view () {
    # looping view for info display use
    local _sleep_time=3600

    case "$1" in -i)    shift
                        if [[ "$1" ]] && [ ! -z "${1##*[!0-9]*}" ] ; then
                                _sleep_time="$1"
                                shift
                            fi
        esac

    # if user input list of countries use it
    case "$1" in all|short) eval country_list=('$'"COUNTRY_LIST_${1^^}" ) ; shift ;; esac
    if [[ "$1" ]]; then country_list=("$@") ; fi


    corona.update
    while : ; do
            current_date=$(date '+%Y%m%d')
            corona.status
            read -n1 -t $_sleep_time -p "[q|p|b|n|t|h]: " _cmd
            echo $_cmd ; echo $_cmd > $HOME/file.txt
            case $_cmd in
                    q)  printf " - take care!${NC}\n" ; break                           ;;
                    t)  [[ $timestamp ]] && timestamp="" || timestamp=true              ;;
                    h)  [[ $header ]]  && unset header || header=true                   ;;
                  p|b)  target_date=$(date -d "$target_date - 1 days" +'%Y%m%d')
                        ((target_date<20200122)) && target_date=20200122                ;;
                    n)  target_date=$(date -d "$target_date + 1 days" +'%Y%m%d')
                        ((target_date>current_date)) && target_date=${current_date}     ;;
                   "")  corona.update
                        target_date=$(date +'%Y%m%d')                                   ;;
                    #*)  cd ; echo "$_cmd" ; echo "$_cmd" >> file.txt
                esac
            clear

        done
}


corona.md () {

    declare -a total_count_list=()
    unset timestamp
    corona.update
    case "$1" in all|short) eval country_list=('$'"COUNTRY_LIST_${1^^}" ) ; shift ;; esac
    if [[ "$1" ]]; then country_list=("$@") ; fi

    # printout header
    echo                                                   # make some space to make copy paste easy
    printf "%-18s | %10s | %10s | %10s | %s \n" "Country" "Confirmed" "Deaths" "Recovered" "Updated"
    printf ": %s |: %s:|: %s:|: %s:|: %s\n" \
           "$(echo -e ''$_{1..17}'\b-')" "$(echo -e ''$_{1..10}'\b-')" "$(echo -e ''$_{1..10}'\b-')" \
           "$(echo -e ''$_{1..10}'\b-')" "$(echo -e ''$_{1..18}'\b-')"

    # printout data lines
    for _country in ${country_list[@]} ; do
            corona.get_data "$_country"

            # cut country names
            local _country_name="$(cut -c -18 <<< ${current_data_list[0]})"
            _country_name="${_country_name//'_'/' '}"

            # printout data
            printf "%-18s | %10s | %10s | %10s | %s \n" \
            "$_country_name" "${current_data_list[3]}" "${current_data_list[4]}" \
            "${current_data_list[5]}" "$(date -d ${current_data_list[2]} +%d.%m.%Y)"

            # summary counter
            for _i in {0..2} ; do
                total_count_list[$_i]=$((total_count_list[$_i] + ${current_data_list[$((_i+3))]}))
            done
    done
    # printout summary
    printf "%-18s | %10s | %10s | %10s | %s\n"  \
    "Summary" "${total_count_list[0]}" "${total_count_list[1]}" \
    "${total_count_list[2]}" "$(date -d $target_date +'%d.%m.%Y')"
    # printout table note
    printf "\n*corona status at %s*\n" "$(date)"
    echo
}


corona.raw () {
    declare -a total_count_list=()
    unset timestamp
    corona.update
    local _output=""
    local _separator=" "

    if [[ "$1" ]] ; then _separator="$1" ; shift ; fi
    case "$1" in all|short) eval country_list=('$'"COUNTRY_LIST_${1^^}" ) ; shift ;; esac
    if [[ "$1" ]]; then country_list=("$@") ; fi
    if [[ $header ]] ; then printf "Country%sConfirmed%sDeaths%sRecovered%sUpdated\n" \
                                   "$_separator" "$_separator" "$_separator" "$_separator" ; fi

    for _country in ${country_list[@]}; do
            corona.get_data "$_country"
            # cut country names
            local _country_name="$(cut -c -18 <<< ${current_data_list[0]})"
            _country_name="${_country_name//'_'/' '}"

            # printout data
            printf "%s$_separator%s$_separator%s$_separator%s$_separator%s\n" \
                   "$_country_name" "${current_data_list[3]}" "${current_data_list[4]}" \
                   "${current_data_list[5]}" "${current_data_list[2]}_${current_data_list[1]}"

            # printout summary
            for _i in {0..2} ; do
                total_count_list[$_i]=$((total_count_list[$_i] + ${current_data_list[$((_i+3))]}))
            done

        done
        printf "%s$_separator%s$_separator%s$_separator%s$_separator%s\n" \
               "Summary" "${total_count_list[0]}" "${total_count_list[1]}" "${total_count_list[2]}" \
               "$(date -d $target_date +'%d.%m.%Y')"
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

    if [[ $UPDATE_METHOD=="git" ]] ; then
        if ! which git >/dev/null; then
            echo "plase install git first!"
            echo "debian based systems: 'sudo apt update && sudo apt install git'"
            exit 123
            fi
        fi

    corona.main "$@"
    exit 0
fi
