#!/usr/bin/env bash

# Install some stuff before others!
important_casks=(
  #google-chrome
  istat-menus
  visual-studio-code
)

brews=(  
  awscli
  bat
  ffmpeg
  git
  htop
  httpie
  iftop
  "imagemagick --with-webp"
  m-cli
  mas
  mediainfo
  ncdu
  neofetch
  nmap  
  node
  python3
  ruby
  streamlink
  tree
  trash
  "vim --with-override-system-vi"
  "wget --with-iri"
  yarn
  youtube-dl
)

casks=(
  aerial
  docker
  firefox
  geekbench
  github
  handbrake
  iina
  qlcolorcode
  qlmarkdown
  qlstephen
  quicklook-json
  quicklook-csv
  rectangle
  transmission
)

pips=(
  pip
  instaloader
)

npms=(
  gatsby-cli
)

git_email='joseph@anguiano.me'
git_configs=(
  "branch.autoSetupRebase always"
  "color.ui auto"
  "core.autocrlf input"
  "credential.helper osxkeychain"
  "merge.ff false"
  "pull.rebase true"
  "push.default simple"
  "rebase.autostash true"
  "rerere.autoUpdate true"
  "remote.origin.prune true"
  "rerere.enabled true"
  "user.name josephanguiano"
  "user.email ${git_email}"
)

vscode=(
  ms-azuretools.vscode-docker
  esbenp.prettier-vscode
)

fonts=(
  font-hack
)

######################################## End of app list ########################################
set +e
set -x

function prompt {
  if [[ -z "${CI}" ]]; then
    read -p "Hit Enter to $1 ..."
  fi
}

function install {
  cmd=$1
  shift
  for pkg in "$@";
  do
    exec="$cmd $pkg"
    #prompt "Execute: $exec"
    if ${exec} ; then
      echo "Installed $pkg"
    else
      echo "Failed to execute: $exec"
      if [[ ! -z "${CI}" ]]; then
        exit 1
      fi
    fi
  done
}

function brew_install_or_upgrade {
  if brew ls --versions "$1" >/dev/null; then
    if (brew outdated | grep "$1" > /dev/null); then 
      echo "Upgrading already installed package $1 ..."
      brew upgrade "$1"
    else 
      echo "Latest $1 is already installed"
    fi
  else
    brew install "$1"
  fi
}

if [[ -z "${CI}" ]]; then
  sudo -v # Ask for the administrator password upfront
  # Keep-alive: update existing `sudo` time stamp until script has finished
  while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &
fi

if test ! "$(command -v brew)"; then
  prompt "Install Homebrew"
  ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
  if [[ -z "${CI}" ]]; then
    prompt "Update Homebrew"
    brew update
    brew upgrade
    brew doctor
  fi
fi
export HOMEBREW_NO_AUTO_UPDATE=1

echo "Install important software ..."
brew tap homebrew/cask-versions
install 'brew cask install' "${important_casks[@]}"

prompt "Install packages"
install 'brew_install_or_upgrade' "${brews[@]}"
brew link --overwrite ruby

prompt "Set git defaults"
for config in "${git_configs[@]}"
do
  git config --global ${config}
done

prompt "Install software"
install 'brew cask install' "${casks[@]}"

prompt "Install secondary packages"
install 'pip3 install --upgrade' "${pips[@]}"
install 'npm install --global' "${npms[@]}"
install 'code --install-extension' "${vscode[@]}"
brew tap caskroom/fonts
install 'brew cask install' "${fonts[@]}"

prompt "Update packages"
pip3 install --upgrade pip setuptools wheel
if [[ -z "${CI}" ]]; then
  m update install all
fi

if [[ -z "${CI}" ]]; then
  prompt "Install software from App Store"
  mas list
fi

prompt "Cleanup"
brew cleanup

echo "Done!"
