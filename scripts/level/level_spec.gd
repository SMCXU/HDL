extends Resource
# Runtime world configuration. The first level is migrated without changing coordinates.
@export var vertical=false
@export var moving_data: Array[Dictionary]=[]
@export var rock_data: Array[Dictionary]=[]
@export var branch_routes: Array[PackedVector2Array]=[]
@export var allow_platform_drop=true
# Explicit solid exceptions; floor_rects always stay solid.
@export var solid_platforms: Array[Rect2]=[]
@export var play_left=20.0
@export var play_right=-1.0
@export var world_top=-1900.0
@export var boss_trigger_zone=Rect2()
@export var height_ends=PackedFloat32Array()
@export var checkpoint_ids=PackedStringArray()
@export var id="iron_factory"
@export var title="钢铁突围"
@export var length=37600.0
@export var ground=435.0
@export var spawn=Vector2(100,435)
@export var boss_checkpoint=Vector2(35700,435)
@export var boss_trigger=35900.0
@export var boss_left=35750.0
@export var boss_position=Vector2(36950,230)
@export var gate_x=37160.0
@export var sectors: Array[Resource]=[]
@export var floor_rects: Array[Rect2]=[]
@export var extra_platforms: Array[Rect2]=[]
@export var pickup_data: Array[Dictionary]=[]
@export var boss_supply=Vector2.ZERO
@export var pickup_points=PackedVector2Array()
@export var checkpoint_points=PackedVector2Array()
@export var encounter_data: Array[Dictionary]=[]
@export var target_data: Array[Dictionary]=[]
@export var hazard_data: Array[Dictionary]=[]
@export var climb_route=PackedVector2Array()
@export var music_tracks=PackedStringArray(["level","workshop","core","boss"])
func section(x: float) -> Resource:
	for spec in sectors:
		if x<spec.end_x:return spec
	return sectors[-1]
func music_for_x(x: float) -> String:
	for i in range(sectors.size()):
		if x<sectors[i].end_x:return music_tracks[mini(i,music_tracks.size()-2)]
	return music_tracks[-2]
func all_platforms() -> Array:
	var result=[]
	for spec in sectors:result.append_array(spec.platforms)
	result.append_array(extra_platforms)
	result.append_array(solid_platforms)
	return result
func arenas() -> Array:
	if not encounter_data.is_empty():return encounter_data.duplicate(true)
	var result=[]
	for section_index in range(sectors.size()):
		var spec=sectors[section_index]
		for i in range(spec.arena_bounds.size()):
			var points=[]
			var types=[]
			for j in range(3):
				points.append(spec.enemy_positions[i*3+j]);types.append(spec.enemy_types[i*3+j])
			result.append({"id":"factory_%02d" % result.size(),"left":spec.arena_bounds[i].x,"right":spec.arena_bounds[i].y,"positions":points,"types":types,"sector":section_index,"last_in_sector":i==spec.arena_bounds.size()-1})
	return result

func section_index_at(position: Vector2) -> int:
	if vertical:
		var height=spawn.y-position.y
		for i in range(height_ends.size()):
			if height<height_ends[i]:return i
		return sectors.size()-1
	for i in range(sectors.size()):
		if position.x<sectors[i].end_x:return i
	return sectors.size()-1
func section_at(position: Vector2) -> Resource:return sectors[section_index_at(position)]
func music_at(position: Vector2) -> String:return music_tracks[mini(section_index_at(position),music_tracks.size()-2)]
