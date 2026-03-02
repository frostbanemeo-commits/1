# Game Design Document — Working Title: [Unnamed]
## Logline

Cinder was cursed by the Emperor and stripped of her ability to fly. Now she navigates a world of procedural sky islands — by skyship, by hover, by sheer will — to reach the heart of the evil empire and reclaim the Holy Stone that will restore what was taken from her.

## Platform

- **Primary:** PC / Steam
- **Secondary (later):** Samsung Z Fold 4 (Android / Google Play)

---

## Engine

**Godot 4**

- Handles voxel/chunky 3D world geometry
- Supports 2D decal projection onto 3D surfaces (blood system)
- Exports to PC and Android
- Free and open source

---

## Visual Style

### World / Environment
- Dense voxel aesthetic
- Chunky low-poly geometry
- Heavy, atmospheric, readable
- References: **Shadows of Doubt**, **Barony**

### Characters
- Hyper-detailed illustrated / painterly art
- Reference: Cinder character art
- Rendered as **3D objects** in the voxel world
- High detail characters contrast against chunky world geometry — intentional

### Items & Objects
- 3D, consistent with world geometry

---

## Blood System

### How it works
1. Character or object takes damage
2. Blood particle emits from wound (3D)
3. Particle travels and hits nearest surface (wall, floor, object)
4. On contact — converts to **2D decal** stamped onto that surface
5. Stain persists based on player settings

### Why this works
- Godot 4 decal system projects 2D textures onto 3D geometry natively
- Keeps world geometry clean (no 3D blood meshes cluttering voxel space)
- Visual contrast: 3D world + 2D blood feels deliberate and stylized

---

## Options System

Options menu built early so every system plugs into it.

### Blood & Gore Options
| Setting | Values |
|---|---|
| Blood Effects | Off / Minimal / On |
| Stain Persistence | Disappear instantly / Fade over time / Stay forever |
| Splatter Intensity | Low / Medium / High / Extreme |
| Blood Color | Red / Black / Fantasy (for non-human enemies) |
| Decal Limit | Max number of stains before oldest are removed (performance) |

### Planned Option Categories
- Visual (resolution, quality, FOV)
- Audio (master, music, SFX, ambient)
- Controls (keybindings, sensitivity)
- Accessibility
- Blood & Gore (above)
- Gameplay

---

## Core Narrative

### Protagonist — Cinder
- Formerly able to fly freely
- Cursed — her flight is now broken, reduced to limited hover and limited jumps
- The curse is not just story — it IS the gameplay limitation the player feels every moment
- Goal: reach the Holy Stone held by the Emperor to heal herself and fly again

### The Curse as Mechanic
- Hover bar depleting = the curse draining her
- Counting jumps = something stolen from her
- The mechanical frustration IS the emotional story

### The Emperor
- Primary antagonist — holds the Holy Stone
- Rules an evil empire spread across the sky islands
- Final destination of the journey — heart of the empire

### The Baron
- Secondary antagonist — lord serving the Emperor
- Cruel and evil
- Commanded the agents who captured Cinder
- Was transporting Cinder to the Emperor aboard his personal skyship
- Escapes/survives the opening — becomes the recurring threat across the mid-game
- The face of the empire the player will hate before ever meeting the Emperor

### Opening Cinematic Sequence
```
1. Cinder — cursed, flight failing — crashes onto the starter island
2. Local villagers find her, take her in, begin nursing her back to health
3. Cinder is comatose. Completely helpless.
4. Empire agents learn she is there — arrive on the island
5. Agents confiscate her. She cannot resist. Put in chains.
6. Taken aboard The Baron's skyship.
7. The Baron intends to deliver her to the Emperor.
8. [ESCAPE — TBD] ← player takes control here
```

### The Escape — The Baron's Ship, 3am

**Setup:**
- Cinder is chained upright on a standing rack in a holding room below deck
- The Baron has been gloating over her unconscious body — cruel, smug, alone with his prize
- 3am — shift change. Skeleton crew. Most soldiers asleep.

**The Pirate Attack:**
- Pirates have learned The Baron captured something valuable
- They choose the shift change at 3am deliberately — maximum vulnerability
- An infiltrator slips belowdecks ahead of the main assault
- Finds the room. Finds Cinder chained to the rack.
- Reaches for her to free her—

**The Blast:**
- Cinder's eyes snap open — disoriented, terrified, dark room, stranger's face
- Pure instinct. The cone blast fires.
- The infiltrator is thrown. The room explodes outward.
- Alarms. Shouting. The whole ship erupts into chaos.
- Outside — the pirate assault begins under cover of the explosion.

**Why this works:**
- The cone blast is introduced as reflex — something Cinder *is*, not something she chose
- The chains crack / rack partially breaks — she has limited movement
- The pirate battle raging on deck covers her escape
- Tutorial starts mid-chaos: half-freed, 3am, pirates vs empire soldiers everywhere
- The Baron survives — escapes in the chaos, furious, humiliated

**After the Blast:**
- Cinder fires — and collapses unconscious again. The blast took everything left in her.
- Pirates flood the room, cut her free from the rack, carry her out
- On deck: the pirate captain is trading blows directly with The Baron
- The captain holds him — then swings back to the pirate ship at the last moment
- The Baron's ship burning behind them as they pull away into the dark
- The Baron screaming curses into the smoke — alive, furious, humiliated

**The Following Morning — Character Customization:**
- Cinder wakes on the deck of the pirate ship
- Morning light. Open sky. She is free for the first time since the curse.
- She looks at her hands. Looks at herself.
- → **CHARACTER CUSTOMIZATION begins here**
- Framing: the player is not in a menu — Cinder is on this deck, in this body, deciding who she is now
- Pirates nearby — curious, giving her space
- The captain is the first person she will speak to when customization ends

**Why this structure works:**
- Cinder is unconscious or helpless for the entire cinematic — player has no agency yet, only witness
- First agency = the blast (reflex, uncontrolled)
- Second agency = character customization (identity, intentional)
- The pirates earn trust through action before a single word is spoken

### World Structure (narrative axis)
```
[Outer islands — weak empire presence, early game]
        ↓
[Mid islands — empire patrols, skyship blockades]
        ↓
[Empire territory — fortified, dangerous, late game]
        ↓
[Heart of the empire — Emperor, Holy Stone, final confrontation]
```

### Skyship Traversal
- Primary means of island-to-island travel
- Cinder is never fully safe without her ship
- Ships can potentially be attacked, boarded, or destroyed
- Every gap between islands without a ship is a risk decision

### Movement — Cinder
- Limited hover (resource bar — recharge rules TBD)
- Limited jumps (count resets on landing)
- No freeform flight (cursed)
- Void below islands = death or significant consequence

---

## Perspective System

### Camera Modes
- **First Person** and **Third Person** both fully supported
- Toggled freely from the options menu at any time
- Both are complete playstyles — neither is secondary

### Fixed Perspective Moments (not toggleable)
| Moment | Perspective | Reason |
|---|---|---|
| Opening cinematic | First person | Narrative immersion — you are trapped in Cinder's experience |
| Character customization | Third person | You must be able to see her |
| After customization | Player choice | Default: third person, changeable any time |

### What Changes Between Perspectives
| Element | First Person | Third Person |
|---|---|---|
| Cone blast aim | Fires where you look | Aimed separately from movement |
| Camera | Cinder's eyes | Behind / above Cinder |
| Hover | Felt, not seen | Visible animation |
| Island gaps | Imposing, harder to judge | More readable distances |
| Combat | Visceral, close | Spatial, readable |
| Controls | Look = aim | Move and aim decoupled |

### What Stays Identical
- All mechanics (hover bar, jump count, blast, movement)
- All systems (blood, options, progression)
- World, enemies, story — no content differences

---

## Open Questions

- [ ] Are characters 2D billboarded sprites in 3D world (Doom/Barony style) or fully 3D with painterly textures?
- [ ] Working title / game name
- [ ] Cinder's curse — is it publicly known or is she a stranger to the world?
- [ ] The infiltrator — the pirate who first reached Cinder on the rack. Identity? Fate after the blast?
- [ ] The pirate captain — name, design, personality. First speaking character Cinder meets.
- [ ] The Baron — does he have a name? What makes him personally cruel (backstory)?
- [ ] The starter island villagers — do any become recurring characters / allies?
- [ ] Character customization scope — appearance only? Name? Background/origin?
- [ ] Hover recharge rules — ground only? Over time? Resource-based?
- [ ] Jump count — how many? Double jump? Resets on landing only?
- [ ] Fall into the void — instant death or long fall with consequence?
- [ ] Partial healing — does Cinder recover fragments of flight as she progresses?
- [ ] Skyships — can they be destroyed? Stolen? Multiple ships?
- [ ] Empire presence — random patrols or structured faction system?
