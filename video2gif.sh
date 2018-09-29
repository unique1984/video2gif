#!/usr/bin/env bash
#---------------------------------------------------------------------
# video2gif.sh
#
# ffmpeg shellscript video to gif animation
#
# Script: video2gif.sh
# Version: 1.0.0
# Author: Yasin KARABULAK <yasinkarabulak@gmail.com>
#
#---------------------------------------------------------------------
LC_NUMERIC=C

function help {
	echo -e "Bağımlılıklar: ffmpeg, bc\n"
	echo -e "Kullanım\nvideo2gif <videoDosyası.mp4> <ölçek> <fps> [<start> <length>]"
}

function parcala {
	#~ https://stackoverflow.com/questions/3362920/get-just-the-filename-from-a-path-in-a-bash-script?answertab=votes#tab-top
	FULL="$1"
	F_PATH=${FULL%/*}
	F_BASE=${FULL##*/}
	F_NAME=${F_BASE%.*}
	F_EXT=${F_BASE##*.}
	#~ echo $F_PATH
	#~ echo $F_BASE
	#~ echo $F_NAME
	#~ echo $F_EXT
	#~ exit
}

if [ -z $(which ffmpeg) ]; then
	echo -e "ffmpeg bulunamadı!"
	help
	exit
fi

if [ -z $(which bc) ]; then
	echo -e "bc bulunamadı!"
	help
	exit
fi

if [ -z "$1" ]; then
	help
	echo -e "Kullanım\nvideo2gif <videoDosyası.mp4> <ölçek [default=full] | bilgi [WxH, süre]> <fps [default=10]> <start [default=0]> <length [default=all]>"
	exit
fi
#~ echo "$1"

exportDir="$HOME/Videolar/gifConvert"
if [ ! -d $exportDir ]; then
	mkdir -p "$exportDir"
fi

parcala "$1"
#~ echo $F_NAME
exportFile="$exportDir/$F_NAME.gif"
#~ echo $exportFile
#~ exit
inputVideo="$PWD/$1"
resolution=$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of  default=nw=1:nk=1 "$inputVideo")
	width=$(echo $resolution | awk '{print $1}')
	height=$(echo $resolution | awk '{print $2}')
framerate=$(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=noprint_wrappers=1:nokey=1 "$inputVideo")
durationSec=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 "$inputVideo")
	durationDecimal=$(printf "%.0f" $durationSec)
#~ 6630.134000
durationDigit=$(ffprobe -v error -show_entries format=duration -of default=noprint_wrappers=1:nokey=1 -sexagesimal "$inputVideo")
#~ 1:50:30.134000

if [ -z "$2" ]; then
	echo -e "$width x $height\n"
	scale=$width
elif [ "$2" == "bilgi" ]; then
	echo -e "Dosya\t$inputVideo"
	echo -e "Çözünürlük\t"$width"x"$height
	echo -e "Fps\t"$framerate" default for gif 25"
	echo -e "Süre sn\t"$durationSec" sec\n"$durationDigit" Saat:Dakika:Saniye.microSaniye"
	echo -e "Süre biçimli\t"$durationDigit" Saat:Dakika:Saniye.microSaniye"
	exit
else
	echo -e "Video $2 pixel genişliğe ölçeklenecek!"
	scale=$2
fi

if [ -z "$3" ]; then
	echo -e "Gif 25 fps olarak oluşturulacak!\n"
	framerate=25
else
	echo -e "Gif $3 fps olarak oluşturulacak!\n"
	framerate=$3;
fi

if [ -z "$4" ]; then
	startSec=0
	start=" -ss "$startSec
	length=" -t "$durationSec
else
	startSec=$4
		if [ $startSec -ge $durationDecimal ]; then
			echo -e "Başlangıç saniyesi video süresinden uzun!"
			exit
		fi
	start=" -ss "$4
	minus=$(bc <<< "$durationSec-$startSec")
	if [ -z $5 ]; then
		length=" -t "$minus
	else
		lengthSec=$5
		length=" -t "$5
		minus=$(bc <<< "$durationSec-($startSec+$lengthSec)")
			if [ $(printf "%.0f" $minus) -lt 0 ]; then
				echo -e "Bitiş saniyesi video bitiş zamanını aşmakta!\n $startSec . saniye başlangıç en fazla "$(bc <<< "$durationSec-$startSec")" saniye olabilir."
				exit
			fi
	fi
fi
echo "Videonun $startSec. saniyesinden -> $lengthSec saniye dönüştür"

ffmpeg -y $start$length -i "$inputVideo" -vf fps=$framerate,scale=$scale:-1:flags=lanczos,palettegen palette.png
ffmpeg -y $start$length -i "$inputVideo" -i palette.png -filter_complex  "fps=$framerate,scale=$scale:-1:flags=lanczos[x];[x][1:v]paletteuse" "$exportFile"
rm palette.png

if [ -f "$exportFile" ]; then
	echo -e "$F_NAME.gif dosyası $exportDir dizininde oluşturuldu."
else
	echo -e "$F_NAME.gif dosyası oluşturulamadı!"
fi
