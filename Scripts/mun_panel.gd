extends Control

@onready var label_comite = $VBoxContainer/LineEdit2
@onready var input = $VBoxContainer/LineEdit
@onready var add_button = $VBoxContainer/Button
@onready var list = $VBoxContainer/ItemList
@onready var save_button = $VBoxContainer/SaveButton
@onready var timer_label = $VBoxContainer/TimerLabel
@onready var start_button = $VBoxContainer/StartPause
@onready var reset_button = $VBoxContainer/Reset
@onready var clear_button = $VBoxContainer/ClearOradoresButton  # Botón para limpiar la lista
@onready var alarm = $AudioStreamPlayer

@onready var btn_favor = $VBoxContainer/Votacion/FavorButton
@onready var btn_contra = $VBoxContainer/Votacion/ContraButton
@onready var btn_abstencion = $VBoxContainer/Votacion/AbstencionButton
@onready var label_resultados = $VBoxContainer/Votacion/ResultadosLabel
@onready var reiniciar_btn = $VBoxContainer/Votacion/ReiniciarVotacionButton

# Nuevo ItemList fuera del VBoxContainer
@onready var oradores_lateral = $ListaOradoresLateral

var oradores: Array = []
var time_left = 60.0
var running = false
var votos_a_favor := 0
var votos_en_contra := 0
var votos_abstencion := 0

func _ready():
	label_comite.text = "Comité: " + Global.comite
	add_button.pressed.connect(_on_add)
	save_button.pressed.connect(_on_save)
	start_button.pressed.connect(_on_start_pause)
	reset_button.pressed.connect(_on_reset)
	clear_button.pressed.connect(_on_clear_oradores_pressed)  # Conectar botón limpiar

	btn_favor.pressed.connect(_on_voto_favor)
	btn_contra.pressed.connect(_on_voto_contra)
	btn_abstencion.pressed.connect(_on_voto_abstencion)
	reiniciar_btn.pressed.connect(_on_reiniciar_votacion)

	alarm.stream = load("res://assets/bell.wav")
	_load_oradores()

func _on_add():
	if input.text.strip_edges() != "":
		var nombre = input.text.strip_edges()
		oradores.append(nombre)
		list.add_item(nombre)  # Lista principal
		oradores_lateral.add_item(nombre)  # Lista lateral (a un lado)
		input.text = ""

func _on_save():
	var path = "user://%s_oradores.json" % Global.comite
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"oradores": oradores}, "\t"))
	file.close()

func _load_oradores():
	var path = "user://%s_oradores.json" % Global.comite
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		var data = JSON.parse_string(content)
		if typeof(data) == TYPE_DICTIONARY and "oradores" in data:
			oradores = data["oradores"]
			for nombre in oradores:
				list.add_item(nombre)
				oradores_lateral.add_item(nombre)

func _process(delta):
	if running:
		time_left -= delta
		if time_left <= 0:
			time_left = 0
			running = false
			alarm.play()
		timer_label.text = "Tiempo: " + str(int(time_left)) + "s"

func _on_start_pause():
	running = !running
	var texto_boton = "Stop" if running else "Start"
	start_button.text = texto_boton

func _on_reset():
	time_left = 60.0
	running = false
	timer_label.text = "Tiempo: 60s"

func _on_clear_oradores_pressed():
	oradores.clear()
	list.clear()
	oradores_lateral.clear()
	
	# Borra el archivo guardado para que no se recargue la lista
	var path = "user://%s_oradores.json" % Global.comite
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)

func _on_voto_favor():
	votos_a_favor += 1
	_actualizar_resultados()

func _on_voto_contra():
	votos_en_contra += 1
	_actualizar_resultados()

func _on_voto_abstencion():
	votos_abstencion += 1
	_actualizar_resultados()

func _on_reiniciar_votacion():
	votos_a_favor = 0
	votos_en_contra = 0
	votos_abstencion = 0
	_actualizar_resultados()

func _actualizar_resultados():
	label_resultados.text = "✅ A favor: %d  ❌ En contra: %d  ➖ Abstenciones: %d" % [votos_a_favor, votos_en_contra, votos_abstencion]
