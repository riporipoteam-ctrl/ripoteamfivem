# 🚀 Missiles vs Cities

A complete Roblox tycoon/battle game: build your city, earn cash, upgrade
rockets, blow up other players' cities — and save up **$995 Trillion** for
NUKE ACCESS to wipe someone's city off the map (once per day).

Roblox hosts the game **for free, 24/7**, publicly joinable on PC, mobile,
tablet and console.

## ✨ Features

- **5 players per server**, each with their own far-apart island — spawn, shop,
  NPCs, leaderboard and rebirth shrine are all on YOUR island (no hub, no bridges)
- **12 buildable zones** per city (Houses → Space Center), bought and
  upgraded by **stepping on pads**, with income per second and floating `+$` popups
- **Upgradeable rocket silo** (Launch / Upgrade panel) — blow up parts of other
  players' cities from a **top-down BLOW UP attack view** and steal the value
  of every building you destroy
- **☢️ Nuke Access** — buy it on the purple pad next to your own silo for $995T (in-game cash, no Robux), launch
  **one nuke per 24h**: the victim gets a flashing red alert + siren + beacon
  marking the impact spot, then a mushroom cloud flattens their whole city and
  you steal its entire worth. The city rebuilds itself over the next few minutes.
- **Shields** (block a missile), **Barrage** (3 rockets at once), **spawn
  protection**, auto-repair and HP regen
- **Daily rewards** 7-day streak calendar (Day 7 = FREE NUKE), free gift every
  15 minutes, gem shop
- **Leaderstats** (Cash / City Worth), chunky cartoon UI, sound effects, music,
  camera shake, explosions, debris — the works
- **Data saving** via DataStores (cash, gems, buildings, rocket level, nuke
  access, streaks, rebirths, cosmetics, quest progress)
- **NPCs on YOUR island** (real Roblox avatars with dialogue): Benny the Shopkeeper (shop stand), Tilly the
  Tailor (character shop: speed/jump boosts, titles, rainbow trail), plus
  **quest givers** Mayor Penny (building quests) and General Boom (combat
  quests) — with endless repeatable end-quests
- **16 building types** now (up to the Golden Tower at $28Qa) and a
  **🌟 Rebirth Shrine**: reset your city for a permanent, stacking income
  multiplier — the game literally never ends
- **Random world events**: Cash Frenzy, Gem Rain, Meteor Showers, Supply Drops
- **Global leaderboard on every island**: Richest Cities of All Time (saved
  across all servers)
- **Small citizen avatars** walking the roads of every active city, volumetric clouds,
  and SFX on every interaction (buttons, panels, dialogue typewriter, quests,
  events, purchases, explosions...)

## 🆕 Big update: economy, air war & events

- **Start from $0** — your first House is FREE; everything after costs cash.
- **Collect-to-earn**: income piles up over each building (green $ float).
  Walk onto a building to collect it, or buy **Auto-Collect** (War panel) to
  bank it automatically.
- **Island expansion**: unlock new areas one pad at a time as you can afford them.
- **Rockets grow**: each rocket upgrade makes your silo rocket bigger and
  changes its colours; buy up to **3 silos** (fire more per launch).
- **✈️ Airport & Jets**: build the Airport, buy **hangars**, upgrade jets, then
  send them to **bomb a city** or **bomb rocket silos** (knocks the victim's
  rockets offline for a while).
- **🛡️ Air Defense**: turrets on your island that can shoot down incoming
  missiles and jets — upgrade for a higher intercept chance.
- **🚀 Missile Battery**: buy a small side-island of BIG silos. One BLOW UP
  button rains a random volley across the target's whole city (long reload,
  upgradeable).
- **📹 Missile Cam**: when you launch, ride a camera behind your missile and
  watch it strike — or hit SKIP.
- **👥 Living cities**: more citizens and cars appear as your city grows; being
  bombed costs you **population and cash**, and the attacker earns the value of
  what they destroy.
- **👨‍✈️ The Pilot event** (airport owners): an old cropduster radios in low on
  fuel. **Accept** for a big payout (he lands, refuels, thanks you, takes off)
  or **decline** and risk him crashing into your city.
- **🎲 More random events** + **randomized daily rewards** (fresh set each week).
- **🛠️ Admin Panel**: the game owner (and any UserIds in `Config.Admins`) get a
  gold badge button with moderation/testing tools.
- **Real Roblox SFX**, chill music, new sky, and a redesigned UI + notifications
  that scale for **PC, mobile and console**. Missile aiming is now pixel-accurate
  on touch and mouse.

## 🕹️ How to publish (10 minutes, free)

1. Install **Roblox Studio** (free): https://create.roblox.com
2. Download `MissilesVsCities.rbxlx` from this repo and double-click it — it
   opens directly in Studio.
3. **File → Publish to Roblox** → give it a name → Publish.
4. In Studio: **Home → Game Settings → Security** → enable
   **"Allow Studio Access to API Services"** (this makes saving work).
5. In **Game Settings → Basic Info** set **Max Players = 5** (the file
   requests this already, but confirm it here).
6. In **Game Settings → Permissions** set the experience to **Public** so
   anyone can join.
7. Press **Play** in Studio to test, then share your game's link!

## 🔧 Tweaking the game

Every balance number lives in `src/shared/Config.luau`: nuke price and
cooldown, rocket damage/cost curves, building income, daily rewards, shop
prices, etc.

- **2X CASH / 2X DAMAGE buttons**: create two Game Passes for your experience
  on the Roblox site, then put their IDs into `Config.GamePassCash2x` /
  `Config.GamePassDamage2x`.
- **Music / sounds**: edit `src/shared/SoundBook.luau`.
- **Buildings**: edit `src/shared/BuildingDefs.luau`.

## 🛠️ Developer workflow (optional)

The source is a standard [Rojo](https://rojo.space) project
(`default.project.json`). If you edit the `.luau` files, rebuild the place
file with:

```
python3 tools/build_place.py
```

or sync live into Studio with `rojo serve`.

## 📁 Layout

```
src/shared/   Config, building definitions, number formatting, world layout,
              remotes, sounds (used by both server and client)
src/server/   World generation, plots/buildings, economy, combat (missiles +
              nukes), daily rewards, DataStore persistence
src/client/   HUD, side buttons, rocket panel, attack view, daily rewards UI,
              alarms, explosion/nuke FX, cash popups, music
```
