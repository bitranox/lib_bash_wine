#!/bin/bash

sudo_askpass="$(command -v ssh-askpass)"
export SUDO_ASKPASS="${sudo_askpass}"
export NO_AT_BRIDGE=1  # get rid of (ssh-askpass:25930): dbind-WARNING **: 18:46:12.019: Couldn't register with accessibility bus: Did not receive a reply.

export bitranox_debug_global="${bitranox_debug_global}"  # set to True for global Debug
export debug_lib_bash_wine="${debug_lib_bash_wine}"  # set to True for Debug in lib_bash_wine


# call the update script if nout sourced
if [[ "${0}" == "${BASH_SOURCE[0]}" ]] && [[ -d "${BASH_SOURCE%/*}" ]]; then "${BASH_SOURCE%/*}"/install_or_update.sh else "${PWD}"/install_or_update.sh ; fi


function include_dependencies {
    local my_dir
    # shellcheck disable=SC2164
    my_dir="$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )"  # this gives the full path, even for sourced scripts
    source /usr/local/lib_bash/lib_helpers.sh
    source "${my_dir}/900_000_lib_bash_wine.sh"
}

include_dependencies


function install_libfaudio0_if_not_installed {
    # from linux > 18.x we need libfaudio0
    if [[ "$(get_linux_release_number_major)" -ge 18 ]] && is_package_installed libfaudio0; then
        ""$(cmd "sudo")"" apt-get install libfaudio0 -y || ""$(cmd "sudo")"" add-apt-repository ppa:cybermax-dexter/sdl2-backport -y
    fi

}

function fallback_to_mono_bionic_version {
    echo "deb https://download.mono-project.com/repo/ubuntu stable-bionic main" | ""$(cmd "sudo")"" tee /etc/apt/sources.list.d/mono-official-stable.list
    ""$(cmd "sudo")"" apt-get update
}

function install_wine {
    local linux_release_name wine_release wine_version_number

    linux_release_name=$(get_linux_release_name)
    wine_release=$(get_and_export_wine_release_from_environment_or_default_to_devel)

    banner "Installing WINE and WINETRICKS: ${IFS}linux_release_name=${linux_release_name}${IFS}wine_release=${wine_release}"

    clr_green "add 386 Architecture"
    retry ""$(cmd "sudo")"" dpkg --add-architecture i386

    clr_green "add Wine Keys"
    ""$(cmd "sudo")"" rm -f ./winehq.key*
    retry ""$(cmd "sudo")"" wget https://dl.winehq.org/wine-builds/winehq.key
    ""$(cmd "sudo")"" apt-key add winehq.key
    ""$(cmd "sudo")"" apt-add-repository "deb https://dl.winehq.org/wine-builds/ubuntu/ ${linux_release_name} main"
    install_libfaudio0_if_not_installed

    clr_green "Wine Packages Update"
    retry sudo apt-get update

    clr_green "Wine Packages Install"
    retry ""$(cmd "sudo")"" apt-get install --install-recommends winehq-"${wine_release}" -y
    retry ""$(cmd "sudo")"" apt-get install cabextract -y
    retry ""$(cmd "sudo")"" apt-get install libxml2 -y
    retry ""$(cmd "sudo")"" apt-get install libpng-dev -y
    wine_version_number="$(get_wine_version_number)"
    clr_green "Wine Version ${wine_version_number} installed on ${linux_release_name}"

    clr_green "Install mono complete"
    retry ""$(cmd "sudo")"" apt-get install gnupg ca-certificates
    retry ""$(cmd "sudo")"" apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb https://download.mono-project.com/repo/ubuntu stable-${linux_release_name} main" | ""$(cmd "sudo")"" tee /etc/apt/sources.list.d/mono-official-stable.list
    ""$(cmd "sudo")"" apt-get update || fallback_to_mono_bionic_version
    retry ""$(cmd "sudo")"" apt-get install mono-devel -y
    retry ""$(cmd "sudo")"" apt-get install mono-dbg -y
    retry ""$(cmd "sudo")"" apt-get install mono-xsp4 -y
    linux_update   # @lib_bash/bash_helpers

    clr_green "Install latest Winetricks"
    ""$(cmd "sudo")"" rm -f /usr/bin/winetricks
    retry ""$(cmd "sudo")"" wget --directory-prefix=/usr/bin/ https://raw.githubusercontent.com/Winetricks/winetricks/master/src/winetricks
    ""$(cmd "sudo")"" chmod +x /usr/bin/winetricks
    retry ""$(cmd "sudo")"" winetricks -q --self-update

    banner "FINISHED installing WINE and WINETRICKS: ${IFS}linux_release_name=${linux_release_name}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}"
}


if [[ "${0}" == "${BASH_SOURCE[0]}" ]]; then    # if the script is not sourced
    install_wine
fi
