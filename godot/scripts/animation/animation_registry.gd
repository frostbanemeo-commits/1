extends RefCounted
class_name AnimationRegistry

# ═══════════════════════════════════════════════════════════════════
#  Animation Registry
#
#  All character animations live here with a unique string ID.
#
#  Two access tiers:
#    CINEMATIC — triggered by the narrative/cutscene system only.
#                Never surfaced to the player. The player cannot
#                call these even if they appeared in a cutscene.
#
#    EMOTE     — player-accessible in 3rd person mode only.
#                Appear in the emote selection menu.
#                Never play during cutscenes (different call path).
#
#    GAMEPLAY  — driven by movement/state (run, jump, glide, blast).
#                Neither player-callable nor cutscene-assigned —
#                the state machine controls these automatically.
# ═══════════════════════════════════════════════════════════════════

enum AccessTier {
	CINEMATIC = 0,   # narrative system only — invisible to player
	EMOTE     = 1,   # player-callable in 3rd person
	GAMEPLAY  = 2,   # state-machine driven — not manually triggered
}


# ── Animation definitions ─────────────────────────────────────────
# id:           unique string — used by all call sites
# tier:         AccessTier (controls who can trigger it)
# anim_path:    AnimationPlayer track name (matches .glb / AnimationTree)
# duration:     seconds (informational — actual length lives in the clip)
# interruptible: can another animation cut this one short?
# emote_label:  display name shown in player emote menu (EMOTE tier only)
# emote_icon:   icon resource path (EMOTE tier only)

const ANIMATIONS: Dictionary = {

	# ── Cinematic ─────────────────────────────────────────────────
	# Opening sequence
	"cin_crash_landing": {
		"tier": AccessTier.CINEMATIC,
		"anim_path": "CinCrashLanding",
		"duration": 4.2,
		"interruptible": false,
	},
	"cin_chains_standing": {
		"tier": AccessTier.CINEMATIC,
		"anim_path": "CinChainsStanding",
		"duration": 0.0,   # idle loop — held until cutscene advances
		"interruptible": false,
	},
	"cin_eyes_open": {
		"tier": AccessTier.CINEMATIC,
		"anim_path": "CinEyesOpen",
		"duration": 1.1,
		"interruptible": false,
	},
	"cin_reflex_blast": {
		"tier": AccessTier.CINEMATIC,
		"anim_path": "CinReflexBlast",
		"duration": 0.8,
		"interruptible": false,
		# The blast that breaks the rack — introduced as pure instinct
	},
	"cin_collapse": {
		"tier": AccessTier.CINEMATIC,
		"anim_path": "CinCollapse",
		"duration": 1.6,
		"interruptible": false,
	},
	"cin_carried_out": {
		"tier": AccessTier.CINEMATIC,
		"anim_path": "CinCarriedOut",
		"duration": 3.0,
		"interruptible": false,
	},
	"cin_waking_on_deck": {
		"tier": AccessTier.CINEMATIC,
		"anim_path": "CinWakingOnDeck",
		"duration": 2.4,
		"interruptible": false,
	},
	"cin_look_at_hands": {
		"tier": AccessTier.CINEMATIC,
		"anim_path": "CinLookAtHands",
		"duration": 3.5,
		"interruptible": false,
		# → transitions into character customisation
	},

	# ── Gameplay (state-machine driven) ───────────────────────────
	"gp_idle": {
		"tier": AccessTier.GAMEPLAY,
		"anim_path": "Idle",
		"duration": 0.0,   # loop
		"interruptible": true,
	},
	"gp_run": {
		"tier": AccessTier.GAMEPLAY,
		"anim_path": "Run",
		"duration": 0.0,
		"interruptible": true,
	},
	"gp_jump": {
		"tier": AccessTier.GAMEPLAY,
		"anim_path": "Jump",
		"duration": 0.5,
		"interruptible": true,
	},
	"gp_air_jump": {
		"tier": AccessTier.GAMEPLAY,
		"anim_path": "AirJump",
		"duration": 0.4,
		"interruptible": true,
	},
	"gp_glide": {
		"tier": AccessTier.GAMEPLAY,
		"anim_path": "Glide",
		"duration": 0.0,   # loop while held
		"interruptible": true,
	},
	"gp_land": {
		"tier": AccessTier.GAMEPLAY,
		"anim_path": "Land",
		"duration": 0.3,
		"interruptible": true,
	},
	"gp_blast": {
		"tier": AccessTier.GAMEPLAY,
		"anim_path": "Blast",
		"duration": 0.6,
		"interruptible": true,   # can move while blasting
	},
	"gp_fall": {
		"tier": AccessTier.GAMEPLAY,
		"anim_path": "Fall",
		"duration": 0.0,
		"interruptible": true,
	},

	# ── Emotes (player-callable, 3rd person only) ─────────────────
	"em_look_around": {
		"tier": AccessTier.EMOTE,
		"anim_path": "EmoteLookAround",
		"duration": 2.8,
		"interruptible": true,
		"emote_label": "Look Around",
		"emote_icon": "res://assets/icons/emote_look_around.png",
	},
	"em_stretch": {
		"tier": AccessTier.EMOTE,
		"anim_path": "EmoteStretch",
		"duration": 3.1,
		"interruptible": true,
		"emote_label": "Stretch",
		"emote_icon": "res://assets/icons/emote_stretch.png",
	},
	"em_sit": {
		"tier": AccessTier.EMOTE,
		"anim_path": "EmoteSit",
		"duration": 0.0,   # held until cancelled
		"interruptible": true,
		"emote_label": "Sit",
		"emote_icon": "res://assets/icons/emote_sit.png",
	},
	"em_crouch_look": {
		"tier": AccessTier.EMOTE,
		"anim_path": "EmoteCrouchLook",
		"duration": 0.0,
		"interruptible": true,
		"emote_label": "Crouch Look",
		"emote_icon": "res://assets/icons/emote_crouch_look.png",
	},
	"em_hand_out": {
		"tier": AccessTier.EMOTE,
		"anim_path": "EmoteHandOut",
		"duration": 2.0,
		"interruptible": true,
		"emote_label": "Reach Out",
		"emote_icon": "res://assets/icons/emote_hand_out.png",
	},
	"em_kneel": {
		"tier": AccessTier.EMOTE,
		"anim_path": "EmoteKneel",
		"duration": 0.0,
		"interruptible": true,
		"emote_label": "Kneel",
		"emote_icon": "res://assets/icons/emote_kneel.png",
	},
	"em_look_at_sky": {
		"tier": AccessTier.EMOTE,
		"anim_path": "EmoteLookAtSky",
		"duration": 3.5,
		"interruptible": true,
		"emote_label": "Look at Sky",
		"emote_icon": "res://assets/icons/emote_look_at_sky.png",
		# Cinder looking up at what she can't reach — resonant given the curse
	},
}


# ── API ───────────────────────────────────────────────────────────

## Returns the definition dict for a given animation ID.
static func get_anim(id: String) -> Dictionary:
	return ANIMATIONS.get(id, {})


## Returns all EMOTE animations — for populating the player emote menu.
static func get_emotes() -> Array:
	var result := []
	for id in ANIMATIONS:
		if ANIMATIONS[id]["tier"] == AccessTier.EMOTE:
			result.append({"id": id, "data": ANIMATIONS[id]})
	return result


## Returns true if this ID can be triggered by the player.
## Cinematic and gameplay IDs always return false.
static func is_player_callable(id: String) -> bool:
	var anim := ANIMATIONS.get(id, {})
	return anim.get("tier", -1) == AccessTier.EMOTE


## Returns true if this ID is a valid cinematic animation.
static func is_cinematic(id: String) -> bool:
	var anim := ANIMATIONS.get(id, {})
	return anim.get("tier", -1) == AccessTier.CINEMATIC
