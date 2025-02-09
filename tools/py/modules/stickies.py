import os
import plistlib

STICKIES_DB_PATH = "/Library/Containers/com.apple.Stickies/Data/Library/StickiesDatabase"

def list_stickies():
    if not os.path.exists(STICKIES_DB_PATH):
        return "Stickies database not found."

    with open(STICKIES_DB_PATH, "rb") as f:
        data = plistlib.load(f)

    stickies = []
    for note in data.get("Notes", []):
        stickies.append({
            "title": note.get("Title", "Untitled"),
            "text": note.get("Text", "")
        })
    return stickies

def add_sticky(title, text):
    if not os.path.exists(STICKIES_DB_PATH):
        return "Stickies database not found."

    with open(STICKIES_DB_PATH, "rb") as f:
        data = plistlib.load(f)

    new_note = {"Title": title, "Text": text}
    data.setdefault("Notes", []).append(new_note)

    with open(STICKIES_DB_PATH, "wb") as f:
        plistlib.dump(data, f)
    return "Sticky note added successfully."