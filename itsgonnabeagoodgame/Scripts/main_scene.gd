extends Node2D

var patty_scene = preload("res://Scenes/patty.tscn")

var money: float = 0.0
var patty_count: int = 0
var money_per_second_per_patty: float = 1.0

var spawn_timer: float = 0.0
var spawn_interval: float = 10.0
var spawn_position: Vector2

@onready var money_label: Label
@onready var patty_count_label: Label

var counted_patties = []

func _ready():
	spawn_position = Vector2(240, 100)
	
	create_ui()
	
	var money_timer = Timer.new()
	money_timer.wait_time = 1.0
	money_timer.timeout.connect(_on_money_timer_timeout)
	money_timer.autostart = true
	add_child(money_timer)
	
func _process(delta):
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_patty()
		spawn_timer = 0.0
		
	update_ui()

func spawn_patty():
	var patty = patty_scene.instantiate()
	
	var random_offset = randf_range(-5, 5)
	patty.position = Vector2(spawn_position.x + random_offset, spawn_position.y)
	
	patty.patty_landed.connect(_on_patty_landed.bind(patty))
	
	add_child(patty)
	print("PATTY SPAWNED!")
	
func _on_patty_landed(patty):
	if patty in counted_patties:
		print("PATTY ALREADY COUNTED _ IGNORING")
		return
	
	counted_patties.append(patty)
	patty_count += 1
	print("PATTY LANDED IN THE GRILL: TOTAL PATTIES = ", patty_count)		

func _on_money_timer_timeout():
	var earnings = patty_count * money_per_second_per_patty
	money += earnings
	if earnings > 0:
		print("EARNED ", earnings, " TOTAL MONEY", money)
		
func create_ui():
	var canvas_layer = CanvasLayer.new()
	add_child(canvas_layer)
	
	money_label = Label.new()
	money_label.position = Vector2(10, 10)
	money_label.add_theme_font_size_override("font_size", 24)
	canvas_layer.add_child(money_label)
	
	patty_count_label = Label.new()
	patty_count_label.position = Vector2(10, 40)
	patty_count_label.add_theme_font_size_override("font_size", 24)
	canvas_layer.add_child(patty_count_label)

func update_ui():
	if money_label:
		money_label.text ="MONEY: $%.2f" % money
	if patty_count_label:
		patty_count_label.text = "PATTIES %d" % patty_count
