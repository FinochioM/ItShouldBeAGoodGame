extends Node

class_name ShopManager

signal sauce_upgraded(new_level: int)

var sauce_level: int = 0
var sauce_base_cost: float = 450.0
var sauce_cost_multiplier: float = 2.0

var patty_textures = {
	0: preload("res://Textures/patty.png"),
	1: null,
	2: null,
	3: null,
}

var sauce_data = {
	0: {"name": "No sauce", "multiplier": 1.0, "sprite": "patty.png"},
	1: {"name": "Mayo", "multiplier": 1.1, "sprite": "patty_with_mayo.png"},
	2: {"name": "Ketchup", "multiplier": 1.2, "sprite": "patty_with_ketchup.png"},
	3: {"name": "Mustard", "multiplier": 1.3, "sprite": "patty_with_mustard.png"},
}

func _ready():
	_load_sauce_textures()
	
func _load_sauce_textures():
	for level in range(1, sauce_data.size()):
		var sprite_path = "res://Textures/" + sauce_data[level]["sprite"]
		if ResourceLoader.exists(sprite_path):
			patty_textures[level] = load(sprite_path)
			print("LOADED SAUCE TEXTURE FOR WHATEVER LEVEL WE ARE IN NOW")
		else:
			print("SAUCE TEXTURE NOT FOUND, THE CODE DOES NOT WORK")
			patty_textures[level] = patty_textures[0]

func get_sauce_upgrade_cost() -> float:
	if sauce_level >= sauce_data.size() - 1:
		return -1
	return sauce_base_cost * pow(sauce_cost_multiplier, sauce_level)

func can_upgrade_sauce(current_money: float) -> bool:
	if sauce_level >= sauce_data.size() - 1:
		return false
	return current_money >= get_sauce_upgrade_cost()

func purchase_sauce_upgrade(current_money: float) -> float:
	if not can_upgrade_sauce(current_money):
		return current_money
	
	var cost = get_sauce_upgrade_cost()
	sauce_level += 1
	sauce_upgraded.emit(sauce_level)
	
	print("SAUCE UPGRADED TO LEVEL ", sauce_level, " (", get_current_sauce_name(), ")")
	return current_money - cost

func get_current_sauce_name() -> String:
	return sauce_data[sauce_level]["name"]

func get_current_money_multiplier() -> float:
	return sauce_data[sauce_level]["multiplier"]

func get_current_patty_texture() -> Texture2D:
	return patty_textures[sauce_level]

func get_next_sauce_info() -> Dictionary:
	if sauce_level >= sauce_data.size() - 1:
		return {"max_level": true}
	
	var next_level = sauce_level + 1
	return {
		"max_level": false,
		"name": sauce_data[next_level]["name"],
		"multiplier": sauce_data[next_level]["multiplier"],
		"cost": get_sauce_upgrade_cost()
	}

func is_max_sauce_level() -> bool:
	return sauce_level >= sauce_data.size() - 1
