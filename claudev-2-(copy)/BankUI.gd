extends Control

signal back_pressed

@onready var money_label = $Panel/VBox/MoneyLabel
@onready var timer_label = $Panel/VBox/TimerLabel
@onready var rate_label = $Panel/VBox/RateLabel
@onready var back_button = $BackButton

func _ready():
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	back_pressed.emit()

func update_display(money: int, current_timer: float, generation_interval: float, speed_multiplier: float):
	# Update money display
	money_label.text = "Money: " + str(money)
	
	# Calculate actual generation time with multiplier
	var actual_interval = generation_interval / speed_multiplier
	rate_label.text = "Generates 1 money every " + str(snapped(actual_interval, 0.1)) + " seconds"
	if speed_multiplier > 1.0:
		rate_label.text += " (x" + str(snapped(speed_multiplier, 0.1)) + " speed)"
	
	# Calculate time remaining until next money
	var time_remaining = actual_interval - current_timer
	if time_remaining < 0:
		time_remaining = actual_interval
	
	var seconds_left = int(ceil(time_remaining))
	timer_label.text = "Next money in: " + str(seconds_left) + "s"
