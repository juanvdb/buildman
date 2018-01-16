#! /bin/bash
# This file moves selected files to newly created .dotfile folder and creates symbolic synblinks.

# STEPS:.
# 1. create and array of with .dotfiles elements.
# 2. create a new directory .dotfiles if this directory does not exits.
# 3. move selected .dotfiles from step 1 into directory created in step 2.
# 4. create symbolic links for all .dotfiles from step 1.
# 5. initialize a git repo.

# 1. declare an array with .dotfiles element for versioning:.
declare -a Dotfiles=('bash_profile' 'bashrc' 'bash_aliases' 'gitconfig' 'gitignore' 'vimrc' 'vimrc.after' 'kde' 'config' 'gconf' 'pki' 'ssh')

# inform the user and print the whole array on the screen:
echo 'going to move the following selected .dotfiles:'
echo "${Dotfiles[@]}"

# 2. create a variable for new directory for storing dotfiles..
dir=/data/dotfiles/sdb3
homedir="/media/juan/Kubuntu2-1710/home/juan"
cd "$homedir" && mkdir -p $dir
echo 'directory created'

# move selected dotfiles to new directory .dotfiles

for dotfile in "${Dotfiles[@]}";do
  echo "moving $homedir/.$dotfile into directory $dir"
  mv "$homedir"/."$dotfile" "$dir"/
  echo "creating symblik for $dotfile"
  ln -s "$dir/$dotfile" "$homedir"/."$dotfile"
done
cd "$dir"
git init
cd ~
echo 'done'


  266  cd /data/dotfiles/sdb3/
  267  ln -s .bash* /media/juan/Kubuntu2-1710/home/juan
  268  ll
  269  touch .vimrc
  270  ll
  271  rm .vimrc
  272  touch .vimrc
  273  ll
  274  rm .vimrc.after 
  275  touch .vimrc.after 
  276  rm .gitignore 
  277  touch .gitignore 
  278  ll
  279  ln -s .bash_profile /media/juan/Kubuntu2-1710/home/juan/
  280  ln --help
  281  ln -sf .bash_profile /media/juan/Kubuntu2-1710/home/juan/
  282  ln -sf .bash_profile /media/juan/Kubuntu2-1710/home/juan/.bash_profile
  283  cd /media/juan/Kubuntu2-1710/home/juan/
  284  ln -sf /data/dotfiles/sdb3/.bash_aliases ./.bash_aliases 
  285  ln -sf /data/dotfiles/sdb3/.bash_history ./.bash_history 
  286  ln -sf /data/dotfiles/sdb3/.bash_profile ./.bash_profile 
  287  ln -sf /data/dotfiles/sdb3/.bashrc ./.bashrc 
  288  ln -sf /data/dotfiles/sdb3/.config ./.config 
  289  ln -sf /data/dotfiles/sdb3/.gconf ./.gconf 
  290  ln -sf /data/dotfiles/sdb3/.gitconfig ./.gitconfig 
  291  ln -sf /data/dotfiles/sdb3/.gitignore ./.gitignore 
  292  ln -sf /data/dotfiles/sdb3/.kde ./.kde 
  293  ln -sf /data/dotfiles/sdb3/.pki ./.pki 
  294  ln -sf /data/dotfiles/sdb3/.ssh ./.ssh
  295  ln -sf /data/dotfiles/sdb3/.vimrc ./.vimrc
  296  ln -sf /data/dotfiles/sdb3/.vimrc.after ./.vimrc.after 
  297  history
  298  ln -sf /data/dotfiles/sdb3/.dropbox* ./.dropbox* 
  299  ln -sf /data/dotfiles/sdb3/.dropbox ./.dropbox
  300  ln -sf /data/dotfiles/sdb3/.dropbox-dist/ ./.dropbox-dist
  301  ln -sf /data/dotfiles/sdb3/.eclipse ./.eclipse
  302  ln -sf /data/dotfiles/sdb3/.dropbox-dist ./.dropbox-dist
  303  ln -sf /data/dotfiles/sdb3/eclipse ./eclipse
  304  ln -sf /data/dotfiles/sdb3/.gem ./.gem
  305  ln -sf /data/dotfiles/sdb3/.gitkraken/ ./gitkraken
  306  ln -sf /data/dotfiles/sdb3/.gitkraken ./.gitkraken
  307  ln -sf /data/dotfiles/sdb3/.lastpass ./lastpass
  308  cp -rv /media/juan/Kubuntu1-1610/home/juan/.lastpass/ /data/dotfiles/sdb3/.lastpass/
  309  ln -sf /data/dotfiles/sdb3/.lastpass ./lastpass
  310  ln -sf /data/dotfiles/sdb3/.lastpass ./.lastpass
  311  rm ./lastpass
  312  ln -sf /data/dotfiles/sdb3/.m2 ./.m2
  313  ln -sf /data/dotfiles/sdb3/.oc ./.oc
  314  ln -sf /data/PDF ./PDF
  315  cd ../../../Kubuntu1-1610/home/juan/
  316  ln -sf /data/PDF ./PDF
  317  ll
  318  cd ../../../Kubuntu2-1710/home/juan/
  319  ln -sf /data/dotfiles/sdb3/.remmina ./.remmina
  320  ll
  321  ln -sf /data/dotfiles/sdb3/snap ./snap
  322  ln -sf /data/dotfiles/sdb3/.vim ./vim
  323  ln -sf /data/dotfiles/sdb3/.vmware ./vmware
  324  ln -sf /data/dotfiles/sdb3/.workrave ./.workrave
  325  ln -sf /data/dev/workspace ./workspace
  326  ll
  327  ln -sf /data/bin ./bin
  328  ll
  329  ln -sf /data/dotfiles/sdb3/.face ./.face
  ln -s ownCloud/dev/git ~/git

