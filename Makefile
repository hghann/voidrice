# inspired by this video
# https://www.youtube.com/watch?v=aP8eggU2CaU

BASE = $(PWD)
SCRIPTS = $(HOME)/.scripts
MKDIR = mkdir -p
LN = ln -vsf
LNDIR = ln -vs
SUDO = doas
PKGINSTALL = $(SUDO) xbps-install -S

doas: ## Configure doas
	$(SUDO) $(LN) $(PWD)/etc/doas.conf /etc/doas.conf

sudo: ## stop asking for password when using sudo
	$(SUDO) echo "## Prevents entering password in new windows\nDefaults \!tty_tickets" >> /etc/sudoers

autologin: ## setup auto login
	$(SUDO) $(MKDIR) /etc/systemd/system/getty@tty1.service.d/
	$(SUDO) $(LN) $(PWD)/etc/systemd/system/getty@tty1.service.d/override.conf /etc/systemd/system/getty@tty1.service.d/override.conf

suspend:
	$(SUDO) $(LN) $(PWD)/etc/systemd/logind.conf /etc/systemd/logind.conf

nobeep: # remove system beeping
	rmmod pcspkr
	echo "blacklist pcspkr" > /etc/modprobe.d/nobeep.conf
	xset -b

defaultshell: ## Change default shell to zsh
	chsh -s /bin/zsh $(USER)

firmware: ## Install required firmware for 2013 MacBook Air
	# REQUIRES NON-FREE REPOS
	$(PKGINSTALL) void-repo-nonfree intel-ucode

tlp: ## Setting for power saving and preventing battery deterioration
	$(SUDO) $(PKGINSTALL) tlp powertop
	$(SUDO) $(LN) $(PWD)/etc/default/tlp /etc/default/tlp
	$(SUDO) $(LN) ln -s /etc/sv/tlp /var/service/
	$(SUDO) $(LN) ln -s /etc/sv/tlp-spleep /var/service/
	$(SUDO) sv up tlp
	$(SUDO) sv up tlp-spleep

powersave: ## Powersave settings
	$(SUDO) $(MKDIR) /etc/udev/rules.d
	$(SUDO) $(LN) $(PWD)/etc/udev/rules.d/81-powersave.rules /etc/udev/rules.d/81-powersave.rules
	$(SUDO) $(LN) $(PWD)/etc/udev/rules.d/powersave.rules /etc/udev/rules.d/powersave.rules
	$(SUDO) $(MKDIR) /etc/modprobe.d
	$(SUDO) $(LN) $(PWD)/etc/modprobe.d/iwlwifi.conf /etc/modprobe.d/iwlwifi.conf

networkmanager: ## Fix wifi on broadband BCM4306 chips
	$(SUDO) usermod -aG network $(USER)
	$(PKGINSTALL) NetworkManager network-manager-applet
	$(SUDO) rm /var/service/dhcpcd
	$(SUDO) rm /var/service/wpa_supplicant
	$(SUDO) rm /var/service/wicd
	$(SUDO) $(LN) ln -s /etc/sv/NetworkManager /var/service/
	$(SUDO) sv up NetworkManager

bluetooth: ## Before using the Bluetooth device, make sure that it is not blocked by rfkill
	$(PKGINSTALL) bluez bluez-alsa blueman
	$(SUDO) $(LN) ln -s /etc/sv/bluetoothd /var/service/
	$(SUDO) sv up bluetoothd

flatpak: ## Install Flatpak and GNOME Software Center (flatpak only)
	$(PKGINSTALL) flatpak gnome-software
	flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

touchegg: flatpak ## Install Touchegg and Touche (application to configure Touchegg)
	$(PKGINSTALL) touchegg
	flatpak install flathub com.github.joseexposito.touche
	$(SUDO) ln -s /etc/sv/touchegg /var/service

apparmor: ## Get apparmor up and running on void
	$(PKGINSTALL) apparmor
	$(SUDO) $(LN) $(PWD)/etc/default/grub /etc/default/grub
	$(SUDO) update-grub

firejail: ## Install and configure firejail
	$(PKGINSTALL) firejail
	\sudo firecfg

runit: networkmanager # Setup runit services
	$(SUDO) $(MKDIR) /etc/systemd/system

syncthing: runit
	$(SUDO) $(MKDIR) /etc/NetworkManager/dispatcher.d
	$(SUDO) $(LN) $(PWD)/etc/NetworkManager/dispatcher.d/10-syncthingstart.sh /etc/NetworkManager/dispatcher.d/10-syncthingstart.sh

printing: ## Install CUPS and printer drivers and run service
	$(PKGINSTALL) cups cups-filters epson-inkjet-printer-escpr imagescan \
		lpadmin system-config-printer 
	$(SUDO) $(LN) ln -s /etc/sv/cupsd /var/service/
	$(SUDO) sv up cupsd

pass:
	git clone https://github.com/hghann/pass $(HOME)/.password-store

capsmod: ## Rebind Caps Lock to ctrl
	setxkbmap -option "caps:ctrl"
	$(SUDO) $(MKDIR) /etc/X11/xorg.conf.d/00-keyboard.conf
	$(SUDO) $(LN) $(PWD)/etc/X11/xorg.conf.d/00-keyboard.conf /etc/X11/xorg.conf.d/00-keyboard.conf

vim: ## Init vim
	# requires vim
	git clone https://github.com/hghann/dotvim $(HOME)/.vim
	cd $(HOME)/.vim && make -f $(HOME)/.vim/Makefile

vimupdate: ## Updates vim config
	cd $(HOME)/.vim;\
		git pull

installsuckless: ## Install and setup suckless programs
	$(MKDIR) $(HOME)/.suckless
	git clone https://github.com/hghann/dwm $(HOME)/.suckless
	cd $(HOME)/.suckless/dwm && make -f $(HOME)/.suckless/dwm/Makefile
	git clone https://github.com/hghann/st $(HOME)/.suckless
	cd $(HOME)/.suckless/st && make -f $(HOME)/.suckless/st/Makefile
	git clone https://github.com/hghann/dmenu $(HOME)/.suckless
	cd $(HOME)/.suckless/dmenu && make -f $(HOME)/.suckless/dmenu/Makefile

sucklessupdate: ## Updates suckless programs
	cd $(HOME)/.suckless/dwm;\
		git pull;\
		make -f $(HOME)/.suckless/dwm/Makefile
	cd $(HOME)/.suckless/st;\
		git pull;\
		make -f $(HOME)/.suckless/st/Makefile
	cd $(HOME)/.suckless/dmenu;\
		git pull;\
		make -f $(HOME)/.suckless/dmenu/Makefile

init: ## Inital deploy dotfiles
	$(LN) $(PWD)/.bash_profile $(HOME)/.bash_profile
	$(LN) $(PWD)/.bashrc $(HOME)/.bashrc
	$(LN) $(PWD)/.profile $(HOME)/.profile
	rm -rf $(HOME)/.config/zsh
	$(LNDIR) $(PWD)/.config/zsh $(HOME)/.config/zsh
	rm -rf $(HOME)/.config/shell
	$(LNDIR) $(PWD)/.config/shell $(HOME)/.config/shell
	rm -rf $(HOME)/.config/xfce4
	$(LNDIR) $(PWD)/.config/xfce4 $(HOME)/.config/xfce4
	rm -rf $(HOME)/.local/share/xfce4
	$(LNDIR) $(PWD)/.local/share/xfce4 $(HOME)/.local/share/xfce4
	rm -rf $(HOME)/.config/firejail
	$(LNDIR) $(PWD)/.config/firejail $(HOME)/.config/firejail
	$(LN) $(PWD)/.config/user-dirs.dirs $(HOME)/.config/user-dirs.dirs
	$(LN) $(PWD)/.config/user-dirs.locale $(HOME)/.config/user-dirs.locale
	rm -rf $(HOME)/.config/dunst
	$(LNDIR) $(PWD)/.config/dunst $(HOME)/.config/dunst
	#rm -rf $(HOME)/.config/picom
	#$(LNDIR) $(PWD)/.config/picom $(HOME)/.config/picom
	rm -rf $(HOME)/.config/alacritty
	$(LNDIR) $(PWD)/.config/alacritty $(HOME)/.config/alacritty
	#rm -rf $(HOME)/.config/nvim
	#$(LNDIR) $(PWD)/.config/nvim $(HOME)/.config/nvim
	#rm -rf $(HOME)/.config/fontconfig
	#$(LNDIR) $(PWD)/.config/fontconfig $(HOME)/.config/fontconfig
	rm -rf $(HOME)/.config/lf
	$(LNDIR) $(PWD)/.config/lf $(HOME)/.config/lf
	rm -rf $(HOME)/.config/mpd
	$(LNDIR) $(PWD)/.config/mpd $(HOME)/.config/mpd
	rm -rf $(HOME)/.config/mpv
	$(LNDIR) $(PWD)/.config/mpv $(HOME)/.config/mpv
	rm -rf $(HOME)/.config/ncmpcpp
	$(LNDIR) $(PWD)/.config/ncmpcpp $(HOME)/.config/ncmpcpp
	rm -rf $(HOME)/.config/newsboat
	$(LNDIR) $(PWD)/.config/newsboat $(HOME)/.config/newsboat
	#rm -rf $(HOME)/.config/openbox
	#$(LNDIR) $(PWD)/.config/openbox $(HOME)/.config/openbox
	rm -rf $(HOME)/.config/btop
	$(LNDIR) $(PWD)/.config/btop $(HOME)/.config/btop
	rm -rf $(HOME)/.config/startpage
	$(LNDIR) $(PWD)/.config/startpage $(HOME)/.config/startpage
	rm -rf $(HOME)/.config/sxiv
	$(LNDIR) $(PWD)/.config/sxiv $(HOME)/.config/sxiv
	#rm -rf $(HOME)/.config/tint2
	#$(LNDIR) $(PWD)/.config/tint2 $(HOME)/.config/tint2
	rm -rf $(HOME)/.config/wget
	$(LNDIR) $(PWD)/.config/wget $(HOME)/.config/wget
	#rm -rf $(HOME)/.config/X11
	#$(LNDIR) $(PWD)/.config/X11 $(HOME)/.config/X11
	#rm -rf $(HOME)/.config/calcurse
	#$(LNDIR) $(PWD)/.config/calcurse $(HOME)/.config/calcurse
	rm -rf $(HOME)/.config/flameshot
	$(LNDIR) $(PWD)/.config/flameshot $(HOME)/.config/flameshot
	rm -rf $(HOME)/.config/gtk-2.0
	$(LNDIR) $(PWD)/.config/gtk-2.0 $(HOME)/.config/gtk-2.0
	rm -rf $(HOME)/.config/gtk-3.0
	$(LNDIR) $(PWD)/.config/gtk-3.0 $(HOME)/.config/gtk-3.0
	rm -rf $(HOME)/.config/neofetch
	$(LNDIR) $(PWD)/.config/neofetch $(HOME)/.config/neofetch
	rm -rf $(HOME)/.config/nitrogen
	$(LNDIR) $(PWD)/.config/nitrogen $(HOME)/.config/nitrogen
	rm -rf $(HOME)/.config/pcmanfm
	$(LNDIR) $(PWD)/.config/pcmanfm $(HOME)/.config/pcmanfm
	rm -rf $(HOME)/.config/qt5ct
	$(LNDIR) $(PWD)/.config/qt5ct $(HOME)/.config/qt5ct
	rm -rf $(HOME)/.config/xarchiver
	$(LNDIR) $(PWD)/.config/xarchiver $(HOME)/.config/xarchiver
	rm -rf $(HOME)/.config/zathura
	$(LNDIR) $(PWD)/.config/zathura $(HOME)/.config/zathura
	$(LN) $(PWD)/.config/mimeapps.list $(HOME)/.config/mimeapps.list
	rm -rf $(HOME)/.local/bin
	$(LNDIR) $(PWD)/.local/bin $(HOME)/.local/bin
	rm -rf $(HOME)/.local/share/applications
	$(LNDIR) $(PWD)/.local/share/applications $(HOME)/.local/share/applications
	rm -rf $(HOME)/.local/share/getkeys
	$(LNDIR) $(PWD)/.local/share/getkeys $(HOME)/.local/share/getkeys
	$(LN) $(PWD)/.local/share/emoji $(HOME)/.local/share/emoji

X: ## Setup files for xorg
	$(MKDIR) $(HOME)/.config/X11
	$(LN) $(PWD)/.config/X11/xinitrc $(HOME)/.config/X11/xinitrc
	$(LN) $(PWD)/.config/X11/xprofile $(HOME)/.config/X11/xprofile
	$(LN) $(PWD)/.config/X11/xresources $(HOME)/.config/X11/xresources
	$(LN) $(PWD)/.config/X11/xserverrc $(HOME)/.config/X11/xserverrc
	$(MKDIR) $(HOME)/.config/picom
	$(LN) $(PWD)/.config/picom/picom.conf $(HOME)/.config/picom/picom.conf
	$(MKDIR) $(HOME)/.config/fontconfig
	$(LN) $(PWD)/.config/fontconfig/fonts.conf $(HOME)/.config/fontconfig/fonts.conf
	$(MKDIR) $(HOME)/.config/dunst
	$(LN) $(PWD)/.config/dunst/critical.png $(HOME)/.config/dunst/critical.png
	$(LN) $(PWD)/.config/dunst/dunstrc $(HOME)/.config/dunst/dunstrc
	$(LN) $(PWD)/.config/dunst/normal.png $(HOME)/.config/dunst/normal.png
	$(MKDIR) $(HOME)/.config/zathura
	$(LN) $(PWD)/.config/zathura/zathurarc $(HOME)/.config/zathura/zathurarc
	$(MKDIR) $(HOME)/.config/qutebrowser/bookmarks
	$(LN) $(PWD)/.config/bookmarks $(HOME)/.config/qutebrowser/bookmarks/urls
	$(MKDIR) $(HOME)/.config/sxiv/exec
	$(LN) $(PWD)/.config/sxiv/exec/key-handler $(HOME)/.config/sxiv/exec/key-handler
	$(LN) $(PWD)/.config/mimeapps.list $(HOME)/.config/mimeapps.list
	$(LN) $(PWD)/.config/user-dirs.dirs $(HOME)/.config/user-dirs.dirs

alacritty: ## Setup files for alacritty
	$(MKDIR) $(HOME)/.config/alacritty
	$(LN) $(PWD)/.config/alacritty/alacritty.yml $(HOME)/.config/alacritty/alacritty.yml

lf: ## Setup files for lf
	$(MKDIR) $(HOME)/.config/lf
	$(LN) $(PWD)/.config/lf/cleaner $(HOME)/.config/lf/cleaner
	$(LN) $(PWD)/.config/lf/lfrc $(HOME)/.config/lf/lfrc
	$(LN) $(PWD)/.config/lf/preview $(HOME)/.config/lf/preview

mpv: ## Setup files for mpv
	$(MKDIR) $(HOME)/.config/mpv
	$(LN) $(PWD)/.config/mpv/input.conf $(HOME)/.config/mpv/input.conf
	$(LN) $(PWD)/.config/mpv/mpv.conf $(HOME)/.config/mpv/mpv.conf

mpd: ## Setup files for mpd
	$(MKDIR) $(HOME)/.config/mpd/mpd.conf
	$(LN) $(PWD)/.config/mpd/mpd.conf $(HOME)/.config/mpd/mpd.conf

ncmpcpp: ## Setup files for ncmpcpp
	$(MKDIR) $(HOME)/.config/ncmpcpp
	$(LN) $(PWD)/.config/ncmpcpp/bindings $(HOME)/.config/ncmpcpp/bindings
	$(LN) $(PWD)/.config/ncmpcpp/config $(HOME)/.config/ncmpcpp/config

startpage: ## Setup files for startpage
	$(MKDIR) $(HOME)/.local/share/startpage
	rm -rf $(HOME)/.local/share/startpage/SauceCodePro.ttf
	cp $(PWD)/.config/startpage/SauceCodePro.ttf $(HOME)/.local/share/startpage/SauceCodePro.ttf
	rm -rf $(HOME)/.local/share/startpage/startpage.css
	cp $(PWD)/.config/startpage/startpage.css $(HOME)/.local/share/startpage/startpage.css
	rm -rf $(HOME)/.local/share/startpage/startpage.html
	cp $(PWD)/.config/startpage/startpage.html $(HOME)/.local/share/startpage/startpage.html

openbox: ## Setup files for openbox
	$(MKDIR) $(HOME)/.config/openbox
	$(LN) $(PWD)/.config/openbox/autostart $(HOME)/.config/openbox/autostart
	$(LN) $(PWD)/.config/openbox/menu.xml $(HOME)/.config/openbox/menu.xml
	$(LN) $(PWD)/.config/openbox/rc.xml $(HOME)/.config/openbox/rc.xml

PREFIX = /usr/local
MANPREFIX = $(PREFIX)/share/man
TMPDIR = $(PWD)/tmp

walk: ## installs plan9 find SUDO NEEDED
	$(MKDIR) $(TMPDIR)
	git clone https://github.com/google/walk.git $(TMPDIR)/walk
	cd $(TMPDIR)/walk && make
	$(MKDIR) $(DESTDIR)$(PREFIX)/bin
	# installing walk
	cp -f     $(TMPDIR)/walk/walk   $(DESTDIR)$PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/walk
	cp -f     $(TMPDIR)/walk/walk.1 $(DESTDIR)$(MANPREFIX)/man1/walk.1
	chmod 644 $(DESTDIR)$(MANPREFIX)/man1/walk.1
	# installing sor
	cp -f     $(TMPDIR)/walk/sor   $(DESTDIR)$PREFIX)/bin
	chmod 755 $(DESTDIR)$(PREFIX)/bin/sor
	cp -f     $(TMPDIR)/walk/sor.1 $(DESTDIR)$(MANPREFIX)/man1/sor.1
	chmod 644 $(DESTDIR)$(MANPREFIX)/man1/sor.1

jot: ## install jot a markdown style  preprocessor for note-taking in groff
	$(MKDIR) $(TMPDIR)
	git clone https://gitlab.com/rvs314/jot.git $(TMPDIR)/$<
	rm -rf $(TMPDIR)

# grap can be found here: https://www.lunabase.org/-faber/Vault/software/grap/

base: ## Install base and base-devel package plus doas because sudo is bloated
	$(PKGINSTALL) filesystem gcc-libs glibc bash coreutils file findutils gawk \
		grep procps-ng sed tar gettext pciutils psmisc shadow util-linux bzip2 gzip \
		xz licenses pacman systemd systemd-sysvcompat iputils iproute2 autoconf sudo \
		automake binutils bison fakeroot flex gcc groff libtool m4 make patch pkgconf \
		texinfo which opendoas

docker: ## Docker initial setup
	$(SUDO) pacman -S docker
	$(SUDO) usermod -aG docker $(USER)
	$(MKDIR) $(HOME)/.docker
	$(LN) $(PWD)/.docker/config.json $(HOME)/.docker/config.json
	$(SUDO) systemctl enable docker.service
	$(SUDO) systemctl start docker.service

install: ## Install arch linux packages using pacman
	$(PKGINSTALL) --needed - < $(PWD)/pkg/pacmanlist
	#$(PKG) pkgfile --update
	$(SUDO) pacman -Fy

desktop: ## Update desktop entries
	$(SUDO) $(LN) $(PWD)/usr/share/applications/vim.desktop /usr/share/applications/vim.desktop

backup: ## Backup arch linux packages
	$(MKDIR) $(PWD)/pkg
	xbps-query -m | awk "{print $$2}" > ${PWD}/pkg/xbpslist

update: ## Update arch linux packages and save packages cache 3 generations
	yay -Syu

pip: ## Install python packages
	pip install --user --upgrade pip
	pip install --user 'python-language-server[all]'

pipbackup: ## Backup python packages
	$(MKDIR) $(PWD)/pkg
	pip freeze > $(PWD)/pkg/piplist.txt

pipupdate: ## Update python packages
	pip list --user | cut -d" " -f 1 | tail -n +3 | xargs pip install -U --user

testpath: ## ECHO PATH
	PATH=$$PATH
	@echo $$PATH
	echo $(PWD)
	PWD=$(PWD)
	echo $(HOME)
	HOME=$(HOME)

voidinstall: base install tlp networkmanager bluetooth doas sudo suspend X init vim installsuckless

allinstall: install init tlp

allupdate: update vimupdate scriptsupdate sucklessupdate

allbackup: backup

.DEFAULT_GOAL := help
.PHONY: allinstall allupdate allbackup

help: ## Prints out Make help
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) \
	| sort \
	| awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
