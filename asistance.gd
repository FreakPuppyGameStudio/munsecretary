extends Control

# --- NODOS ---
@onready var input_nombre = $VBoxContainer/HBoxContainer/LineEdit
@onready var add_btn = $VBoxContainer/HBoxContainer/AddButton
@onready var paises_container = $VBoxContainer/PaisesContainer
@onready var reset_btn = $VBoxContainer/HBoxContainer2/ResetButton
@onready var save_btn = $VBoxContainer/HBoxContainer2/SaveButton
@onready var delete_btn = $VBoxContainer/HBoxContainer2/DeleteButton

# ¡LA CORRECCIÓN ESTÁ AQUÍ! Si el Label es hijo directo del Control raíz,
# la ruta es simplemente el nombre del nodo.
@onready var asistencia_label = $Label 

# --- VARIABLES ---
var asistencia: Dictionary = {} # {"México": false, "España": true}

func _ready() -> void:
	# Conectamos el botón de borrado (si no está ya conectado en el editor)
	if delete_btn:
		delete_btn.pressed.connect(Callable(self, "_on_delete_pressed"))
	
	# 1. Cargar datos previos (incluyendo los CheckButtons)
	load_asistencia()
	
	# 2. Inicializar el conteo visual
	_contar_y_actualizar_asistencia()


# ----------------------------------------------------------------------
# --- LÓGICA DE ASISTENCIA ---
# ----------------------------------------------------------------------

# --- AGREGAR PAÍS ---
func _on_add_button_pressed() -> void:
	var nombre = input_nombre.text.strip_edges()
	if nombre != "" and not asistencia.has(nombre):
		asistencia[nombre] = false
		_agregar_checkbutton(nombre, false)
		input_nombre.text = ""
		# Llama a guardar, que a su vez actualiza el Label
		_on_save_button_pressed() 


# --- CREAR CHECKBUTTON ---
func _agregar_checkbutton(nombre: String, marcado: bool) -> void:
	var check = CheckButton.new()
	check.text = nombre
	check.button_pressed = marcado
	
	# CONEXIÓN CLAVE: Al hacer clic, actualiza el diccionario y llama a guardar/contar
	check.toggled.connect(func(estado: bool) -> void:
		asistencia[nombre] = estado
		_on_save_button_pressed() 
	)
	paises_container.add_child(check)


# --- RESET ---
func _on_reset_button_pressed() -> void:
	for child in paises_container.get_children():
		if child is CheckButton:
			child.button_pressed = false
	for k in asistencia.keys():
		asistencia[k] = false
	# Llama a guardar, que actualizará el Label a 0
	_on_save_button_pressed() 


# --- DELETE ---
func _on_delete_pressed() -> void:
	# Vaciar diccionario
	asistencia.clear()

	# Borrar todos los hijos dentro del contenedor
	for child in paises_container.get_children():
		child.queue_free()

	# Guardar cambios (esto también actualizará el Label a 0/0)
	_on_save_button_pressed()

	print("🗑️ Lista de asistencia borrada")


# ----------------------------------------------------------------------
# --- LÓGICA DE CONTEO Y PERSISTENCIA ---
# ----------------------------------------------------------------------

# --- CONTAR Y ACTUALIZAR ASISTENCIAS ---
func _contar_y_actualizar_asistencia():
	var presentes = 0
	for nombre in asistencia.keys():
		# Cuenta solo si el valor en el diccionario es 'true'
		if asistencia[nombre]:
			presentes += 1
	
	var total = asistencia.size()
	
	if asistencia_label:
		# Actualiza el texto del Label
		asistencia_label.text = "Presentes: %d / %d" % [presentes, total]
		# Puedes añadir un print() temporal aquí para confirmar que esta línea se ejecuta.
		# print("Conteo actualizado: %d/%d" % [presentes, total])


# --- GUARDAR ---
func _on_save_button_pressed() -> void:
	# 1. ACTUALIZA EL LABEL antes de guardar
	_contar_y_actualizar_asistencia()
	
	# 2. Guarda los datos
	var path = "user://asistencia.json"
	var file = FileAccess.open(path, FileAccess.WRITE)
	file.store_string(JSON.stringify(asistencia, "\t"))
	file.close()
	print("✅ Guardado")


# --- CARGAR ---
func load_asistencia() -> void:
	var path = "user://asistencia.json"
	if FileAccess.file_exists(path):
		var file = FileAccess.open(path, FileAccess.READ)
		var content = file.get_as_text()
		file.close()
		var data = JSON.parse_string(content)
		if typeof(data) == TYPE_DICTIONARY:
			asistencia = data
			for nombre in asistencia.keys():
				_agregar_checkbutton(nombre, asistencia[nombre])
	
	# Actualiza el Label al cargar los datos iniciales
	_contar_y_actualizar_asistencia()


# --- CAMBIAR ESCENA ---
func _on_button_pressed() -> void:
	get_tree().change_scene_to_file("res://start_menu.tscn")
