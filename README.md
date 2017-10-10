  mp3downloader
=================

### Table of contents

 * [Download mp3 from direct input](#Download-mp3-from-direct-input)
 * [Download mp3 from file ](#Download-mp3-from-file)
 * [Example file ](#Example-file)

### Download mp3 from direct input

```sh
./mp3downloader.sh -d "https://www.youtube.com/watch?v=<ID>"
./mp3downloader.sh -d "https://www.youtube.com/watch?v=<ID>&index=1&list=<ID>"
./mp3downloader.sh -d "Les blagues de Toto"
```

### Download mp3 from file

```sh
./mp3downloader.sh -f tracklist.txt
```

### Example file
```sh
[pinksnake@ubuntu:mp3downloader] cat tracklist.txt
https://www.youtube.com/watch?v=yGZuJnkMBso
La tribu de Dana
Les balgues de toto
https://www.youtube.com/watch?v=yGZuJnkMBso
```

### Contributing

1. Fork it!
2. Create your feature branch: `git checkout -b my-new-feature`
3. Commit your changes: `git commit -am 'Add some feature'`
4. Push to the branch: `git push origin my-new-feature`
5. Submit a pull request and enjoy!

### Contributors

Check out all the awesome [contributors](https://github.com/PinkSnake/mp3downloader/graphs/contributors).
