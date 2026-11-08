extends RefCounted
# A single continuous level; distance and arena coordinates have one source of truth.
const LENGTH=37600.0
const GROUND=435.0
const CHECKPOINT_X=35700.0
const BOSS_TRIGGER=35900.0
const BOSS_LEFT=35750.0
const BOSS_POSITION=Vector2(36950,230)
const GATE_X=37160.0
const SECTORS=[preload("res://resources/encounters/sector1.tres"),preload("res://resources/encounters/sector2.tres"),preload("res://resources/encounters/sector3.tres")]
const FACTORY=preload("res://resources/levels/iron_factory.tres")
# Compatibility facade for older first-level diagnostics; runtime uses game.level.
static func sector(x: float) -> Resource:return FACTORY.section(x)
static func platforms() -> Array:return FACTORY.all_platforms()
static func arenas() -> Array:return FACTORY.arenas()
static func music_for_x(x: float) -> String:return FACTORY.music_for_x(x)
