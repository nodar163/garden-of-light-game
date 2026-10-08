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
	map=preload("res://scripts/estate_map.gd").new(); map.house=house; map.reduced=game.store.data.settings.reduce_motion; map.garden=ui.g(); map.english=ui.english(); map.size_flags_vertical=Control.SIZE_EXPAND_FILL; map.custom_minimum_size.y=320; game.root_box.add_child(map)
	map.selected.connect(details); map.entrance.connect(enter)
	var row:=HBoxContainer.new(); game.root_box.add_child(row)
	game.button("−",func(): map.magnify(1/1.4),row); game.button(words("Обзор","Overview"),func(): map.zoom=1; map.center=Vector2(.5,.5); map.refresh(),row); game.button("+",func(): map.magnify(1.4),row)
	game.label(words("Развитие: %d / 2000 · Монеты: %d","Development: %d / 2000 · Coins: %d") % [Rules.progress(ui.g()),ui.g().coins],23)
	game.button(words("В усадьбу","Estate") if house else words("В центральный сад","Central garden"),func(): open(false) if house else ui.show())
	if Rules.complete(ui.g()): game.label(words("Золотой садовник: все уровни и ремонты завершены!","Golden Gardener: all levels and repairs completed!"),25)
	# Final honour is deliberately separate from functional upgrades.
	game.label(words("Звание садовника: уровни %d/2000","Gardener honour: levels %d/2000") % ui.g().earned.size(),21) if not Rules.complete(ui.g()) else null
	var guide: String="house" if house else "estate"
	if preload("res://scripts/tutorial.gd").seen(game.store.data,guide): game.tutorial.maybe_open("living_garden")
	else: game.tutorial.maybe_open(guide)
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
	game.label(Rules.benefit(ui.g(),id/4,ui.english())+words(". Каждые 4 этапа ремонта комнаты усиливают её пользу.",". Every 4 room repair stages increase its benefit."),25) if house else game.label(words("Восстанови это место и выбери его цветочное оформление.","Restore this place and choose its floral colours."),27)
	var art:=TextureRect.new(); var atlas:=AtlasTexture.new()
	atlas.atlas=load("res://assets/"+("house" if house else "estate")+("-restored.png" if t==3 else "-abandoned.png"))
	if house and t==3:
		var chosen: int=int(ui.g().get("estate_styles",{}).get(Rules.key(house,id),0))
		if chosen>0: atlas.atlas=load("res://assets/house-"+("rose" if chosen==1 else "lavender")+".png")
	var uv: Vector2=(Rules.HOUSE_POINTS if house else Rules.LAND_POINTS)[id]
	atlas.region=Rect2((uv-Vector2(.10,.12)).clamp(Vector2.ZERO,Vector2(.80,.76))*atlas.atlas.get_size(),Vector2(.20,.24)*atlas.atlas.get_size()); art.texture=atlas
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE; art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED; art.custom_minimum_size.y=250; art.size_flags_vertical=Control.SIZE_EXPAND_FILL; game.root_box.add_child(art)
	game.label(words("Этапы: уборка → восстановление → украшение","Stages: tidy → restore → decorate")+" · %d/3" % t,25)
	if t<3:
		var need:=Rules.required(house,id,t+1); var price:=Rules.price(t+1)
		game.label(words("Развитие: %d/%d\nЦена: %d · у тебя: %d монет","Development: %d/%d\nCost: %d · you have: %d coins") % [Rules.progress(ui.g()),need,price,ui.g().coins],26)
		var b: Button=game.button(words(["Убрать","Восстановить","Украсить"][t],["Tidy up","Restore","Decorate"][t]),func():
			if game.store.garden_transaction(func(g): return Rules.upgrade(g,house,id)):
				open(house); map.focus_area(id)
			else: game.label(words("Не удалось сохранить ремонт.","Could not save the repair."),24),null,true)
		b.disabled=Rules.progress(ui.g())<need or int(ui.g().coins)<price or 0 not in ui.g().repairs
		if Rules.progress(ui.g())<need:
			game.label(words("Победа +1 · продажа +3 · каждые 2 цветка урожая +1.","Win +1 · sale +3 · every 2 harvested flowers +1."),22)
			game.button(words("Выбрать занятие","Choose an activity"),ui.requests.activities)
	else:
		game.label(words("Оформление можно менять бесплатно","Change the finish for free"),26)
		var styles:=HBoxContainer.new(); game.root_box.add_child(styles)
		for choice in 3:
			var selected: bool=int(ui.g().get("estate_styles",{}).get(Rules.key(house,id),0))==choice
			game.button(words(["Классика","Розы","Лаванда"][choice],["Classic","Rose","Lavender"][choice]),func():
				if game.store.garden_transaction(func(g): return Rules.choose(g,house,id,choice)):
					open(house); map.focus_area(id)
				else: game.label(words("Не удалось сохранить оформление.","Could not save colours."),23),styles,selected)
	game.button(words("Назад к карте","Back to the map"),func(): open(house); map.focus_area(id))
