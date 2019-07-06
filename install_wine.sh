#!/bin/bash

function include_dependencies {
    local my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    source "${my_dir}/install_lib_bash.sh"
    source "${my_dir}/lib_bash/lib_color.sh"
    source "${my_dir}/lib_bash/lib_retry.sh"
    source "${my_dir}/lib_bash/lib_helpers.sh"
    source "${my_dir}/lib_wine.sh"
}

include_dependencies  # me need to do that via a function to have local scope of my_dir
linux_codename=$(get_linux_codename)
banner "Install WINE on ${linux_codename}"
clr_green "add 386 Architecture"
retry sudo dpkg --add-architecture i386
clr_green "add Wine Keys"
retry wget https://dl.winehq.org/wine-builds/winehq.key
sudo apt-key add winehq.key
sudo apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ ${linux_codename} main"
clr_green "Wine Packages Update"
retry sudo apt-get update
clr_green "Wine Packages Install"
retry sudo apt-get install --install-recommends winehq-${wine_release}
retry sudo apt-get install -y cabextract
retry sudo apt-get install -y libxml2
retry sudo apt-get install -y libpng-dev
wine_version_number=$(get_wine_version_number)
clr_green "Wine Version ${wine_version_number} installed on ${linux_codename}"

clr_green "Install latest Winetricks"
sudo rm -f /usr/bin/winetricks
retry sudo wget --directory-prefix=/usr/bin/ https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
sudo chmod +x /usr/bin/winetricks
retry sudo winetricks -q --self-update
clr_green "Install latest Winetricks - done"

banner "FINISHED installing WINE and WINETRICKS on linux ${linux_codename}${IFS}Wine Release: ${wine_release}${IFS}Wine Version: ${wine_version_number}"
