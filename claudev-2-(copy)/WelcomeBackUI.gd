extends Control

signal rewards_claimed

@onready var title_label = $Panel/VBox/TitleLabel
@onready var time_away_label = $Panel/VBox/TimeAwayLabel
@onready var rewards_container = $Panel/VBox/RewardsContainer
@onready var claim_button = $Panel/VBox/ClaimButton
@onready var background = $Background

var rewards_data: Dictionary = {}

func _ready():
	claim_button.pressed.connect(_on_claim_pressed)
	
	# Darken background
	background.color = Color(0, 0, 0, 0.7)

func setup(time_away_seconds: float, gold_earned: int, money_earned: int, levels_progressed: int, had_limit: bool, limit_hours: float):
	# Format time away
	var time_text = format_time(time_away_seconds)
	
	if had_limit and limit_hours > 0:
		var limit_text = format_time(limit_hours * 3600)
		time_away_label.text = "You were away for: " + time_text + " / " + limit_text
	elif had_limit and limit_hours < 0:
		time_away_label.text = "You were away for: " + time_text + " (Unlimited)"
	else:
		time_away_label.text = "You were away for: " + time_text
	
	# Clear existing rewards
	for child in rewards_container.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	# Store rewards for claiming
	rewards_data = {
		"gold": gold_earned,
		"money": money_earned,
		"levels": levels_progressed
	}
	
	# Add rewards display
	if levels_progressed > 0:
		add_reward_display("Levels Progressed", str(levels_progressed), null)
	
	if gold_earned > 0:
		add_reward_display("Gold", str(gold_earned), SpriteManager.get_icon_texture("gold"))
	
	if money_earned > 0:
		add_reward_display("Money", str(money_earned), SpriteManager.get_icon_texture("money"))
	
	# Show bonus message if earned a lot
	if gold_earned > 1000 or levels_progressed > 10:
		var bonus_label = Label.new()
		bonus_label.text = "⭐ Great progress while you were away! ⭐"
		bonus_label.add_theme_font_size_override("font_size", 14)
		bonus_label.add_theme_color_override("font_color", Color.GOLD)
		bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		rewards_container.add_child(bonus_label)

func add_reward_display(reward_name: String, amount: String, icon: Texture2D):
	var hbox = HBoxContainer.new()
	hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Icon
	if icon != null:
		var icon_rect = TextureRect.new()
		icon_rect.texture = icon
		icon_rect.custom_minimum_size = Vector2(32, 32)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		hbox.add_child(icon_rect)
		
		# Spacer
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(10, 0)
		hbox.add_child(spacer)
	
	# Text
	var label = Label.new()
	label.text = reward_name + ": " + amount
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(label)
	
	rewards_container.add_child(hbox)
	
	# Add separator
	var separator = HSeparator.new()
	rewards_container.add_child(separator)

func format_time(seconds: float) -> String:
	var days = int(seconds / 86400)
	var hours = int((seconds - (days * 86400)) / 3600)
	var minutes = int((seconds - (days * 86400) - (hours * 3600)) / 60)
	var secs = int(seconds - (days * 86400) - (hours * 3600) - (minutes * 60))
	
	if days > 0:
		if hours > 0:
			return str(days) + "d " + str(hours) + "h"
		else:
			return str(days) + " day" + ("s" if days > 1 else "")
	elif hours > 0:
		if minutes > 0:
			return str(hours) + "h " + str(minutes) + "m"
		else:
			return str(hours) + " hour" + ("s" if hours > 1 else "")
	elif minutes > 0:
		return str(minutes) + " minute" + ("s" if minutes > 1 else "")
	else:
		return str(secs) + " second" + ("s" if secs != 1 else "")

func _on_claim_pressed():
	rewards_claimed.emit(rewards_data)
	queue_free()
