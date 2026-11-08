extends SceneTree
## Reproducible density/safe-area derivatives of the original generated artwork.
func _initialize():
	var original = Image.load_from_file("res://source_assets/branding/armored-helmet-source.png")
	assert(original != null and original.get_width() == original.get_height())
	original.convert(Image.FORMAT_RGBA8)
	var main = original.duplicate()
	main.resize(1024, 1024, Image.INTERPOLATE_LANCZOS)
	assert(main.save_png("res://assets/branding/app-icon.png") == OK)
	main.resize(192, 192, Image.INTERPOLATE_LANCZOS)
	assert(main.save_png("res://assets/branding/launcher-main.png") == OK)
	var foreground = Image.create(432, 432, false, Image.FORMAT_RGBA8)
	foreground.fill(Color.TRANSPARENT)
	var content = original.duplicate()
	content.resize(288, 288, Image.INTERPOLATE_LANCZOS)
	foreground.blit_rect(content, Rect2i(0, 0, 288, 288), Vector2i(72, 72))
	assert(foreground.save_png("res://assets/branding/launcher-foreground.png") == OK)
	var background = Image.create(432, 432, false, Image.FORMAT_RGBA8)
	background.fill(original.get_pixel(0, 0))
	assert(background.save_png("res://assets/branding/launcher-background.png") == OK)
	# Launcher mask simulation: visible adaptive viewport is 72/108 of full layer.
	var combined = background.duplicate()
	combined.blend_rect(foreground, Rect2i(0, 0, 432, 432), Vector2i.ZERO)
	var crop = combined.get_region(Rect2i(72, 72, 288, 288))
	var sheet = Image.create(768, 320, false, Image.FORMAT_RGBA8)
	sheet.fill(Color("182436"))
	for index in range(3):
		var tile = crop.duplicate()
		tile.resize(216, 216, Image.INTERPOLATE_LANCZOS)
		for y in range(216):
			for x in range(216):
				var point = Vector2(x + 0.5, y + 0.5) - Vector2(108, 108)
				var outside = point.length() > 108 if index == 0 else (pow(abs(point.x) / 108, 4) + pow(abs(point.y) / 108, 4) > 1)
				if index == 2: outside = false
				if outside: tile.set_pixel(x, y, Color.TRANSPARENT)
		var pos = Vector2i(20 + index * 256, 16)
		sheet.blend_rect(tile, Rect2i(0, 0, 216, 216), pos)
		tile.resize(48, 48, Image.INTERPOLATE_LANCZOS)
		sheet.blend_rect(tile, Rect2i(0, 0, 48, 48), pos + Vector2i(84, 246))
	assert(sheet.save_png("res://docs/evidence/branding/launcher-mask-preview.png") == OK)
	print("ICON_DERIVATIVES_OK: legacy192 adaptive432 safe288; preview circle/squircle/square +48px")
	quit()
