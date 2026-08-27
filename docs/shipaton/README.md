# Shipaton 2026

Everything written for the [RevenueCat Shipaton 2026](https://www.shipaton.com/)
submission. Kept in the repo rather than on a desktop so it can be found again.

**Submitted 2026-08-28** — <https://devpost.com/software/sidebell>. Entries stay
editable until the deadline, **2026-09-30, 11:45pm PDT**.

| File | What it is |
|---|---|
| `devpost-sidebell.md` | The Devpost page field by field, in form order, plus the rule-by-rule compliance check |
| `devpost-story.md` | The "About the project" body, `##` headings, ready to paste |
| `peace-prize.txt` | The Peace Prize description — plain text, that field is not Markdown |
| `judges-notes.txt` | "Additional notes for the judges" |
| `devpost-thumbnail.png` | Project card image, 1500×1000 (3:2, as Devpost recommends) |
| `make-thumbnail.swift` | Generates the above. Run from the repo root: `swift docs/shipaton/make-thumbnail.swift` |
| `linkedin-en.txt` / `linkedin-zh.txt` | Launch announcement, as posted |

## Entered for

**RevenueCat Peace Prize** only. Why every other category was skipped is written
down in `devpost-sidebell.md` — read that before assuming one was overlooked.

Two are worth revisiting before 2026-09-30 if the facts change: **Grand Prize**
needs post-launch growth numbers, and **#BuildInPublic** needs public posts
tagged `#Shipaton` from during development. Neither had anything true to say on
submission day.

## Regenerating the screenshots

The rules demand at least one screenshot at **exactly 1179×2556 without device
frames**. That is an **iPhone 15 Pro** — not the 17 Pro (1206×2622) and not the
17 Pro Max the App Store screenshots use (1320×2868). Create the simulator if it
does not exist, then:

```bash
OUT="$PWD/build/shipaton" IPHONE_NAME="iPhone 15 Pro" LANGS=en DEVICES=iphone \
  ./scripts/screenshots.sh
```

The status bar's **date** follows the simulator's own system language, which
`-AppleLanguages` does not touch — an English screenshot on a simulator that was
once set to Chinese shows a Chinese date. `scripts/screenshots.sh` documents the
fix in a comment beside the `status_bar` call.

The app icon is uploaded separately, at 1024×1024:
`Sources/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png`.
