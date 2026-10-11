extends Node3D

const Rules = preload("res://scripts/chess.gd")
const AI = preload("res://scripts/ai.gd")
const Models = preload("res://scripts/pieces.gd")
const NAMES = {
	1:["Soldado raso (Footman)","Grunt orco"], 2:["Hipogrifo","Gárgola"],
	3:["Frostmourne","Gujas de Illidan"], 4:["Torre humana","Torre orca"],
	5:["Jaina","Sylvanas"], 6:["Arthas","Thrall"]}
var chess = Rules.new()
var models = Models.new()
var pieces: Dictionary = {}
var highlights: Array[Node3D] = []
var history: Array = []
var selected = -1
var legal: Array = []
var human = 1
var elo = 800
var busy = false
var generation = 0
var ai_thread: Thread
var ai_generation = -1
var camera: Camera3D
var yaw = 0.0
var elevation = 0.80
var distance = 12.7
var dragging = false
var pointer_start = Vector2.ZERO
var pointer_last = Vector2.ZERO
var dragged = false
var contacts: Dictionary = {}
var pinch_distance = 0.0
var last_touch_time = -1000
var top_panel: PanelContainer
var heading: BoxContainer
var title_label: Label
var toolbar: GridContainer
var ui: Control
var status: Label
var detail: Label
var turn_label: Label
var elo_choice: OptionButton
var faction_choice: OptionButton
var new_dialog: ConfirmationDialog
var promotion_dialog: AcceptDialog
var promotion_pending: Array = []
var sound_enabled = true
var effects_enabled = true
var sound_toggle: Button
var effects_toggle: Button
var sound: AudioStreamPlayer
var move_sound: AudioStreamWAV
var capture_sound: AudioStreamWAV
var magic_sound: AudioStreamWAV
var last_move: Dictionary = {}
var flying: Array[Node3D] = []
var terminal = ""
var elapsed = 0.0
var mobile = OS.has_feature("mobile")

func _ready() -> void:
	create_world()
	create_ui()
	create_sounds()
	load_game()
	legal = chess.legal_moves()
	rebuild_pieces()
	update_status()
	if history.is_empty() and chess.fullmove == 1 and chess.turn == 1:
		new_dialog.popup_centered(Vector2i(520,340))
	else:
		maybe_start_ai()
	get_tree().auto_accept_quit = false

func create_world() -> void:
	var environment = WorldEnvironment.new()
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#0c1724")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8cacc9")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.environment = env
	add_child(environment)
	var sun = DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-52,-28,0)
	sun.light_color = Color("#ffe3ad")
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 24
	add_child(sun)
	var fill = DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-35,150,0)
	fill.light_color = Color("#67b5ef")
	fill.light_energy = 0.45
	add_child(fill)
	var floor_mesh = models.box(self,Vector3(0,-0.54,0),Vector3(200,0.15,200),Color("#17212a"))
	floor_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	models.box(self,Vector3(0,-0.28,0),Vector3(8.7,0.45,8.7),Color("#293743"))
	models.box(self,Vector3(0,-0.06,0),Vector3(8.35,0.10,8.35),models.gold)
	for rank in range(8):
		for file in range(8):
			var color = Color("#b1b2a0") if (rank+file)%2 else Color("#344b60")
			models.box(self,Vector3(file-3.5,0.01,3.5-rank),Vector3(0.98,0.10,0.98),color)
	for i in range(8):
		label_3d(String.chr(65+i),Vector3(i-3.5,0.01,4.23))
		label_3d(str(i+1),Vector3(-4.23,0.01,3.5-i))
	for side in [-1,1]:
		for z in [-4.8,4.8]:
			var x = side*4.8
			models.cone(self,Vector3(x,-0.13,z),0.34,0.25,0.8,models.dark)
			var orb_color = models.ice if side == -1 else Color("#e76540")
			models.ball(self,Vector3(x,0.41,z),Vector3(0.22,0.31,0.22),orb_color,true)
			var light = OmniLight3D.new()
			light.position = Vector3(x,0.9,z)
			light.light_color = orb_color
			light.light_energy = 1.1
			light.omni_range = 3.8
			add_child(light)
	camera = Camera3D.new()
	camera.fov = 48
	camera.near = 0.1
	camera.far = 120
	add_child(camera)
	camera.current = true
	update_camera()
	models.batch(self)

func label_3d(text: String, pos: Vector3) -> void:
	var label = Label3D.new()
	label.text = text
	label.font_size = 54
	label.pixel_size = 0.007
	label.modulate = models.gold
	label.outline_size = 0
	label.position = pos
	label.rotation_degrees.x = -90
	add_child(label)

func update_camera() -> void:
	if not is_instance_valid(camera):
		return
	var viewport_size = get_viewport().get_visible_rect().size
	if viewport_size.x <= 0 or viewport_size.y <= 0:
		return
	var portrait = viewport_size.y > viewport_size.x
	var factor = minf(1.0,viewport_size.x/(540.0 if portrait else 1180.0))
	# Keep the full board and tall figures outside both overlay panels.
	var inset = (330.0 if portrait else 240.0)*factor
	var bottom_inset = 110.0*factor
	var allowed = Rect2(Vector2(20*factor,inset),Vector2(viewport_size.x-40*factor,maxf(100,viewport_size.y-inset-bottom_inset)))
	var direction = Vector3(sin(yaw)*cos(elevation),sin(elevation),cos(yaw)*cos(elevation))
	var fitted_distance = 9.0
	for attempt in range(80):
		camera.v_offset = fitted_distance*tan(deg_to_rad(camera.fov)*0.5)*(inset-bottom_inset)/viewport_size.y
		camera.position = direction*fitted_distance
		camera.look_at(Vector3(0,0.1,0),Vector3.UP)
		var fits = true
		for x in [-4.5,4.5]:
			for z in [-4.5,4.5]:
				for y in [0.0,1.5]:
					if not allowed.has_point(camera.unproject_position(Vector3(x,y,z))):
						fits = false
		if fits:
			break
		fitted_distance *= 1.035
	camera.v_offset *= distance/12.7
	camera.position = direction*fitted_distance*(distance/12.7)
	camera.look_at(Vector3(0,0.1,0),Vector3.UP)

func style(bg: Color, border: Color = Color("#8b7448")) -> StyleBoxFlat:
	var s = StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(7)
	s.content_margin_left = 16
	s.content_margin_right = 16
	s.content_margin_top = 9
	s.content_margin_bottom = 9
	return s

func text_label(text: String, size: int, color: Color = Color("#ede2c8")) -> Label:
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size",size)
	label.add_theme_color_override("font_color",color)
	return label

func button(text: String, action: Callable) -> Button:
	var b = Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(0,64)
	b.pressed.connect(action)
	return b

func create_ui() -> void:
	var canvas = CanvasLayer.new()
	add_child(canvas)
	ui = Control.new()
	ui.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.add_child(ui)
	var theme = Theme.new()
	theme.default_font_size = 18
	for type in ["Button","OptionButton"]:
		theme.set_stylebox("normal",type,style(Color("#1b2c3d")))
		theme.set_stylebox("hover",type,style(Color("#304c63"),models.gold))
		theme.set_stylebox("pressed",type,style(Color("#466075"),models.gold))
		theme.set_stylebox("focus",type,style(Color(0,0,0,0),Color("#92d4f7")))
		theme.set_color("font_color",type,Color("#eee2c9"))
	theme.set_stylebox("panel","PanelContainer",style(Color(0.045,0.075,0.115,0.96)))
	theme.set_stylebox("panel","PopupMenu",style(Color("#122438")))
	theme.set_stylebox("panel","Window",style(Color("#122438")))
	ui.theme = theme
	var top = PanelContainer.new()
	top_panel = top
	top.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	top.offset_left = 18
	top.offset_top = 16
	top.offset_right = -18
	top.offset_bottom = 140
	ui.add_child(top)
	var rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation",7)
	top.add_child(rows)
	heading = BoxContainer.new()
	rows.add_child(heading)
	var title = text_label("AZEROTH / CHESS 3D",24,models.gold)
	title_label = title
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	heading.add_child(title)
	turn_label = text_label("ALIANZA",20,models.ice)
	heading.add_child(turn_label)
	toolbar = GridContainer.new()
	toolbar.columns = 8
	toolbar.add_theme_constant_override("separation",10)
	rows.add_child(toolbar)
	toolbar.add_child(button("Nueva partida",func(): new_dialog.popup_centered(Vector2i(520,340))))
	toolbar.add_child(button("Deshacer",undo_turn))
	toolbar.add_child(button("Girar",func(): yaw += PI; update_camera()))
	toolbar.add_child(button("−",func(): distance = minf(19,distance+1); update_camera()))
	toolbar.add_child(button("+",func(): distance = maxf(9,distance-1); update_camera()))
	toolbar.add_child(button("Ayuda",show_help))
	sound_toggle = button("Sonido: sí",func(): pass)
	sound_toggle.pressed.connect(func(): sound_enabled = not sound_enabled; sound_toggle.text = "Sonido: sí" if sound_enabled else "Sonido: no"; save_game())
	toolbar.add_child(sound_toggle)
	effects_toggle = button("Magia: sí",func(): pass)
	effects_toggle.pressed.connect(func(): effects_enabled = not effects_enabled; effects_toggle.text = "Magia: sí" if effects_enabled else "Magia: no"; save_game())
	toolbar.add_child(effects_toggle)
	var bottom = PanelContainer.new()
	bottom.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	bottom.offset_left = 18
	bottom.offset_right = -18
	bottom.offset_top = -88
	bottom.offset_bottom = -16
	ui.add_child(bottom)
	var bottom_rows = VBoxContainer.new()
	bottom.add_child(bottom_rows)
	status = text_label("Tu turno · elegí una figura",21)
	bottom_rows.add_child(status)
	detail = text_label("Tocá para jugar · arrastrá para girar · pellizcá para acercar",16,Color("#9cafbf"))
	bottom_rows.add_child(detail)
	detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	create_new_dialog()
	promotion_dialog = AcceptDialog.new()
	promotion_dialog.title = "Coronación"
	promotion_dialog.dialog_text = "Elegí la nueva figura para tu peón."
	promotion_dialog.get_ok_button().hide()
	promotion_dialog.canceled.connect(func(): promotion_pending.clear())
	ui.add_child(promotion_dialog)
	promotion_dialog.theme = theme
	# Responsive canvas maintains touch target sizes on small landscape screens.
	get_viewport().size_changed.connect(resize_ui)
	resize_ui()

func resize_ui() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var portrait = viewport_size.y > viewport_size.x
	var factor = minf(1.0,viewport_size.x/(540.0 if portrait else 1180.0))
	ui.scale = Vector2(factor,factor)
	ui.size = viewport_size / factor
	heading.vertical = portrait
	toolbar.columns = 3 if portrait else 4
	for control in toolbar.get_children():
		control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_panel.offset_bottom = 310 if portrait else 220
	update_camera()

func create_new_dialog() -> void:
	new_dialog = ConfirmationDialog.new()
	new_dialog.title = "Preparar la batalla"
	new_dialog.ok_button_text = "Jugar"
	new_dialog.cancel_button_text = "Volver"
	new_dialog.dialog_text = ""
	ui.add_child(new_dialog)
	new_dialog.theme = ui.theme
	var form = VBoxContainer.new()
	form.add_theme_constant_override("separation",14)
	new_dialog.add_child(form)
	form.add_child(text_label("Elegí tu ejército",22,models.gold))
	faction_choice = OptionButton.new()
	faction_choice.add_item("Alianza · blancas · primer movimiento")
	faction_choice.add_item("Horda · negras")
	faction_choice.custom_minimum_size.y = 48
	form.add_child(faction_choice)
	form.add_child(text_label("Dificultad de la inteligencia artificial",18))
	elo_choice = OptionButton.new()
	for value in range(100,2001,100):
		elo_choice.add_item("%d ELO aproximado" % value)
	elo_choice.select(7)
	elo_choice.custom_minimum_size.y = 48
	form.add_child(elo_choice)
	form.add_child(text_label("20 niveles orientativos · juego sin conexión",16,Color("#9cafbf")))
	new_dialog.confirmed.connect(start_new_game)

func start_new_game() -> void:
	generation += 1
	chess.reset()
	history.clear()
	last_move.clear()
	human = 1 if faction_choice.selected == 0 else -1
	elo = (elo_choice.selected+1)*100
	selected = -1
	busy = false
	terminal = ""
	yaw = 0 if human == 1 else PI
	update_camera()
	legal = chess.legal_moves()
	clear_highlights()
	rebuild_pieces()
	save_game()
	update_status()
	maybe_start_ai()

func show_help() -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Los ejércitos de Azeroth"
	dialog.ok_button_text = "Volver al tablero"
	dialog.dialog_text = (
		"ALIANZA                      HORDA\n"+
		"Rey: Arthas                   Rey: Thrall\n"+
		"Dama: Jaina                  Dama: Sylvanas\n"+
		"Peón: Footman humano    Peón: Grunt orco\n"+
		"Caballo: hipogrifo          Caballo: gárgola\n"+
		"Alfil: Frostmourne         Alfil: gujas de Illidan\n"+
		"Torre: fortaleza humana   Torre: fortaleza orca\n\n"+
		"Tocá una figura y después una casilla iluminada.\n"+
		"Arrastrá el tablero para girar la cámara. Pellizcá para zoom.\n"+
		"En computadora: arrastrá, rueda del mouse o botones + / −.\n"+
		"Enroque: mové el rey dos casillas. Coronación: elegí figura.\n"+
		"Captura al paso disponible en el turno siguiente al avance doble.\n"+
		"Deshacer vuelve a tu turno anterior. La partida se guarda sola.\n\n"+
		"Los ELO son niveles nominales, sin calibración competitiva.\n"+
		"Esculturas originales low poly inspiradas en fantasía Warcraft.")
	ui.add_child(dialog)
	dialog.theme = ui.theme
	dialog.popup_centered()
	dialog.confirmed.connect(dialog.queue_free)
	dialog.canceled.connect(dialog.queue_free)

func square_position(s: int) -> Vector3:
	return Vector3(s%8-3.5,0.07,3.5-(s/8 as int))

func rebuild_pieces() -> void:
	for node in pieces.values():
		node.queue_free()
	pieces.clear()
	flying.clear()
	for s in range(64):
		if chess.board[s] == 0:
			continue
		var node = models.create(chess.board[s])
		add_child(node)
		node.position = square_position(s)
		pieces[s] = node
		var flier = node.get_node_or_null("Sculpture/Flying")
		if flier:
			flying.append(flier)

func clear_highlights() -> void:
	for h in highlights:
		h.queue_free()
	highlights.clear()

func highlight(s: int, color: Color) -> void:
	var shape = CylinderMesh.new()
	shape.top_radius = 0.43
	shape.bottom_radius = 0.43
	shape.height = 0.015
	shape.radial_segments = 24
	var h = models.mesh(self,shape,square_position(s)+Vector3(0,0.01,0),color,Vector3.ZERO,true)
	h.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	highlights.append(h)

func select_square(s: int) -> void:
	if busy or not terminal.is_empty() or chess.turn != human or not promotion_pending.is_empty():
		return
	var candidates = legal.filter(func(m): return m["from"] == selected and m["to"] == s)
	if not candidates.is_empty():
		if candidates.size() > 1:
			offer_promotion(candidates)
		else:
			animate_move(candidates[0])
		return
	clear_highlights()
	selected = s if signi(chess.board[s]) == human else -1
	if selected >= 0:
		highlight(s,models.gold)
		for m in legal:
			if m["from"] == s:
				highlight(m["to"],Color("#547f96") if chess.board[m["to"]] == 0 else Color("#a75450"))
		detail.text = "%s · %s" % [NAMES[absi(chess.board[s])][0 if human == 1 else 1],notation(s)]
	else:
		detail.text = "Tocá para jugar · arrastrá para girar · pellizcá para acercar"

func notation(s: int) -> String:
	return String.chr(97+s%8)+str(int(s/8)+1)

func offer_promotion(candidates: Array) -> void:
	promotion_pending = candidates
	var old = promotion_dialog.get_node_or_null("Choices")
	if old:
		promotion_dialog.remove_child(old)
		old.queue_free()
	var choices = HBoxContainer.new()
	choices.name = "Choices"
	promotion_dialog.add_child(choices)
	for m in candidates:
		var choice = m.duplicate()
		var label = {5:"Dama",4:"Torre",3:"Alfil",2:"Caballo"}[m["promotion"]]
		choices.add_child(button(label,func():
			promotion_pending.clear()
			promotion_dialog.hide()
			animate_move(choice)))
	promotion_dialog.popup_centered(Vector2i(mini(560,int(get_viewport().get_visible_rect().size.x)-24),190))

func animate_move(m: Dictionary) -> void:
	busy = true
	selected = -1
	clear_highlights()
	var token = generation
	var a: int = m["from"]
	var b: int = m["to"]
	var piece = chess.board[a]
	var captured = chess.board[b] != 0
	var capture_square = b
	if absi(piece) == 1 and b == chess.ep and not captured:
		capture_square = b - chess.turn*8
		captured = true
	history.append(chess.serialize())
	if history.size() > 400:
		history.pop_front()
	chess.play(m)
	last_move = m.duplicate()
	save_game()
	play_sound(capture_sound if captured else move_sound)
	if effects_enabled:
		magic_effect(square_position(b),models.ice if piece > 0 else models.violet)
	var tween = create_tween().set_parallel(true)
	if pieces.has(a):
		tween.tween_property(pieces[a],"position",square_position(b),0.34).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	if captured and pieces.has(capture_square):
		tween.tween_property(pieces[capture_square],"scale",Vector3.ZERO,0.25)
	if absi(piece) == 6 and absi(b-a) == 2:
		var rook_from = a+3 if b>a else a-4
		var rook_to = a+1 if b>a else a-1
		if pieces.has(rook_from):
			tween.tween_property(pieces[rook_from],"position",square_position(rook_to),0.34)
	await tween.finished
	if token != generation:
		return
	rebuild_pieces()
	highlight(a,Color("#756641"))
	highlight(b,Color("#756641"))
	legal = chess.legal_moves()
	busy = false
	update_status()
	if chess.in_check(chess.turn):
		play_sound(magic_sound)
		var king = chess.board.find(chess.turn*6)
		if effects_enabled:
			magic_effect(square_position(king),Color("#ef6150"))
	maybe_start_ai()

func magic_effect(pos: Vector3, color: Color) -> void:
	var effect = Node3D.new()
	add_child(effect)
	effect.position = pos
	var torus = TorusMesh.new()
	torus.inner_radius = 0.32
	torus.outer_radius = 0.38
	torus.rings = 16
	torus.ring_segments = 8
	models.mesh(effect,torus,Vector3(0,0.08,0),color,Vector3.ZERO,true)
	for i in range(8):
		var angle = i*TAU/8
		models.ball(effect,Vector3(cos(angle)*0.32,0.13,sin(angle)*0.32),Vector3(0.035,0.15,0.035),color,true)
	var tween = create_tween().set_parallel(true)
	tween.tween_property(effect,"scale",Vector3(1.65,3.0,1.65),0.60)
	tween.tween_property(effect,"position:y",pos.y+0.7,0.60)
	tween.chain().tween_callback(effect.queue_free)

func maybe_start_ai() -> void:
	if busy or not terminal.is_empty() or chess.turn == human:
		return
	if ai_thread != null:
		return
	busy = true
	ai_generation = generation
	var snapshot = chess.copy()
	var strength = elo
	ai_thread = Thread.new()
	var error = ai_thread.start(func(): return AI.new().choose(snapshot,strength))
	if error != OK:
		ai_thread = null
		busy = false
		status.text = "No se pudo iniciar la IA. Usá Nueva partida para reintentar."
	else:
		status.text = "La IA está pensando · %d ELO aproximado" % elo

func _process(delta: float) -> void:
	elapsed += delta
	if effects_enabled:
		for node in flying:
			if not is_instance_valid(node):
				continue
			node.position.y = 0.18 + sin(elapsed*2.3+node.get_instance_id()%11)*0.035
			var phase = sin(elapsed*3.2)*0.17
			node.get_node("WingL").rotation.z = phase
			node.get_node("WingR").rotation.z = -phase
	if ai_thread != null and not ai_thread.is_alive():
		var move = ai_thread.wait_to_finish()
		ai_thread = null
		if ai_generation == generation and chess.turn != human and not move.is_empty():
			busy = false
			animate_move(move)
		else:
			busy = false
			maybe_start_ai()

func update_status() -> void:
	terminal = chess.result(legal)
	turn_label.text = ("ALIANZA" if chess.turn == 1 else "HORDA") + "  ·  %d ELO" % elo
	turn_label.add_theme_color_override("font_color",models.ice if chess.turn == 1 else Color("#e58175"))
	if not terminal.is_empty():
		status.text = terminal + (" · jaque mate" if chess.in_check(chess.turn) else "")
	elif chess.turn == human:
		status.text = "Jaque: protegé a tu rey" if chess.in_check(human) else "Tu turno · elegí una figura"
	else:
		status.text = "Turno de la IA"
	detail.text = "Movimiento %d · %s · arrastrá para girar · pellizcá para zoom" % [chess.fullmove,"Alianza" if human == 1 else "Horda"]

func undo_turn() -> void:
	if busy or history.is_empty() or not promotion_pending.is_empty():
		return
	generation += 1
	var previous = history.pop_back()
	while int(previous["turn"]) != human and not history.is_empty():
		previous = history.pop_back()
	chess.restore(previous)
	last_move.clear()
	legal = chess.legal_moves()
	selected = -1
	clear_highlights()
	rebuild_pieces()
	update_status()
	save_game()
	maybe_start_ai()

func pick(pos: Vector2) -> void:
	var origin = camera.project_ray_origin(pos)
	var dir = camera.project_ray_normal(pos)
	var hit = Plane(Vector3.UP,0.07).intersects_ray(origin,dir)
	if hit == null:
		return
	var file = floori(hit.x+4)
	var rank = floori(4-hit.z)
	if file >= 0 and file < 8 and rank >= 0 and rank < 8:
		select_square(rank*8+file)

func rotate_pointer(pos: Vector2) -> void:
	if pos.distance_to(pointer_start) > 14:
		dragged = true
	if dragged:
		var change = pos-pointer_last
		yaw -= change.x*0.006
		elevation = clampf(elevation+change.y*0.004,0.38,1.32)
		update_camera()
	pointer_last = pos

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		last_touch_time = Time.get_ticks_msec()
		if event.pressed:
			contacts[event.index] = event.position
			if contacts.size() == 1:
				pointer_start = event.position
				pointer_last = event.position
				dragged = false
			else:
				dragged = true
				pinch_distance = pinch_span()
		else:
			if contacts.size() == 1 and not dragged:
				pick(event.position)
			contacts.erase(event.index)
			if contacts.size() == 1:
				pointer_last = contacts.values()[0]
		return
	if event is InputEventScreenDrag:
		last_touch_time = Time.get_ticks_msec()
		contacts[event.index] = event.position
		if contacts.size() == 2:
			var span = pinch_span()
			if pinch_distance > 0 and span > 0:
				distance = clampf(distance*pinch_distance/span,9,19)
				update_camera()
			pinch_distance = span
		elif contacts.size() == 1:
			rotate_pointer(event.position)
		return
	if Time.get_ticks_msec()-last_touch_time < 500:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				dragging = true
				dragged = false
				pointer_start = event.position
				pointer_last = event.position
			elif dragging:
				dragging = false
				if not dragged:
					pick(event.position)
		elif event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN]:
			distance = clampf(distance + (-0.7 if event.button_index == MOUSE_BUTTON_WHEEL_UP else 0.7),9,19)
			update_camera()
	elif event is InputEventMouseMotion and dragging:
		rotate_pointer(event.position)

func pinch_span() -> float:
	var points = contacts.values()
	return points[0].distance_to(points[1]) if points.size() == 2 else 0.0

func create_sounds() -> void:
	sound = AudioStreamPlayer.new()
	sound.volume_db = -13
	add_child(sound)
	move_sound = synth(260,0.15,0)
	capture_sound = synth(115,0.26,1)
	magic_sound = synth(610,0.40,2)

func synth(frequency: float, seconds: float, kind: int) -> AudioStreamWAV:
	var rate = 22050
	var samples = PackedByteArray()
	samples.resize(int(seconds*rate)*2)
	for i in range(samples.size()/2 as int):
		var t = float(i)/rate
		var envelope = exp(-t*(16 if kind == 0 else 8))*minf(t*100,1)
		var f = frequency*(1+0.7*t if kind == 2 else 1-0.3*t)
		var wave = sin(TAU*f*t)+0.3*sin(TAU*f*2.01*t)
		if kind == 1:
			wave += sin(float(i)*12.9898)*0.22
		var value = clampi(int(wave*envelope*18000),-32768,32767)
		samples.encode_s16(i*2,value)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = rate
	stream.data = samples
	return stream

func play_sound(stream: AudioStreamWAV) -> void:
	if sound_enabled:
		sound.stream = stream
		sound.play()

func save_game() -> void:
	var data = {"version":1,"position":chess.serialize(),"history":history,
		"human":human,"elo":elo,"sound":sound_enabled,"effects":effects_enabled}
	var file = FileAccess.open("user://battle.json.tmp",FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
		file.close()
		DirAccess.rename_absolute("user://battle.json.tmp","user://battle.json")

func load_game() -> void:
	if not FileAccess.file_exists("user://battle.json"):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string("user://battle.json"))
	if not data is Dictionary or data.get("version",0) != 1:
		return
	if not data.get("position",null) is Dictionary or not chess.restore(data["position"]):
		return
	human = int(data.get("human",1))
	if human not in [-1,1]:
		human = 1
	elo = clampi(int(data.get("elo",800))/100 as int,1,20)*100
	if data.get("history",[]) is Array:
		for snapshot in data.get("history",[]):
			var check = Rules.new()
			if snapshot is Dictionary and check.restore(snapshot):
				history.append(snapshot)
	sound_enabled = bool(data.get("sound",true))
	effects_enabled = bool(data.get("effects",true))
	sound_toggle.text = "Sonido: sí" if sound_enabled else "Sonido: no"
	effects_toggle.text = "Magia: sí" if effects_enabled else "Magia: no"
	faction_choice.select(0 if human == 1 else 1)
	elo_choice.select(int(elo/100)-1)
	yaw = 0 if human == 1 else PI
	update_camera()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
	if what == NOTIFICATION_WM_GO_BACK_REQUEST and is_instance_valid(new_dialog):
		if new_dialog.visible:
			new_dialog.hide()
		else:
			new_dialog.popup_centered(Vector2i(520,340))

func _exit_tree() -> void:
	if ai_thread != null:
		ai_thread.wait_to_finish()
