#!/bin/bash

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#  - Pn!nkSn@ke - mp3 Downloader
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# [NS] - [05/05/2017] - [1.2.0this scrip(BETA)]
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

VERSION="1.2.0(BETA)"

# add some color to message
readonly ERR="\033[31m[ERROR]\e[0m"
readonly WARN="\033[33m[WARN]\e[0m"
readonly INFO="\033[32m[INFO]\e[0m"

############################################################
##################### Install Java JRE 8 ###################
############################################################
function java_down_and_install {

    sudo add-apt-repository ppa:webupd8team/java -y && \
    sudo apt-get update && \
    sudo apt-get install oracle-java8-installer && \
    sudo apt-get install oracle-java8-set-default
}

############################################################
############## Download filebot 4.7.9 Portable #############
############################################################
function filebot_download_portable {

    local destdir="${PWD}"
    local filebottarball="Filebot.tar.xz"
    local filebotversion="4.7.9"

    echo -e "$INFO Downloading filebot..."

    wget -O "$destdir/$filebottarball" \
    "https://kent.dl.sourceforge.net/project/filebot/filebot/FileBot_$filebotversion/FileBot_$filebotversion-portable.tar.xz"

    echo -e "$INFO Untar..."
    tar -xf "$filebottarball" -C ./filebot

    echo -e "$INFO Installing libchromaprint-tools"
    sudo apt install libchromaprint-tools
}

############################################################
######## Check dependencies in ask for installation ########
############################################################
function depchecker {

    local deplist="youtube-dl"

    echo -e "$INFO Checking dependencies..."

    for element in $deplist
        do

            #echo "$element is required by mp3downloader. Searching..."

            if ! whereis $element > /dev/null; then
                # Really make sure they're serious
                read -p "Do you want to install $element? " -n 1 -r
                echo    # (optional) move to a new line
                if [[ $REPLY =~ ^[Yy]$ ]]
                then
                    sudo apt install $element
                else
                    echo "Skipping $element installation!"
                fi
            else
                echo -e "$INFO $element is already installed on the system"
            fi
        done
}

############################################################
######### Rename tracks  #########
###########################################################
function filebot_rename_tracks {

	local renamedir="$1"

	local filebotscript="./filebot/filebot.sh"

	if [ ! -f "$filebotscript" ]; then
    	echo -e "$ERR Filebot Script not found!"
    	echo -e "$ERR Please launch ./mp3downloader.sh -i filebot"
	fi

	./filebot/filebot.sh -rename "$renamedir" --db AcoustID

}

############################################################
######### Extract and store audio from youtube url #########
############################################################
function youtube_download_audio {

    local destdir="$1"
    local dlpath="$2"

    youtube-dl --extract-audio \
               --audio-format mp3 \
               --output "$destdir/%(title)s.%(ext)s" "$dlpath" \
               --ignore-errors
}

############################################################
######## Parse a file to dowload audio from Youtube ########
############################################################
function youtube_download_from_file {

    local filetoparse="$1"
    local destdir="$2"

    # Not space allow in the directory name
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

            youtube_download_audio "$PWD/$destdir" "$line"

        else
            echo -e "$WARN empty line founded in the source file please take care the next time."
        fi
    done < "$filetoparse"
}

############################################################
####### Download all tracks from a Youtube Playlist ########
############################################################
function youtube_playlist_download {

    local default_playlist_name="Unknown_PLaylist"
    DOWNPATH_DIR=""

    DOWNPATH_DIR=$(lynx -dump "$YOUTUBEURL" | \
                   grep "Play all*$" -A 2   | \
                   tail -n 1                  \
                   )

    # check Mix ?
    if [ -z "$DOWNPATH_DIR" ]; then
        echo -e "It's maybe a Youtube Mix. Let me check... ";

        DOWNPATH_DIR=$(lynx -dump "$YOUTUBEURL" | \
                       grep "Sign in to YouTube" -A 4 | \
                       tail -n 1 | \
                       sed 's/\[.[1234567890]]*//g' \
                       )

        # if return is empy ask
        if [ -z "$DOWNPATH_DIR" ]; then
            echo -e "$WARN Playlist not found!"
            read -r -p "PLease enter a name for you playlist and press [ENTER]: " DOWNPATH_DIR
            if [ -z "$DOWNPATH_DIR" ]; then
                echo "Empy entry! Well done! Playlist will be Unknown_PLaylist"
                DOWNPATH_DIR="$default_playlist_name"
            else
                DOWNPATH_DIR=$(echo "$DOWNPATH_DIR" | sed -e 's/\ /-/g')
                echo -e "$INFO Playlist name will be : $DOWNPATH_DIR"
            fi
        fi
    fi

    YOUTUBEPLAYLIST=$(lynx -dump "$YOUTUBEURL" | \
                      sed -n '/Hidden links/,$p' | \
                      tail -n +4                 | \
                      head -n -1                 | \
                      sed 's/[[:digit:]]\+\.//g' | \
                      sed 's/\&index.*//'        | \
                      sed 's/\&list.*//'           \
                      )

    local nbrtrack=$(echo "$YOUTUBEPLAYLIST" | wc -l )

    echo -e "$INFO Playlist name : $DOWNPATH_DIR"
    echo "Nbr track : $nbrtrack"

    local tmpfile="$DOWNPATH_DIR"".tmp"

    # Replcae all spaces with -
    tmpfile=$(echo "$tmpfile" | sed -e 's/\ /-/g')
    echo -e "$WARN tmp: $tmpfile"

    touch "$tmpfile"
    echo "$YOUTUBEPLAYLIST" >> "$tmpfile"

    youtube_download_from_file "$tmpfile" "$DOWNPATH_DIR"

    # Clean tmp file
    rm "$tmpfile"
}

###########################################################
####### Parse Playlist file and download all files ########
###########################################################
function track_playlist_download {

    local inputfile="$1"

    # Create outuput directory
    mkdir -p "$DOWNPATH_DIR"

    # How many tracks
    local numoflines=$(wc -l < "$inputfile")
    echo -e "$INFO $numoflines tracks will be downloaded!"

    # Read playlist file line by line
    while read line
    do
       count=$((count+1))
       echo "****************************************"
       echo -e "Downloading trak [ $count / $numoflines]"
       track_playlist_direct "$line"
    done < "$FILESOURCEPATH"
}

###########################################################
############### Download mp3 from string ##################
###########################################################
function track_playlist_direct { # download mp3 from string

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

    youtube_download_audio "$PWD/$DOWNPATH_DIR" "$urltodonwload"
}

#**********************************************************
#********************** Entry point ***********************
#**********************************************************
clear;
echo -e "*** Welecome to mp3downloader $VERSION ***\n"

depchecker

# Extract args
while getopts "s:p:u:i:r:vh" opt; do
  case $opt in
    s)
        SOURCENAME=$OPTARG

        case "$SOURCENAME" in
        "youtube" ) # youtube playlist aka all youtube urls in one file
            echo -e "$INFO youtube selected!"
        ;;
        "playlist" ) # youtube playlist aka playlist URL
            echo -e "$INFO youtube playlist selected!"
        ;;
        "tracklist" ) # track list aka track name in file
            echo -e "$INFO tracklist selected!"
        ;;
        "direct" ) # direct download from arg string
            echo -e "$INFO direct download selected!"
            DOWNPATH_DIR="./direct"
            echo -e "Output directory will be: $DOWNPATH_DIR"
            track_playlist_direct "${@:3}" # pass arg from the 3rd (e.g without -s direct)
            exit 0
        ;;
        *)
            echo -e "$ERR Source didn't matched!"
            exit 2
        ;;
        esac
        ;;
    p)
        FILESOURCEPATH=$OPTARG
        echo -e "$INFO Loading tracks from: $FILESOURCEPATH"
        # Get file name
        DOWNPATH_DIR=$(basename "$FILESOURCEPATH")
        # Remove extention to create a folder with the same name
        DOWNPATH_DIR="${DOWNPATH_DIR%.*}"
        echo -e "$INFO Download directory will be: $DOWNPATH_DIR"
        ;;
    u)
        YOUTUBEURL=$OPTARG
        echo -e "$INFO Loading tracks from: $YOUTUBEURL"
        ;;
    i)
        ASKINSTALL=$OPTARG
        case "$ASKINSTALL" in
        "java" ) # youtube playlist aka all youtube urls in one file
            java_down_and_install
        ;;
        "filebot" ) # youtube playlist aka playlist URL
            filebot_download_portable
        ;;
        *)
            echo -e "$ERR Package didn't matched!"
            exit 2
        ;;
        esac
        ;;
    r)
		FOLDERTORENAME=$OPTARG
		filebot_rename_tracks "$FOLDERTORENAME"
		;;
    h)
        echo "This program dump mp3 from youtube playlist or tracklist."
        echo -e "\t -s : source name [ youtube | tracklist | direct ]"
        echo -e "\t -p : source path [ path to playlist ]"
        echo -e "\t -u : url to youtube playlist"
        echo
        echo -e "\t -i : install tools [ java | filebot ]"
        echo -e "\t -r rename files with AcoustID database"
        echo -e "\nYou can find few examples in the README.md"
        exit 0
        ;;
    \?)
      echo -e "$ERR Invalid option: -$OPTARG"
      exit 1
      ;;
    :)
      echo -e "$ERR Option -$OPTARG requires an argument."
      exit 1
      ;;

  esac
done

# Processing
case "$SOURCENAME" in

    "youtube")
        echo -e "$INFO Downloading from Youtube..."
        youtube_download_from_file "$FILESOURCEPATH" "$DOWNPATH_DIR"
    ;;
    "playlist")
        echo -e "$INFO Downloading from Youtube playlist URL..."
        youtube_playlist_download
    ;;
    "tracklist")
        echo -e "$INFO Downloading from Tracklist..."
        track_playlist_download "$FILESOURCEPATH"
    ;;
    *)
        echo "Commande will be not processed"
        exit 2
    ;;
esac

exit 0
