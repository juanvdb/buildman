#! /bin/bash

# declare -A linkpath=(
# [config/doublecmd]="$HOME/.config/doublecmd"
# [config/latte]="$HOME/.config/latte"
# [config/lattedockrc]="$HOME/.config/lattedockrc"
# [remmina]="$HOME/.remmina"
# )

parentDir="/data/dotfiles/"

declare -A dotfilePaths
dotfilePaths=(
#[config]="$HOME/.config"
[local]="$HOME/.local"
[homedir]="$HOME"
)

# for sourcePath in "${!linkpath[@]}"; do
#     echo "$sourcePath => ${linkpath[$sourcePath]}"
#     if [ -e ${linkpath[$sourcePath]} ]; then
#         echo "Path ${linkpath[$sourcePath]} exists!"
#     fi
# done

for sourceDir in "${!dotfilePaths[@]}";
do
  echo "SOURCEDIR=$sourceDir"
  echo "PARENTDIR+SOURCEDIR=$parentDir$sourceDir/*"
  searchDir="$parentDir$sourceDir/*"
  for fullFilename in $searchDir; do
    echo "FOR directory loop"
    echo "SOURCE FILE: $fullFilename"
    echo "TARGET FILE: ${dotfilePaths[$sourceDir]}/"
    filename=$(basename -- "$fullFilename")
    echo "FILENAME: $filename"
    targetFullFilename="${dotfilePaths[$sourceDir]}/$filename"
    if [[ $sourceDir = "homedir" ]]; then
      targetFullFilename="${dotfilePaths[$sourceDir]}/.$filename"
    fi
    echo "TARGET FILE: $targetFullFilename"
    if [[ -e $targetFullFilename ]]; then
      echo "$targetFullFilename exists, will remove!"
      filetype=$(stat -c%F "$targetFullFilename")
      echo "FILETYPE: $filetype"
      case "$filetype" in
        "regular file")
          echo "DELETE FILE: rm $targetFullFilename"
        ;;
        "directory")
          echo "DELETE DIRECTORY: rmdir -r $targetFullFilename"
        ;;
        "symbolic link")
          echo "DELETE LINK: rm $targetFullFilename"
        ;;
        # *) exit 3;;
      esac
      # if [[ -L $targetFullFilename ]]; then
      #   echo "DELETE LINK: rm $targetFullFilename"
      # fi
      # if [[ -f $targetFullFilename  ]]; then
      #   echo "DELETE FILE: rm $targetFullFilename"
      # fi
      # if [[ -d $targetFullFilename  ]]; then
      #   echo "DELETE DIRECTORY: rmdir -r $targetFullFilename"
      # fi
    fi
    echo "LINK: ln -s  $fullFilename $targetFullFilename "
    echo " "
  done
done

# for file in "/data/dotfiles/config/*"; do
#  echo $file
# done
