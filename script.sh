#! /bin/bash
# Apk Multi-Tools 1.0 (C) 2012 by Gerald Wayne Baggett JR {Raziel23x}
# Ported to Linux by farmatito 2010
# Changelog for linux version:
# v 0.1 Initial version
current="pwd"
# ========Colors============
NOCOLOR='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHTGRAY='\033[0;37m'
DARKGRAY='\033[1;30m'
LIGHTRED='\033[1;31m'
LIGHTGREEN='\033[1;32m'
YELLOW='\033[1;33m'
LIGHTBLUE='\033[1;34m'
LIGHTPURPLE='\033[1;35m'
LIGHTCYAN='\033[1;36m'
WHITE='\033[1;37m'
# ===========================

# 0) Pull APK
ap () {
	clear
	if [[ $(adb devices | grep "device" -c) -gt "1" ]] ; then
		echo "Enter APK remote file location:"
		echo "i.e. /system/app/launcher.apk"
		echo
		printf "Input: "
		read INPUT
		APK_FILE=`basename $INPUT`
		adb pull "$INPUT" "place-apk-here-for-modding/$APK_FILE"
		if [ "$?" -ne "0" ] ; then
			echo "Error: while pulling $APK_FILE"
		fi
		if [[ -f "place-apk-here-for-modding/$APK_FILE" ]] ; then
			echo "$APK_FILE copied."
			fileName=${APK_FILE%*.apk}
		fi
	else
		echo "Error. No device connected."
	fi
}

# 1) Extract APK
ex () {
	echo
	clear
	if [[ -n $fileName ]] ; then
		cd bin
		rm -f "../place-apk-here-for-modding/$fileName-signed.apk"
		rm -f "../place-apk-here-for-modding/$fileName-unsigned.apk"
		rm -rf "../projects/$fileName.apk"
		if [ ! -d "../projects/$fileName.apk" ] ; then
			mkdir "../projects/$fileName.apk"
		fi
		clear
		# Must be -o"../projects" and not -o "../projects"
		7za x -o"../projects/$fileName.apk" ../place-apk-here-for-modding/$fileName.apk
		cd ..
	else
		actvfile ; retval=$? ; if [[ $retval == 0 ]]; then ex ; fi
	fi
}

# 2) Optimize APK PNGs
opt () {
	clear
	echo
	if [[ -n $fileName || -f ../projects/$fileName.apk/res ]] ; then
		cd bin
		find "../projects/$fileName.apk/res" -name *.png | while read PNG_FILE ;
		do
			if [ `echo "$PNG_FILE" | grep -c "\.9\.png$"` -eq 0 ] ; then
				optipng -o99 "$PNG_FILE"
			fi
		done
		clear
		echo
		echo "PNGs optimized."
		cd ..
	else
		echo "Error. Check active APK file and if APK is extracted."
	fi
}

pack () {
	clear
	cd bin
	7za a -tzip "../place-apk-here-for-modding/$fileName-unsigned.apk" ../projects/$fileName.apk/* -mx"$clvl"
	cd ..
}

oa () {
	rm -rf "projects/$fileName.apk/META-INF"
	pack
}

# 3) Zip APK
zip () {
	clear
	if [[ -n $fileName ]] ; then
		echo "Enter APK type:"
		echo "---------------"
		PS3=$(echo "Enter selection: ")
		select mode in "System APK" "Regular APK" ; do
			case "$mode" in
			"System APK"  ) pack ; break ;;
			"Regular APK" ) oa ; break ;;
				*) echo "Invalid input." ;;
			esac
		done
		clear ; echo "File: $fileName.apk zipped."
	else
		actvfile ; retval=$? ; if [[ $retval == 0 ]]; then zip ; fi
	fi
}

# 4) Sign APK
si () {
	 clear
	echo
	if [[ -n $fileName ]] ; then
		clear
		cd bin
		dt=$(date '+%d-%m-%Y-%H-%M');
		INFILE="../place-apk-here-for-modding/$fileName-unsigned.apk"
		projectsFILE="../place-apk-here-for-signing/$fileName-$dt-signed.apk"
		# md5=($(md5sum $projectsFILE))
	    
		if [ -e "$INFILE" ] ; then
			#echo "java -jar signapk.jar -w testkey.x509.pem testkey.pk8 $INFILE $projectsFILE"
		java -jar apksigner.jar sign --key testkey.pk8 --cert testkey.x509.pem --in "$INFILE" --out "$projectsFILE"
			if [ "x$?" = "x0" ] ; then
			# // 
				echo "Not delete."
				# rm -f "$INFILE"
			fi
			echo "Done."
			mdq=$(md5sum $projectsFILE | cut -c -32)
			echo "NAME:$fileName-$dt-signed.apk MD5:$mdq">>"../place-apk-here-for-signing/MD5.ini"
		else
			echo -e "${RED}Warning: cannot find file '$INFILE'${NOCOLOR}"
		fi
		cd ..
	else
		actvfile ; retval=$? ; if [[ $retval == 0 ]]; then si ; fi
	fi

}

# 5) Zipalign
zipa () {
	echo
	if [[ -n $fileName ]] ; then
		for STRING in "unsigned" "signed"
		do
			if [ -f "place-apk-here-for-modding/$fileName-$STRING.apk" ] ; then
				zipalign -fv 4 "place-apk-here-for-modding/$fileName-$STRING.apk" "place-apk-here-for-modding/$fileName-$STRING-aligned.apk"
				if [ "x$?" = "x0" ] ; then
					mv -f "place-apk-here-for-modding/$fileName-$STRING-aligned.apk" "place-apk-here-for-modding/$fileName-$STRING.apk"
				fi
			else
				echo "Zipalign: Cannot find file 'place-apk-here-for-modding/$fileName-$STRING.apk'"
			fi
		done
		clear ; echo "Done."
	else
		actvfile ; retval=$? ; if [[ $retval == 0 ]]; then zipa ; fi
	fi
}

# 6) Install APK
ins () {
	clear
	if [[ -n $fileName ]] ; then
		echo
		if [[ $(adb devices | grep "device" -c) -gt "1" ]] ; then
			echo "Install APK: $fileName.apk (y/N)?"
			read -p INPUT[yn] answer
			if [[ $answer = y ]] ; then
				#echo "adb install -r place-apk-here-for-modding/$fileName-signed.apk"
				adb install -r "place-apk-here-for-signing/$fileName-signed.apk"
			fi
		else
			echo "Error. No device connected."
		fi
	else
		actvfile ; retval=$? ; if [[ $retval == 0 ]]; then si ; fi
	fi
}

# 7) Zip / Sign / Install APK
alli () {
	if [[ -n $fileName ]] && [[ $(adb devices | grep "device" -c) -gt "1" ]] ; then
		echo "Enter APK type:"
		echo "---------------"
		PS3=$(echo "Enter selection: ")
		select mode in "System APK" "Regular APK" ; do
			case "$mode" in
				"System APK"  ) pack ; ins ; break ;;
				"Regular APK" ) oa ; pack ; si ; ins ; break ;;
					*) echo "Invalid input." ;;
			esac
		done
	else
		echo "Error. Check active APK file and make sure device is connected."
	fi
}

# 8)
apu () {
	if [[ -n $fileName ]] && [[ $(adb devices | grep "device" -c) -gt "1" ]] ; then
		clear
		echo "Enter remote APK location."
		echo "i.e. /system/app/launcher.apk "
		echo
		printf "Input: "
		read INPUT
		adb root
		adb remount
		adb shell cp $INPUT $INPUT.backup
		adb push "place-apk-here-for-modding/$fileName-unsigned.apk" "$INPUT"
		adb shell chmod 644 $INPUT
	else
		echo "Error. Check active APK file and make sure device is connected."
	fi
}

# 9)
de () {
	
	if [[ -n $fileName ]] ; then
		clear
		cd bin
		rm -f "../place-apk-here-for-modding/$fileName-signed.apk"
		rm -f "../place-apk-here-for-modding/$fileName-unsigned.apk"
		rm -rf "../projects/$fileName.apk"
		java -jar apktool.jar --only-main-classes d ../place-apk-here-for-modding/$fileName.apk -o "../projects/$fileName.apk"
		cd ..
	else
		echo
		actvfile ; retval=$? ; if [[ $retval == 0 ]]; then de ; fi
	fi
}

# 10)
co () {
	# clear
	cochk
	if [[ -n $fileName ]] ; then
		cd bin
		baseAPK=`basename $fileName`
		java -jar apktool.jar --use-aapt2 b "../projects/$fileName.apk" -o "../place-apk-here-for-modding/$fileName-unsigned.apk"
		cd ..
	else
		actvfile ; retval=$? ; if [[ $retval == 0 ]]; then co ; fi
	fi
	retainorigfiles
}

cochk () {
	clear
	echo "Enter APK type:"
	echo "---------------"
	PS3=$(echo "Enter selection: ")

	select comptype in "System APK" "Regular APK" ; do
		case "$comptype" in
			"System APK"|"Regular APK" ) break ;; # valid input.
			   *) echo "Invalid input." ;;
		esac
	done
}


retainorigfiles () {
	echo
	# clear
	if [[ $comptype == 1 ]]; then
		echo "Aside from APK signatures, copy unmodified files "
	else
		printf "Copy unmodified files "
	fi
	printf "to compiled APK to reduce errors (Y/n)? "
	read INPUT
	if [[ x$INPUT ==  "xY" || x$INPUT ==  "xy" || x$INPUT ==  "x" ]] ; then
		cd bin
		rm -rf ../keep
		7za x -o"../keep" ../place-apk-here-for-modding/$fileName.apk
		if [[ $comptype == 2 ]] ; then
			rm -rf ../keep/META-INF
		fi
		echo
		echo "Delete all modified files in the /keep directory."
		echo "If you modified an XML file, delete the resources.arsc file."
		echo "Press Enter key to continue."
		read DUMMY
		7za a -tzip "../place-apk-here-for-modding/$fileName-unsigned.apk" ../keep/* -mx"$clvl" -r
		rm -rf ../keep
		cd ..
	fi
	clear
	echo
	echo "Done"
}

# 11)
all () {
	co
	si
	ins
}

# 12)
bopt () {
	clear
	cd bin
	mkdir -p "../place-apk-here-to-batch-optimize/original"
	find "../place-apk-here-to-batch-optimize" -name *.apk | while read APK_FILE ;
	do
		echo "Optimizing $APK_FILE"
		# Extract
		7za x -o"../place-apk-here-to-batch-optimize/original" "../place-apk-here-to-batch-optimize/$APK_FILE"
		# PNG
		find "../place-apk-here-to-batch-optimize/original" -name *.png | while read PNG_FILE ;
		do
			if [ `echo "$PNG_FILE" | grep -c "\.9\.png$"` -eq 0 ] ; then
				optipng -o99 "$PNG_FILE"
			fi
		done
		# TODO optimize .ogg files
		# Re-compress
		7za a -tzip "../place-apk-here-to-batch-optimize/temp.zip" ../place-apk-here-to-batch-optimize/original/* -mx"$clvl"
		FILE=`basename "$APK_FILE"`
		DIR=`dirname "$APK_FILE"`
		mv -f "../place-apk-here-to-batch-optimize/temp.zip" "$DIR/optimized-$FILE"
		rm -rf ../place-apk-here-to-batch-optimize/original/*
	done
	rm -rf "../place-apk-here-to-batch-optimize/original"
	cd ..
}

# 13)
asi () {
	clear
	echo
	cd bin
	find "../place-apk-here-for-signing" -name *.apk | while read PLACE-APK-HERE-FOR-SIGNING ;
	do
		java -jar signapk.jar -w testkey.x509.pem testkey.pk8 $PLACE-APK-HERE-FOR-SIGNING ${PLACE-APK-HERE-FOR-SIGNING%.*}-signed.apk
		echo "${PLACE-APK-HERE-FOR-SIGNING%.*}-signed.apk - Done."
	done
	cd ..
}

# 14)
ogg () {
	clear
	cd bin
	mkdir -p "../place-ogg-here"
	find "../place-ogg-here/" -name *.ogg | while read OGG_FILE ;
	do
		FILE=`basename "$OGG_FILE"`
		DIR=`dirname "$OGG_FILE"`
		printf "%s" "Optimizing: $FILE"
		sox "$OGG_FILE" -C 0 "$DIR/optimized-$FILE"
		if [ "x$?" = "x0" ] ; then
			printf "\n"
		else
			printf "...%s\n" "Failed"
		fi
	done
}

# 15)
selt () {
	clear
	cd place-apk-here-for-modding
	echo
	echo -e "${YELLOW}Listing APK files:${NOCOLOR}"
	echo "------------------"
	PS3=$(echo ""; echo -e "${YELLOW}Choose APK: ${NOCOLOR}")
	fileList=$(find . -type f -name "*.apk")
	# Clean up list.
	fileList=${fileList/\.\//}

	if [[ -z $fileList ]] ; then
		clear
		echo -e "${RED}No APK files found. Please check the place-apk-here-for-modding directory.${NOCOLOR}"
		return 1
	else
		select fileName in $fileList; do
			if [[ -n "$fileName" ]] ; then
				fileName=${fileName%.*}
				if [[ $1 == "s1" ]]; then clear ; fi
					echo "Selected: $fileName.apk" ; break
					return 0
			else
		    	echo -e "${RED}Error. Wrong input."
				
		    	return 1
		    fi
		done
	fi


	cd ..
}

actvfile () {
	clear
	echo -e "${YELLOW}No active APK file set.${NOCOLOR}"
	printf "Set active APK file? (Y/n): "
	read INPUT
	if [[ x$INPUT == "xy" || x$INPUT == "xY" || x$INPUT == "x" ]]; then
		selt ; retval=$? ; if [[ $retval == 1 ]]; then
			echo "Operation aborted."
			return 1
		else
			return 0
		fi
	else
		clear ; echo "Operation aborted."
		return 1
	fi
}

# 16)
frm () {
	clear
	echo
	rm -rf $HOME/apktool
	cd bin
	printf "Pull framework-res.apk from an ADB device (Y/n)? "
	read INPUT
	if [[ x$INPUT == "xY" || x$INPUT == "xy" || x$INPUT == "x" ]] ;  then
		if [[ $(adb devices | grep "device" -c) -gt "1" ]] ; then
			echo
			echo "Pulling framework-res.apk from device."
			adb pull /system/framework/framework-res.apk ./framework-res.apk
		else
			echo "Error. No device connected."
		fi
	else
		localMode="true"
	fi

	if [[ -f ./framework-res.apk ]]; then
		if [[ $localMode == "true" ]]; then
			echo "Local framework-res.apk found."
		fi
		echo
		echo $(java -jar apktool.jar "if" ./framework-res.apk) | grep "Framework installed"
		clear
		echo
		if [ $? -eq 0 ] ; then
			echo "Done importing framework-res.apk"
		else
			echo "Error. Import failed."
		fi
	fi
	cd ..
}

# 17)
clr () {
	clear
	printf "${YELLOW}Do you want to clean your current projects (y/N)? ${NOCOLOR}"
	read INPUT
	if [[ "x$INPUT" = "xy" || "x$INPUT" = "xY" ]] ; then
		rm -rf place-apk-here-for-signing
		rm -rf projects
		rm -rf place-apk-here-to-batch-optimize
		mkdir place-apk-here-for-signing
		mkdir place-apk-here-to-batch-optimize
		echo "Projects cleared."
		echo
		printf "Clear place-apk-here-for-modding directory (y/N)? "
		read INPUT
		if [[ "x$INPUT" = "xy" || "x$INPUT" = "xY" ]] ; then
			echo "Directory place-apk-here-for-modding cleared."
			rm -rf place-apk-here-for-modding
			mkdir place-apk-here-for-modding
			fileName=""
		fi
		echo
		printf "Delete framework-res.apk import (y/N)? "
		read INPUT
		if [[ "x$INPUT" = "xy" || "x$INPUT" = "xY" ]] ; then
			echo "File framework-res.apk deleted."
			rm -rf $HOME/apktool
		fi
	else
		echo "Canceled."
	fi
}

# 20)
setclv () {
	echo "Current compression level: $clvl"
	printf "Enter new compression level (Value 0-9): "
	read INPUT
	echo
	case "$INPUT" in
		0|1|2|3|4|5|6|7|8|9 )
			clvl=$INPUT
			sed -i "1s/compressionLevel=.*/compressionLevel=$INPUT/g" "$confFile"
			echo "Compression level set at: $clvl"
		;;

		*)  echo "Invalid value."
		;;
	esac
}

# 00)
quit () {
	exit 0
}

apren () {
	echo
	mkdir -p "apk-rename"
	if [[ ! -z $1 ]]; then
		apkclean $1
	fi
	clear ; echo "Done."
}

apkclean () {
	cd bin
	echo Renaming APKs...
	if [[ ! -z $1 ]]; then
		dir=$1
		find $dir -type f -name "*.apk" | while read APK_FILE ;
		do
			labl=$(aapt d badging "$APK_FILE" | grep "application: label=" | cut -d "'" -f2)
			labl=${labl//"&"/"-"}
			if [[ ! -z $labl ]]; then
				vers=$(aapt d badging "$APK_FILE" | grep "versionName=" | cut -d "'" -f6)
			else
				echo "ERROR: (File) ${APK_FILE//"../apk-rename/"/}"
			fi
			if [[ "$APK_FILE" != "${dir}${labl} $vers.apk" && -n $labl ]] ; then
				mv -nf "$APK_FILE" "$dir$labl $vers.apk"
				echo "Renamed `basename "$APK_FILE"` to $labl $vers.apk"
			fi
		done
	fi
	cd ..
}

devback () {
	mkdir -p "apk-backup"
	if [[ $(adb devices | grep "device" -c) -gt "1" ]] ; then
		echo
		echo "Pulling all APKs from device /data/app/..."
		echo "(WARNING: This operation can take a long time depending"
		echo "          on the number of installed APKs)" ; echo

		adb pull "/data/app/" "./apk-backup/"
		echo
		apkclean "../apk-backup/"
	else
		echo "Error. No device connected."
	fi

	clear ; echo "Done."
}

devres () {
	if [[ $(adb devices | grep "device" -c) -gt "1" ]] ; then
		echo
		echo "Installing all APKs in ./apk-backup/ to device..."
		echo "(WARNING: This operation can take a long time depending"
		echo "          on the number of APKs)" ; echo

		echo
		echo -n "Use Whitelist.txt as filter? (Y/n): "
		read USE_LIST

		case "$USE_LIST" in
			"" | "Y" | "y" ) LISTMODE="y"
				;;
		esac

		echo

		totalapp=$(ls ./apk-backup/ | grep ".apk" -c)
		progress=1
		find "./apk-backup/" -type f -name "*.apk" | while read APK_FILE ;
		do
			CURRENTAPK=${APK_FILE##.*/}
			echo "App #$progress of $totalapp"
			if [[ $(cat ./apk-backup/Whitelist.txt | grep -c "$CURRENTAPK") != "0" && "$LISTMODE" == "y" ]] ; then
				adb install -r "$APK_FILE"
			else
				echo "$CURRENTAPK is not allowed. Check Whitelist.txt."
			fi
			progress=$((progress+1))
			echo
		done
	else
		echo "Error. No device connected."
	fi

	clear ; echo "Done."
}

mkzip () {
	if [[ -f "./bin/template.zip" ]]; then
		if [[ -d "./zip-temp" ]]; then
			echo ;  printf "Clean zip-temp directory? (y/N): "
			read PRMPT
			case $PRMPT in
				Y|y ) rm -rf "./zip-temp" ; mkdir -p "zip-temp"
					  hidden=$(7za x -o"./zip-temp" "./bin/template.zip")
					;;
			esac
		else
			mkdir -p "zip-temp"
			hidden=$(7za x -o"./zip-temp" "./bin/template.zip")
		fi
		echo
		echo "Modify contents of the zip-temp directory to match update.zip contents."
		echo "Edit /zip-temp/META-INF/com/google/android/updater-script to your requirements."
		echo ; printf "Enter custom update.zip name (Default: update.zip): "
		read zipName
		echo ; printf "Append zip creation timestamp? (Y/n): "
		read zipTime
		echo ; printf "Press ENTER to begin update.zip creation..."
		read DUMMY
		case $zipName in
			"" | " " | "." | "/" | "\\" | "|" ) zipName="update" ;;
		esac
		case $zipTime in
			"n" | "N" ) zipName="$zipName" ;;
			* ) zipName="${zipName}-$(date +%Y%m%d-%H%M)" ;;
		esac
		echo "Compressing update.zip..."
		7za a -tzip "./projects/$zipName.zip" ./zip-temp/* -mx"$clvl" -r-
		echo "Signing $zipName.zip..."
		java -jar "./bin/signapk.jar" -w "./bin/testkey.x509.pem" "./bin/testkey.pk8" "./projects/$zipName.zip" "./projects/$zipName-signed.zip"
		rm -f "./projects/$zipName.zip"
		clear ; echo ; printf "Done."
		if [[ -f "./projects/$zipName-signed.zip" ]]; then
			printf " Created: /projects/$zipName-signed.zip\n"
		fi
	fi
}

pushzip () {
	if [[ $(adb devices | grep "device" -c) -gt "1" ]] ; then
		cd "./projects"
		echo
		echo "Listing ZIP files:"
		echo "------------------"
		PS3=$(echo ""; echo "Choose ZIP: ")
		fileList=$(find -type f -name "*.zip")
		# Clean up list.
		fileList=${fileList//"./"/}

		if [[ -z $fileList ]] ; then
			clear
			echo "No ZIP files found. Please check the projects directory."
		else
			select zipName in $fileList; do
				if [[ -n "$zipName" ]] ; then
					zipName=${zipName%.*}
					echo "Pushing $zipName.zip to device /sdcard/"
					adb push "./$zipName.zip" "/sdcard/"
					clear ; echo "Done." ; break
				else
			    	echo "Error. Wrong input."
			    fi
			done
		fi
		cd ..
	else
		echo "Error. No device connected."
	fi
}

cls2jar () {
	echo
	# Check if an active APK is set.
	if [[ -n $fileName ]] ; then

		cd bin
		7za e "../place-apk-here-for-modding/$fileName.apk" -ir\!"classes.dex" -o"../projects/" -y
		safeName=${fileName//" "/"-"}
		mv "../projects/classes.dex" "../projects/$safeName.dex"
		cd ..
		cd projects
		../bin/dex2jar/dex2jar "$safeName.dex"
		if [[ $safeName != $fileName ]]; then
			mv -uf "$safeName.dex" "$fileName.dex"
		fi
		mv -uf "$safeName-dex2jar.jar" "$fileName.jar"
		cd ..

		clear ; echo "Created /projects/$fileName.jar"
	else
		actvfile ; retval=$? ; if [[ $retval == 0 ]]; then cls2jar ; fi
	fi
}

viewjar () {
	echo
	# Check if an active APK is set.
	if [[ -n $fileName ]] ; then
		if [[ -f "./projects/$fileName.jar" ]]; then
			# Execute jd-gui as a parallel process
			gnome-terminal -x ./bin/jd-view $fileName

			clear ; echo "Viewing file: $fileName.jar"
		else
			echo "File: /projects/$fileName.jar does not exist. Please extract from APK."
		fi
	else
		actvfile ; retval=$? ; if [[ $retval == 0 ]]; then viewjar ; fi
	fi
}

crtdirs () {
	mkdir -p place-apk-here-for-modding
	mkdir -p apk-rename
	mkdir -p place-apk-here-for-signing
	mkdir -p place-apk-here-to-batch-optimize
	mkdir -p place-ogg-here
	echo
	echo "Done."
}

showpkg () {
	if [[ -n $fileName ]] ; then 
		echo -e "${CYAN}"
		./bin/aapt dump badging "./place-apk-here-for-modding/$fileName.apk"
		echo -e "${NOCOLOR}"
	else
		actvfile ; retval=$? ; if [[ $retval == 0 ]]; then clear ; showpkg ; fi
	fi
}

fixperm () {
	./bin/perm
	clear
	echo "Done. Scroll up to see changes."
}

# 71) stringsXmlMerger
stringsxmlmerger(){

	if [[ -n $fileName ]] ; then 
	clear
	echo -e "${YELLOW}Enter translated: /home/string.xml${NOCOLOR}"
	read ANSWER
	echo -e "${YELLOW}Enter locale prefix : ru,ky${NOCOLOR}"
	read LOCALE
		mkdir "./projects/$fileName.apk/res/values-$LOCALE"
		echo -e "${CYAN}" 
	
		java -jar "./bin/StringsXmlMerger.jar" "./projects/$fileName.apk/res/values/strings.xml" "$ANSWER" "./projects/$fileName.apk/res/values-$LOCALE/strings.xml" 
	 	echo -e " Done! ${NOCOLOR}"
		 plugins
	else
		actvfile ; retval=$? ; if [[ $retval == 0 ]]; then clear ; showpkg ; fi
	fi

}

# Plugins
plugins(){
	echo
	echo -e "${ORANGE}------------------------------------------------------------------------------ ${LIGHTGRAY}"
	echo    "  1    StringsXmlMerger.jar                                                                        "
	echo    "  0  Home                                                                                        "
	echo -e "${ORANGE}------------------------------------------------------------------------------ ${LIGHTGRAY}"
	echo
	printf "%s" "Enter selection: "
	read ANSWER
	# restart
	clear
	case "$ANSWER" in
		1)  stringsxmlmerger ;;
		0) restart;;
		"00"|"exit")   quit ;;
		 *)
		echo "Unknown command: '$ANSWER'"
		;;
	esac
}
# end Plugins



restart () {
	
	echo
	echo -e "${ORANGE}------------------------------------------------------------------------------ ${LIGHTGRAY}"
	echo -e "${ORANGE}|                              Apk Multi-Tools                               |${LIGHTGRAY}"
	echo -e "${ORANGE}------------------------------------------------------------------------------ ${LIGHTGRAY}"
	echo 
	echo -e "${YELLOW}- Simple Tasks (Image editing, etc.)  -----------------------------------------${LIGHTGRAY}"
	echo "  1    Extract APK                       2    Optimize APK Images              "
	echo "  3    Zip APK                                                                 "
	echo "  7    One-step Zip-Sign-Install"
	echo
	echo -e "${YELLOW}- Advanced Tasks (XML, Smali, etc.) -------------------------------------------${LIGHTGRAY}"
	echo -e "   ${CYAN}9    Decompile APK                       10   Compile APK${NOCOLOR} "
	echo    "  11   One-step Compile-Sign-Install															    "
	echo
	echo -e "${YELLOW}- Common Tasks ----------------------------------------------------------------${LIGHTGRAY}"
	echo "  0    ADB Pull                          8    ADB Push                         "
	echo -e "${CYAN}  4    Sign APK${NOCOLOR}                          6    Install APK                      "
	echo "  5    Zipalign APK                                                            "
	echo
	echo -e "${YELLOW}- Batch Operations ------------------------------------------------------------${LIGHTGRAY}"
	echo "  12   Batch Optimize APK                13   Batch Sign APK                   "
	echo "  14   Batch Optimize OGG files"
	echo
	echo -e "${YELLOW}- Distribution & Update.zip Creation ------------------------------------------${LIGHTGRAY}"
	echo "  41   Create Update.zip                 42   Push Update.zip to device        "
	echo
	echo -e "${YELLOW}- Decompile Classes.dex & View Decompiled Code --------------------------------${LIGHTGRAY}"
	echo "  51   Decompile Classes.dex             52   View Decompiled Code             "
	echo
	echo -e "${YELLOW}- ADB Device & APK Management -------------------------------------------------${LIGHTGRAY}"
	echo "  30   Backup Device Installed APKs      31   Batch Rename APK                 "
	echo "  32   Batch Install APK (apk-backup)"
	echo
	echo -e "${YELLOW}-------------------------------------------------------------------------------${NOCOLOR}"
	echo -e "${CYAN}  20   Set Active APK${NOCOLOR}"
	echo "  21   Import framework-res.apk  (Perform apktool.jar if framework-res.apk)"
	echo "  22   Clear Project Files"
	echo "  23   Set Compression Level     (Current compression level: $clvl)"
	echo "  24   Create all missing directories"
	echo "  25   Show APK package information"
	echo "  70   Plugins"
	echo "  99   Fix Tools permissions"
	echo -e "${RED}  00   Quit${NOCOLOR}"
	echo "-------------------------------------------------------------------------------"
	printf " ${CYAN} Active APK File: ${NOCOLOR}"
	if [[ -n $fileName ]] ; then
		printf "${GREEN}$fileName.apk ${NOCOLOR}"
	else
		printf "${RED}NONE${NOCOLOR}"
	fi 
	
	printf "\n"
	
	echo "-------------------------------------------------------------------------------"
	echo
	printf "%s" "Enter selection: "
	read ANSWER
	reset
	case "$ANSWER" in
		 0)       ap ;;
		 1)       ex ;;
		 2)      opt ;;
		 3)      zip ;;
		 4)       si ;;
		 5)     zipa ;;
		 6)      ins ;;
		 7)     alli ;;
		 8)      apu ;;
		 9)       de ;;
		10)       co ;;
		11)      all ;;
		12)     bopt ;;
		13)      asi ;;
		14)      ogg ;;
		20)     selt "s1" ;; # Set via menu
		21)      frm ;;
		22)      clr ;;
		23)   setclv ;;
		24)  crtdirs ;;
		25)  showpkg ;;
		30)  devback ;;
		31)   apren "../apk-rename/" ;;
		32)   devres ;;
		41)    mkzip ;;
		42)  pushzip ;;
		51)  cls2jar ;;
		52)  viewjar ;;
		70)  plugins ;;
		99)  fixperm ;;
		000) menu;;
		"00"|"exit")   quit ;;
		 *)
			echo "Unknown command: '$ANSWER'"
		;;
	esac
}

# Start ----------------------------------------
echo -e "${CYAN}Starting APK Multi-Tools...${NOCOLOR}"
# Terminal Dimensions
printf '\033[8;48;80t'
PATH="$PATH:$PWD/bin"
reset

echo -n "Loading defaults & preferences... "
# Defaults
IFS=$(echo -en "\n\b") # Support for filenames with white spaces.
fileName=""	# Active APK File
confFile=settings.conf 	# Config File

# Config File Check
if [[ ! -f ./$confFile ]]; then
	clvl="3"	# Compression Level - Default value
	echo "compressionLevel=3" >> settings.conf
else
	setprs=$(sed -n "1p" "$confFile")
	clvl=${setprs##*=}
fi
echo "Done."
# clear
export PATH
#echo $PATH
echo -n "Checking required binaries & files... "
# Test for needed programs and warn if missing
ERROR="0"
for PROGRAM in "optipng" "7za" "java" "sudo" "adb" "aapt" "sox"
do
	which "$PROGRAM" > /dev/null
	if [ "x$?" = "x1" ] ; then
		ERROR="1"
		echo ; echo "The program $PROGRAM is missing or is not in your PATH."
		echo "Please install it or fix your PATH variable"
	fi
done
if [ "x$ERROR" = "x1" ] ; then
	exit 1
fi
echo "Done."
# Create place-apk-here-for-modding directory if missing
if [[ ! -d ./place-apk-here-for-modding ]]; then
	mkdir -p ./place-apk-here-for-modding
fi

echo -n "Initializing ADBD... "
# adbd=$(adb start-server)	# Start ADB Daemon
echo "Done."

clear
reset
while [ "1" = "1" ] ;
do
	restart
done

exit 0