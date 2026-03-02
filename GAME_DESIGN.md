# Game Design Document — Working Title: [Unnamed]

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

## Open Questions

- [ ] Are characters 2D billboarded sprites in 3D world (Doom/Barony style) or fully 3D with painterly textures?
- [ ] Working title / game name
- [ ] Core gameplay loop (beyond the cone weapon and sky world context)
- [ ] Character: Cinder — is she the player character, an NPC, or both?
