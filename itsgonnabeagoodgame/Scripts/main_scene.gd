extends Node2D

var patty_scene = preload("res://Scenes/patty.tscn")

var money: float = 0.0
var patty_count: int = 0
var money_per_second_per_patty: float = 1.0

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

@onready var timing_upgrade_button: TextureButton = $UI/UpgradesContainer/TimingUpgradeSection/UpgradeButton
@onready var amount_upgrade_button: TextureButton = $UI/UpgradesContainer/AmountUpgradeSection/UpgradeButton
@onready var timing_info_label: Label = $UI/UpgradesContainer/TimingUpgradeSection/Information
@onready var amount_info_label: Label = $UI/UpgradesContainer/AmountUpgradeSection/Information

@onready var upgrade_toggle_button: TextureButton = $UI/UpgradesToggle
@onready var animation_player: AnimationPlayer = $UI/ToggleUpgradesPlayer
@onready var upgrade_container: Control = $UI/UpgradesContainer
@onready var click_catcher: Control = $UI/ClickCatcher
@onready var timer_bar_fill: ColorRect = $UI/TimerBarBorder/TimerBarFill

var counted_patties = []
var upgrades_visible: bool = false
var timer_bar_max_width: float

var displayed_money: float = 0.0
var money_lerp_speed: float = 1.0
var money_timer_elapsed: float = 0.0

func _ready():
	spawn_position = Vector2(240, 100)
	update_spawn_interval()
	
	timer_bar_max_width = timer_bar_fill.size.x
	
	upgrade_toggle_button.pressed.connect(toggle_upgrades)
	click_catcher.gui_input.connect(_on_click_catcher_input)
	click_catcher.visible = false
	
	displayed_money = money
	

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= current_spawn_interval:
		spawn_patty()
		spawn_timer = 0.0
	
	money_timer_elapsed += delta
	if money_timer_elapsed >= 1.0:
		_on_money_timer_timeout()
		money_timer_elapsed = 0.0
	
	var current_earnings_per_second = patty_count * money_per_second_per_patty
	var predicted_money = money + (current_earnings_per_second * money_timer_elapsed)
	
	displayed_money = lerp(displayed_money, predicted_money, money_lerp_speed * delta)
	
	update_ui()
	update_upgrade_buttons()
	update_timer_bar()

func spawn_patty():
	var patty = patty_scene.instantiate()

	var random_offset = randf_range(-5, 5)
	var spawn_y = get_stack_top_y()
	patty.position = Vector2(spawn_position.x + random_offset, spawn_y)

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
		money_label.text = format_money(displayed_money)
	if patty_count_label:
		patty_count_label.text = "PATTIES: %d" % patty_count
	if grill_level_label:
		grill_level_label.text = "GRILL: %d" % grill_level

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

func toggle_upgrades():
	if upgrades_visible:
		animation_player.play("hide_upgrades_panel")
		click_catcher.visible = false
		upgrades_visible = false
	else:
		animation_player.play("show_upgrades_panel")
		click_catcher.visible = true
		upgrades_visible = true

func _on_click_catcher_input(event):
	if event is InputEventMouseButton and event.pressed:
		toggle_upgrades()

func update_timer_bar():
	if current_spawn_interval > 0:
		var progress = spawn_timer / current_spawn_interval
		progress = clamp(progress, 0.0, 1.0)
		
		timer_bar_fill.size.x = timer_bar_max_width * progress

func get_stack_top_y() -> float:
	if counted_patties.is_empty():
		return spawn_position.y
		
	var top_y = spawn_position.y
	for patty in counted_patties:
		if is_instance_valid(patty):
			if patty.global_position.y < top_y:
				top_y = patty.global_position.y
	return top_y - 50

func format_money(amount: float) -> String:
	if amount >= 1000000:
		return "MONEY: %.1fM" % (amount / 1000000.0)
	elif amount >= 1000:
		return "MONEY: %.1fK" % (amount / 1000.0)
	else:
		return "MONEY: %.0f" % amount
