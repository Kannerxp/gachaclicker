extends Control

signal back_pressed
signal reset_progress_requested

@onready var back_button = $BackButton
@onready var reset_button = $Panel/VBox/ResetButton
@onready var version_label = $Panel/VBox/VersionLabel

func _ready():
	back_button.pressed.connect(_on_back_pressed)
	reset_button.pressed.connect(_on_reset_pressed)
	version_label.text = "Version: 0.2.0"

func _on_back_pressed():
	back_pressed.emit()

func _on_reset_pressed():
	# Show confirmation dialog
	var confirm = ConfirmationDialog.new()
	confirm.dialog_text = "Are you sure you want to RESET ALL PROGRESS?\n\nThis will delete:\n• All characters\n• All prestige upgrades\n• All currencies\n• Everything!\n\nThis action cannot be undone!"
	confirm.title = "RESET PROGRESS"
	add_child(confirm)
	
	confirm.confirmed.connect(_confirm_reset.bind(confirm))
	confirm.canceled.connect(confirm.queue_free)
	confirm.popup_centered()

func _confirm_reset(dialog: ConfirmationDialog):
	reset_progress_requested.emit()
	dialog.queue_free()
