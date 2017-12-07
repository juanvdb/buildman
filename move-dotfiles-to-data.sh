#! /bin/bash
# Move dotfiles to /data/.dotfiles and link back

mkdir -p /data/.dotfiles
cd /data/.dotfiles/
git init
mv ~/.config/ /data/.dotfiles/
ln -s /data/.dotfiles/.config/ .config
mv ~/.bash* /data/.dotfiles/
ln -s /data/.dotfiles/.bash* ~/
mv ~/.gconf/ /data/.dotfiles/
ln -s /data/.dotfiles/.gconf ~/
mv ~/.kde/ /data/.dotfiles/
ln -s /data/.dotfiles/.kde ~/
mv ~/.local/ /data/.dotfiles/
ln -s /data/.dotfiles/.local ~/
mv ~/.profile /data/.dotfiles/
ln -s /data/.dotfiles/.profile ~/
mv ~/.ssh/ /data/.dotfiles/
ln -s /data/.dotfiles/.ssh ~/
sudo chown $USER:$USER .viminfo
mv ~/.viminfo /data/.dotfiles/
ln -s /data/.dotfiles/.viminfo ~/
mv ~/.wget-hsts /data/.dotfiles/
ln -s /data/.dotfiles/.wget-hsts ~/
mv ~/bin/ /data/
ln -s /data/bin ~/
