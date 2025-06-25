extends Control

@onready var input = $LineEdit
@onready var button = $Button

func _ready():
	button.pressed.connect(_on_enter_pressed)

func _on_enter_pressed():
	if input.text.strip_edges() != "":
		var comite = input.text.strip_edges()
		get_tree().change_scene_to_file("res://mun_panel.tscn")
		Global.comite = comite


func _on_button_2_pressed():
	get_tree().quit()
