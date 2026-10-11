class_name PieceModels
extends RefCounted

# Original sculpted, textured glTF miniatures generated with Blender.
var materials: Dictionary = {}
var templates: Dictionary = {}
var blue = Color("#405b78")
var red = Color("#70464a")
var steel = Color("#8b9299")
var dark = Color("#293b4b")
var gold = Color("#a9956c")
var skin = Color("#e4b990")
var green = Color("#568853")
var ice = Color("#83adbd")
var violet = Color("#90829e")

func mat(color: Color, glow: bool = false) -> StandardMaterial3D:
	var key = str(color) + str(glow)
	if materials.has(key):
		return materials[key]
	var m = StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = 0.72
	if color == steel or color == gold:
		m.metallic = 0.25
	if glow:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = 0.35
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

const MODEL_NAMES = {
	1: "footman", -1: "grunt", 2: "hippogryph", -2: "gargoyle",
	3: "frostmourne", -3: "warglaives", 4: "human_tower", -4: "orc_tower",
	5: "jaina", -5: "sylvanas", 6: "arthas", -6: "thrall"
}

func animation_player(root: Node3D) -> AnimationPlayer:
	var players = root.find_children("*", "AnimationPlayer", true, false)
	return players[0] as AnimationPlayer if not players.is_empty() else null

func create(piece: int) -> Node3D:
	var root = Node3D.new()
	var sculpture = Node3D.new()
	sculpture.name = "Sculpture"
	root.add_child(sculpture)
	sculpture.rotation.y = 0 if piece > 0 else PI
	if not templates.has(piece):
		templates[piece] = load("res://assets/models/" + MODEL_NAMES[piece] + ".glb") as PackedScene
	var scene: PackedScene = templates[piece]
	assert(scene != null, "Missing authored 3D model")
	var model = scene.instantiate() as Node3D
	model.name = "Model"
	# Blender's front (-Y) imports facing +Z. Face the opposing army.
	model.rotation.y = PI
	sculpture.add_child(model)
	var player = animation_player(root)
	if player:
		player.get_animation("walk").loop_mode = Animation.LOOP_LINEAR
		player.play("idle")
	return root

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

