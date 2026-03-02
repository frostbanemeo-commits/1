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
- 3D voxel objects, consistent with world geometry

---

## Voxel World System

### Core Principle — Teardown Style
Every object in the world is built from small colored voxel blocks.
No polygon meshes with textures — color is baked directly into each voxel.
Everything is potentially destructible. The cone blast carves real geometry.

**Reference:** Teardown (voxel destruction), MagicaVoxel (asset authoring)
**Engine addon:** godot-voxel (Zylann) for terrain chunks and LOD
**Asset format:** .vox (MagicaVoxel) for structures and objects

### Voxel Scale
- Each voxel ≈ 0.1m cube — fine enough to feel physical, coarse enough to perform
- Islands are voxel terrain chunks, procedurally generated
- Structures authored in MagicaVoxel, placed on islands

### Full Material Registry

#### Forces (destruction sources)
| Force | Source |
|---|---|
| Cone Blast | Cinder's weapon |
| Fire | Burning, spreads to flammable materials |
| Physical | Collision, fall impact |
| Explosion | Barrel chain reactions, ruby bursts |
| Empire Weapon | Enemy attacks |
| Void | Lore / special — bypasses most immunity |

#### Reactions
| Reaction | Meaning |
|---|---|
| IMMUNE | Zero effect — not even a scratch |
| RESISTANT | Partial damage, cannot fully destroy |
| NORMAL | Standard destruction at rated hardness |
| WEAK | Extra vulnerable — destroyed at low power |
| INSTANT | Destroyed immediately, power irrelevant |
| REACTIVE | Triggers secondary effect (explosion, fire spread) |

---

#### Natural
| Material | Hardness | Cone Blast | Notable |
|---|---|---|---|
| Soil | 0.05 | NORMAL | Soft, scatters |
| Sand | 0.02 | NORMAL | Very soft |
| Grass | 0.02 | NORMAL | Surface layer |
| Gravel | 0.15 | NORMAL | Scatters in chunks |

#### Organic
| Material | Hardness | Cone Blast | Notable |
|---|---|---|---|
| Wood | 0.20 | **INSTANT** | Blast destroys completely. Flammable. |
| Bark | 0.15 | **INSTANT** | Flammable |
| Leaves | 0.00 | **INSTANT** | Flammable |
| Wildflower | 0.00 | **INSTANT** | Decorative scatter |
| Vine | 0.05 | **INSTANT** | Flammable |
| Root | 0.25 | WEAK | Harder than surface wood |

#### Stone
| Material | Hardness | Cone Blast | Notable |
|---|---|---|---|
| Limestone | 0.45 | NORMAL | Mid-tier |
| Granite | 0.75 | **RESISTANT** | Blast bounces off, needs explosion |
| Marble | 0.55 | NORMAL | Shatters beautifully |
| Sandstone | 0.35 | NORMAL | Crumbles |
| Basalt | 0.85 | **RESISTANT** | Toughest natural stone |

#### Ruby Civilization
| Material | Hardness | Cone Blast | Notable |
|---|---|---|---|
| Ruby Sphere | 0.35 | **REACTIVE** | Crimson voxel explosion. Emissive. |
| Ruby Inlay | 0.30 | **REACTIVE** | Embedded in marble |
| Ancient Tile | 0.50 | NORMAL | Floor/wall decoration |
| Ancient Pillar | 0.65 | NORMAL | Structural ruin element |
| Glowstone | 0.40 | **REACTIVE** | Ancient light source. Emissive. |

#### Sacred / Indestructible
| Material | Cone Blast | All Forces | Lore |
|---|---|---|---|
| **Ancient Temple Block** | **IMMUNE** | **IMMUNE** | Predates ruby civilization. Nothing breaks it. |
| Void Stone | RESISTANT | RESISTANT | Empire-quarried, near-indestructible |
| Heart Stone | **IMMUNE** | **IMMUNE** | Pulses. Connected to the Holy Stone. |
| Cursed Iron | **IMMUNE** | **IMMUNE** | Cinder's chains. Only unlocked, never broken. |

#### Empire
| Material | Hardness | Cone Blast | Notable |
|---|---|---|---|
| Empire Iron | 0.80 | NORMAL | Hard, heavy |
| Empire Plating | 0.92 | **RESISTANT** | Reinforced armour |
| Empire Treated Wood | 0.45 | NORMAL | Fire-resistant treatment |
| Empire Glass | 0.05 | **INSTANT** | Shatters dramatically |
| Explosive Barrel | 0.10 | **REACTIVE** | Chain detonation, 4m radius |

#### Ship
| Material | Hardness | Cone Blast | Notable |
|---|---|---|---|
| Ship Hull Plank | 0.30 | NORMAL | Flammable |
| Ship Rope | 0.00 | **INSTANT** | Snaps immediately |
| Ship Sail | 0.00 | **INSTANT** | Tears immediately |
| Ship Iron Fitting | 0.65 | NORMAL | Structural |

#### Environmental
| Material | Hardness | Cone Blast | Notable |
|---|---|---|---|
| Ice | 0.10 | WEAK | Slippery surface effect |
| Snow | 0.00 | **INSTANT** | Puffs away |
| Ash | 0.00 | **INSTANT** | Scatters in wisps |
| Ember | 0.00 | **INSTANT** | Damages on contact. Emissive. |

### Destruction
- **Cone blast** excavates voxels in the cone volume — carves real holes in geometry
- Destroyed voxels scatter as physics debris briefly, then despawn
- Destruction is persistent within a session
- Different materials require different blast power to destroy (tunable)
- Blasting island edges enough could collapse sections — environmental hazard

### Why This Works for This Game
- The cone blast becomes **visually readable** — you see the hole it makes
- Ruby spheres exploding into crimson voxels = immediately satisfying
- Marble columns shattering = the world feels ancient and breakable
- Empire structures resisting the blast = communicates danger before combat
- Wildflowers scattered by a blast = even beauty is fragile here

### Island Aesthetic — The Ruby Civilization
The sky islands are ruins of an ancient civilization. Nature has reclaimed them.
Every island tells the story of something lost.

**Wildflowers**
- Dense, colorful, growing through everything
- Chaotic and alive — contrast against dead stone
- The world is beautiful even in decay

**Ancient Marble**
- Columns, archways, plazas, cracked tile floors
- A civilization built here once — grand and deliberate
- Now broken, overgrown, silent

**The Ruby Sphere Civilization**
- The ancient people built with red ruby spheres — their defining material
- Spheres appear as architecture, inlays, free-standing objects, buried fragments
- Some still pulse faintly — residual energy, not fully dead
- The empire is actively excavating and collecting them
- Scattered across every island — common enough to be worldbuilding, rare enough to matter

**A typical island surface reads:**
```
Wildflowers pushing through cracked marble tiles
A broken column — ruby inlays still glowing faintly
Red spheres half-buried in soil at the island's edge
Vines over an archway that once marked something sacred
Empire crates nearby — they've been here, taking what they can
```

**The implied history:**
- The ruby civilization once controlled the sky islands
- Something ended them — unknown, possibly connected to the Emperor
- The Holy Stone the Emperor holds may be the last great ruby artifact
- Cinder's curse and the civilization's fall may be connected

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
- **Jump limit: 1** base — one jump, must land to reset
- **Glide: hold jump after all jumps spent** — no bar, no energy limit
- Gravity itself is the limiter — you are still falling, just slowly
- No freeform flight (cursed)
- Void below islands = death or significant consequence

### Strength Fragments
- Collectible items found in the world (ruins, hidden spots, enemy drops)
- Each fragment grants **+1 mid-air jump** permanently
- **Hard cap: 5 total jumps** (1 ground + 4 mid-air = 4 fragments max)
- The extra jumps are mid-air only — first jump is always a ground jump
- Ties into the ruby civilization lore (fragments of ancient power)
- Progression feels earned — the world gives back what the curse took

### Jump Progression
| Fragments | Total Jumps | Final Action (always) |
|---|---|---|
| 0 | 1 | Press jump again → **GLIDE** |
| 1 | 2 | Press jump again → **GLIDE** |
| 2 | 3 | Press jump again → **GLIDE** |
| 3 | 4 | Press jump again → **GLIDE** |
| 4 | 5 (MAX) | Press jump again → **GLIDE** |

### Glide (always available — base mechanic)
- **Glide is always the final action** after all current jumps are spent
- Fragments give more jumps *before* glide — not a requirement to unlock it
- **Activated:** press jump when airborne with no jumps remaining
- **Sustained:** hold jump to maintain glide
- **Cancel:** release jump — normal fall resumes
- No energy bar — gravity is the only limiter (you are still descending)
- Horizontal momentum fully preserved + slight speed boost
- She is still falling. Still cursed. Still not flying.
- Resets on landing alongside jumps

---

## Cone Blast

Cinder's primary weapon. First introduced as pure reflex in the opening cinematic.

### Behaviour
- **Origin:** fires from screen center (camera crosshair) forward
- **Shape:** pierces as a tight point at origin, expands as a cone over distance
- **Radius growth:** `BASE_RADIUS × (1.0 + 0.15 × (distance / 60m))`
  - Base radius ≈ 0.31m (π × 0.1) at origin — nearly a pierce
  - ≈ 0.36m at 60m — visibly wider at range
- **Falloff:** hard cutoff at **60 metres**
- **Damage:** linear falloff — high near origin, lower at range
- **Knockback:** strong near, reduced at range
- **Cooldown:** 1.2 seconds between blasts
- **Deduplication:** a target is hit once per blast regardless of cone overlap

### Feel
- Near targets: devastating, high damage, strong knockback
- Far targets: pushes and weakens, rarely kills outright
- The cone shape rewards closing distance — Cinder is not a sniper

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
- [ ] The ruby civilization — what ended them? Is it connected to the Emperor or the curse?
- [ ] Is the Holy Stone the last great ruby artifact from the old civilization?
- [ ] Do the ruby spheres have mechanical function (power sources, puzzle elements, upgrades)?
- [ ] Working title / game name
- [ ] Cinder's curse — is it publicly known or is she a stranger to the world?
- [ ] The infiltrator — the pirate who first reached Cinder on the rack. Identity? Fate after the blast?
- [ ] The pirate captain — name, design, personality. First speaking character Cinder meets.
- [ ] The Baron — does he have a name? What makes him personally cruel (backstory)?
- [ ] The starter island villagers — do any become recurring characters / allies?
- [ ] Character customization scope — appearance only? Name? Background/origin?
- [ ] Cone blast visual FX — what does the expanding cone look like as it travels?
- [ ] Jump count — how many? Double jump? Resets on landing only?
- [ ] Fall into the void — instant death or long fall with consequence?
- [ ] Partial healing — does Cinder recover fragments of flight as she progresses?
- [ ] Skyships — can they be destroyed? Stolen? Multiple ships?
- [ ] Empire presence — random patrols or structured faction system?
