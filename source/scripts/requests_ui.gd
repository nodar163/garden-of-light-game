extends RefCounted
const Rules=preload("res://scripts/garden_requests.gd")
const Farm=preload("res://scripts/garden_farm.gd")
var ui: RefCounted
var game: Control
func _init(owner_ui: RefCounted) -> void: ui=owner_ui; game=ui.game
func show() -> void:
	game.clear_page("requests"); game.header(game.words("ИСТОРИИ ПОКУПАТЕЛЕЙ","CUSTOMER STORIES"))
	var s:=Rules.state(ui.g()); var id:=int(s.next)
	if id>=Rules.REQUESTS.size():
		game.label(game.words("Восемь историй стали частью сада. Спасибо! Покупатели продолжают приходить, а письма можно перечитать.","Eight stories became part of the garden. Thank you! Customers keep coming, and their letters are here to reread."),30)
	else:
		var r: Array=Rules.REQUESTS[id]; var en: bool=ui.english()
		game.label(str(r[1 if en else 0])+" · %d/8" % (id+1),32)
		game.label(str(r[(7 if en else 6) if s.ready else (5 if en else 4)]),28)
		var preview:=preload("res://scripts/illustrated_preview.gd").new(); preview.kind="bouquet"; preview.flowers=[]
		for i in int(r[3]): preview.flowers.append(int(r[2]))
		preview.custom_minimum_size.y=220; preview.size_flags_vertical=Control.SIZE_EXPAND_FILL; game.root_box.add_child(preview)
		if s.ready:
			game.button(game.words("Прочитано · забрать 60 монет","Read · collect 60 coins"),func():
				if game.store.garden_transaction(Rules.claim): show()
				else: game.label(game.words("Не удалось сохранить. Попробуй снова.","Could not save. Please try again."),24),null,true)
		else:
			var species: Array=Farm.SPECIES[int(r[2])]
			game.label(game.words("Собери и продай: %d × %s.\nПодарок за историю: 60 монет. Срока нет.","Make and sell: %d × %s.\nStory gift: 60 coins. No deadline.") % [r[3],species[1 if en else 0]],26)
			var enough: bool=int(ui.g().farm.stock[int(r[2])])>=int(r[3])
			game.button(game.words("Собрать в магазине","Make it in the shop") if enough else game.words("Вырастить цветы","Grow the flowers"),ui.business.shop if enough else ui.business.nursery,null,true)
	var history:=OptionButton.new(); history.custom_minimum_size.y=100; history.add_theme_font_size_override("font_size",26); history.add_item(game.words("Письма соседей","Neighbours' letters"),-1)
	for i in id: history.add_item(str(Rules.REQUESTS[i][1 if ui.english() else 0]),i)
	history.item_selected.connect(func(index):
		if index>0: letter(history.get_item_id(index)))
	game.root_box.add_child(history)
	game.button(game.words("В сад","Garden"),ui.open_garden)
func letter(id: int) -> void:
	game.clear_page("customer_letter"); game.header(str(Rules.REQUESTS[id][1 if ui.english() else 0]))
	game.label(str(Rules.REQUESTS[id][7 if ui.english() else 6]),32); game.spacer()
	game.button(game.words("К заказам","Back to requests"),show)

func activities() -> void:
	game.clear_page("activities"); game.header(game.words("ЧЕМ ЗАЙМЁМСЯ?","WHAT SHALL WE DO?"))
	game.label(game.words("Выбери занятие по настроению. Всё помогает восстановить сад.","Choose what you feel like doing. It all helps restore the garden."),30)
	game.label(ui.task_title()+"\n"+ui.task_detail(),26)
	game.spacer()
	game.button(game.words("Уровни · +1 развитие, +25 монет впервые","Levels · +1 progress, +25 coins on first win"),ui.modes,null,true)
	game.button(game.words("Огород · +1 развитие за 2 цветка","Nursery · +1 progress per 2 harvested flowers"),ui.business.nursery)
	game.button(game.words("Магазин · +3 развитие за букет","Shop · +3 progress per bouquet"),ui.business.shop)
	game.button(game.words("Заказ и письмо · подарок 60 монет","Request and letter · 60 coin gift"),show)
	game.button(game.words("Вернуться в сад","Return to the garden"),ui.open_garden)
