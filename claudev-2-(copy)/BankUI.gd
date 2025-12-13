extends Control

signal back_pressed

@onready var money_label = $Panel/VBox/MoneyLabel
@onready var timer_label = $Panel/VBox/TimerLabel
@onready var rate_label = $Panel/VBox/RateLabel
@onready var back_button = $BackButton

var current_money: int = 0
var time_until_next: float = 0.0
var generation_interval: float = 60.0
var speed_multiplier: float = 1.0

func _ready():
	back_button.pressed.connect(_on_back_pressed)

func _on_back_pressed():
	back_pressed.emit()

func _process(delta):
	if time_until_next > 0:
		time_until_next -= delta
		update_timer_display()

func setup(money: int, timer: float, interval: float, multiplier: float):
	current_money = money
	time_until_next = timer
	generation_interval = interval
	speed_multiplier = multiplier
	update_display()

func update_display():
	money_label.text = "Money: " + str(current_money)
	
	# Calculate actual generation time with multiplier
	var actual_interval = generation_interval / speed_multiplier
	rate_label.text = "Generates 1 money every " + str(int(actual_interval)) + " seconds"
	if speed_multiplier > 1.0:
		rate_label.text += " (x" + str(snapped(speed_multiplier, 0.1)) + " speed)"
	
	update_timer_display()

func update_timer_display():
	var seconds_left = int(ceil(time_until_next))
	timer_label.text = "Next money in: " + str(seconds_left) + "s"
