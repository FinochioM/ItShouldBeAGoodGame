extends Node2D

var patty_scene = preload("res://Scenes/patty.tscn")

var money: float = 0.0
var patty_count: int = 0
var money_per_second_per_patty: float = 1.0

var grill_manager: GrillManager
var shop_manager: ShopManager

var spawn_timer: float = 0.0
var spawn_position: Vector2
var counted_patties = []

@onready var money_label: Label = $UI/MoneyLabel
@onready var patty_count_label: Label = $UI/PattyCountLabel
@onready var grill_level_label: Label = $UI/GrillLevelLabel

@onready var timing_upgrade_button: TextureButton = $UI/UpgradesContainer/TimingUpgradeSection/UpgradeButton
@onready var amount_upgrade_button: TextureButton = $UI/UpgradesContainer/AmountUpgradeSection/UpgradeButton
@onready var timing_info_label: Label = $UI/UpgradesContainer/TimingUpgradeSection/Information
@onready var amount_info_label: Label = $UI/UpgradesContainer/AmountUpgradeSection/Information

@onready var sauce_upgrade_button: TextureButton = $UI/ShopContainer/SauceSection/UpgradeButton
@onready var sauce_info_label: Label = $UI/ShopContainer/SauceSection/Information

@onready var upgrade_toggle_button: TextureButton = $UI/UpgradesToggle
@onready var animation_player: AnimationPlayer = $UI/ToggleUpgradesPlayer
@onready var upgrade_container: Control = $UI/UpgradesContainer
@onready var click_catcher: Control = $UI/ClickCatcher
@onready var timer_bar_fill: ColorRect = $UI/TimerBarBorder/TimerBarFill

var upgrades_visible: bool = false
var timer_bar_max_width: float

var displayed_money: float = 0.0
var money_lerp_speed: float = 5.0
var money_timer_elapsed: float = 0.0

func _ready():
	grill_manager = GrillManager.new()
	shop_manager = ShopManager.new()
	add_child(grill_manager)
	add_child(shop_manager)
	
	grill_manager.grill_upgraded.connect(_on_grill_upgraded)
	shop_manager.sauce_upgraded.connect(_on_sauce_upgraded)
	
	spawn_position = Vector2(240, 100)
	timer_bar_max_width = timer_bar_fill.size.x
	displayed_money = money
	
	upgrade_toggle_button.pressed.connect(toggle_upgrades)
	click_catcher.gui_input.connect(_on_click_catcher_input)
	click_catcher.visible = false
	
	sauce_upgrade_button.pressed.connect(purchase_sauce_upgrade)

func _process(delta):
	spawn_timer += delta
	if spawn_timer >= grill_manager.current_spawn_interval:
		spawn_patty()
		spawn_timer = 0.0
	
	money_timer_elapsed += delta
	if money_timer_elapsed >= 1.0:
		_on_money_timer_timeout()
		money_timer_elapsed = 0.0
	
	var current_earnings_per_second = get_total_earnings_per_second()
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

	var texture = shop_manager.get_current_patty_texture()
	patty.set_patty_sprite(texture)

	print("PATTY SPAWNED!")

func _on_patty_landed(patty):
	if patty in counted_patties:
		print("PATTY ALREADY COUNTED - IGNORING")
		return

	counted_patties.append(patty)
	patty_count += grill_manager.patty_multiplier
	print("PATTY LANDED IN THE GRILL: TOTAL PATTIES = ", patty_count)

func _on_money_timer_timeout():
	var earnings = get_total_earnings_per_second()
	money += earnings
	
	if earnings > 0:
		print("EARNED ", earnings, " TOTAL MONEY ", money)

func get_total_earnings_per_second() -> float:
	var base_earnings = patty_count * money_per_second_per_patty
	var sauce_multiplier = shop_manager.get_current_money_multiplier()
	return base_earnings * sauce_multiplier

func purchase_timing_upgrade():
	money = grill_manager.purchase_timing_upgrade(money)

func purchase_amount_upgrade():
	money = grill_manager.purchase_amount_upgrade(money)

func purchase_sauce_upgrade():
	money = shop_manager.purchase_sauce_upgrade(money)

func _on_grill_upgraded(new_level: int):
	print("Grill upgraded to level: ", new_level)

func _on_sauce_upgraded(new_level: int):
	print("Sauce upgraded to level: ", new_level, " (", shop_manager.get_current_sauce_name(), ")")
	print("Money multiplier is now: ", shop_manager.get_current_money_multiplier())

func update_upgrade_buttons():
	timing_upgrade_button.disabled = not grill_manager.can_timing_upgrade() or money < grill_manager.get_timing_upgrade_cost()
	amount_upgrade_button.disabled = not grill_manager.can_amount_upgrade() or money < grill_manager.get_amount_upgrade_cost()
	
	if sauce_upgrade_button:
		sauce_upgrade_button.disabled = not shop_manager.can_upgrade_sauce(money)

func update_ui():
	if money_label:
		money_label.text = format_money(displayed_money)
	if patty_count_label:
		patty_count_label.text = "PATTIES: %d" % patty_count
	if grill_level_label:
		grill_level_label.text = "GRILL: %d" % grill_manager.grill_level

	update_grill_upgrade_info()
	update_shop_info()

func update_grill_upgrade_info():
	if timing_info_label:
		var timing_info = grill_manager.get_timing_upgrade_info()
		if timing_info["available"]:
			timing_info_label.text = "Next Level: %d\nCost: $%.0f\nTime: %.1fs -> %.1fs" % [
				timing_info["next_level"], 
				timing_info["cost"], 
				timing_info["current_interval"], 
				timing_info["next_interval"]
			]
		else:
			timing_info_label.text = "Available in\n%d levels\n(Level %d)" % [
				timing_info["levels_until_next"], 
				timing_info["unlock_level"]
			]

	if amount_info_label:
		var amount_info = grill_manager.get_amount_upgrade_info()
		if amount_info["available"]:
			amount_info_label.text = "Next Level: %d\nCost: $%.0f\nMultiplier: x%d -> x%d" % [
				amount_info["next_level"], 
				amount_info["cost"], 
				amount_info["current_multiplier"], 
				amount_info["next_multiplier"]
			]
		else:
			amount_info_label.text = "Available in\n%d levels\n(Level %d)" % [
				amount_info["levels_until_next"], 
				amount_info["unlock_level"]
			]

func update_shop_info():
	if sauce_info_label:
		var sauce_info = shop_manager.get_next_sauce_info()
		if sauce_info.get("max_level", false):
			sauce_info_label.text = "MAX LEVEL\n%s\nMultiplier: %.1fx" % [
				shop_manager.get_current_sauce_name(),
				shop_manager.get_current_money_multiplier()
			]
		else:
			sauce_info_label.text = "Next: %s\nCost: $%.0f\nMultiplier: %.1fx -> %.1fx" % [
				sauce_info["name"],
				sauce_info["cost"],
				shop_manager.get_current_money_multiplier(),
				sauce_info["multiplier"]
			]

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
	if grill_manager.current_spawn_interval > 0:
		var progress = spawn_timer / grill_manager.current_spawn_interval
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

func spend_money(amount: float):
	money -= amount
	displayed_money = money
