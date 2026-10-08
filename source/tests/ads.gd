extends SceneTree
const Ads=preload("res://scripts/ad_rules.gd")
const Saves=preload("res://scripts/save_store.gd")
var checks:=0
var failures:=0
func check(value: bool,message: String) -> void:
	checks+=1
	if not value: failures+=1; push_error(message)
func _initialize() -> void:
	var d:=Saves.defaults(); d.completed=range(1,21); Saves.Garden.sync(d)
	Ads.ensure(d); check(d.ad_state.since==0 and not d.ad_state.pending,"old wins don't trigger an ad")
	for i in range(21,31): Ads.won(d,"light",i)
	check(d.ad_state.pending and d.ad_state.since==0,"tenth new win schedules ad")
	check(not Ads.won(d,"light",30),"replay doesn't count")
	var coins: int=d.garden.coins
	check(Ads.claim(d,"one","coins","light",21),"coins granted")
	check(d.garden.coins==coins+50,"exact coin reward")
	check(not Ads.claim(d,"one","coins","light",21),"duplicate reward rejected")
	check(Ads.claim(d,"two","skip","match",1),"skip succeeds")
	check(d.match3.current==2 and Ads.skipped(d,"match",1),"skip unlock recorded")
	check(d.match3.completed.is_empty() and d.garden.coins==coins+50,"skip never grants victory coins")
	check(not Ads.claim(d,"three","skip","match",1),"duplicate skip rejected")
	check(not Ads.claim(d,"four","skip","light",2),"cannot skip completed level")
	check(not Ads.claim(d,"five","skip","match",1001),"invalid level rejected")
	check(Saves.valid(JSON.parse_string(JSON.stringify(d))),"JSON roundtrip keeps ads state")
	var invalid: Dictionary=d.duplicate(true); invalid.ad_state.since=10
	check(not Saves.valid(invalid),"invalid counter rejected")
	invalid=d.duplicate(true); invalid.ad_state.skipped.match=[1.5]
	check(not Saves.valid(invalid),"fractional skip rejected")
	for i in 70: Ads.claim(d,"coin:"+str(i),"coins","light",1)
	check(d.ad_state.claims.size()==64,"claim history bounded")
	check(Saves.valid(Saves.defaults()),"legacy save stays valid")
	print("Ads checks=",checks," failures=",failures); quit(1 if failures else 0)
