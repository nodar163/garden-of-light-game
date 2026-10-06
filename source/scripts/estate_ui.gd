extends RefCounted
const Rules=preload("res://scripts/estate_rules.gd")
var ui: RefCounted
var game: Control
var map: Control
var house:=false
var last_id:=-1
func _init(owner_ui: RefCounted) -> void: ui=owner_ui; game=ui.game
func words(ru: String,en: String) -> String: return game.words(ru,en)
func open(inside: bool=false) -> void:
	house=inside
	game.clear_page("house" if house else "estate"); game.header(words("ДОМ ДЖЕКА","JACK'S HOME") if house else words("БОЛЬШАЯ УСАДЬБА","THE ESTATE"))
	game.label(words("Проведи по карте · коснись предмета для ремонта","Drag to explore · tap an object to restore"),24)
	map=preload("res://scripts/estate_map.gd").new(); map.house=house; map.garden=ui.g(); map.english=ui.english(); map.size_flags_vertical=Control.SIZE_EXPAND_FILL; map.custom_minimum_size.y=320; game.root_box.add_child(map)
	map.selected.connect(details); map.entrance.connect(enter)
	var row:=HBoxContainer.new(); game.root_box.add_child(row)
	game.button("−",func(): map.magnify(1/1.4),row); game.button(words("Обзор","Overview"),func(): map.zoom=1; map.center=Vector2(.5,.5); map.refresh(),row); game.button("+",func(): map.magnify(1.4),row)
	game.label(words("Новых побед: %d / 2000 · Монеты: %d","First wins: %d / 2000 · Coins: %d") % [ui.g().earned.size(),ui.g().coins],23)
	game.button(words("В усадьбу","Estate") if house else words("В центральный сад","Central garden"),func(): open(false) if house else ui.show())
	game.tutorial.maybe_open("house" if house else "estate")
func enter(kind: String) -> void:
	match kind:
		"house":
			if 0 in ui.g().repairs: open(true)
			else: ui.select_place("repair",0)
		"nursery": ui.business.nursery()
		"shop": ui.business.shop()
		_: ui.show()
func details(id: int) -> void:
	last_id=id
	game.clear_page("estate_repair"); game.header(Rules.name_of(house,id,ui.english()))
	var t:=Rules.tier(ui.g(),house,id)
	game.label(words("Джек: Сначала приведём место в порядок, затем восстановим его и добавим последние детали.","Jack: First we tidy up, then restore it and add the finishing details."),29)
	var art:=TextureRect.new(); var atlas:=AtlasTexture.new()
	atlas.atlas=load("res://assets/"+("house" if house else "estate")+("-restored.png" if t==3 else "-abandoned.png"))
	var uv: Vector2=(Rules.HOUSE_POINTS if house else Rules.LAND_POINTS)[id]
	atlas.region=Rect2((uv-Vector2(.10,.12)).clamp(Vector2.ZERO,Vector2(.80,.76))*atlas.atlas.get_size(),Vector2(.20,.24)*atlas.atlas.get_size()); art.texture=atlas
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.custom_minimum_size.y=250; art.size_flags_vertical=Control.SIZE_EXPAND_FILL; game.root_box.add_child(art)
	game.label(words("Этапы: уборка → восстановление → украшение","Stages: tidy → restore → decorate")+" · %d/3" % t,25)
	if t<3:
		var need:=Rules.required(house,id,t+1); var price:=Rules.price(t+1)
		game.label(words("Первые победы: %d/%d\nЦена: %d · у тебя: %d монет","First wins: %d/%d\nCost: %d · you have: %d coins") % [ui.g().earned.size(),need,price,ui.g().coins],26)
		var b: Button=game.button(words(["Убрать","Восстановить","Украсить"][t],["Tidy up","Restore","Decorate"][t]),func():
			if game.store.garden_transaction(func(g): return Rules.upgrade(g,house,id)):
				open(house); map.focus_area(id)
			else: game.label(words("Не удалось сохранить ремонт.","Could not save the repair."),24),null,true)
		b.disabled=ui.g().earned.size()<need or int(ui.g().coins)<price or 0 not in ui.g().repairs
		if ui.g().earned.size()<need: game.button(words("Продолжить уровни","Play more levels"),ui.modes)
	else: game.label(words("Готово! Этот уголок снова живёт.","Finished! This corner feels alive again."),30)
	game.button(words("Назад к карте","Back to the map"),func(): open(house); map.focus_area(id))
