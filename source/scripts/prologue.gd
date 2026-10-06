extends Control
const Garden=preload("res://scripts/garden_rules.gd")
const Farm=preload("res://scripts/garden_farm.gd")
const Room=preload("res://scripts/prologue_room.gd")
const Landscape=preload("res://scripts/story_landscape.gd")
const Preview=preload("res://scripts/illustrated_preview.gd")
class MemoryStore extends RefCounted:
	var data: Dictionary
	func garden_transaction(action: Callable) -> bool: return bool(action.call(data.garden))
var host: Control
var store:=MemoryStore.new()
var sound: Node
var replay:=false
var step:=0
var body: VBoxContainer
var room: Control
var next_button: Button
var hint: Label
func words(ru: String,en: String) -> String: return host.words(ru,en)
func _ready() -> void:
	size_flags_vertical=SIZE_EXPAND_FILL; size_flags_horizontal=SIZE_EXPAND_FILL
	sound=host.sound
	step=0 if replay else int(host.store.data.garden.get("prologue_step",0))
	show_step()
func text(value: String,font_size: int=25) -> Label:
	var label:=Label.new(); label.text=value; label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size",font_size); label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	body.add_child(label); return label
func show_step() -> void:
	for child in get_children(): remove_child(child); child.queue_free()
	room=null
	body=VBoxContainer.new(); body.set_anchors_and_offsets_preset(PRESET_FULL_RECT); body.add_theme_constant_override("separation",14); add_child(body)
	text(words("ВОСПОМИНАНИЕ · ","A MEMORY · ")+str(step+1)+" / 7",20)
	var titles: Array=[words("Когда сад был полон жизни","When the garden was full of life"),words("Цветы для Анны","Flowers for Anna"),words("Наш первый букет","Our first bouquet"),words("Обычный счастливый день","An ordinary happy day"),words("Ночь, изменившая всё","The night everything changed"),words("Утро после бури","The morning after"),words("Начнём заново","We will start again")]
	text(titles[step],32)
	if step in [1,2]:
		store.data={"garden":Garden.defaults(),"settings":host.store.data.settings.duplicate(true)}
		Garden.Story.ensure(store.data.garden); Farm.ensure(store.data.garden)
		store.data.garden.repairs=[0,1,2,3,4]
		if step==2: store.data.garden.farm.stock[0]=3
		room=Room.new(); room.game=self; room.mode="nursery" if step==1 else "shop"
		room.size_flags_vertical=SIZE_EXPAND_FILL; room.size_flags_horizontal=SIZE_EXPAND_FILL
		body.add_child(room)
		hint=text("",24); hint.custom_minimum_size.y=100
		room.guidance_changed.connect(func(value): hint.text=value)
		room.lesson_changed.connect(func(): next_button.disabled=not room.finished())
		room.update_guidance()
		text(words("Перетащи предмет или коснись предмета и места.","Drag an object, or tap the object and its destination."),19)
	else:
		var scene:=Landscape.new(); scene.ruined=step>=5; scene.storm=step==4; scene.reduced=host.store.data.settings.reduce_motion
		scene.size_flags_vertical=SIZE_EXPAND_FILL; body.add_child(scene)
		if step!=4:
			var people:=HBoxContainer.new(); people.set_anchors_and_offsets_preset(PRESET_BOTTOM_WIDE); people.offset_top=-210; people.mouse_filter=MOUSE_FILTER_IGNORE; scene.add_child(people)
			for id in ([0,4] if step in [0,3,5] else [0]):
				var portrait:=Preview.new(); portrait.kind="person"; portrait.variant=id; portrait.size_flags_horizontal=SIZE_EXPAND_FILL; portrait.custom_minimum_size.y=210; people.add_child(portrait)
		var ru: Array=["Джек: «Это наш сад. Я выращиваю цветы, а Лилия помогает в лавке. Сегодня очередь с самого утра! Анна ждёт букет для мамы. Поможешь?»","","","Анна уходит с букетом, следующий покупатель подходит к кассе.\nЛилия: «Ещё немного — и откроем большой магазин!»\nДжек: «Главное, чтобы людям хотелось возвращаться». Эти монеты и цветы — часть воспоминания.","К вечеру ветер усилился. Джек и Лилия успели укрыться в доме. Ночью буря повредила теплицу, лавку и клумбы. Никто не пострадал, но сад пришлось закрыть.","Лилия: «Все наши планы рухнули. Я не хочу снова считать каждую монету. Я ухожу».\nДжек: «Я не могу тебя удержать. Но сад я не брошу».\nОна уезжает. На столе остаётся записка Анны: «Мы будем ждать твоих цветов».","Джек: «Я ещё покажу, чего стою. Но сначала — один живой уголок».\nУцелели семена и 50 монет. Проходи уровни, восстанавливай здания и возвращай покупателей. Мы снова соберём букет для Анны."]
		var en: Array=["Jack: ‘This is our garden. I grow the flowers, and Lily helps in the shop. People have been lining up all morning! Anna needs flowers for Mum. Will you help?’","","","Anna leaves with her bouquet and the next customer steps forward.\nLily: ‘Soon we can open a bigger shop!’\nJack: ‘As long as people want to come back.’ These coins and flowers belong to the memory.","The wind rose that evening. Jack and Lily reached the cottage safely. Overnight, the storm damaged the greenhouse, shop and flowerbeds. Nobody was hurt, but the garden had to close.","Lily: ‘Our plans are gone. I don't want to count every coin again. I'm leaving.’\nJack: ‘I can't make you stay. But I won't abandon the garden.’\nShe leaves. Anna's note remains: ‘We'll be waiting for your flowers.’","Jack: ‘I'll show what I can do. But first, one living corner.’\nSome seeds and 50 coins survived. Play levels, restore the buildings and bring customers back. We will make another bouquet for Anna."]
		text(words(ru[step],en[step]),24)
	next_button=host.button(words("В огород","To the nursery") if step==0 else words("В магазин","To the shop") if step==1 else words("Начать восстановление","Start rebuilding") if step==6 else words("Продолжить","Continue"),advance,body,true)
	next_button.custom_minimum_size.y=88
	if room: next_button.disabled=not room.finished()
	var skip: Button=host.button(words("Вернуться в игру","Return to the game") if replay else words("Пропустить предысторию","Skip the prologue"),finish,body)
	skip.custom_minimum_size.y=84
func advance() -> void:
	if room and not room.finished(): return
	if step==6: finish(); return
	var next:=step+1
	if not replay and not host.store.garden_transaction(func(data): data.prologue_step=next; return true):
		next_button.text=words("Не сохранилось · повторить","Not saved · retry"); return
	step=next; show_step()
func finish() -> void:
	if replay: host.garden_ui.replay=false; host.show_home(); return
	if not host.store.garden_transaction(func(data): data.prologue_step=6; data.intro_done=true; data.intro_step=3; return true):
		next_button.text=words("Не сохранилось · повторить","Not saved · retry"); return
	host.show_home()
