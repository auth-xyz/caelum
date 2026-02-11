#! /usr/bin/python3 

import os, json, tkinter as tk
from PIL import Image, ImageTk
import ttkbootstrap as ttk
import subprocess

from tkinter import filedialog

cfg = os.path.expanduser("~/.config/walchooser.json")
wal = os.path.expanduser("~/scripts/wal.sh")

def load_cfg():
    if os.path.exists(cfg):
        with open(cfg) as f: return json.load(f)
    return {"dir": os.path.expanduser("~")}

def save_cfg(d):
    with open(cfg, "w") as f: json.dump({"dir": d}, f)

def choose_dir():
    d = filedialog.askdirectory(title="Select Wallpaper Folder")
    if d:
        save_cfg(d)
        load_wallpapers(d)

def select_wallpaper(p):
    wp_var.set(p)
    root.quit()

def on_mousewheel(e):
    canvas.yview_scroll(int(-1*(e.delta/120)), "units")

def load_wallpapers(d):
    for w in frame.winfo_children(): w.destroy()
    exts = (".jpg",".jpeg",".png",".bmp",".webp",".gif")
    files = [os.path.join(d,f) for f in os.listdir(d) if f.lower().endswith(exts)]
    cols = 4
    r = c = 0
    for p in files:
        try:
            img = Image.open(p)
            img.thumbnail((150,150))
            imgtk = ImageTk.PhotoImage(img)
            b = ttk.Button(frame, image=imgtk, command=lambda p=p: select_wallpaper(p))
            b.image = imgtk
            b.grid(row=r, column=c, padx=6, pady=6)
            c += 1
            if c >= cols:
                c = 0
                r += 1
        except: pass

root = ttk.Window(themename="darkly")
root.geometry("900x600")
root.minsize(600,400)

wp_var = tk.StringVar()
conf = load_cfg()

ttk.Button(root, text="Change Folder", command=choose_dir).pack(pady=10)
canvas = tk.Canvas(root)
scroll = ttk.Scrollbar(root, orient="vertical", command=canvas.yview)
frame = ttk.Frame(canvas)
frame.bind("<Configure>", lambda e: canvas.configure(scrollregion=canvas.bbox("all")))
canvas.create_window((0,0), window=frame, anchor="nw")
canvas.configure(yscrollcommand=scroll.set)
canvas.pack(side="left", fill="both", expand=True)
scroll.pack(side="right", fill="y")

canvas.bind_all("<MouseWheel>", on_mousewheel)

load_wallpapers(conf["dir"])
root.mainloop()

wallpaper_path = wp_var.get()
subprocess.run([wal, wallpaper_path])
