extends SceneTree

class FakeProgression:
	extends RefCounted
	var owned: Array[String] = []

class FakeGame:
	extends Node2D
	var location := "store"
	var active := true
	var player := Node2D.new()
	var progression := FakeProgression.new()

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	var tasks = load("res://scripts/store_tasks.gd").new()
	var fake := FakeGame.new()
	root.add_child(fake)
	fake.add_child(fake.player)
	fake.add_child(tasks)
	tasks.setup(fake)
	tasks.rng.seed = 21
	tasks.reset_shift()
	assert(tasks.until_spill>=100 and tasks.until_spill<=160)
	assert(tasks.nearest(Vector2(575,275))=="warehouse")
	assert(tasks.nearest(Vector2(65,275))=="ledger")
	assert(tasks.nearest(Vector2(320,275))=="")
	tasks.add_spill(Vector2(264,222))
	tasks.add_spill(Vector2(264,222))
	tasks.add_spill(Vector2(180,140))
	assert(tasks.spill_count()==1)
	assert(not tasks.clean())
	fake.player.position = Vector2(264,222)
	assert(tasks.nearest(fake.player.position)=="spill")
	assert(tasks.clean() and tasks.spill_count()==0 and tasks.cleaned_this_shift==1)
	assert(not tasks.clean())
	for i in range(10): tasks.tick(170)
	assert(tasks.spill_count()==3)
	var data: Dictionary = tasks.snapshot()
	tasks.reset_shift()
	tasks.restore(data)
	assert(tasks.spill_count()==3 and tasks.cleaned_this_shift==1)
	fake.active = false
	assert(not tasks.clean())
	var before: float = tasks.until_spill
	tasks.tick(999)
	assert(tasks.until_spill==before)
	fake.location = "city"
	assert(tasks.nearest(Vector2(575,275))=="")
	fake.active = true
	fake.location = "store"
	fake.progression.owned.append("cleaning")
	tasks.reset_shift()
	assert(tasks.until_spill>=160 and tasks.until_spill<=256)
	tasks.restore({"spills":[[1,2],[264,222],[264,222],"bad"],"cleaned":"bad","until_spill":"bad"})
	assert(tasks.spill_count()==1 and tasks.cleaned_this_shift==0 and tasks.until_spill==120)
	await process_frame
	print("PASS: bodega, registro, derrames limitados, limpieza próxima, pausa, restauración y mejora")
	quit()
