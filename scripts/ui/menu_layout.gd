extends RefCounted
# The same rectangles drive drawing, pointer hit testing and keyboard/gamepad activation.
static func items(game: Node) -> Array:
	if game.mode=="level_select":
		var cards=[]
		var ids=["iron_factory","spillway","redrock"]
		var titles=["01 钢铁突围","02 暴雨水坝","03 赤岩瀑布"]
		var details=["工业前哨 · 核心突入","雷闸行动","断崖要塞"]
		for i in range(3):
			# Manual mission selection is open; campaign completion remains separate.
			cards.append({"rect":Rect2(50+i*300,175,260,175),"title":titles[i],"detail":details[i],"action":ids[i],"enabled":true})
		cards.append({"rect":Rect2(300,420,360,52),"title":"返回主菜单","action":"menu","enabled":true})
		return cards
	var primary="开始行动";var action="factory"
	if game.mode=="paused":primary="继续游戏";action="resume"
	elif game.mode=="dead":primary="从检查点重试" if game.checkpoint else "重新挑战";action="retry"
	elif game.mode=="won":
		primary="进入第二关" if game.level.id=="iron_factory" else "进入第三关" if game.level.id=="spillway" else "重玩第三关";action="next" if game.level.id!="redrock" else "retry_full"
	var result=[{"rect":Rect2(260,265,440,65),"title":primary,"action":action,"enabled":true},{"rect":Rect2(260,345,440,60),"title":"行动设置" if game.mode!="won" else "返回关卡选择","action":"settings" if game.mode!="won" else "select","enabled":true}]
	if game.mode=="menu" or game.mode=="paused":result.append({"rect":Rect2(300,428,360,42),"title":"关卡选择","action":"select","enabled":true})
	return result
static func activate(game: Node,action: String):
	game.clear_input();game.menu_selection=0
	match action:
		"factory","iron_factory":game.start_level("iron_factory")
		"spillway":game.start_level("spillway")
		"redrock":game.start_level("redrock")
		"resume":game.mode="playing"
		"retry":game.reset_game(game.checkpoint)
		"retry_full":game.reset_game()
		"next":game.start_level("spillway" if game.level.id=="iron_factory" else "redrock",game.debug_run or game.replay.enabled)
		"select":game.leave_to_selection()
		"menu":game.mode="menu"
		"settings":game.settings_return=game.mode;game.mode="settings"
static func draw(view: Node,game: Node):
	var title={"menu":"钢 铁 突 围","paused":"已 暂 停","dead":"任 务 失 败","won":"第三关完成" if game.level.id=="redrock" else "第二关完成" if game.level.id=="spillway" else "第一关完成","level_select":"选 择 行 动"}.get(game.mode,"")
	view.label(Vector2(265,150 if game.mode=="level_select" else 170),title,40,Color("84e4d7"))
	if game.mode!="level_select":view.label(Vector2(270,215),"IRON BREAKOUT / "+game.level.title,20,Color("9db1c6"))
	var buttons=items(game)
	for i in range(buttons.size()):
		var b=buttons[i];var tint=Color("56dbea") if b.enabled else Color("536474")
		view.panel(b.rect,tint)
		if i==game.menu_selection:view.rect(Rect2(b.rect.position+Vector2(0,8),Vector2(4,b.rect.size.y-16)),tint)
		view.label(b.rect.position+Vector2(24,40 if b.rect.size.y>100 else 36),b.title,24 if b.rect.size.y>60 else 21,tint if b.enabled else Color("8995a0"))
		if b.has("detail"):view.label(b.rect.position+Vector2(24,90),b.detail,18,Color("a3b7c9"))
		if game.mode=="level_select" and i<3:view.label(b.rect.position+Vector2(24,135),"最佳 %d" % int(game.best_scores.get(["iron_factory","spillway","redrock"][i],0)),16,Color("e6be79"))
	if game.mode!="level_select":
		var y=423 if game.mode in ["menu","paused"] else 450
		view.label(Vector2(260,y),"得分 %d / 本次 %02d:%02d" % [game.score,int(game.elapsed)/60,int(game.elapsed)%60],16,Color("f2c37a"))
	view.label(Vector2(180,510),"左侧移动与瞄准 · 右侧跳跃/射击 · 右上角暂停" if OS.has_feature("android") else "A/D移动 · W瞄准 · 空格跳跃 · J射击 · ESC返回",16,Color("899fb3"))
	if game.save_error:view.label(Vector2(260,535),"进度保存失败，请保留当前游戏后重试",15,Color("ffb275"))
