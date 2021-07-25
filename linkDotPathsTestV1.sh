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
[config]="$HOME/.config"
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
  for file in "$parentDir$sourceDir/*"
  do
    echo "SOURCE FILE: $file"
    echo "TARGET FILE: ${dotfilePaths[$sourceDir]}/$file"
    if [[ -e ${dotfilePaths[$sourceDir]}/$file ]]; then
      echo "${dotfilePaths[$sourceDir]}/$file file exists, will remove!"
      if [[ -f ${dotfilePaths[$sourceDir]}/$file ]]; then
        echo "DELETE FILE ${dotfilePaths[$sourceDir]}/$file"
      fi
      if [[ -L ${dotfilePaths[$sourceDir]}/$file ]]; then
        echo "DELETE LINK ${dotfilePaths[$sourceDir]}/$file"
      fi
      if [[ -d ${dotfilePaths[$sourceDir]}/$file ]]; then
        echo "DELETE DIRECTORY ${dotfilePaths[$sourceDir]}/$file"
      fi
    fi
    echo "LINK: ln -s  $parentDir$sourceDir/$file ${dotfilePaths[$sourceDir]}/$file"
    echo " "
  done
done

for file in "/data/dotfiles/config/*"; do
 echo $file
done
