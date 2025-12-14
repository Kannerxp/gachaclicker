extends Control

signal buy_gems_requested
signal buy_pulls_requested
signal back_pressed

@onready var gems_buy_button = $TabContainer/GemsTab/BuyButton
@onready var pulls_buy_button = $TabContainer/PullsTab/BuyButton
@onready var back_button = $BackButton

func _ready():
	gems_buy_button.pressed.connect(_on_buy_gems_pressed)
	pulls_buy_button.pressed.connect(_on_buy_pulls_pressed)
	back_button.pressed.connect(_on_back_pressed)

func _on_buy_gems_pressed():
	buy_gems_requested.emit()

func _on_buy_pulls_pressed():
	buy_pulls_requested.emit()

func _on_back_pressed():
	back_pressed.emit()

func update_button_states(money: int, gems: int):
	gems_buy_button.disabled = money < 10
	pulls_buy_button.disabled = gems < 5
