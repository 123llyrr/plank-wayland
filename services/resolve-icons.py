#!/usr/bin/env python3
import os
import sys

EXTENSIONS = {".svg", ".png", ".xpm"}


def icon_dirs(theme):
    home = os.environ.get("HOME", "")
    bases = [
        os.path.join(home, ".icons"),
        os.path.join(home, ".local", "share", "icons"),
        "/usr/local/share/icons",
        "/usr/share/icons",
    ]
    return [os.path.join(base, theme) for base in bases if theme and os.path.isdir(os.path.join(base, theme))]


def inherited_themes(theme):
    for directory in icon_dirs(theme):
        index_path = os.path.join(directory, "index.theme")
        if not os.path.isfile(index_path):
            continue

        in_icon_theme = False
        try:
            with open(index_path, "r", encoding="utf-8", errors="ignore") as file:
                for raw_line in file:
                    line = raw_line.strip()
                    if line == "[Icon Theme]":
                        in_icon_theme = True
                        continue
                    if line.startswith("["):
                        in_icon_theme = False
                    if in_icon_theme and line.startswith("Inherits="):
                        return [name.strip() for name in line.split("=", 1)[1].split(",") if name.strip()]
        except OSError:
            pass
    return []


def theme_chain(theme):
    result = []
    queue = [theme] if theme else []
    seen = set()

    while queue:
        current = queue.pop(0)
        if not current or current in seen:
            continue
        seen.add(current)
        result.append(current)
        queue.extend(inherited_themes(current))

    if "hicolor" not in seen:
        result.append("hicolor")
    return result


def candidate_score(path):
    parts = path.split(os.sep)
    ext = os.path.splitext(path)[1].lower()
    score = 0

    if ext == ".svg":
        score += 100000
    elif ext == ".png":
        score += 50000

    if "scalable" in parts:
        score += 40000

    if "symbolic" in path.lower():
        score -= 20000

    for part in parts:
        size = part.split("x", 1)[0]
        if size.isdigit():
            score += min(int(size), 512)

    return score


def resolve(theme, icons):
    requested = {icon for icon in icons if icon}
    best = {}

    for icon in requested:
        if os.path.isabs(icon) and os.path.isfile(icon):
            best[icon] = (10**9, icon)

    missing = requested - set(best.keys())
    if not missing:
        return {icon: best[icon][1] for icon in requested}

    for theme_name in theme_chain(theme):
        for directory in icon_dirs(theme_name):
            for root, dirs, files in os.walk(directory):
                dirs[:] = [name for name in dirs if not name.startswith(".")]
                for filename in files:
                    name, ext = os.path.splitext(filename)
                    if name not in missing or ext.lower() not in EXTENSIONS:
                        continue

                    path = os.path.join(root, filename)
                    score = candidate_score(path)
                    if name not in best or score > best[name][0]:
                        best[name] = (score, path)

    return {icon: best.get(icon, (0, ""))[1] for icon in requested}


def main():
    theme = sys.argv[1] if len(sys.argv) > 1 else ""
    icons = sys.argv[2:]
    resolved = resolve(theme, icons)
    for icon in icons:
        print(f"{icon}\t{resolved.get(icon, '')}")


if __name__ == "__main__":
    main()
