# 🐉 rde_farming

[![Version](https://img.shields.io/badge/version-1.0.0-red?style=for-the-badge)](https://github.com/RedDragonElite/rde_farming)
[![License](https://img.shields.io/badge/license-RDE%20Black%20Flag-black?style=for-the-badge)](https://github.com/RedDragonElite/rde_farming/blob/main/LICENSE)
[![FiveM](https://img.shields.io/badge/FiveM-Compatible-blue?style=for-the-badge)](https://fivem.net)
[![ox_core](https://img.shields.io/badge/Framework-ox__core-blue?style=for-the-badge)](https://github.com/overextended/ox_core)
[![Dynamic](https://img.shields.io/badge/Areas-Fully%20Dynamic-green?style=for-the-badge)](https://github.com/RedDragonElite/rde_farming)
[![Quality](https://img.shields.io/badge/Quality-Production-gold?style=for-the-badge)](https://github.com/RedDragonElite)

**🌿 RDE FARMING | Dynamic Resource Gathering for FiveM ox_core | Full In-Game Admin CRUD | Proximity Prop Streaming | StateBag Sync | Tool Requirements | Animations | Auto-Respawn | Production-Ready**

*Built by [Red Dragon Elite](https://rd-elite.com) | Free Forever | No Paywalls | No Legacy*

[📖 Installation](#-installation) • [⚙️ Configuration](#️-configuration) • [🎬 Animations](#-animation-library) • [🌍 Locales](#-locales) • [📡 Events](#-events) • [🐛 Troubleshooting](#-troubleshooting) • [🌐 Website](https://rd-elite.com)

---

## 🔥 Why This Destroys Every Other Farming Script

Every other farming resource ships with hardcoded coordinates in a config file, 50 dependencies, and zero flexibility. Want to add a new mining spot? Edit Lua, restart server, pray. Want to move a spot? Same pain.

We said no.

| ❌ Other Farming Scripts | ✅ rde_farming |
|---|---|
| Coords hardcoded in config | 100% dynamic — all areas & spots live in the DB |
| Restart required to add spots | In-game Admin CRUD — create, edit, move, delete, toggle live |
| All props always loaded | Proximity streaming — props only exist within 150m |
| One animation fits all | 10 built-in animation keys, all customizable, fully extensible |
| No tool requirement | Per-area tool item required to harvest (or none at all) |
| Instant respawn | Configurable respawn timer per area, server-scheduled |
| No anti-exploit | Rate limiting, distance validation, server-side inventory give |
| One language | EN / DE out of the box, add more in minutes |
| ESX / QBCore bloat | ox_core native — clean, modern, fast |

---

### 🎯 Key Features

- 🌿 **Fully Dynamic Areas** — every farming area is created and managed in-game via the admin menu. No config restarts ever
- 📍 **Proximity Prop Streaming** — resource props only spawn clientside within `Config.LoadRadius` (default 150m). Hysteresis band prevents pop-in. Zero network overhead for distant spots
- 📡 **StateBag Sync** — `GlobalState[rde_farm_area_*]` and `GlobalState[rde_farm_spot_*]` keep every client in sync in real time. New players joining mid-session get the full state immediately
- 🎬 **Animation Library** — 10 pre-built harvest animations (pickaxe, axe, shovel, hands, knife, crouch, fish, bottle, plant, hammer). Admin picks a key. Add your own freely in `data/animations.lua`
- 🔧 **Tool Requirements** — each area can require a specific `ox_inventory` item. No item = blocked with a notification. Optional — leave blank for no requirement
- 🎁 **Tool Hand Props** — while harvesting, a 3D prop attaches to the player's right hand bone. Per-animation, or overridden per-area. Full offset & rotation control
- 🔄 **Auto-Respawn** — depleted spots are queued server-side with a per-area timer. Spot goes ghosted/transparent on depletion, disappears, reappears on respawn
- 🎲 **Random Gather Amounts** — configurable min/max per area. Each harvest rolls in that range
- 🏗️ **Admin CRUD** — in-game menu for create / edit / move center / toggle active / delete areas. No `/setcoords` nonsense — stand where you want and confirm
- 🔐 **Dual Permission System** — ACE permission + ox_core group check. Configurable
- 🛡️ **Anti-Exploit** — server-side distance validation, per-player per-spot harvest cooldown, rate limiting, server-side item give via ox_inventory
- 🗺️ **Map Blips** — optional per-area minimap blip, toggleable by admin
- 🌍 **Multilanguage** — EN / DE included. Full locale system, add any language in minutes

---

## 📸 Screenshots

https://github.com/user-attachments/assets/f9921af9-35b0-4cf3-8de6-a21bcc6513b1

> Coming soon — drop a PR with your screenshots!

---

## 📦 Dependencies

```
ox_lib        → https://github.com/overextended/ox_lib
ox_core       → https://github.com/overextended/ox_core
ox_inventory  → https://github.com/overextended/ox_inventory
ox_target     → https://github.com/overextended/ox_target
oxmysql       → https://github.com/overextended/oxmysql
```

---

## 🚀 Installation

### Step 1: Clone or download

```bash
cd resources
git clone https://github.com/RedDragonElite/rde_farming.git
```

### Step 2: Add to server.cfg

```
# Dependencies first — order matters!
ensure oxmysql
ensure ox_lib
ensure ox_core
ensure ox_inventory
ensure ox_target

# The farming system
ensure rde_farming
```

### Step 3: Configure

Open `config.lua` and adjust to your server. Sensible defaults work out of the box.

### Step 4: Start and create your first area

Start your server. **No SQL import needed** — both tables are created automatically on first boot.

Then in-game, run `/farmadmin` (or whatever you bind the admin command to), stand where you want the center of a farming area to be, and hit **Create Farming Area**. That's it. Live, immediately, no restart.

> ℹ️ **Required items** (e.g. `pickaxe`, `iron_ore`) must exist in your `ox_inventory` items file. rde_farming only checks counts and gives items — it doesn't define them.

---

## ⚙️ Configuration

`config.lua` is self-documented. Key sections:

### Core

```lua
Config.Debug  = false
Config.Locale = 'en'   -- 'en' or 'de'
```

### Admin Permissions

```lua
Config.AllowAcePermissions = true   -- also check ACE 'command' and 'admin'

Config.AdminGroups = {
    ['admin']      = true,
    ['superadmin'] = true,
    ['owner']      = true,
    ['moderator']  = true,
}
```

### Proximity Loading

```lua
Config.LoadRadius    = 150.0   -- props spawn within this distance (meters)
Config.UnloadRadius  = 170.0   -- props despawn beyond this (hysteresis band, no pop-in)
Config.ProximityTick = 1500    -- ms between proximity checks per client
```

### Timing

```lua
Config.HarvestCooldown   = 3000   -- ms between harvests on the same spot per player
Config.RespawnCheckTick  = 5000   -- ms: server polls the respawn queue this often
Config.AnimationDuration = 4000   -- ms: default harvest animation length
Config.PropFadeTick      = 100    -- ms: depleted prop fade-out speed
```

### Gather Amounts

```lua
Config.DefaultGatherMin = 1   -- global default minimum items per harvest
Config.DefaultGatherMax = 3   -- global default maximum items per harvest
-- Per-area overrides are set in the admin menu when creating/editing an area
```

### Visuals

```lua
Config.Colors = {
    adminOutline  = { r = 255, g = 60, b = 60 },  -- red outline on depleted spots (admin view)
    depletedAlpha = 80,                              -- ghosted alpha on depleted props
    areaBlip = { sprite = 280, color = 2, scale = 0.6 },
}

Config.ShowBlips    = true
Config.BlipLabel    = 'Farming Area'
Config.RandomRotateZ = true  -- randomize prop Z rotation for natural variety
```

---

## 🏗️ In-Game Admin Menu

Open with the `farmadmin` command (ACE `command`/`admin` or configured ox_core group).

### What you can do

| Action | Description |
|---|---|
| **Create Farming Area** | Opens input dialog. Stand at the desired center. Confirm coords. Props are auto-generated within the spawn radius immediately |
| **Manage Areas** | Lists all existing areas with status badge (✅ Active / ⏸ Inactive) |
| **Edit Area** | Change any property: name, prop model, tool, animation, reward, limits, respawn time |
| **Move Center Here** | Stand anywhere and reassign the area center — spots are regenerated |
| **Toggle Active** | Instantly enable/disable an area for all players. Depleted props removed, active props re-sync |
| **Delete Area** | Removes area and all its spots from DB. Cascaded by FK. No orphaned rows |

### Per-Area Settings (set at creation or edit)

| Field | What it does |
|---|---|
| **Name** | Display name, shown in admin menus and blip label |
| **Prop Model** | GTA5 object model spawned at each spot (e.g. `prop_rock_3_a`, `prop_weed_01`) |
| **Required Tool Item** | `ox_inventory` item name required to harvest. Leave blank = no tool needed |
| **Tool Hand Prop** | Prop model attached to right hand during harvest animation |
| **Reward Item** | `ox_inventory` item given on successful harvest |
| **Min / Max Gather** | Random amount range per harvest |
| **Max Active Spots** | How many prop instances spawn in this area |
| **Respawn Time (s)** | How long after depletion before the spot comes back |
| **Spawn Radius (m)** | Radius around area center where spots are randomly placed |
| **Animation Key** | Key from `data/animations.lua` (e.g. `pickaxe_mine`, `axe_chop`) |
| **Show Map Blip** | Toggle minimap blip for this area |

---

## 🎬 Animation Library

Animations live in `data/animations.lua`. Admin picks a **key** in the area creation menu. Add your own — just add an entry and restart.

| Key | Description | Duration | Tool Prop |
|---|---|---|---|
| `pickaxe_mine` | Mining / pickaxe swing | 5000ms | `prop_tool_pickaxe` |
| `axe_chop` | Wood chopping | 4500ms | `prop_cs_hand_axe` |
| `shovel_dig` | Digging / burying | 5500ms | `prop_tool_shovel` |
| `hand_pick` | Bare-hand picking | 3000ms | — |
| `knife_cut` | Cutting / slicing | 3500ms | `prop_cs_knife` |
| `crouch_collect` | Crouching, picking up | 4000ms | — |
| `hand_fish` | Fishing (no rod) | 6000ms | — |
| `bottle_fill` | Filling a bottle | 4000ms | `prop_amb_whiskey_jd01a` |
| `plant_tend` | Plant care / farming | 5000ms | — |
| `hammer_work` | Hammering / crafting | 4500ms | `prop_tool_hammer` |
| `search_ground` | Scavenging / searching | 4000ms | — |

### Adding a custom animation

```lua
-- data/animations.lua — add inside the Animations table:
['my_custom_anim'] = {
    dict       = 'amb@world_human_gardener_plant@male@idle_a',
    anim       = 'idle_a',
    duration   = 4000,
    flag       = 1,              -- 1 = loop, 0 = play once, 49 = loop upper body
    toolProp   = 'prop_tool_shovel',   -- nil = no prop
    boneIndex  = 28422,          -- 28422 = right hand
    propOffset = { x = 0.0, y = 0.0, z = 0.0 },
    propRot    = { x = 0.0, y = 0.0, z = 0.0 },
},
```

Restart the resource. The key is immediately available in the admin menu dropdown.

---

## 🌍 Locales

Locale files live in `locales/`. Both `en.lua` and `de.lua` are always loaded. The active one is determined by `Config.Locale`.

```lua
Config.Locale = 'de'   -- config.lua
```

**Add a new language:**

1. Copy `locales/en.lua` → `locales/fr.lua`
2. Rename the table: `Lang_fr = { ... }`
3. At the bottom: `if Config and Config.Locale == 'fr' then Lang = Lang_fr end`
4. Add `'locales/fr.lua'` to `shared_scripts` in `fxmanifest.lua`
5. Set `Config.Locale = 'fr'`

Currently included:

| Code | Language |
|---|---|
| `en` | 🇬🇧 English |
| `de` | 🇩🇪 Deutsch |

---

## 🗃️ Database

Two tables. Both created automatically on first boot. No SQL import needed.

| Table | Purpose |
|---|---|
| `rde_farming_areas` | All farming areas — config, center coords, reward, tool, animation, limits |
| `rde_farming_spots` | All generated spots — position, rotation, depletion state, depleted timestamp |

Spots have a **cascading FK** on `area_id` — deleting an area wipes all its spots automatically. No orphaned rows, ever.

### Schema overview

```sql
rde_farming_areas:
  id, name, center_x/y/z, spawn_radius, prop_model,
  tool_item, tool_prop, anim_key, reward_item,
  gather_min, gather_max, max_spots, respawn_time,
  show_blip, is_active, created_by, created_at

rde_farming_spots:
  id, area_id (FK → areas), pos_x/y/z, rot_z,
  is_depleted, depleted_at
```

---

## 📡 Events

### Server Events (triggered from client)

```lua
-- Harvest a specific spot (validated server-side)
TriggerServerEvent('rde_farming:harvest', spotId, playerPos)

-- Admin: create a new farming area
TriggerServerEvent('rde_farming:createArea', data)

-- Admin: edit an existing area
TriggerServerEvent('rde_farming:editArea', areaId, data)

-- Admin: delete an area (cascades spots)
TriggerServerEvent('rde_farming:deleteArea', areaId)

-- Admin: toggle area active state
TriggerServerEvent('rde_farming:toggleArea', areaId)

-- Admin: move area center to new coords
TriggerServerEvent('rde_farming:setAreaCenter', areaId, newCenter)

-- Admin: regenerate all spots for an area
TriggerServerEvent('rde_farming:regenSpots', areaId)

-- Request full area + spot state (on player init)
TriggerServerEvent('rde_farming:requestAreas')

-- Client signals ready to receive initial sync
TriggerServerEvent('rde_farming:init')
```

### Client Events (triggered from server → all clients)

```lua
-- Area created or updated
AddEventHandler('rde_farming:areaUpdate', function(areaId, data) end)

-- Area deleted
AddEventHandler('rde_farming:areaDelete', function(areaId) end)

-- Spot state changed (depleted / respawned)
AddEventHandler('rde_farming:spotUpdate', function(spotId, data) end)

-- Spot permanently removed
AddEventHandler('rde_farming:spotDelete', function(spotId) end)
```

### StateBags (GlobalState)

```lua
-- Full area data for any area:
GlobalState['rde_farm_area_' .. areaId]

-- Full spot data for any spot:
GlobalState['rde_farm_spot_' .. spotId]
```

Prefix is configurable: `Config.StatebagPrefix = 'rde_farm_'`

---

## 🗂️ Folder Structure

```
rde_farming/
├── fxmanifest.lua          ← Resource manifest, dependencies
├── config.lua              ← All configuration — timing, proximity, visuals, permissions
├── data/
│   └── animations.lua      ← Animation library — all harvest animations with props & offsets
├── locales/
│   ├── en.lua              ← English strings
│   └── de.lua              ← German strings
├── client/
│   └── client.lua          ← Proximity streaming, prop spawning, ox_target, animation, admin menu
└── server/
    └── server.lua          ← DB setup, CRUD, harvest validation, respawn scheduler, StateBag sync
```

---

## 🛡️ Security

- Harvest **validated server-side** — distance check between player position and spot position
- Per-player per-spot **cooldown** enforced server-side (`HarvestCooldowns[source][spotId]`)
- Items given **server-side via ox_inventory** — client cannot fake a give
- Admin actions gated by ACE + ox_core group check — no client-side bypass possible
- **Rate limiting** built into the cooldown system — no spam-harvest exploit
- Spot depletion state managed server-side — client cannot mark a spot as available

---

## 🔧 Debug

Enable with `Config.Debug = true` in `config.lua`.

Server logs prefix: `[RDE Farming SERVER]` in green (INFO), yellow (WARN), red (ERROR).
Client logs prefix: `[RDE Farming]` in F8 console.

| What to check | Where |
|---|---|
| Tables not creating | Server console — `[RDE Farming SERVER] Database ready` |
| Props not spawning | F8 — proximity enter/exit logs, model load errors |
| Harvest rejected | Server console — distance check output, cooldown state |
| Spots not respawning | Server console — `RespawnCheckTick` fires every 5000ms |
| Admin menu not opening | Confirm ACE `command`/`admin` or correct ox_core group |
| Animation not playing | Check the key matches exactly what's in `data/animations.lua` |

---

## 🐛 Troubleshooting

### Props spawn underground or floating

The client Z-snaps spots to the ground on first render using `GetGroundZFor_3dCoord`. If you placed the area center at a Z that's far off from the actual ground, spots may take one proximity cycle to settle. This is normal. Regen spots after moving the area center for the cleanest result.

### "You need a X to harvest this" but player has the item

1. Confirm the item name in the area config exactly matches the `ox_inventory` item name (case-sensitive)
2. Confirm `ox_inventory` is started before `rde_farming`
3. Enable debug — server logs the inventory check result for every harvest attempt

### Spots never respawn

1. Enable debug — server logs every respawn queue check
2. Check `rde_farming_spots.depleted_at` in the DB — must be a valid Unix timestamp (ms)
3. Confirm `Config.RespawnCheckTick` is set (default 5000ms) and the respawn_time of the area is in **seconds**

### Admin menu shows "no areas" after restart

Areas are loaded from DB on resource start via `rde_farming:requestAreas` / `rde_farming:init`. Check server console for DB errors on startup.

### Harvest animation plays but no item given

1. Confirm the reward item exists in `ox_inventory`
2. Enable debug — server logs the `exports.ox_inventory:AddItem` call and result
3. Check `gather_min` and `gather_max` — if both are 0, no item is given

---

## 📚 Tech Stack

```
ox_core       → Player auth, group permission check
ox_lib        → Context menus, input dialogs, notifications, progress bars, lib.points
ox_inventory  → Item requirement check (tool), item give (reward)
ox_target     → Harvest interaction zone on each spawned prop
oxmysql       → Async DB — areas and spots persist across restarts
StateBags     → GlobalState sync for all area/spot state to all clients
```

---

## 🤝 Contributing

PRs are always welcome.

1. **Fork** the repository
2. **Create** a branch: `git checkout -b feature/your-feature`
3. **Test** on a live server before submitting
4. **Commit**: `git commit -m 'feat: your feature description'`
5. **Push**: `git push origin feature/your-feature`
6. **Open** a Pull Request

**Guidelines:**

- ✅ Keep the RDE header in all files
- ✅ Follow existing code style — ox_core, ox_lib, server-side authority
- ✅ Run `luac5.4 -p` on every `.lua` file before pushing
- ✅ Test on a live server
- ❌ No telemetry, no paywalls, no ESX/QBCore
- ❌ Don't move logic to client-side — harvest authority stays on server
- ❌ Don't hardcode strings — use `Lang['key']` and add to all locale files

---

## 📜 License

**RDE Black Flag Source License v6.66**

```
###################################################################################
#                                                                                 #
#       .:: RED DRAGON ELITE (RDE)  -  BLACK FLAG SOURCE LICENSE v6.66 ::.        #
#                                                                                 #
#   PROJECT:    RDE_FARMING (DYNAMIC RESOURCE GATHERING FOR FIVEM OX_CORE)        #
#   ARCHITECT:  .:: RDE ⧌ Shin [△ ᛋᛅᚱᛒᛅᚾᛁᛋ ᛒᛁᛞᛅ ▽] ::. | https://rd-elite.com     #
#   ORIGIN:     https://github.com/RedDragonElite                                 #
#                                                                                 #
#   WARNING: THIS CODE IS PROTECTED BY DIGITAL VOODOO AND PURE HATRED FOR LEAKERS #
#                                                                                 #
#   [ THE RULES OF THE GAME ]                                                     #
#                                                                                 #
#   1. // THE "FUCK GREED" PROTOCOL (FREE USE)                                    #
#      You are free to use, edit, and abuse this code on your server.             #
#      Learn from it. Break it. Fix it. That is the hacker way.                   #
#      Cost: 0.00€. If you paid for this, you got scammed by a rat.               #
#                                                                                 #
#   2. // THE TEBEX KILL SWITCH (COMMERCIAL SUICIDE)                              #
#      Listen closely, you parasites:                                             #
#      If I find this script on any paid store, Patreon, or "Premium Pack":       #
#      > I will DMCA your store into oblivion.                                    #
#      > I will publicly shame your community on Nostr. Permanently.              #
#      > I hope every farming spot you ever stand on stays depleted forever        #
#        and the respawn timer is hardcoded to infinity.                          #
#      SELLING FREE WORK IS THEFT. AND I AM THE JUDGE.                            #
#                                                                                 #
#   3. // THE CREDIT OATH                                                         #
#      Keep this header. If you remove my name, you admit you have no skill.      #
#      You can add "Edited by [YourName]", but never erase the original creator.  #
#      Don't be a skid. Respect the architecture.                                 #
#                                                                                 #
#   4. // THE CURSE OF THE COPY-PASTE                                             #
#      This code implements real proximity streaming, uniform disc spot           #
#      distribution, StateBag sync, and server-side harvest authority.            #
#      If you copy-paste without understanding, your spots will spawn in the      #
#      ocean and your players will harvest nothing forever.                        #
#      Don't come crying to my DMs. RTFM.                                         #
#                                                                                 #
#   --------------------------------------------------------------------------    #
#   "We build the future on the graves of paid resources."                        #
#   "REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY."                          #
#   --------------------------------------------------------------------------    #
###################################################################################
```

**TL;DR:**

- ✅ **Free forever** — use it, edit it, learn from it
- ✅ **Keep the header** — credit where it's due
- ❌ **Don't sell it** — commercial use = instant DMCA + permanent Nostr shaming
- ❌ **Don't be a skid** — copy-paste without reading and your spots spawn in the ocean

---

## ⚡ Related Projects

| Resource | Description |
|---|---|
| [rde_mechanic](https://github.com/RedDragonElite/rde_mechanic) | Next-Gen Vehicle Mechanic & Tuner — preview, orbit cam, StateBag sync |
| [rde_banking](https://github.com/RedDragonElite/rde_banking) | Full banking — prestige tiers, investments, loans, ATM targeting |
| [rde_aipd](https://github.com/RedDragonElite/rde_aipd) | Ultimate AI Police System — StateBag-synced, Nostr-logged |
| [rde_nostr_log](https://github.com/RedDragonElite/rde_nostr_log) | Decentralized FiveM logging via Nostr — replace Discord forever |

---

## 🌐 Community & Support

| | |
|---|---|
| 🌍 **Website** | [rd-elite.com](https://rd-elite.com) |
| 🔭 **Nostr Terminal** | [rd-elite.com/Files/NOSTR/Terminal](https://rd-elite.com/Files/NOSTR/Terminal/) |
| 🐙 **GitHub** | [github.com/RedDragonElite](https://github.com/RedDragonElite) |
| 🟣 **Nostr** | `npub1wr4e24zn6zzjqx8kvnelfvktf0pu6l2gx4gvw06zead2eqyn23sq9tsd94` |

**Before opening an issue:**

- ✅ Read this README fully
- ✅ Enable `Config.Debug = true` and include server + F8 logs
- ❌ Don't open issues without logs — we can't help without them

---

**Made with 🔥 and zero tolerance for paid farming scripts by [Red Dragon Elite](https://rd-elite.com)**

*The future is ours. We are already inside.*

**REJECT MODERN MEDIOCRITY. EMBRACE RDE SUPERIORITY.**

**RDE FOREVER. SYSTEM FAILURE. ⚡777⚡**

[![Website](https://img.shields.io/badge/Website-Visit-red?style=for-the-badge&logo=google-chrome)](https://rd-elite.com)
[![Nostr](https://img.shields.io/badge/Nostr-Follow-purple?style=for-the-badge&logo=rss)](https://primal.net/p/npub1wr4e24zn6zzjqx8kvnelfvktf0pu6l2gx4gvw06zead2eqyn23sq9tsd94)
[![Terminal](https://img.shields.io/badge/Terminal-Live-green?style=for-the-badge&logo=gnome-terminal)](https://rd-elite.com/Files/NOSTR/)
