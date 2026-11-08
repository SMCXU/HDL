extends RefCounted
const FACTORY=preload("res://resources/levels/iron_factory.tres")
static func get_level(id: String) -> Resource:
	if id=="redrock":return load("res://resources/levels/redrock.tres")
	if id=="spillway":return load("res://resources/levels/spillway.tres")
	return FACTORY
