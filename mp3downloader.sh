#!/bin/bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  - Pn!nkSn@ke - mp3 Downloader
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# [NS] - [05/05/2017] - [2.0 (BETA)]
# -----------------------------------------------------------------------
# DESCRIPTION
#    This program dump mp3 from youtube playlist or tracklist.
#
# OPTIONS
#   -s, [ youtube | tracklist | direct ]   Set the source
#   -p, [ path to playlist ]               Set the playlist path
#   -u, [ url ]                            Set URL from Youtube
#   -i, [ java | filebot ]                 Install Java or Filebot
#   -r, [ folder path ]                    Rename all trakcs in a folder
#   -v,                                    Print script information
#   -h,                                    Print this help
#
# EXAMPLES
#    You can find few examples in the README.md
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
VERSION="2.1"

TRACKPATTERN="watch?v="
PLAYLISTPATTERN="playlist?list="

DOWNPATH_DIR="$PWD"

prompt()
{
    read -r -p "$1 [y/N] " response < /dev/tty
    if [[ $response =~ ^(yes|y|Y)$ ]]; then
        true
    else
        false
    fi
}

# printout fucntions
success() { echo -e "$(tput setaf 2)$1$(tput sgr0)";}
inform()  { echo -e "$(tput setaf 6)$1$(tput sgr0)";}
warning() { echo -e "$(tput setaf 1)$1$(tput sgr0)";}
newline() { echo "";}

######## Check dependencies in ask for installation ########
depchecker()
{
    local deplist="youtube-dl putty"

    inform "Checking dependencies..."
    for element in $deplist
    do
        if ! $(whereis -b $element | grep /usr/bin)> /dev/null; then
            # Really make sure they're serious
            if prompt "Do you want to install $element?"; then
                sudo apt install $"element"
            else
                warning "Skipping $element installation."
            fi
        else
            success "$element is already installed on the system."
        fi
    done
}

######### Extract and store audio from youtube url #########
dl_track_from_url()
{
    local destdir="$1"
    local dlpath="$2"

    youtube-dl --extract-audio \
               --audio-format mp3 \
               --output "$destdir/%(title)s.%(ext)s" "$dlpath" \
               --ignore-errors > /dev/null
}

######### Download mp3 from string #########
dl_from_string()
{
    # Get video title
    local title=$(echo "$@"|sed -e 's/\ /+/g')

    # Check if stdin is not enmpty
    if [ -z "$title" ]; then echo -e "nothing to look for"; exit 1; fi

    # Get Youtube URL (thx to Guillaume :P )
    local urltodonwload=$(lynx -dump \
                    https://www.youtube.com/results?search_query="$title" | \
                    grep "watch?" | \
                    head -n1      | \
                    awk '{print $2}' \
                    )

    # Sometime with have [num.] at the beginning of the URL...
    urltodonwload=$(echo "$urltodonwload" | sed 's/\[.[1234567890]]*//g')

    dl_track_from_url "$PWD/$DOWNPATH_DIR" "$urltodonwload"
}

####### Download all tracks from a Youtube Playlist ########
dl_from_playlist()
{
    local destdir="$1"
    local inputurl="$2"

    local youtubeplaylist=$(lynx -dump "$inputurl" | \
                      sed -n '/Hidden links/,$p' | \
                      tail -n +4                 | \
                      head -n -1                 | \
                      sed 's/[[:digit:]]\+\.//g' | \
                      sed 's/\&index.*//'        | \
                      sed 's/\&list.*//'           \
                      )

    local nbrtrack=$(echo "$youtubeplaylist" | wc -l )

    echo -e "$INFO Playlist name : $DOWNPATH_DIR"
    echo "$nbrtrack track(s) will be downloaded"

    local tmpfile="$DOWNPATH_DIR"".tmp"

    # Replcae all spaces with -
    tmpfile=$(echo "$tmpfile" | sed -e 's/\ /-/g')
    #echo -e "$WARN tmp: $tmpfile"

    touch "$tmpfile"
    echo "$youtubeplaylist" >> "$tmpfile"

    dl_from_urlfile "$tmpfile" "$DOWNPATH_DIR"

    # Clean tmp file
    rm "$tmpfile"
}

######### get a folder name #########
ask_for_destination_folder()
{
    read -r -p "PLease enter a name for your playlist and press [ENTER]: " DOWNPATH_DIR
    if [ -z "$DOWNPATH_DIR" ]; then
        echo "Empy entry! Well done! Playlist name will be Unknown_PLaylist"
        DOWNPATH_DIR="Unknown_PLaylist"
        else
        inform "Playlist name will be : $DOWNPATH_DIR"
    fi
}

######## Parse a file to dowload audio from Youtube ########
dl_from_urlfile()
{

    local filetoparse="$1"
    local destdir="$2"

    # Not space allowed in the directory name
    destdir=$(echo "$destdir" | sed -e 's/\ /-/g')

    # Count how many lines are not empty in file
    local nbrlines=$(grep -cve '^\s*$' "$filetoparse")

    mkdir -p "$destdir"

    # Read playlist file line by line
    while read line
    do
        if [ "$line" != "" ]; then

            count=$((count+1))

            echo "****************************************"
            echo -e "Downloading trak [ $count / $nbrlines]"

            dl_track_from_url "$PWD/$destdir" "$line"

        else
            echo -e "$WARN empty line founded in the source file please take care the next time."
        fi
    done < "$filetoparse"
}


#### Check if arg is youtube playlist or track ####
#### return 2 trak
####        3 playlist
####        1 error
is_yt_url()
{
    if [[ "${@}" =~ ^https://www.youtube.com.* || "${@}" =~ ^http://www.youtube.com.* ]]; then
        if [[ "${@}" == *"$TRACKPATTERN"* ]]; then
            return 2
        elif [[ "${@}" == *"$PLAYLISTPATTERN"*  ]]; then
            return 3
        else
            warning "Seems to be a strange Youtube URL."
            return 1
        fi
    fi
}

#### Parse inpute file ad download items ####
check_and_dl_input_file()
{
    local filepath="$1"
    local nbrtrack=$(wc "$filepath" | awk '{print $1}' )

    inform "Checking input file $filepath"
    # Read playlist file line by line
    while read line
    do
        if [ "$line" != "" ]; then

            count=$((count+1))
            echo "****************************************"
            inform "Downloading Item [ $count / $nbrtrack]"

            smart_download "$line"
        else
            inform "Empty line founded in the source file please take care the next time."
        fi
    done < "$filepath"

}

#### check if the arg is Youtube url or string ####
smart_download()
{
    local input="$@"

    is_yt_url "$input"
    rc="$?"
    if [[ "2" = "$rc" ]]; then
        success "Input seems to ba an Youtube track."
        dl_track_from_url "$DOWNPATH_DIR" "$@"
    elif [[ "3" = "$rc"  ]]; then
        success "Input seems to ba an Youtube playlist."
        dl_from_playlist "$DOWNPATH_DIR" "$@"
    elif [[ "1" = "$rc"  ]]; then
        warning "Seems to be a strange youtube URL"
        warning "Please check input and try again."
        exit 2
    else # assume it's a string input
        success "Assuming input is a simple string."
        dl_from_string "$input"
    fi
}

#**********************************************************
#********************** Entry point ***********************
#**********************************************************
clear;
echo -e "*** Welecome to mp3downloader $VERSION ***"

# Extract args
while getopts "d:f:vh" opt; do
  case $opt in
    d) # direct download
        ask_for_destination_folder
        # check if it's a youtube url or not
        smart_download "${@:2}"
    ;;
    f) # download from file filename
        ask_for_destination_folder
        check_and_dl_input_file "${@:2}"
    ;;
    h)
        echo "This program dump mp3 from youtube playlist or tracklist."
        echo -e "\t -d : Direct download from string input"
        echo -e "\t -f : Download from file"
        echo -e "\nYou can find few examples in the README.md"
        exit 0
    ;;
    \?)
      warning "Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      warning "Option -$OPTARG requires an argument."
      exit 1
      ;;
  esac
done

exit 0