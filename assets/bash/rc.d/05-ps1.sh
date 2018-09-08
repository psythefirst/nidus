__NIDUS_COMMAND_SNO=0
__NIDUS_COMMAND_ERRNO=0

function __nidus_inline_echo {
    builtin echo -n "$*"
}

function  __nidus_cursor_xpos {
    local saved_state xpos dummy
    saved_state=$(stty -g)
    stty -echo
    echo -n $'\033[6n' > /dev/tty; read -s -d ';' dummy; read -s -dR xpos
    echo "$xpos"
    stty $saved_state 2>/dev/null
}

function __nidus_force_newline {
    if ! [ "$NIDUS_ENABLE_EXPLICIT_EOF" = yes ]; then
        return
    fi

    if [ "$(__nidus_cursor_xpos)" != 1 ]; then
        nidus_reset_fmt
        nidus_fmt force_newline
        __nidus_inline_echo ":no_eol:"
        nidus_reset_fmt

        if [ "$(__nidus_cursor_xpos)" != 1 ]; then
            builtin echo
        fi
    fi
}

function __nidus_short_hostname {
    if [ -z "$NIDUS_PS1_HOSTNAME" ]; then
        local node_name=$(uname -n)
        __nidus_inline_echo ${node_name%%.*}
    else
        __nidus_inline_echo $NIDUS_PS1_HOSTNAME
    fi
}

function nidus_ps1_user_host {
    __nidus_ps1_username

    nidus_fmt ps1_userhost_punct zero_width
    __nidus_inline_echo "@"
    nidus_reset_fmt zero_width

    __nidus_ps1_hostname
    return 0
}

function __nidus_ps1_username {
    nidus_fmt ps1_username zero_width
    __nidus_inline_echo $(whoami)
    nidus_reset_fmt zero_width
}

function __nidus_ps1_hostname {
    nidus_fmt ps1_hostname zero_width
    __nidus_inline_echo $(__nidus_short_hostname)
    nidus_reset_fmt zero_width
    return 0
}

function nidus_ps1_non_default_ifs {
    if [[ "${#IFS}" == 3 && "$IFS" == *" "* && "$IFS" == *$'\t'* && "$IFS" == *$'\n'* ]]; then
        return 1
    fi

    nidus_fmt ps1_ifs zero_width
    __nidus_inline_echo "(IFS="
    nidus_reset_fmt zero_width

    nidus_fmt ps1_ifs_value zero_width
    printf "%q" "$IFS"
    nidus_reset_fmt zero_width

    nidus_fmt ps1_ifs zero_width
    __nidus_inline_echo ")"
    nidus_reset_fmt zero_width

    return 0
}

function nidus_ps1_chroot {
    if [ -n "$debian_chroot" ]; then
        nidus_fmt ps1_chroot zero_width
        __nidus_inline_echo "($debian_chroot)"
        nidus_reset_fmt zero_width
        return 0
    else
        return 1
    fi
}

function nidus_ps1_bg_indicator {
    local njobs="$1"
    if [ "$njobs" -gt 0 ]; then
        nidus_fmt ps1_bg_indicator zero_width
        __nidus_inline_echo "&$njobs"
        nidus_reset_fmt zero_width
        return 0
    fi
    return 1
}

function nidus_ps1_shlvl_indicator {
    if [ "$SHLVL" -gt 1 ]; then
        nidus_fmt ps1_shlvl_indicator zero_width
        __nidus_inline_echo "^$(expr $SHLVL - 1)"
        nidus_reset_fmt zero_width
        return 0
    fi
    return 1
}

function nidus_ps1_screen_indicator {
    if [ -n "$STY" ]; then
        nidus_fmt ps1_screen_indicator zero_width
        __nidus_inline_echo "*${STY#*.}*"
        nidus_reset_fmt zero_width
        return 0
    fi
    return 1
}

function nidus_ps1_git_indicator {

    if type git &>/dev/null; then
        gbr=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
        if [ -n "$gbr" ]; then
            if [ "$gbr" = HEAD ]; then
                gbr=$(git rev-parse HEAD 2>/dev/null | head -c8)
            fi
            groot=$(basename ///$(git rev-parse --show-toplevel) 2>/dev/null)

            if [ "${#groot}" -gt 12 ]; then
                groot="${groot: 0:8}\`${groot: -3:3}"
            fi
            nidus_fmt ps1_git_indicator zero_width
            if [ "$groot" = / ]; then
                __nidus_inline_echo "(.git)"
            else
                __nidus_inline_echo "$groot[$gbr]"
            fi
            nidus_reset_fmt zero_width
            return 0
        fi
    fi
    return 1
}

function nidus_ps1_cwd {
    nidus_fmt ps1_cwd zero_width
    __nidus_inline_echo "$1"
    nidus_reset_fmt zero_width
    return 0
}

function nidus_ps1_physical_cwd {
    local physical_cwd="$(pwd -P)"
    if [ "$physical_cwd" != "$(pwd)" ]; then
        nidus_fmt ps1_physical_cwd zero_width
        __nidus_inline_echo "(Physical: $physical_cwd)"
        nidus_reset_fmt zero_width
        return 0
    fi
    return 1
}

function nidus_ps1_dollar_hash {
    nidus_fmt ps1_dollar_hash zero_width
    __nidus_inline_echo "$1"
    nidus_reset_fmt zero_width
}

function nidus_ps1_space {
    __nidus_inline_echo ' '
}

function nidus_ps1_newline {
    builtin echo
}

PS1='$(
nidus_ps1_user_host         && nidus_ps1_space
nidus_ps1_chroot            && nidus_ps1_space
nidus_ps1_bg_indicator "\j" && nidus_ps1_space
nidus_ps1_shlvl_indicator   && nidus_ps1_space
nidus_ps1_screen_indicator  && nidus_ps1_space
nidus_ps1_git_indicator     && nidus_ps1_space
nidus_ps1_cwd "\w"          && nidus_ps1_newline
nidus_ps1_physical_cwd      && nidus_ps1_newline
nidus_ps1_dollar_hash "\$"  && nidus_ps1_space
nidus_ps1_non_default_ifs   && nidus_ps1_space
)'

function __nidus_do_before_command {

    # This assignment must be done first
    __NIDUS_COMMAND_ERRNO="${PIPESTATUS[@]}"

    local IFS=$' \t\n'
    if [ "$BASH_COMMAND" = __nidus_do_after_command ]; then
        return
    fi
    let '__NIDUS_COMMAND_SNO += 1'

    if [ "${NIDUS_ENABLE_CMD_EXPANSION}" = no ]; then
        return
    fi

    read -r -a cmd_tokens <<< "$BASH_COMMAND"
    case $(type -t "${cmd_tokens[0]}") in
        file|alias)
            # even we got alias here, it has already been resolved
            cmd_tokens[0]=$(type -P "${cmd_tokens[0]}")
            ;;
        builtin)
            cmd_tokens[0]="builtin ${cmd_tokens[0]}"
            ;;
        function)
            cmd_tokens[0]="function ${cmd_tokens[0]}"
            ;;
        keyword)
            cmd_tokens[0]="keyword ${cmd_tokens[0]}"
            ;;
        *)
            ;;
    esac

    local sink=${NIDUS_CMD_EXPANSION_SINK:-&2}
    local proxy_fd=${NIDUS_CMD_EXPANSION_SINK_PROXY_FD:-99}
    local stat_str="[$__NIDUS_COMMAND_SNO] -> ${cmd_tokens[@]} ($(date +'%m/%d/%Y %H:%M:%S'))"

    if [ -w "$sink" ]; then
        eval "exec $proxy_fd>>$sink"
    else
        eval "exec $proxy_fd>$sink"
    fi

    __nidus_force_newline

    [ -t "$proxy_fd" ] && eval "nidus_fmt cmd_expansions >&$proxy_fd"
    eval '__nidus_inline_echo "$stat_str" '"| tr '[:cntrl:]' '.' >&$proxy_fd"
    [ -t "$proxy_fd" ] && eval "nidus_reset_fmt >&$proxy_fd"
    eval "nidus_ps1_newline >&$proxy_fd"

    eval "exec $proxy_fd>&-"
}

function __nidus_do_after_command {

    local IFS=$' \t\n'
    local eno ts
    local ret=OK

    __nidus_force_newline

    if [ $__NIDUS_COMMAND_SNO -gt 0 ]; then
        __NIDUS_COMMAND_SNO=0

        if [ "${NIDUS_ENABLE_STATUS_LINE}" = no ]; then
            return
        fi

        ts=$(date +"%m/%d/%Y %H:%M:%S")
        for eno in $__NIDUS_COMMAND_ERRNO; do
            if [ $eno -ne 0 ]; then
                ret=ERR
                break
            fi
        done

        nidus_reset_fmt
        [ "$NIDUS_THICK_SEPARATOR" = yes ] || nidus_fmt underline
        if [ $ret = OK ]; then
            nidus_fmt status_ok
            printf "%${COLUMNS}s\n" "$ts [ Status OK ]"
        else
            nidus_fmt status_error
            printf "%${COLUMNS}s\n" "$ts [ Exception code $__NIDUS_COMMAND_ERRNO ]"
        fi
        nidus_reset_fmt

        if [ "$NIDUS_THICK_SEPARATOR" = yes ]; then
            nidus_fmt horizontal_rule
            printf "%${COLUMNS}s\n" "" | tr " " "${NIDUS_THICK_SEPARATOR_CHAR:-~}"
            nidus_reset_fmt
        fi
    fi
}