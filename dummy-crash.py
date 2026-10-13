#!/usr/bin/env python3
# dummy-crash.py — Opens a window, waits 5 seconds, then DIES violently
# Longer wait = more poll cycles for crash-watcher to detect the window.

import tkinter as tk
import threading
import ctypes
import time

def die_horribly():
    """True native segfault via ctypes — not catchable by Python's faulthandler."""
    time.sleep(5)
    # Write to address 0x0 — instant SIGSEGV, no Python signal handling involved
    ctypes.string_at(0)

root = tk.Tk()
root.title("Crash Test Dummy")
root.geometry("300x120")

label = tk.Label(root, text="I'm gonna crash in 5 seconds... RIP 🪦", wraplength=260)
label.pack(pady=35)

# Crash happens on a background thread so mainloop() keeps the window alive and
# fully mapped — this guarantees crash-watcher has time to detect the X11 window.
t = threading.Thread(target=die_horribly, daemon=True)
t.start()

root.mainloop()
