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
- Antagonist — holds the Holy Stone
- Rules an evil empire spread across the sky islands
- Final destination of the journey

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

## Open Questions

- [ ] Are characters 2D billboarded sprites in 3D world (Doom/Barony style) or fully 3D with painterly textures?
- [ ] Working title / game name
- [ ] Cinder's curse — is it publicly known or is she a stranger to the world?
- [ ] Hover recharge rules — ground only? Over time? Resource-based?
- [ ] Jump count — how many? Double jump? Resets on landing only?
- [ ] Fall into the void — instant death or long fall with consequence?
- [ ] Partial healing — does Cinder recover fragments of flight as she progresses?
- [ ] Skyships — can they be destroyed? Stolen? Multiple ships?
- [ ] Empire presence — random patrols or structured faction system?
