# 💀 crash-watcher — The Crash Dialog Nobody Asked For (But Everyone Needed)

> *"All toasters toast toast."*
> — Hotel Mario, 1994. Also, your system, right now.

---

## 🧠 What In The Actual Hell Is This?

You know how on Windows, when something crashes, you get that depressing grey box that says "Program has stopped working" and offers you absolutely nothing useful?

**This is NOT that.**

This is a **kernel-level crash hook** for **Linux Mint 22 Cinnamon (X11)** that intercepts your crashes at the deepest possible level — we're talking `/proc/sys/kernel/core_pattern` deep — and instead of quietly logging to `journalctl` like some kind of boring responsible adult, it **screams CDi Zelda memes at you through your speakers** and pops up a Zenity dialog with randomised Hotel Mario/Philips CD-i nonsense.

When a process sends itself to /dev/null via `SIGSEGV`, `SIGABRT`, `SIGFPE`, `SIGBUS`, `SIGILL`, or `SIGQUIT`, this bad boy **wakes up and gets UNHINGED**.

No polling. No scanning. The **kernel itself** calls our script. Instantaneous. Like death, but funnier.

---

## 📁 Files In This Disaster

| File | What It Does |
|---|---|
| `crash-watcher.sh` | The main event. Gets called by the kernel on crash. Also handles install/uninstall. |
| `dummy-crash.py` | A little tkinter window that opens, says goodbye, and then **violently segfaults itself** via `ctypes`. Like a digital kamikaze. For testing. |

---

## 🛠️ Dependencies (Install These Or It Won't Work, Genius)

### System Packages

Run this and stop wasting time:

```bash
sudo apt install -y \
    zenity \
    xdotool \
    wmctrl \
    mpv \
    python3 \
    python3-tk
```

**What each one does and why you need it:**

| Package | Why It's Here |
|---|---|
| `zenity` | The GTK dialog box. This IS the crash popup. Non-negotiable. |
| `xdotool` | Finds the zenity window by PID so we can... |
| `wmctrl` | ...rip it off the taskbar. Crash dialogs shouldn't clutter your taskbar like a Windows 7 trauma response. |
| `mpv` | Plays the sounds. Lowest startup latency of any CLI audio player. We love it. If absent it falls back to `aplay`/`mpg123` but mpv is preferred. |
| `python3` | Runs `dummy-crash.py`. You probably have it. Linux and all that. |
| `python3-tk` | Tkinter. The crash dummy needs a window to haunt before it dies. |

### Optional Fallback Audio

If you're a `mpv` hater (wrong) or it's not available:

```bash
sudo apt install -y mpg123 alsa-utils
```

`alsa-utils` gives you `aplay` for WAV files. `mpg123` for MP3s. The script tries `mpv` first, falls back to these.

---

## 🔊 Sound Files (The Whole Point, Honestly)

The script expects a folder of audio files. Currently hardcoded to:

```
/home/YourUsername/crash-button-sounds/
```

**⚠️ Replace `YourUsername` with your actual username** in `crash-watcher.sh`. It's in the `DIALOG_SOUND` and `BUTTON_SOUNDS` section near the top. Yes, you have to do this manually. I'm not your fucking mom, dumbass.

### Files You Need

BEHOLD! THE ULTIMATE AUDIO FILES OF OLD ASS BRAINROT:

| Filename | Source | Occasion |
|---|---|---|
| `xpcrtstp.wav` | Windows XP Critical Stop sound | Plays when the dialog opens. The overture. |
| `Dinner.mp3` | "Dinner" — King Harkinian, Zelda CD-i | Classic. Timeless. |
| `Pingas.mp3` | Dr. Robotnik, Adventures of Sonic | Do I need to explain this to you |
| `spaghetti.mp3` | "Hotel Mario Luigi" — Hotel Mario | I hope she made lotsa spaghetti! |
| `Mah-Boi.mp3` | King Harkinian — "Mah boi" | THE thing of legend |
| `toast.mp3` | Hotel Mario "All toasters toast toast" | Philosophy |
| `Squadala.mp3` | Gwonam — "Squadala! We're off!" | For when a crash truly transcends |
| `Billy-Mays.mp3` | Billy Mays "Hi Billy Mays here" | RIP legend, still crashing in heaven |
| `Mama-luigi.mp3` | "Mama Luigi!" — Mario, Super Mario World | *That's* Mama Luigi to you, Mario |

---

## 🚀 Setup (Do This Once, Then Never Think About It Again)

### 1. Clone / Download

Put both files somewhere permanent. Like `/home/YourUsername/crash-watcher/`. Don't put it in `/tmp`. Idiot.

### 2. Edit the Paths

Open `crash-watcher.sh` and fix these pieces of garbage at the top:

```bash
# Change this:
DIALOG_SOUND="/home/YourUsername/crash-button-sounds/xpcrtstp.wav"

# To this (your ACTUAL username):
DIALOG_SOUND="/home/actuallyyourusername/crash-button-sounds/xpcrtstp.wav"
```

Do the same for every entry in `BUTTON_SOUNDS`. Yes, all of them.

### 3. Install

```bash
sudo bash crash-watcher.sh --install
```

This does two things:
1. Copies the script to `/usr/local/bin/crash-handler.sh`
2. Writes to `/proc/sys/kernel/core_pattern` to tell the kernel "hey, call THIS when something explodes"
3. Writes `/etc/sysctl.d/50-crash-handler.conf` so it survives reboots

That's it. No buts.

---

## 🧪 Testing (aka "Does This Actually Work?")

```bash
python3 /path/to/dummy-crash.py
```

A window opens. It says it's going to crash. It fucking means it. Five seconds later, it commits terrorism on itself! YIPPEE! The funny dialog appears. A sound plays.

If nothing happens, check this bullshit:
- Did you actually run `--install`? If not, I don't fucking care.
- Are your paths in the script correct? If not, I don't fucking care.
- Does `/proc/sys/kernel/core_pattern` contain the right thing? Check with: `cat /proc/sys/kernel/core_pattern` If not, I don't fucking care.
- Is `zenity` installed? Run `zenity --version` and find out... but I still don't **CARE**.

---

## 🎲 How The Dialog Works

Every crash gets a **randomly selected** combination of:

- **Title** — chosen from `TITLE_POOL` (e.g. *"Hotel Mario detected a problem with your wife"*)
- **Message** — chosen from `DIALOG_TEXT_POOL` (contains Pinto-grade unhinged text)
- **Buttons** — 3–4 randomly shuffled buttons from `BUTTON_POOL`, each labelled with a good ol meme
- **Button click sound** — clicking a button plays its corresponding stupid audio clip

The dialog also gets **removed from your taskbar** automatically (via `xdotool` + `wmctrl`) so it floats like a spectre above your desktop. Mysterious. Menacing. Meme-ical.

---

## 🗑️ Uninstall (If You've Lost Your Sense of Humor)

```bash
sudo bash crash-watcher.sh --uninstall
```

This removes the script from `/usr/local/bin`, deletes the sysctl config, and restores the kernel core pattern to `core` (default boring behavior). Crashes go back to being silent and depressing.
And now I'm disappointed in you.

---

## ⚠️ Known Issues / Caveats / Don't Say I Didn't Warn You

- **Root vs. User:** The kernel calls the script as root. We `sudo -u $USERNAME` to run the GUI stuff as the actual user so it appears on their display. This *should* work. If your Cinnamon session is doing something weird with DBus or DISPLAY, the dialog might not show. Check `$DISPLAY` and `$DBUS_SESSION_BUS_ADDRESS`. 

- **X11 Only:** This is X11-specific. If you're on Wayland... **YOU PICKED THE WRONG HOUSE, FOOL!**

- **The process might already be dead:** By the time our script runs, the crashed process's `/proc/PID/` entry is often gone. We try to grab the app name from it anyway. Sometimes we get it, sometimes we just say "unknown" and life goes on.

- **Timing:** The crash handler fires *immediately* on crash. The dummy app keeps its window alive for 5 seconds before dying so you can confirm it's visible — that's intentional, not a bug, motherfucker.

- **Sound files must exist:** If a sound file path is wrong or the file doesn't exist, it just silently skips it. No sound. Dialog still appears. Not the end of the world but still, I'm not gonna be nice about saying that I'm disappointed in you.

---

## 🏆 Why Does This Exist?

Because life is short and your computer crashes anyway.

And you're probably sick of those ultra polite clinical dialogue anyway.
Yeah, well, me too!

You can either stare at a silent desktop wondering why your app disappeared, OR you can have King Harkinian yell *"MAH BOI"* at you at 2AM while a Zenity dialog informs you that your program "has decided to go on a dinner date with King Harkinian."

The choice is obvious.

---

## 📜 License

What kind of corporate fucking animal do you take me for?! No! Do whatever the fuck you want with it, ass!

---

*Made for Linux Mint 22 Cinnamon X11. Tested on actual segfaults. No programs were harmed in the making of this README (they were harmed on purpose, for science, lol).*
*And no, unfortunately, no secret sex tapes included! Sorry, not sorry, you horny fucks.*
