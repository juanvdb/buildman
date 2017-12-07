#! /bin/bash
# Link dotfiles that are in /data/.dotfiles to home

ln -sf /data/.dotfiles/.config/ ~/
ln -sf /data/.dotfiles/.bash* ~/
ln -sf /data/.dotfiles/.gconf ~/
ln -sf /data/.dotfiles/.kde ~/
ln -sf /data/.dotfiles/.local ~/
ln -sf /data/.dotfiles/.profile ~/
ln -sf /data/.dotfiles/.ssh ~/
sudo chown $USER:$USER .viminfo
ln -sf /data/.dotfiles/.viminfo ~/
ln -sf /data/.dotfiles/.wget-hsts ~/
ln -sf /data/bin ~/
