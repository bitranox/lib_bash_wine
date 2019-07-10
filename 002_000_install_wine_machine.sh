#!/bin/bash

function update_myself {
    /usr/lib/lib_bash_wine/install_or_update_lib_bash_wine.sh "${@}" || exit 0              # exit old instance after updates
}

function include_dependencies {
    source /usr/lib/lib_bash/lib_color.sh
    source /usr/lib/lib_bash/lib_retry.sh
    source /usr/lib/lib_bash/lib_helpers.sh
    source /usr/lib/lib_bash_wine/lib_bash_wine.sh
}

include_dependencies  # we need to do that via a function to have local scope of my_dir

function install_wine_machine {

    banner "Install Wine Machine"
    local sudo_command=$(get_sudo_command)                                      # @lib_bash/bash_helpers
    local linux_codename=$(get_linux_codename)                                  # @lib_bash/bash_helpers
    local wine_release=$(get_wine_release_from_environment_or_default_to_devel) # @lib_bash_wine
    local wine_prefix=$(get_and_export_wine_prefix_or_default_to_home_wine)     # @lib_bash_wine
    local wine_arch=$(get_and_export_wine_arch_or_default_to_win64)             # @lib_bash_wine
    local wine_windows_version=$(get_wine_windows_version_or_default_to_win10)  # @lib_bash_wine
    local is_xvfb_service_active=$(get_is_xvfb_service_active)                  # @lib_bash_wine
    local wine_version_number=$(get_wine_version_number)                        # @lib_bash_wine

    banner "Setup Wine Machine:${IFS}linux=${linux_codename}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}${IFS}WINEPREFIX=${wine_prefix}${IFS}WINEARCH=${wine_arch}${IFS}wine_windows_version=${wine_windows_version}"
    mkdir -p ${wine_prefix}
    wine_drive_c_dir=${wine_prefix}/drive_c
    # xvfb-run --auto-servernum winecfg # fails marshal_object couldnt get IPSFactory buffer for interface ...

    if [[ ${is_xvfb_service_active} == "True" ]]; then
        clr_green "Stopping xvfb because winecfg crashes if it is enabled"
        ${sudo_command} service xvfb stop
    fi

    banner "winecfg for Wine Machine, WINEPREFIX=${wine_prefix}, WINEARCH=${wine_arch}, wine_windows_version=${wine_windows_version}"
    winecfg

    if [[ ${is_xvfb_service_active} == "True" ]]; then
        clr_green "restarting xvfb"
        ${sudo_command} service xvfb start
    fi

    banner "Disable GUI Crash Dialogs"
    winetricks nocrashdialog

    banner "Set Windows Version to ${wine_windows_version}"
    winetricks -q ${wine_windows_version}

    banner "Install common Packages"

    banner "install windowscodecs"
    retry winetricks -q windowscodecs

    banner "install msxml3"
    retry winetricks -q msxml3

    banner "install msxml6"
    retry winetricks -q msxml6

    banner "FINISHED installing Wine MachineWine Machine:${IFS}linux=${linux_codename}${IFS}wine_release=${wine_release}${IFS}wine_version=${wine_version_number}${IFS}WINEPREFIX=${wine_prefix}${IFS}WINEARCH=${wine_arch}${IFS}wine_windows_version=${wine_windows_version}"
}


update_myself ${0} ${@}                                                              # pass own script name and parameters
install_wine_machine


