extends Node2D

var patty_scene = preload("res://Scenes/patty.tscn")

var money: float = 0.0
var patty_count: int = 0
var money_per_second_per_patty: float = 1.0

# GRILL UPGRADES SYSTEM
var grill_level: int = 1
var base_spawn_interval: float = 10.0
var spawn_timer: float = 0.0
var spawn_position: Vector2
var current_spawn_interval: float = 10.0
var patty_multiplier: int = 1

var timing_upgrade_base_cost: float = 10.0
var amount_upgrade_base_cost: float = 50.0
var upgrade_cost_multiplier: float = 1.5

@onready var money_label: Label = $UI/MoneyLabel
@onready var patty_count_label: Label = $UI/PattyCountLabel
@onready var grill_level_label: Label = $UI/GrillLevelLabel
@onready var timing_upgrade_button: TextureButton = $UI/TimingUpgradeSection/UpgradeButton
@onready var amount_upgrade_button: TextureButton = $UI/AmountUpgradeSection/UpgradeButton
@onready var timing_info_label: Label = $UI/TimingUpgradeSection/Information
@onready var amount_info_label: Label = $UI/AmountUpgradeSection/Information

var counted_patties = []

func _ready():
	spawn_position = Vector2(240, 100)
	update_spawn_interval()

	var money_timer = Timer.new()
	money_timer.wait_time = 1.0
	money_timer.timeout.connect(_on_money_timer_timeout)
	money_timer.autostart = true
	add_child(money_timer)

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= current_spawn_interval:
		spawn_patty()
		spawn_timer = 0.0

	update_ui()
	update_upgrade_buttons()

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
	patty_count += patty_multiplier
	print("PATTY LANDED IN THE GRILL: TOTAL PATTIES = ", patty_count)

func _on_money_timer_timeout():
	var earnings = patty_count * money_per_second_per_patty
	money += earnings
	if earnings > 0:
		print("EARNED ", earnings, " TOTAL MONEY", money)

func can_timing_upgrade() -> bool:
	return grill_level % 5 != 0

func can_amount_upgrade() -> bool:
	return grill_level % 5 == 0

func get_timing_upgrade_cost() -> float:
	var timing_upgrades = get_timing_upgrades_count()
	return timing_upgrade_base_cost * pow(upgrade_cost_multiplier, timing_upgrades)

func get_amount_upgrade_cost() -> float:
	var amount_upgrades = get_amount_upgrades_count()
	return amount_upgrade_base_cost * pow(upgrade_cost_multiplier, amount_upgrades)

func get_timing_upgrades_count() -> int:
	var count = 0
	for level in range(1, grill_level + 1):
		if level % 5 != 0:
			count += 1
	return count

func get_amount_upgrades_count() -> int:
	@warning_ignore("integer_division")
	return grill_level / 5

func update_spawn_interval():
	var timing_upgrades = get_timing_upgrades_count()
	current_spawn_interval = max(base_spawn_interval - (timing_upgrades * 0.1), 0.5)

func update_patty_multiplier():
	var amount_upgrades = get_amount_upgrades_count()
	patty_multiplier = amount_upgrades + 1

func purchase_timing_upgrade():
	if can_timing_upgrade() and money >= get_timing_upgrade_cost():
		money -= get_timing_upgrade_cost()
		grill_level += 1
		update_spawn_interval()
		print("TIMING UPGRADE PURCHASED, THE NEW LEVEL IS: ", grill_level, " AND THE SPAWN INTERVAL IS ", current_spawn_interval)

func purchase_amount_upgrade():
	if can_amount_upgrade() and money >= get_amount_upgrade_cost():
		money -= get_amount_upgrade_cost()
		grill_level += 1
		update_patty_multiplier()
		print("AMOUNT UPGRADE PURCHASED, THE NEW LEVEL IS: ", grill_level, " AND THE NEW MULTIPLIER IS ", patty_multiplier)

func update_upgrade_buttons():
	timing_upgrade_button.disabled = not can_timing_upgrade() or money < get_timing_upgrade_cost()

	amount_upgrade_button.disabled = not can_amount_upgrade() or money < get_amount_upgrade_cost()

func update_ui():
	if money_label:
		money_label.text = "MONEY: $%.0f" % money
	if patty_count_label:
		patty_count_label.text = "PATTIES: %d" % patty_count
	if grill_level_label:
		grill_level_label.text = "GRILL LEVEL: %d" % grill_level

	if timing_info_label:
		if can_timing_upgrade():
			var cost = get_timing_upgrade_cost()
			var next_interval = max(current_spawn_interval - 0.1, 0.5)
			timing_info_label.text = "Next Level: %d\nCost: $%.0f\nTime: %.1fs -> %.1fs" % [grill_level + 1, cost, current_spawn_interval, next_interval]
		else:
			var levels_until_next = 5 - (grill_level % 5)
			timing_info_label.text = "Available in\n%d levels\n(Level %d)" % [levels_until_next, grill_level + levels_until_next]

	if amount_info_label:
		if can_amount_upgrade():
			var cost = get_amount_upgrade_cost()
			var next_multiplier = patty_multiplier + 1
			amount_info_label.text = "Next Level: %d\nCost: $%.0f\nMultiplier: x%d -> x%d" % [grill_level + 1, cost, patty_multiplier, next_multiplier]
		else:
			var levels_until_next = 5 - (grill_level % 5)
			amount_info_label.text = "Available in\n%d levels\n(Level %d)" % [levels_until_next, grill_level + levels_until_next]
