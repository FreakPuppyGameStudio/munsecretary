extends Control

@onready var label_comite = $VBoxContainer/LineEdit2
@onready var input = $VBoxContainer/LineEdit
@onready var add_button = $VBoxContainer/Button
@onready var list = $VBoxContainer/ItemList
@onready var save_button = $VBoxContainer/SaveButton
@onready var timer_label = $VBoxContainer/TimerLabel
@onready var start_button = $VBoxContainer/StartPause
@onready var reset_button = $VBoxContainer/Reset
@onready var clear_button = $VBoxContainer/ClearOradoresButton
@onready var tiempo_input = $VBoxContainer/TiempoImput
@onready var aplicar_tiempo_button = $VBoxContainer/AplicarTiempoButton
@onready var alarm = $AudioStreamPlayer

# 🕒 Segundo temporizador (ahora con minutos y segundos reales)
@onready var timer2_label = $VBoxContainer/Timer2Label
@onready var minutes_input = $VBoxContainer/MinutesInput
@onready var aplicar_tiempo_2_button = $VBoxContainer/AplicarTiempo2Button
@onready var start_pause_2_button = $VBoxContainer/StartPause2
@onready var reset_2_button = $VBoxContainer/Reset2

@onready var btn_favor = $VBoxContainer/Votacion/FavorButton
@onready var btn_contra = $VBoxContainer/Votacion/ContraButton
@onready var btn_abstencion = $VBoxContainer/Votacion/AbstencionButton
@onready var label_resultados = $VBoxContainer/Votacion/ResultadosLabel
@onready var reiniciar_btn = $VBoxContainer/Votacion/ReiniciarVotacionButton

@onready var oradores_lateral = $ListaOradoresLateral

# === PROPIEDADES PARA MOCIONES Y PUNTOS EN VBoxContainer2 (Nombres limpios) ===
# Se eliminaron los caracteres invisibles (espacios no estándar) en las rutas de nodos.
@onready var mocion_principal_select = $VBoxContainer2/MotionSelector # OptionButton
@onready var proposed_by_input = $VBoxContainer2/ProposedBy         # LineEdit
@onready var seconded_by_input = $VBoxContainer2/SecondedBy         # LineEdit
@onready var votes_input = $VBoxContainer2/Votes                    # LineEdit
@onready var save_mocion_button = $VBoxContainer2/SaveMotion        # Button
@onready var mociones_list = $VBoxContainer2/MotionList             # ItemList
# ==============================================================================

var oradores: Array = []
var mociones_y_puntos: Array = [] # Variable para almacenar mociones
var time_left = 60.0
var running = false
var votos_a_favor := 0
var votos_en_contra := 0
var votos_abstencion := 0

# Variables del segundo temporizador (ahora en segundos)
var timer2_seconds := 0.0
var running_timer2 := false

# Lista de Mociones Principales (simulando un OptionButton)
const MOCIONES_PRINCIPALES = [
	"--- Seleccionar Moción Principal ---",
	"Moción para Receso del Comité",
	"Moción para Aplazamiento del Debate",
	"Moción para Cerrar Debate",
	"Punto de Orden"
]


func _ready():
	label_comite.text = "Comité: " + Global.comite

	# 🔗 Conexiones existentes
	add_button.pressed.connect(Callable(self, "_on_add"))
	save_button.pressed.connect(Callable(self, "_on_save"))
	start_button.pressed.connect(Callable(self, "_on_start_pause"))
	reset_button.pressed.connect(Callable(self, "_on_reset"))
	clear_button.pressed.connect(Callable(self, "_on_clear_oradores_pressed"))
	aplicar_tiempo_button.pressed.connect(Callable(self, "_on_aplicar_tiempo_button_pressed"))

	aplicar_tiempo_2_button.pressed.connect(Callable(self, "_on_aplicar_tiempo_2_button_pressed"))
	start_pause_2_button.pressed.connect(Callable(self, "_on_start_pause_2_pressed"))
	reset_2_button.pressed.connect(Callable(self, "_on_reset_2_pressed"))

	btn_favor.pressed.connect(Callable(self, "_on_voto_favor"))
	btn_contra.pressed.connect(Callable(self, "_on_voto_contra"))
	btn_abstencion.pressed.connect(Callable(self, "_on_voto_abstencion"))
	reiniciar_btn.pressed.connect(Callable(self, "_on_reiniciar_votacion"))
	
	# 🔗 NUEVAS CONEXIONES PARA MOCIONES Y PUNTOS
	if save_mocion_button:
		save_mocion_button.pressed.connect(Callable(self, "_on_save_mocion_pressed"))
	
	if mocion_principal_select:
		# CONEXIÓN CLAVE: Asegura que el OptionButton llama a la función cuando se selecciona un ítem.
		mocion_principal_select.item_selected.connect(Callable(self, "_on_mocion_principal_selected"))
		_init_mocion_principal_select()
	# ===================================================

	# Ajuste de tamaño mínimo de botones
	for boton in [aplicar_tiempo_2_button, start_pause_2_button, reset_2_button]:
		if boton:
			boton.custom_minimum_size = Vector2(90, 28)

	alarm.stream = load("res://assets/bell.wav")
	_load_data()

# === Funciones de Inicialización ===
func _init_mocion_principal_select():
	if mocion_principal_select:
		mocion_principal_select.clear()
		for i in range(MOCIONES_PRINCIPALES.size()):
			mocion_principal_select.add_item(MOCIONES_PRINCIPALES[i], i)
		mocion_principal_select.select(0) # Selecciona el placeholder inicial

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		_on_save()

func _on_add():
	if input.text.strip_edges() != "":
		var nombre = input.text.strip_edges()
		oradores.append(nombre)
		list.add_item(nombre)
		oradores_lateral.add_item(nombre)
		input.text = ""
		_on_save()

# === NUEVAS FUNCIONES PARA MOCIONES Y PUNTOS ===

func _on_save_mocion_pressed():
	# Esta función toma la información de los LineEdit y la añade como una moción personalizada.
	var mocion_texto = proposed_by_input.text.strip_edges() # Asumo que el ProposedBy se usa para el texto principal
	var secundado_por = seconded_by_input.text.strip_edges()
	var votos = votes_input.text.strip_edges()
	
	# Si se introduce texto en la entrada principal, lo añadimos
	if mocion_texto != "":
		var texto_completo = "Moción/Punto: %s" % mocion_texto
		
		# Agregamos los campos secundarios si tienen contenido
		if secundado_por != "":
			texto_completo += " | Secundado por: %s" % secundado_por
		if votos != "":
			texto_completo += " | Votos requeridos: %s" % votos
			
		_add_mocion_to_list(texto_completo)
		
		# Limpiar las entradas
		proposed_by_input.text = ""
		seconded_by_input.text = ""
		votes_input.text = ""
		_on_save()

func _on_mocion_principal_selected(index: int):
	# Agrega una de las mociones principales seleccionadas del OptionButton
	if index > 0: # El índice 0 es el placeholder "Seleccionar..."
		var mocion_texto = MOCIONES_PRINCIPALES[index]
		_add_mocion_to_list(mocion_texto)
		mocion_principal_select.select(0) # Reinicia la selección
		_on_save()

func _add_mocion_to_list(texto: String):
	# Lógica central para añadir a las estructuras de datos con hora
	# La corrección para Time.get_time_string_from_system(true) está aplicada.
	var mocion_con_fecha = "%s - [%s]" % [texto, Time.get_time_string_from_system(true)]
	mociones_y_puntos.append(mocion_con_fecha)
	if mociones_list:
		mociones_list.add_item(mocion_con_fecha)
# ===============================================

func _on_save():
	var path = "user://%s_data.json" % Global.comite
	var file = FileAccess.open(path, FileAccess.WRITE)
	var data = {
		"oradores": oradores,
		"mociones": mociones_y_puntos, # Se agrega para guardar mociones
		"tiempo": time_left,
		"running": running,
		"timer2_seconds": timer2_seconds,
		"running_timer2": running_timer2,
		"votos_a_favor": votos_a_favor,
		"votos_en_contra": votos_en_contra,
		"votos_abstencion": votos_abstencion
	}
	file.store_string(JSON.stringify(data, "\t"))
	file.close()

func _load_data():
	var path = "user://%s_data.json" % Global.comite
	if not FileAccess.file_exists(path):
		timer_label.text = "Tiempo: " + str(int(time_left)) + "s"
		timer2_label.text = "Timer 2: 00:00"
		return

	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var data = JSON.parse_string(content)
	if typeof(data) != TYPE_DICTIONARY:
		return

	oradores = data.get("oradores", [])
	for nombre in oradores:
		list.add_item(nombre)
		oradores_lateral.add_item(nombre)

	# Cargar mociones
	mociones_y_puntos = data.get("mociones", [])
	for mocion in mociones_y_puntos:
		if mociones_list:
			mociones_list.add_item(mocion)
	
	time_left = float(data.get("tiempo", 60))
	running = data.get("running", false)
	start_button.text = "Stop" if running else "Start"

	timer2_seconds = float(data.get("timer2_seconds", 0))
	running_timer2 = data.get("running_timer2", false)
	start_pause_2_button.text = "Stop" if running_timer2 else "Start"
	timer2_label.text = "Timer 2: %02d:%02d" % [int(timer2_seconds / 60), int(timer2_seconds) % 60]

	votos_a_favor = data.get("votos_a_favor", 0)
	votos_en_contra = data.get("votos_en_contra", 0)
	votos_abstencion = data.get("votos_abstencion", 0)
	_actualizar_resultados()

	timer_label.text = "Tiempo: " + str(int(time_left)) + "s"

func _process(delta):
	# ⏱️ Primer temporizador
	if running:
		time_left -= delta
		if time_left <= 0.0:
			time_left = 0.0
			running = false
			alarm.play()
		timer_label.text = "Tiempo: " + str(int(time_left)) + "s"

	# 🕒 Segundo temporizador (minutos y segundos)
	if running_timer2:
		if timer2_seconds > 0.0:
			timer2_seconds -= delta
			if timer2_seconds <= 0.0:
				timer2_seconds = 0.0
				running_timer2 = false
				alarm.play()
		timer2_label.text = "Timer 2: %02d:%02d" % [int(timer2_seconds / 60), int(timer2_seconds) % 60]

func _on_start_pause():
	running = !running
	start_button.text = "Stop" if running else "Start"
	_on_save()

func _on_reset():
	time_left = 60.0
	running = false
	timer_label.text = "Tiempo: 60s"
	_on_save()

func _on_clear_oradores_pressed():
	# Limpiar la lista de oradores, mociones y archivos de guardado
	oradores.clear()
	list.clear()
	oradores_lateral.clear()
	mociones_y_puntos.clear() # Limpiar mociones
	if mociones_list:
		mociones_list.clear() # Limpiar lista visual de mociones
	
	var path = "user://%s_data.json" % Global.comite
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	votos_a_favor = 0
	votos_en_contra = 0
	votos_abstencion = 0
	time_left = 60.0
	timer2_seconds = 0.0
	_actualizar_resultados()
	timer_label.text = "Tiempo: 60s"
	timer2_label.text = "Timer 2: 00:00"

func _on_aplicar_tiempo_button_pressed():
	var new_time = 0.0
	if tiempo_input is LineEdit:
		new_time = float(tiempo_input.text) if tiempo_input.text != "" else 0.0
	elif tiempo_input.has_method("get_value"):
		new_time = tiempo_input.get_value()
	new_time = clamp(new_time, 0.0, 3630.0)
	time_left = new_time
	running = false
	timer_label.text = "Tiempo: " + str(int(time_left)) + "s"
	_on_save()

# 🎯 Segundo temporizador
func _on_aplicar_tiempo_2_button_pressed():
	var min = 0
	if minutes_input is LineEdit:
		min = int(minutes_input.text) if minutes_input.text != "" else 0
	elif minutes_input.has_method("get_value"):
		min = int(minutes_input.get_value())
	min = clamp(min, 0, 999)
	timer2_seconds = float(min * 60)
	running_timer2 = false
	timer2_label.text = "Timer 2: %02d:%02d" % [int(timer2_seconds / 60), int(timer2_seconds) % 60]
	_on_save()

func _on_start_pause_2_pressed():
	running_timer2 = !running_timer2
	start_pause_2_button.text = "Stop" if running_timer2 else "Start"
	_on_save()

func _on_reset_2_pressed():
	timer2_seconds = 0.0
	running_timer2 = false
	timer2_label.text = "Timer 2: 00:00"
	_on_save()

# 🗳️ Votaciones
func _on_voto_favor():
	votos_a_favor += 1
	_actualizar_resultados()
	_on_save()

func _on_voto_contra():
	votos_en_contra += 1
	_actualizar_resultados()
	_on_save()

func _on_voto_abstencion():
	votos_abstencion += 1
	_actualizar_resultados()
	_on_save()

func _on_reiniciar_votacion():
	votos_a_favor = 0
	votos_en_contra = 0
	votos_abstencion = 0
	_actualizar_resultados()
	_on_save()

func _actualizar_resultados():
	label_resultados.text = "✅ A favor: %d  ❌ En contra: %d  ➖ Abstenciones: %d" % [
		votos_a_favor, votos_en_contra, votos_abstencion
	]

func _on_menu_pressed():
	get_tree().change_scene_to_file("res://start_menu.tscn")


func _on_deletemotion_pressed() -> void:
	pass # Replace with function body.
