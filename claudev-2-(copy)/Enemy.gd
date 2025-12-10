extends Control
class_name Enemy

signal enemy_defeated(gold_reward: int)

var max_health: int
var current_health: int
var gold_reward: int
var is_boss: bool = false

@onready var health_bar = $HealthBar
@onready var health_label = $HealthLabel
@onready var sprite = $EnemySprite
@onready var boss_indicator = $BossIndicator

func _ready():
	boss_indicator.visible = false

func setup_as_normal(level: int):
	is_boss = false
	max_health = 50 + (level * 10)  # Health scales with level
	current_health = max_health
	gold_reward = 5 + (level * 2)   # Gold scales with level
	
	sprite.modulate = Color.WHITE
	boss_indicator.visible = false
	
	update_health_display()

func setup_as_boss(level: int):
	is_boss = true
	max_health = 200 + (level * 25)  # Bosses have much more health
	current_health = max_health
	gold_reward = 50 + (level * 10)  # Bosses give more gold
	
	sprite.modulate = Color.RED  # Make bosses red
	boss_indicator.visible = true
	boss_indicator.text = "BOSS"
	
	update_health_display()

func take_damage(damage: int):
	current_health -= damage
	current_health = max(0, current_health)
	
	update_health_display()
	
	# Create damage number effect
	show_damage_number(damage)
	
	if current_health <= 0:
		enemy_defeated.emit(gold_reward)

func update_health_display():
	var health_percentage = float(current_health) / float(max_health)
	health_bar.value = health_percentage * 100
	health_label.text = str(current_health) + "/" + str(max_health)

func show_damage_number(damage: int):
	# Simple damage number effect (you can enhance this later)
	var tween = create_tween()
	var damage_label = Label.new()
	damage_label.text = "-" + str(damage)
	damage_label.add_theme_color_override("font_color", Color.YELLOW)
	damage_label.position = Vector2(randf_range(-50, 50), -30)
	add_child(damage_label)
	
	tween.parallel().tween_property(damage_label, "position", damage_label.position + Vector2(0, -50), 1.0)
	tween.parallel().tween_property(damage_label, "modulate:a", 0.0, 1.0)
	tween.tween_callback(damage_label.queue_free)
