extends "res://scripts/farm_world.gd"
## Guided practice uses the real room gestures against an isolated memory store.
signal lesson_changed
var lesson:=0
func expected_kind() -> String:
	return ["spade","seed","watering","bed",""][mini(lesson,4)] if mode=="nursery" else ["flower","paper","bouquet",""][mini(lesson,3)]
func finished() -> bool: return lesson>=(4 if mode=="nursery" else 3)
func endpoints() -> Array:
	if mode=="nursery":
		return [projected(TOOL_POS[0] if lesson==0 else seed_pos(0) if lesson==1 else TOOL_POS[1] if lesson==2 else BED_POS[0]),projected(TOOL_POS[2] if lesson==3 else BED_POS[0])]
	return [projected(STOCK_POS[0] if lesson==0 else paper_pos(0) if lesson==1 else DESK),projected(CASH if lesson==2 else DESK)]
func source_at(at: Vector2) -> Array:
	if finished(): return []
	var result:=super.source_at(at)
	if result.is_empty() or result[0]!=expected_kind(): return []
	if result[0] in ["bed","seed","flower","paper"] and int(result[1])!=0: return []
	return result
func perform_drop(kind: String,id: int,at: Vector2) -> bool:
	if finished() or kind!=expected_kind() or (kind in ["seed","bed","flower","paper"] and id!=0): return false
	if mode=="nursery" and lesson<3 and not near(at,BED_POS[0],1.4): return false
	var success:=super.perform_drop(kind,id,at)
	if success:
		lesson+=1
		# A clearly labelled time jump, only in the memory: normal growth is unchanged.
		if mode=="nursery" and lesson==3: g().farm.beds["0"].growth=3
		refresh(); lesson_changed.emit()
	return success
func update_guidance() -> void:
	var ru: Array=["Лопатка > верхняя левая грядка. Подготовим землю для цветов Анны.","Розовые семена слева > подготовленная грядка.","Лейка > наша грядка. Полив помогает цветам расти.","Прошло несколько дней. Цветы > корзина справа. В основной игре рост ускоряют победы.","Урожай собран! Анна ждёт букет для мамы в магазине."] if mode=="nursery" else ["Розовый цветок с витрины > букетный стол внизу.","Верхняя упаковка справа > цветок на столе.","Готовый букет > касса слева или первый покупатель.","Анна: «Мама поставит его у окна. Спасибо!» Букет продан."]
	var en: Array=["Spade > top-left bed. Prepare the soil for Anna's flowers.","Pink seeds on the left > prepared bed.","Watering can > our bed. Water helps flowers grow.","A few days later. Flowers > basket on the right. In the main game, wins help flowers grow.","Harvest collected! Anna is waiting for Mum's bouquet in the shop."] if mode=="nursery" else ["Pink flower from the display > bouquet table below.","Top wrapping paper on the right > flower on the table.","Wrapped bouquet > checkout on the left or the first customer.","Anna: ‘Mum will put it by her window. Thank you!’ Bouquet sold."]
	guidance_changed.emit(words(ru[lesson],en[lesson]))
func _draw() -> void:
	super._draw()
	if finished(): return
	var points:=endpoints()
	for at in points:
		draw_arc(at,maxf(25,size.x*.058),0,TAU,40,Color("fff0ae"),4,true)
	var direction: Vector2=(points[1]-points[0]).normalized()
	var mid: Vector2=(points[0]+points[1])*.5
	draw_line(mid-direction*16,mid+direction*16,Color("fff0ae"),4,true)
	draw_line(mid+direction*16,mid+direction.rotated(2.5)*12,Color("fff0ae"),4,true)
	draw_line(mid+direction*16,mid+direction.rotated(-2.5)*12,Color("fff0ae"),4,true)
