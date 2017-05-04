  mp3downloader
=================

### Table of contents

 * [Download all mp3 from Youtube Playlist](#Download-all-mp3-from-Youtube-Playlist)
 * [Download mp3 from string](#Download-mp3-from-string)
 * [Download mp3 from file (string)](#Download-mp3-from-file-(string))
 * [Download mp3 from file (youtube URL)](Download-mp3-from-file-(youtube URL))

### Download all mp3 from Youtube Playlist

```sh
./mp3downloader.sh -s playlist -u "https://www.youtube.com/playlist?list=<ID>"
```

### Download mp3 from string

```sh
./mp3downloader.sh -s direct balgue de toto
```

### Download mp3 from file (string)

```sh
./mp3downloader.sh -s tracklist -p playlistTrack.txt
```

### Download mp3 from file (youtube URL)

```sh
./mp3downloader.sh -s youtube -p playlistYoutube.txt
```

### Rename Tracks with AcoustID database

```sh
./mp3downloader.sh -r ./playlistYoutube
```
