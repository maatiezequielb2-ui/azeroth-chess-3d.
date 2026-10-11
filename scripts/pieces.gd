class_name PieceModels
extends RefCounted

# Original, faceted 3D sculpture built from meshes; no billboard pieces.
var materials: Dictionary = {}
var templates: Dictionary = {}
var blue = Color("#2677bd")
var red = Color("#942c31")
var steel = Color("#a4b7c7")
var dark = Color("#293b4b")
var gold = Color("#d7b56b")
var skin = Color("#e4b990")
var green = Color("#568853")
var ice = Color("#69dcff")
var violet = Color("#ac69ef")

func mat(color: Color, glow: bool = false) -> StandardMaterial3D:
	var key = str(color) + str(glow)
	if materials.has(key):
		return materials[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.72
	if color == steel or color == gold:
		m.metallic = 0.55
	if glow:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 1.8
	materials[key] = m
	return m

func mesh(parent: Node3D, shape: Mesh, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO, glow: bool = false) -> MeshInstance3D:
	var n = MeshInstance3D.new()
	n.mesh = shape
	n.material_override = mat(color, glow)
	parent.add_child(n)
	n.position = pos
	n.rotation_degrees = rot
	return n

func box(parent: Node3D, pos: Vector3, size: Vector3, color: Color, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var shape = BoxMesh.new()
	shape.size = size
	return mesh(parent,shape,pos,color,rot)

func cone(parent: Node3D, pos: Vector3, bottom: float, top: float, height: float, color: Color, rot: Vector3 = Vector3.ZERO, glow: bool = false) -> MeshInstance3D:
	var shape = CylinderMesh.new()
	shape.bottom_radius = bottom
	shape.top_radius = top
	shape.height = height
	shape.radial_segments = 10
	return mesh(parent,shape,pos,color,rot,glow)

func ball(parent: Node3D, pos: Vector3, size: Vector3, color: Color, glow: bool = false) -> MeshInstance3D:
	var shape = SphereMesh.new()
	shape.radius = 0.5
	shape.height = 1.0
	shape.radial_segments = 12
	shape.rings = 6
	var n = mesh(parent,shape,pos,color,Vector3.ZERO,glow)
	n.scale = size
	return n

func triangle(parent: Node3D, a: Vector3, b: Vector3, c: Vector3, color: Color) -> void:
	var st = SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.add_vertex(a)
	st.add_vertex(b)
	st.add_vertex(c)
	st.add_vertex(c)
	st.add_vertex(b)
	st.add_vertex(a)
	st.generate_normals()
	mesh(parent,st.commit(),Vector3.ZERO,color)

func create(piece: int) -> Node3D:
	if templates.has(piece):
		return templates[piece].instantiate()
	var root = Node3D.new()
	var alliance = piece > 0
	var faction = blue if alliance else red
	cone(root,Vector3(0,0.055,0),0.34,0.34,0.11,dark)
	cone(root,Vector3(0,0.125,0),0.32,0.29,0.035,gold if alliance else red)
	var body = Node3D.new()
	body.name = "Sculpture"
	root.add_child(body)
	body.rotation.y = 0 if alliance else PI
	match absi(piece):
		1: soldier(body,alliance,faction)
		2: creature(body,alliance,faction)
		3: weapon(body,alliance)
		4: tower(body,alliance,faction)
		5: heroine(body,alliance,faction)
		6: hero(body,alliance,faction)
	var flier = body.get_node_or_null("Flying")
	if flier:
		batch(flier.get_node("WingL"))
		batch(flier.get_node("WingR"))
		batch(flier)
	batch(body)
	batch(root)
	set_owners(root,root)
	var packed = PackedScene.new()
	if packed.pack(root) == OK:
		templates[piece] = packed
	return root

func set_owners(node: Node, root: Node) -> void:
	for child in node.get_children():
		child.owner = root
		set_owners(child,root)

func batch(parent: Node3D) -> void:
	# Batch immediate static meshes by material. Animated subnodes remain separate.
	var grouped: Dictionary = {}
	var originals: Array = []
	for child in parent.get_children():
		if child is MeshInstance3D and child.mesh:
			var material = child.material_override
			if not grouped.has(material):
				var st = SurfaceTool.new()
				st.begin(Mesh.PRIMITIVE_TRIANGLES)
				grouped[material] = st
			grouped[material].append_from(child.mesh,0,child.transform)
			originals.append(child)
	for material in grouped:
		var combined = MeshInstance3D.new()
		combined.mesh = grouped[material].commit()
		combined.material_override = material
		parent.add_child(combined)
	for child in originals:
		child.free()

func humanoid(parent: Node3D, alliance: bool, faction: Color, height: float = 1.0) -> void:
	var flesh = skin if alliance else green
	box(parent,Vector3(-0.105,0.30,0),Vector3(0.13,0.30,0.17),dark)
	box(parent,Vector3(0.105,0.30,0),Vector3(0.13,0.30,0.17),dark)
	box(parent,Vector3(0,0.54,0),Vector3(0.33,0.34,0.21),faction)
	ball(parent,Vector3(0,height*0.82,0),Vector3(0.27,0.30,0.25),flesh)
	box(parent,Vector3(-0.24,0.58,0),Vector3(0.13,0.32,0.15),flesh,Vector3(0,0,-12))
	box(parent,Vector3(0.24,0.58,0),Vector3(0.13,0.32,0.15),flesh,Vector3(0,0,12))
	box(parent,Vector3(-0.22,0.73,0),Vector3(0.23,0.13,0.27),steel if alliance else dark)
	box(parent,Vector3(0.22,0.73,0),Vector3(0.23,0.13,0.27),steel if alliance else dark)
	box(parent,Vector3(0,0.43,-0.125),Vector3(0.34,0.045,0.03),gold)
	ball(parent,Vector3(-0.065,height*0.85,-0.117),Vector3(0.035,0.027,0.02),ice if alliance else red,true)
	ball(parent,Vector3(0.065,height*0.85,-0.117),Vector3(0.035,0.027,0.02),ice if alliance else red,true)

func blade(parent: Node3D, pos: Vector3, color: Color, frost: bool = false) -> void:
	var sword = Node3D.new()
	parent.add_child(sword)
	sword.position = pos
	box(sword,Vector3(0,0.03,0),Vector3(0.055,0.20,0.06),dark)
	box(sword,Vector3(0,0.17,0),Vector3(0.29,0.045,0.08),gold if not frost else steel)
	cone(sword,Vector3(0,0.52,0),0.06,0.012,0.67,color,Vector3.ZERO,frost)
	if frost:
		for h in [0.29,0.41,0.53,0.65]:
			ball(sword,Vector3(0,h,-0.05),Vector3(0.025,0.06,0.018),ice,true)
		ball(sword,Vector3(0,0.16,-0.06),Vector3(0.11,0.12,0.065),steel)
		for side in [-1,1]:
			cone(sword,Vector3(side*0.12,0.22,0),0.035,0,0.19,steel,Vector3(0,0,-side*55))

func soldier(parent: Node3D, alliance: bool, faction: Color) -> void:
	humanoid(parent,alliance,faction)
	if alliance:
		ball(parent,Vector3(0,0.90,0),Vector3(0.32,0.20,0.30),steel)
		box(parent,Vector3(0,0.84,-0.145),Vector3(0.25,0.055,0.025),dark)
		box(parent,Vector3(0,0.99,0),Vector3(0.04,0.13,0.20),blue)
		ball(parent,Vector3(-0.29,0.52,-0.10),Vector3(0.30,0.40,0.10),steel)
		box(parent,Vector3(-0.29,0.52,-0.16),Vector3(0.13,0.25,0.03),blue)
		blade(parent,Vector3(0.29,0.35,-0.04),steel)
	else:
		box(parent,Vector3(0,0.92,0.02),Vector3(0.11,0.11,0.25),dark)
		for side in [-1,1]:
			cone(parent,Vector3(side*0.10,0.75,-0.12),0.035,0,0.14,Color("#f6e6bd"),Vector3(0,0,-side*20))
		cone(parent,Vector3(0.31,0.66,0),0.027,0.027,0.76,Color("#735138"))
		box(parent,Vector3(0.34,0.97,0),Vector3(0.27,0.18,0.08),steel,Vector3(0,0,-18))
		cone(parent,Vector3(-0.22,0.85,0),0.04,0,0.19,steel,Vector3(0,0,-25))

func hero(parent: Node3D, alliance: bool, faction: Color) -> void:
	humanoid(parent,alliance,faction)
	# Long cloak and monumental pauldrons define the kings.
	box(parent,Vector3(0,0.51,0.18),Vector3(0.42,0.67,0.07),blue if alliance else Color("#473e31"))
	for side in [-1,1]:
		ball(parent,Vector3(side*0.24,0.77,0),Vector3(0.32,0.21,0.33),steel if alliance else dark)
		cone(parent,Vector3(side*0.29,0.94,0),0.045,0,0.26,steel,Vector3(0,0,-side*25))
	if alliance: # Arthas: flowing blond hair, icy plate, Frostmourne.
		ball(parent,Vector3(0,0.94,0.025),Vector3(0.34,0.23,0.30),gold)
		box(parent,Vector3(-0.14,0.82,0.025),Vector3(0.07,0.27,0.25),gold)
		box(parent,Vector3(0.14,0.82,0.025),Vector3(0.07,0.27,0.25),gold)
		box(parent,Vector3(0,0.62,-0.125),Vector3(0.25,0.24,0.05),steel)
		blade(parent,Vector3(0.33,0.23,-0.10),ice,true)
		ball(parent,Vector3(0,0.64,-0.17),Vector3(0.10,0.11,0.025),ice,true)
	else: # Thrall: green skin, black braids, Doomhammer and wolf armour.
		ball(parent,Vector3(0,0.94,0.02),Vector3(0.30,0.21,0.29),dark)
		for side in [-1,1]:
			cone(parent,Vector3(side*0.15,0.79,0.03),0.05,0.055,0.33,dark)
			cone(parent,Vector3(side*0.085,0.75,-0.125),0.03,0,0.16,Color("#f6e6bd"))
		cone(parent,Vector3(0.35,0.59,0),0.04,0.04,0.66,Color("#735138"))
		box(parent,Vector3(0.35,0.96,0),Vector3(0.32,0.22,0.24),steel)
		box(parent,Vector3(0.35,0.96,-0.128),Vector3(0.12,0.12,0.015),gold)
		ball(parent,Vector3(-0.25,0.77,-0.06),Vector3(0.29,0.22,0.36),Color("#989b8a"))
		cone(parent,Vector3(-0.25,0.77,-0.27),0.07,0.02,0.18,dark,Vector3(90,0,0))

func heroine(parent: Node3D, alliance: bool, faction: Color) -> void:
	if alliance: # Jaina: white/blond hair, blue robe, crystal staff.
		cone(parent,Vector3(0,0.46,0),0.29,0.12,0.62,Color("#d9dde1"))
		cone(parent,Vector3(0,0.51,0),0.22,0.12,0.57,blue)
		ball(parent,Vector3(0,0.88,0),Vector3(0.25,0.29,0.23),skin)
		ball(parent,Vector3(0,0.98,0.02),Vector3(0.30,0.19,0.27),Color("#ece1b0"))
		box(parent,Vector3(-0.14,0.85,0.05),Vector3(0.09,0.29,0.20),Color("#ece1b0"))
		box(parent,Vector3(0.14,0.85,0.05),Vector3(0.09,0.29,0.20),Color("#ece1b0"))
		box(parent,Vector3(0,0.69,-0.12),Vector3(0.17,0.09,0.04),gold)
		cone(parent,Vector3(0.33,0.67,0),0.027,0.027,1.04,gold)
		ball(parent,Vector3(0.33,1.23,0),Vector3(0.15,0.20,0.15),ice,true)
		cone(parent,Vector3(0.33,1.13,0),0.10,0.04,0.13,gold)
		box(parent,Vector3(0.23,0.67,0),Vector3(0.24,0.10,0.12),blue)
		ball(parent,Vector3(-0.27,0.66,-0.03),Vector3(0.17,0.17,0.17),ice,true)
	else: # Sylvanas: hood, red eyes, elf ears, dark cape and curved bow.
		humanoid(parent,true,Color("#4d3a65"))
		box(parent,Vector3(0,0.50,0.16),Vector3(0.41,0.69,0.08),Color("#482c57"))
		ball(parent,Vector3(0,0.93,0.04),Vector3(0.36,0.34,0.32),Color("#482c57"))
		ball(parent,Vector3(0,0.86,-0.115),Vector3(0.22,0.23,0.075),Color("#a5b4bb"))
		for side in [-1,1]:
			ball(parent,Vector3(side*0.055,0.88,-0.158),Vector3(0.04,0.028,0.025),red,true)
			cone(parent,Vector3(side*0.18,0.90,-0.03),0.05,0,0.21,Color("#a5b4bb"),Vector3(0,0,-side*60))
		var bow = Node3D.new()
		parent.add_child(bow)
		bow.position = Vector3(-0.35,0.67,-0.10)
		for side in [-1,1]:
			box(bow,Vector3(-0.06,side*0.17,0),Vector3(0.045,0.40,0.06),gold,Vector3(0,0,side*22))
			box(bow,Vector3(0,side*0.36,0),Vector3(0.045,0.17,0.06),gold,Vector3(0,0,-side*35))
		box(bow,Vector3(0.08,0,0),Vector3(0.012,0.81,0.012),steel)

func weapon(parent: Node3D, alliance: bool) -> void:
	if alliance: # Frostmourne bishops, set in an ice plinth.
		cone(parent,Vector3(0,0.23,0),0.22,0.10,0.19,dark)
		blade(parent,Vector3(0,0.21,0),ice,true)
		for side in [-1,1]:
			cone(parent,Vector3(side*0.19,0.31,0.06),0.08,0,0.34,ice,Vector3(0,0,-side*22),true)
	else: # Illidan's paired crescent warglaives.
		cone(parent,Vector3(0,0.28,0),0.23,0.12,0.25,dark)
		for side in [-1,1]:
			var glaive = Node3D.new()
			parent.add_child(glaive)
			glaive.position = Vector3(side*0.12,0.75,0)
			glaive.rotation.z = side*0.35
			cone(glaive,Vector3.ZERO,0.03,0.03,0.43,gold)
			for end in [-1,1]:
				triangle(glaive,Vector3(0,end*0.20,-0.04),Vector3(side*0.34,end*0.50,-0.04),Vector3(side*0.28,end*0.13,-0.04),steel)
				triangle(glaive,Vector3(0,end*0.20,-0.045),Vector3(side*0.29,end*0.40,-0.045),Vector3(side*0.18,end*0.17,-0.045),green)
			ball(glaive,Vector3(0,0,-0.06),Vector3(0.09,0.11,0.05),green,true)

func tower(parent: Node3D, alliance: bool, faction: Color) -> void:
	if alliance:
		box(parent,Vector3(0,0.51,0),Vector3(0.45,0.71,0.45),Color("#9a9d96"))
		box(parent,Vector3(0,0.22,0),Vector3(0.54,0.12,0.54),dark)
		box(parent,Vector3(0,0.89,0),Vector3(0.56,0.11,0.56),steel)
		for x in [-0.20,0,0.20]:
			for z in [-0.20,0.20]:
				box(parent,Vector3(x,1.01,z),Vector3(0.12,0.18,0.12),steel)
		box(parent,Vector3(0,0.57,-0.231),Vector3(0.10,0.24,0.013),dark)
		box(parent,Vector3(0,0.32,-0.24),Vector3(0.24,0.27,0.02),Color("#64503c"))
		cone(parent,Vector3(0.22,1.14,0.1),0.013,0.013,0.38,gold)
		box(parent,Vector3(0.31,1.27,0.1),Vector3(0.17,0.14,0.018),faction)
	else:
		cone(parent,Vector3(0,0.54,0),0.27,0.20,0.76,Color("#69533b"))
		for x in [-0.19,0.19]:
			for z in [-0.19,0.19]:
				cone(parent,Vector3(x,0.64,z),0.055,0.035,0.91,Color("#493828"))
		cone(parent,Vector3(0,0.96,0),0.39,0.26,0.22,faction)
		cone(parent,Vector3(0,1.13,0),0.27,0,0.21,dark)
		for side in [-1,1]:
			cone(parent,Vector3(side*0.31,1.04,0),0.06,0,0.37,Color("#e5d9b5"),Vector3(0,0,-side*35))
		box(parent,Vector3(0,0.55,-0.26),Vector3(0.17,0.22,0.05),dark)
		ball(parent,Vector3(0,0.86,-0.31),Vector3(0.13,0.13,0.05),Color("#e5d9b5"))

func creature(parent: Node3D, alliance: bool, faction: Color) -> void:
	var beast = Node3D.new()
	beast.name = "Flying"
	parent.add_child(beast)
	beast.position.y = 0.18
	var hide = Color("#7c869c") if alliance else Color("#596171")
	ball(beast,Vector3(0,0.57,0),Vector3(0.34,0.30,0.60),hide)
	if alliance: # Hippogryph: avian head/beak, equine hindquarters, antlers.
		ball(beast,Vector3(0,0.79,-0.24),Vector3(0.26,0.31,0.27),Color("#c9d3d1"))
		cone(beast,Vector3(0,0.76,-0.44),0.08,0,0.22,gold,Vector3(90,0,0))
		for side in [-1,1]:
			box(beast,Vector3(side*0.11,0.36,0.14),Vector3(0.06,0.31,0.08),hide,Vector3(25,0,side*12))
			cone(beast,Vector3(side*0.12,1.00,-0.17),0.025,0,0.30,gold,Vector3(0,0,-side*30))
			cone(beast,Vector3(side*0.18,1.02,-0.16),0.02,0,0.16,gold,Vector3(0,0,-side*65))
		cone(beast,Vector3(0,0.49,0.37),0.055,0,0.34,hide,Vector3(-65,0,0))
	else: # Flying gargoyle: stone hide, pointed horns, bat membranes, claws.
		ball(beast,Vector3(0,0.82,-0.20),Vector3(0.28,0.30,0.25),hide)
		for side in [-1,1]:
			cone(beast,Vector3(side*0.10,1.00,-0.16),0.055,0,0.30,dark,Vector3(-15,0,-side*20))
			cone(beast,Vector3(side*0.12,0.30,-0.1),0.05,0,0.27,steel,Vector3(160,0,0))
			ball(beast,Vector3(side*0.06,0.84,-0.315),Vector3(0.04,0.03,0.02),violet,true)
	for side in [-1,1]:
		var wing = Node3D.new()
		wing.name = "WingL" if side == -1 else "WingR"
		beast.add_child(wing)
		wing.position = Vector3(side*0.11,0.64,0.03)
		triangle(wing,Vector3.ZERO,Vector3(side*0.60,0.38,-0.05),Vector3(side*0.47,0.06,0.25),faction if alliance else Color("#434255"))
		for feather in range(4):
			var x = side*(0.23+feather*0.10)
			if alliance:
				box(wing,Vector3(x,0.14+feather*0.07,0.16),Vector3(0.11,0.05,0.40),Color("#c5d0d7"),Vector3(0,side*25,side*25))
			else:
				triangle(wing,Vector3.ZERO,Vector3(x,0.10+feather*0.07,0.36),Vector3(side*0.60,0.38,-0.05),hide)
