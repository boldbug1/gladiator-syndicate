extends CanvasLayer

@onready var master_slider = $CenterContainer/MainPanel/MarginContainer/VBox/Scroll/ContentVBox/MasterRow/MasterSlider
@onready var master_val = $CenterContainer/MainPanel/MarginContainer/VBox/Scroll/ContentVBox/MasterRow/MasterVal
@onready var music_slider = $CenterContainer/MainPanel/MarginContainer/VBox/Scroll/ContentVBox/MusicRow/MusicSlider
@onready var music_val = $CenterContainer/MainPanel/MarginContainer/VBox/Scroll/ContentVBox/MusicRow/MusicVal
@onready var sfx_slider = $CenterContainer/MainPanel/MarginContainer/VBox/Scroll/ContentVBox/SFXRow/SFXSlider
@onready var sfx_val = $CenterContainer/MainPanel/MarginContainer/VBox/Scroll/ContentVBox/SFXRow/SFXVal
@onready var mute_check = $CenterContainer/MainPanel/MarginContainer/VBox/Scroll/ContentVBox/MuteRow/MuteCheck
@onready var res_option = $CenterContainer/MainPanel/MarginContainer/VBox/Scroll/ContentVBox/ResRow/ResOption
@onready var window_option = $CenterContainer/MainPanel/MarginContainer/VBox/Scroll/ContentVBox/WindowRow/WindowOption

var resolutions = [
	Vector2i(1920, 1080),
	Vector2i(1600, 900),
	Vector2i(1366, 768),
	Vector2i(1280, 720)
]

func _ready():
	_setup_ui()
	_connect_signals()
	_load_current_settings()

func _setup_ui():
	# Populate Resolution dropdown
	for res in resolutions:
		res_option.add_item(str(res.x) + " x " + str(res.y))
	
	# Populate Window Mode dropdown
	window_option.add_item("Windowed")
	window_option.add_item("Fullscreen")
	window_option.add_item("Borderless")

func _connect_signals():
	master_slider.value_changed.connect(_on_master_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	mute_check.toggled.connect(_on_mute_toggled)
	
	$CenterContainer/MainPanel/MarginContainer/VBox/Buttons/BackButton.pressed.connect(_on_back_pressed)
	$CenterContainer/MainPanel/MarginContainer/VBox/Buttons/ApplyButton.pressed.connect(_on_apply_pressed)

func _load_current_settings():
	# For now, we will default them, but normally we would load from a Save file here
	var master_idx = AudioServer.get_bus_index("Master")
	master_slider.value = db_to_linear(AudioServer.get_bus_volume_db(master_idx))
	_update_label(master_val, master_slider.value)
	
	# Set window mode selection based on current DisplayServer state
	var mode = DisplayServer.window_get_mode()
	if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		window_option.selected = 1
	elif mode == DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN:
		window_option.selected = 1
	else:
		window_option.selected = 0

func _on_master_changed(value):
	_update_label(master_val, value)
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	print("Master Volume Changed: ", value, " DB: ", linear_to_db(value))

func _on_music_changed(value):
	_update_label(music_val, value)
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	else:
		# Fallback to master if Music bus doesn't exist yet
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_sfx_changed(value):
	_update_label(sfx_val, value)
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx != -1:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	else:
		# Fallback to master if SFX bus doesn't exist yet
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(value))

func _on_mute_toggled(button_pressed):
	AudioServer.set_bus_mute(AudioServer.get_bus_index("Master"), button_pressed)

func _update_label(label: Label, value: float):
	label.text = str(int(value * 100)) + "%"

func _on_apply_pressed():
	print("Apply button pressed!")
	var mode_idx = window_option.selected
	var sel_res = resolutions[res_option.selected]
	var win = get_window()
	
	# 1. Always apply the selected resolution first
	DisplayServer.window_set_size(sel_res)
	win.size = sel_res
	
	# 2. Apply Window Mode
	if mode_idx == 0: # Windowed
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		win.mode = Window.MODE_WINDOWED
		
		# Center the window safely
		var screen_size = DisplayServer.screen_get_size()
		win.position = (screen_size / 2) - (sel_res / 2)
		
	elif mode_idx == 1: # Fullscreen
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		win.mode = Window.MODE_FULLSCREEN
		
	elif mode_idx == 2: # Borderless/Exclusive
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
		win.mode = Window.MODE_EXCLUSIVE_FULLSCREEN

func _on_back_pressed():
	if get_tree().current_scene == self:
		get_tree().change_scene_to_file("res://scenes/ui.tscn")
	else:
		# If it's an overlay (like from the pause menu), just close it!
		queue_free()
