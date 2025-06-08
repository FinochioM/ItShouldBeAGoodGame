extends Node
class_name GrillManager


signal grill_upgraded(new_level: int)

var grill_level: int = 1
var base_spawn_interval: float = 10.0
var current_spawn_interval: float = 10.0
var patty_multiplier: int = 1

var timing_upgrade_base_cost: float = 10.0
var amount_upgrade_base_cost: float = 50.0
var upgrade_cost_multiplier: float = 1.5

func _ready():
	update_spawn_interval()
	update_patty_multiplier()

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

func purchase_timing_upgrade(current_money: float) -> float:
	if can_timing_upgrade() and current_money >= get_timing_upgrade_cost():
		var cost = get_timing_upgrade_cost()
		grill_level += 1
		update_spawn_interval()
		grill_upgraded.emit(grill_level)
		print("TIMING UPGRADE PURCHASED, THE NEW LEVEL IS: ", grill_level, " AND THE SPAWN INTERVAL IS ", current_spawn_interval)
		return current_money - cost
	return current_money

func purchase_amount_upgrade(current_money: float) -> float:
	if can_amount_upgrade() and current_money >= get_amount_upgrade_cost():
		var cost = get_amount_upgrade_cost()
		grill_level += 1
		update_patty_multiplier()
		grill_upgraded.emit(grill_level)
		print("AMOUNT UPGRADE PURCHASED, THE NEW LEVEL IS: ", grill_level, " AND THE NEW MULTIPLIER IS ", patty_multiplier)
		return current_money - cost
	return current_money

func get_timing_upgrade_info() -> Dictionary:
	if can_timing_upgrade():
		var cost = get_timing_upgrade_cost()
		var next_interval = max(current_spawn_interval - 0.1, 0.5)
		return {
			"available": true,
			"next_level": grill_level + 1,
			"cost": cost,
			"current_interval": current_spawn_interval,
			"next_interval": next_interval
		}
	else:
		var levels_until_next = 5 - (grill_level % 5)
		return {
			"available": false,
			"levels_until_next": levels_until_next,
			"unlock_level": grill_level + levels_until_next
		}

func get_amount_upgrade_info() -> Dictionary:
	if can_amount_upgrade():
		var cost = get_amount_upgrade_cost()
		var next_multiplier = patty_multiplier + 1
		return {
			"available": true,
			"next_level": grill_level + 1,
			"cost": cost,
			"current_multiplier": patty_multiplier,
			"next_multiplier": next_multiplier
		}
	else:
		var levels_until_next = 5 - (grill_level % 5)
		return {
			"available": false,
			"levels_until_next": levels_until_next,
			"unlock_level": grill_level + levels_until_next
		}
