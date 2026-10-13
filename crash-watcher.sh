#!/usr/bin/env bash
# =============================================================================
# crash-handler.sh — Funny crash dialog for Linux Mint 22 Cinnamon X11
#
# SETUP (one-time, run once as root):
#   sudo bash crash-handler.sh --install
#
# UNINSTALL:
#   sudo bash crash-handler.sh --uninstall
#
# HOW IT WORKS:
#   Uses /proc/sys/kernel/core_pattern to hook into the kernel's crash
#   notification — no polling, no process scanning, fires instantly on SIGSEGV,
#   SIGABRT, SIGFPE, SIGBUS, SIGILL, SIGQUIT (real crashes only).
# =============================================================================

SCRIPT_PATH="$(realpath "$0")"

# =============================================================================
# 🔔 DIALOG SOUND
# =============================================================================
DIALOG_SOUND="home/YourUsername/crash-button-sounds/xpcrtstp.wav"

# =============================================================================
# 🔊 BUTTON SOUNDS
# =============================================================================
declare -A BUTTON_SOUNDS
BUTTON_SOUNDS["DINNER"]="/home/YourUsername/crash-button-sounds/Dinner.mp3"
BUTTON_SOUNDS["PINGAS"]="/home/YourUsername/crash-button-sounds/Pingas.mp3"
BUTTON_SOUNDS["SPAGHETTI"]="/home/YourUsername/crash-button-sounds/spaghetti.mp3"
BUTTON_SOUNDS["MAH BOI"]="/home/YourUsername/crash-button-sounds/Mah-Boi.mp3"
BUTTON_SOUNDS["TOAST"]="/home/YourUsername/crash-button-sounds/toast.mp3"
BUTTON_SOUNDS["SQUADALA"]="/home/YourUsername/crash-button-sounds/Squadala.mp3"
BUTTON_SOUNDS["BILLY MAYS"]="/home/YourUsername/crash-button-sounds/Billy-Mays.mp3"
BUTTON_SOUNDS["MAMA LUIGI"]="/home/YourUsername/crash-button-sounds/Mama-luigi.mp3"

# =============================================================================
# 🪟 TITLE POOL
# =============================================================================
TITLE_POOL=(
    "Obey Weegee! Destroy %APPNAME%!"
    "Windows Movie Maker - CRITICAL_MARE_ERROR"
    "%APPNAME% has left the chat"
    "PINGAS DETECTION SYSTEM — %APPNAME% edition"
    "Hotel Mario detected a problem with %APPNAME%"
    "%APPNAME% - FATAL_YIKES_EXCEPTION"
    "OH NO! %APPNAME% is fucked!"
)

# =============================================================================
# 💬 DIALOG TEXT POOL
# =============================================================================
DIALOG_TEXT_POOL=(
    "<b><span foreground='red'>PINGAS DETECTION SYSTEM ALERT:</span></b>\n\n%APPNAME% has crashed and it's probably your fault.\n\nWhat do you want to do about it?"
    "<b><span foreground='red'>OH NO:</span></b>\n\n%APPNAME% has encountered a fatal error and fucking died.\n\nAll toasters toast toast!"
    "<b><span foreground='red'>CRITICAL TOAST INCIDENT:</span></b>\n\nYour toast was being processed by %APPNAME% when things went sideways.\n\nHotel Mario cannot help you now."
    "<b><span foreground='red'>OH NO! %APPNAME% is fucked!:</span></b>\n\n%APPNAME% has decided to go on a dinner date with King Harkinian.\n\nZelda is not impressed."
)

# =============================================================================
# 🔘 BUTTON POOL
# =============================================================================
BUTTON_POOL=(
    "MAH BOI"
    "DINNER"
    "TOAST"
    "PINGAS"
    "SQUADALA"
    "BILLY MAYS"
    "SPAGHETTI"
    "MAMA LUIGI"
)

# =============================================================================
# INSTALL / UNINSTALL
# =============================================================================
if [[ "$1" == "--install" ]]; then
    echo "Installing crash-handler..."
    cp "$SCRIPT_PATH" /usr/local/bin/crash-handler.sh
    chmod +x /usr/local/bin/crash-handler.sh
    # Tell the kernel: when anything crashes, pipe the core dump to our script.
    # %p = PID, %u = UID, %E = exe path (slashes replaced with !)
    echo "|/usr/local/bin/crash-handler.sh --crash %p %u %E" > /proc/sys/kernel/core_pattern
    # Make it survive reboots
    echo 'kernel.core_pattern=|/usr/local/bin/crash-handler.sh --crash %p %u %E' \
        > /etc/sysctl.d/50-crash-handler.conf
    echo "Done! Crashes will now trigger the funny dialog."
    echo "Test it: python3 /path/to/dummy-crash.py"
    exit 0
fi

if [[ "$1" == "--uninstall" ]]; then
    echo "Uninstalling crash-handler..."
    echo "core" > /proc/sys/kernel/core_pattern
    rm -f /etc/sysctl.d/50-crash-handler.conf
    rm -f /usr/local/bin/crash-handler.sh
    echo "Done. Crashes are boring again."
    exit 0
fi

# =============================================================================
# CRASH HANDLER — called by kernel with: --crash <PID> <UID> <EXE_PATH>
# =============================================================================
if [[ "$1" == "--crash" ]]; then
    CRASHED_PID="$2"
    CRASHED_UID="$3"
    CRASHED_EXE="$4"  # e.g. !!usr!bin!python3 — kernel replaces / with !

    # Convert kernel exe path back to something readable
    APPNAME=$(echo "$CRASHED_EXE" | tr '!' '/' | xargs basename 2>/dev/null)
    APPNAME="${APPNAME:-unknown}"

    # Strip common interpreter names — use the script name instead if possible
    case "$APPNAME" in
        python3*|python*|java|node|perl|ruby|bash|sh)
            # Try to get the actual script name from /proc (may already be gone)
            SCRIPT=$(cat /proc/"$CRASHED_PID"/cmdline 2>/dev/null \
                | tr '\0' '\n' | grep -v '^-' | tail -1)
            SCRIPT=$(basename "${SCRIPT%.py}" 2>/dev/null)
            [[ -n "$SCRIPT" && "$SCRIPT" != "$APPNAME" ]] && APPNAME="$SCRIPT"
            ;;
    esac

    # Find the user's DISPLAY and DBUS session so we can show a GUI as them
    # The crashed process's UID tells us which user to show the dialog for
    USER_HOME=$(getent passwd "$CRASHED_UID" | cut -d: -f6)
    USERNAME=$(getent passwd "$CRASHED_UID" | cut -d: -f1)

    # Find DISPLAY for this user from their running session
    USER_DISPLAY=$(grep -r "DISPLAY" /proc/*/environ 2>/dev/null \
        | grep -m1 "$(id -u "$USERNAME" 2>/dev/null)" \
        | grep -oP 'DISPLAY=\K[^\x00]+' || echo ":0")

    # Find DBUS address for this user
    DBUS_ADDR=$(grep -r "DBUS_SESSION_BUS_ADDRESS" \
        /proc/*/environ 2>/dev/null \
        | xargs -0 2>/dev/null \
        | grep "$USERNAME" \
        | grep -oP 'DBUS_SESSION_BUS_ADDRESS=\K[^\x00 ]+' | head -1)

    # Run the dialog as the crashed user (not root)
    sudo -u "$USERNAME" bash -c "
        export DISPLAY='${USER_DISPLAY:-:0}'
        export DBUS_SESSION_BUS_ADDRESS='$DBUS_ADDR'
        export XDG_RUNTIME_DIR='/run/user/$CRASHED_UID'

        $(declare -p TITLE_POOL)
        $(declare -p DIALOG_TEXT_POOL)
        $(declare -p BUTTON_POOL)
        $(declare -p BUTTON_SOUNDS)
        DIALOG_SOUND='$DIALOG_SOUND'
        APPNAME='$APPNAME'

        random_pick() { local a=(\"\$@\"); echo \"\${a[\$((RANDOM % \${#a[@]}))]}\"; }
        inject() { echo \"\${1//%APPNAME%/\$APPNAME}\"; }

        play_sound() {
            local f=\"\$1\"
            [[ -f \"\$f\" ]] || return
            # mpv has the lowest startup latency of the common CLI players and
            # handles every format without a separate decoder step.
            # Fall back to paplay (wav) / mpg123 (mp3) if mpv is absent.
            if command -v mpv &>/dev/null; then
                mpv --no-video --really-quiet --no-terminal \"\$f\" &>/dev/null &
            else
                case \"\${f##*.}\" in
                    wav) aplay -q \"\$f\" &>/dev/null & ;;
                    mp3) mpg123 -q \"\$f\" &>/dev/null & ;;
                    *)   aplay -q \"\$f\" &>/dev/null & ;;
                esac
            fi
        }

        # Shuffle buttons
        pool=(\"\${BUTTON_POOL[@]}\")
        shuffled=()
        while [[ \${#pool[@]} -gt 0 ]]; do
            i=\$((RANDOM % \${#pool[@]}))
            shuffled+=(\"\${pool[\$i]}\")
            pool=(\"\${pool[@]:0:\$i}\" \"\${pool[@]:\$((i+1))}\")
        done

        ok_label=\"\${shuffled[0]}\"
        cancel_label=\"\${shuffled[1]}\"
        extra_args=()
        for i in 2 3; do
            [[ -n \"\${shuffled[\$i]}\" ]] && extra_args+=(\"--extra-button=\${shuffled[\$i]}\")
        done

        title=\$(inject \"\$(random_pick \"\${TITLE_POOL[@]}\"))\")
        text=\$(inject \"\$(random_pick \"\${DIALOG_TEXT_POOL[@]}\"))\")

        play_sound \"\$DIALOG_SOUND\"

        # Run zenity in the background so we can strip its taskbar button
        # before the user even sees it.  Stdout goes to a temp file because
        # extra-button labels are printed there.
        _ZTMP=\"\$(mktemp /tmp/crash-zenity.XXXXXX)\"
        zenity --question \
            --title=\"\$title\" \
            --text=\"\$text\" \
            --icon-name=error \
            --ok-label=\"\$ok_label\" \
            --cancel-label=\"\$cancel_label\" \
            \"\${extra_args[@]}\" >\"\$_ZTMP\" 2>/dev/null &
        _ZPID=\$!

        # Poll until the window is visible, then remove it from the taskbar.
        # 20 × 50 ms = up to 1 s — plenty of time for zenity to draw itself.
        (
            for _i in \$(seq 1 20); do
                _WID=\$(xdotool search --pid \"\$_ZPID\" 2>/dev/null | head -1)
                if [[ -n \"\$_WID\" ]]; then
                    # wmctrl is the cleanest way; xprop is the fallback.
                    if command -v wmctrl &>/dev/null; then
                        wmctrl -i -r \"\$_WID\" -b add,skip_taskbar 2>/dev/null
                    else
                        xprop -id \"\$_WID\" \
                            -f _NET_WM_STATE 32a \
                            -set _NET_WM_STATE _NET_WM_STATE_SKIP_TASKBAR 2>/dev/null
                    fi
                    break
                fi
                sleep 0.05
            done
        ) &

        wait \"\$_ZPID\"
        code=\$?
        clicked=\$(cat \"\$_ZTMP\" 2>/dev/null)
        rm -f \"\$_ZTMP\"

        if   [[ \$code -eq 0 ]];            then lbl=\"\$ok_label\"
        elif [[ \$code -eq 1 && -z \"\$clicked\" ]]; then lbl=\"\$cancel_label\"
        else lbl=\"\$clicked\"
        fi

        play_sound \"\${BUTTON_SOUNDS[\$lbl]}\"
    "
    exit 0
fi

echo "Usage:"
echo "  sudo bash $0 --install     # hook into kernel crash handler"
echo "  sudo bash $0 --uninstall   # restore default behavior"
