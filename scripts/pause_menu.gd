extends CanvasLayer

@onready var resume_btn = $CenterContainer/VBox/ResumeBtn
@onready var settings_btn = $CenterContainer/VBox/SettingsBtn
@onready var main_menu_btn = $CenterContainer/VBox/MainMenuBtn

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	resume_btn.pressed.connect(_on_resume)
	settings_btn.pressed.connect(_on_settings)
	main_menu_btn.pressed.connect(_on_main_menu)

func _input(event):
	if event.is_action_pressed("ui_cancel"):
		if visible:
			# If Settings menu is open, close it first
			if has_node("Settings"):
				get_node("Settings").queue_free()
			else:
				_on_resume()
		else:
			show()
			get_tree().paused = true

func _on_resume():
	hide()
	get_tree().paused = false

func _on_settings():
	# Don't open if already open
	if has_node("Settings"): return
	
	# Hide the pause buttons so they don't overlap
	$CenterContainer.hide()
	
	var settings = preload("res://scenes/settings.tscn").instantiate()
	settings.layer = 101 # Ensure settings renders on top
	add_child(settings)
	
	# Hide the background video since it's an overlay now
	if settings.has_node("BackgroundVideo"):
		settings.get_node("BackgroundVideo").hide()
		
	# Show the pause menu buttons again when settings is closed
	settings.tree_exited.connect(func(): $CenterContainer.show())

func _on_main_menu():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui.tscn")
