#!/bin/bash

#11 characters (Length of Youtube video ids).
#YOUTUBELENGTHID=11

# add some color to message
readonly ERR="\033[31m[ERROR]\e[0m"
readonly WARN="\033[33m[WARN]\e[0m"
readonly INFO="\033[32m[INFO]\e[0m"

############################################################
# create output directory for playlist and log file inside #
############################################################
function create_output_dir {

	mkdir -p "$DOWNPATH_DIR"
	touch "$MYLOGFILE"
}

############################################################
######### Extract and store audio from youtube url #########
############################################################
function youtube_download_audio {

	local destdir="$1"
	local dlpath="$2"

	youtube-dl --extract-audio \
			   --audio-format mp3 \
			   --output "$destdir/%(title)s.%(ext)s" "$dlpath"
			   --ignore-errors

}

############################################################
######## Parse a file to dowload audio from Youtube ########
############################################################
function youtube_download_from_file {

	local filetoparse="$1"
	local destdir="$2"

	# replcae all spaces with -
	destdir=$(echo "$destdir" | sed -e 's/\ /-/g')

	local nbrlines=$(grep -cve '^\s*$' "$filetoparse") # count how many lines are not empty in file

	echo -e "[FUNC] filetoparse -> $filetoparse "
	echo -e "[FUNC] destdir -> $destdir "

	mkdir -p "$destdir"

	# read playlist file line by line
	while read line
	do
		if [ "$line" != "" ]; then
			count=$((count+1))
			echo "****************************************" #>> "$MYLOGFILE"
			echo -e "Downloading trak [ $count / $nbrlines]" #| tee >> "$MYLOGFILE"
			#echo "$line" >> "$MYLOGFILE"

			youtube_download_audio "$PWD/$destdir" "$line"

			echo "[STATUS DL] --> $?"

		else
			echo -e "$WARN empty line founded in the source file please take care the next time."
		fi

	done < "$filetoparse"

}

############################################################
####### Download all tracks from a Youtube Playlist ########
############################################################
function youtube_playlist_download {

	DOWNPATH_DIR=$(lynx -dump "$YOUTUBEURL" | grep "Play all*$" -A 2 | tail -n 1)

	YOUTUBEPLAYLIST=$(lynx -dump "$YOUTUBEURL" | \
				  	sed -n '/Hidden links/,$p' | \
				  	tail -n +4                 | \
				  	head -n -1                 | \
				  	sed 's/[[:digit:]]\+\.//g' | \
				  	sed 's/\&index.*//'        | \
				  	sed 's/\&list.*//'           \
				  	)

	NBRTRACK=$(echo "$YOUTUBEPLAYLIST" | wc -l )

	echo -e "$INFO Playlist name : $DOWNPATH_DIR"
	echo "Nbr track : $NBRTRACK"

	TMPPLAYLISTFILE="$DOWNPATH_DIR"".tmp"
	# replcae all spaces with -
	TMPPLAYLISTFILE=$(echo "$TMPPLAYLISTFILE" | sed -e 's/\ /-/g')
	echo -e "$WARN tmp: $TMPPLAYLISTFILE"

	touch $TMPPLAYLISTFILE
	echo "$YOUTUBEPLAYLIST" >> "$TMPPLAYLISTFILE"

	youtube_download_from_file "$TMPPLAYLISTFILE" "$DOWNPATH_DIR"

	# clean tmp file
	rm "$TMPPLAYLISTFILE"

}

###########################################################
####### Parse Playlist file and download all files ########
###########################################################
function track_playlist_download {

	create_output_dir

	NUMOFLINES=$(wc -l < "$FILESOURCEPATH")
	echo -e "$INFO $NUMOFLINES tracks will be downloaded!"

	# read playlist file line by line
	while read line
	do
	   count=$((count+1))
	   echo "****************************************" >> "$MYLOGFILE"
	   echo -e "Downloading trak [ $count / $NUMOFLINES]" | tee >> "$MYLOGFILE"
	   echo "$line" >> "$MYLOGFILE"
	   track_playlist_direct "$line"
	done < $FILESOURCEPATH

	echo >> "$MYLOGFILE"
}


###########################################################
############### Download mp3 from string ##################
###########################################################
function track_playlist_direct { # download mp3 from string

	# Get video title
	TITLE=$(echo "$@"|sed -e 's/\ /+/g')
	#echo -e "$WARN TITLE is: $TITLE"
	if [ -z "$TITLE" ]; then echo -e "nothing to look for"; exit 1; fi

	# get Youtube URL (thx to Guillaume :P )
	URLTODONWLOAD=$(lynx -dump https://www.youtube.com/results?search_query="$TITLE"|grep "watch?" |head -n1 |awk '{print $2}')

	# sometime with have [num.] at the beginning of the URL ... i don't know why
	URLTODONWLOAD=$(echo $URLTODONWLOAD | sed 's/\[.[1234567890]]*//g')

	# get the video ID and size
	# VIDEOID=$(echo $URLTODONWLOAD | sed 's/.*watch?v=//')
	# VIDEOIDSIZE=${#VIDEOID}

	# check ID lenght
	#if [ "$YOUTUBELENGTHID" = "$VIDEOIDSIZE" ];
	#   then
	#	echo "Size seems good"
	#else
	#	echo "Size doesn't match with Youtub URL Length!"
	#fi

	# download the video and ask the sound extraction (video will be remove automatically)
	#echo "Downloading from $URLTODONWLOAD with ID: $VIDEOID - $VIDEOIDSIZE "

	youtube_download_audio "$PWD/$DOWNPATH_DIR" "$URLTODONWLOAD"
}


#**********************************************************
#********************** Entry point ***********************
#**********************************************************

# Extract args
while getopts "s:p:u:h" opt; do
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
			#DOWNPATH_DIR=$(echo "${@:3}" | sed -e 's/\ /-/g')
			#MYLOGFILE=direct.log
			track_playlist_direct "${@:3}" # pass arg from the 3rd (e.g without -s direct)
			#rm direct.log
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
		DOWNPATH_DIR=$(basename "$FILESOURCEPATH")
		DOWNPATH_DIR="${DOWNPATH_DIR%.*}"
		echo -e "$INFO Download directory will be: $DOWNPATH_DIR"
		MYLOGFILE=$DOWNPATH_DIR/playlist.log
		;;
	u)
		YOUTUBEURL=$OPTARG
		echo -e "$INFO Loading tracks from: $YOUTUBEURL"
		;;
	h)
		echo "This program dump mp3 from youtube playlist or tracklist."
		echo -e "\t -s : source name [ youtube | tracklist ]"
		echo -e "\t -p : source path [ path to playlist ]"
		echo -e "\t -u : url to youtube playlist"
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
		track_playlist_download
		;;
	*)
		echo "Commande will be not processed"
		exit 2
		;;
esac

exit 1
