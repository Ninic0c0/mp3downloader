
How to use mp3downloader
########################

# Download all mp3 from Youtube Playlist
./mp3downloader.sh -s playlist -u "https://www.youtube.com/playlist?list=PL63F0C78739B09958"

# Download mp3 from string
./mp3downloader.sh -s direct balgue de toto

# Download mp3 from file (string)
./mp3downloader.sh -s tracklist -p playlistTrack.txt

# Download mp3 from file (youtube URL)
./mp3downloader.sh -s youtube -p playlistYoutube.txt