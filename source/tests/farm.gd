extends SceneTree

const Farm = preload("res://scripts/garden_farm.gd")
const Garden = preload("res://scripts/garden_rules.gd")
var checks := 0
var failures := 0

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func _initialize() -> void:
	var old: Dictionary = Garden.defaults()
	old.plots["0"] = 0
	old.plots["1"] = 2
	Farm.ensure(old)
	check(Farm.valid(old.farm), "old garden receives valid farm")
	check(old.farm.beds.size() == 2, "existing flowers migrate once")
	Farm.ensure(old)
	check(old.farm.beds.size() == 2, "migration is idempotent")
	var fresh: Dictionary = Garden.defaults()
	Farm.ensure(fresh)
	check(Farm.plant(fresh, 0, 0), "first cosmos is free")
	check(not Farm.plant(fresh, 0, 1), "occupied bed cannot be replaced")
	check(not Farm.plant(fresh, 1, 1), "later species has level gate")
	for i in 3: Farm.grow(fresh)
	Farm.grow(fresh)
	check(fresh.farm.beds["0"].growth == 3, "growth caps at ready stage")
	check(Farm.harvest(fresh, 0) == 2, "first harvest gives two stems")
	check(Farm.harvest(fresh, 0) == 0, "same harvest cannot repeat")
	check(fresh.farm.stock[0] == 2, "harvest enters basket")
	check(Farm.sell(fresh, [1, 0, 0, 0, 0, 0]), "one-stem order can be sold")
	check(fresh.farm.orders_done == 1 and fresh.farm.stock[0] == 1, "sale consumes exactly one stem")
	check(not Farm.sell(fresh, [2, 0, 0, 0, 0, 0]), "cannot sell missing inventory")
	check(Farm.valid(fresh.farm), "post-sale farm remains valid")
	fresh.earned = ["light:1", "light:2", "light:3"]
	fresh.coins = 300
	check(Farm.plant(fresh, 1, 1), "new species can be planted")
	check(Farm.upgrade(fresh, 0), "bed upgrade buys extra harvest")
	for i in 3: Farm.grow(fresh)
	check(Farm.harvest(fresh, 0) == 3, "upgraded bed produces three stems")
	check(Farm.story_ready({"repairs": [0, 1], "farm": Farm.defaults()}, 0), "Lily arrives after fountain")
	var story_g: Dictionary = Garden.defaults()
	story_g.repairs = [0, 1]
	check(Farm.claim_story(story_g, 0), "first scene claims once")
	check(not Farm.claim_story(story_g, 0), "scene cannot duplicate")
	story_g.repairs = [0, 1, 2, 3]
	story_g.farm.orders_done = 25
	story_g.coins = 5000
	check(Farm.claim_story(story_g, 1) and Farm.claim_story(story_g, 2), "chapters follow repair and sales")
	for tier in 3:
		check(Farm.build_shop(story_g), "shop tier %d builds" % tier)
		check(Farm.claim_story(story_g, tier + 3), "shop tier %d opens scene" % tier)
	check(not Farm.build_shop(story_g), "shop caps at three tiers")
	check(Farm.valid(story_g.farm), "shop progression remains valid")
	var old_farm: Dictionary = Farm.defaults()
	old_farm.erase("buildings")
	var migrated: Dictionary = Garden.defaults()
	migrated.farm = old_farm
	Farm.ensure(migrated)
	check(Farm.valid(migrated.farm) and migrated.farm.buildings.is_empty(), "existing farm save gains buildings safely")
	check(not Farm.build_garden(migrated, 0), "seed pavilion requires greenhouse repair")
	migrated.repairs = [0, 1, 2, 3]
	migrated.coins = 1000
	check(Farm.build_garden(migrated, 0), "bee house can be built")
	check(Farm.build_garden(migrated, 1), "bouquet pavilion can be built")
	check(not Farm.build_garden(migrated, 0), "building cannot be bought twice")
	check(migrated.coins == 100, "building costs are deducted once")
	check(Farm.plant(migrated,0,0),"cosmos can grow beside bee house")
	for i in 3: Farm.grow(migrated)
	check(Farm.harvest(migrated,0)==3,"bee house adds one stem to harvest")
	check(int(Farm.bouquet(migrated,[1,0,0,0,0,0]).coins)==44,"pavilion adds five coins to bouquet")
	check(Farm.valid(migrated.farm), "new buildings persist in valid save")
	print("Farm checks=%d failures=%d" % [checks, failures])
	quit(1 if failures else 0)
