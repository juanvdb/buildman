#! /bin/bash

parentDir="/data/dotfiles/"

declare -A dotfilePaths
dotfilePaths=(
[config]="$HOME/.config"
[local]="$HOME/.local"
[homedir]="$HOME"
)

for sourceDir in "${!dotfilePaths[@]}";
do
  searchDir="$parentDir$sourceDir/*"
  for fullFilename in $searchDir; do
    echo "SOURCE FILE: $fullFilename"
    filename=$(basename -- "$fullFilename")
    targetFullFilename="${dotfilePaths[$sourceDir]}/$filename"
    if [[ $sourceDir = "homedir" ]]; then
      targetFullFilename="${dotfilePaths[$sourceDir]}/.$filename"
    fi
    echo "TARGET FILE: $targetFullFilename"
    if [[ -e $targetFullFilename ]]; then
      echo "$targetFullFilename exists, will remove!"
      filetype=$(stat -c%F "$targetFullFilename")
      case "$filetype" in
        "regular file")
          echo "DELETE FILE: rm $targetFullFilename"
          rm "$targetFullFilename"
        ;;
        "directory")
          echo "DELETE DIRECTORY: rmdir -r $targetFullFilename"
          rmdir -r "$targetFullFilename"
        ;;
        "symbolic link")
          echo "DELETE LINK: rm $targetFullFilename"
          rm "$targetFullFilename"
        ;;
        # *) exit 3;;
      esac
    fi
    echo "LINK: ln -s  $fullFilename $targetFullFilename "
    ln -s  $fullFilename $targetFullFilename
    echo " "
  done
done

exit
