extends RefCounted
## Optional handcrafted requests. Normal sales never block on a story requirement.
const REQUESTS=[
	["Анна · мамин день","Anna · Mum's day",0,2,"Мама вернулась домой. Хочу поставить у её окна две розовые космеи.","Mum is home again. Two pink cosmos by her window would be lovely.","Мама узнала цветы из своего детства. Теперь мы вместе гуляем в твоём саду.","Mum recognised her childhood flowers. Now we visit your garden together."],
	["Марк · первая встреча","Mark · a first date",1,2,"Я пригласил подругу на прогулку. Две ромашки — без лишней торжественности.","I invited a friend for a walk. Two daisies, nothing too formal.","Мы проговорили до вечера! Она оставила одну ромашку мне.","We talked until evening! She gave one daisy back to me."],
	["Нина · школьный праздник","Nina · the school fair",0,3,"Ребята готовят маленькую выставку. Нужны три космеи для первого стенда.","The children need three cosmos for their first exhibition stand.","Дети подписали каждый цветок. Весной хотят вырастить свои.","They labelled every flower. Next spring they want to grow their own."],
	["Олег · слова примирения","Oleg · making peace",2,2,"Мы поссорились с сестрой. Два анемона напомнят о нашем старом дворе.","My sister and I argued. Two anemones might remind her of our childhood garden.","Цветы помогли начать разговор. А извиняться пришлось самому — и правильно.","The flowers started a conversation. I still had to apologise, and I'm glad I did."],
	["София · новая библиотека","Sofia · a new library",3,2,"Для читального зала хочется чего-то воздушного. Собери две незабудки.","Two forget-me-not sprays would brighten our new reading room.","Теперь у окна читают даже те, кто раньше заходил только за книгой.","People now stay to read by the window instead of just borrowing a book."],
	["Илья · годовщина","Ilya · an anniversary",4,2,"Мы вместе сорок лет. Её любимые цветы — два ярких георгина.","Forty years together. Two bright dahlias, her favourite flowers.","Она вспомнила наш первый сад. Принесу тебе фотографию, Джек.","She remembered our first garden. I'll bring you a photograph, Jack."],
	["Лилия · честный подарок","Lily · a sincere gift",5,2,"Нужны две хризантемы. Хочу поблагодарить женщину, которая помогла мне начать заново.","Two chrysanthemums, please. I want to thank someone who helped me start again.","Я впервые выбирала цветы не ради впечатления. Спасибо, что научил слушать.","For once I wasn't trying to impress anyone. Thank you for teaching me to listen."],
	["Соседи · вечер в саду","Neighbours · a garden evening",1,3,"На общий стол поставим три ромашки. Каждый принесёт историю своего первого букета.","Three daisies for our shared table. Everyone will bring a story about their first bouquet.","Мы пришли за цветами, а нашли место, где нас знают. Этот сад уже наш общий дом.","We came for flowers and found a place where people know us. This garden feels like home."]]
static func state(g: Dictionary) -> Dictionary: return g.get("requests",{"next":0,"ready":false})
static func valid(v: Variant) -> bool:
	return v is Dictionary and typeof(v.get("next")) in [TYPE_INT,TYPE_FLOAT] and float(v.next)==int(v.next) and int(v.next)>=0 and int(v.next)<=REQUESTS.size() and v.get("ready") is bool and not (int(v.next)==REQUESTS.size() and v.ready)
static func sold(g: Dictionary,picked: Array) -> bool:
	var s:=state(g)
	if int(s.next)>=REQUESTS.size() or s.ready: return false
	var request: Array=REQUESTS[int(s.next)]
	if int(picked[int(request[2])])<int(request[3]): return false
	g.requests={"next":int(s.next),"ready":true}; return true
static func claim(g: Dictionary) -> bool:
	var s:=state(g)
	if not s.ready or int(s.next)>=REQUESTS.size(): return false
	g.coins+=60; g.requests={"next":int(s.next)+1,"ready":false}; return true
