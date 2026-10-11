extends SceneTree

const Game = preload("res://scripts/game.gd")
var failures = 0

func expect(value: bool, message: String) -> void:
	if value:
		print("PASS: "+message)
	else:
		failures += 1
		push_error("FAIL: "+message)

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	# Isolate the smoke game from any user's saved match.
	var save_path = "user://battle.json"
	var existing = FileAccess.get_file_as_bytes(save_path) if FileAccess.file_exists(save_path) else PackedByteArray()
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	var game = Game.new()
	root.add_child(game)
	await process_frame
	game.new_dialog.hide()
	game.faction_choice.select(0)
	game.elo_choice.select(0)
	game.start_new_game()
	await process_frame
	expect(game.pieces.size()==32,"scene creates 32 real 3D figures")
	expect(game.elo_choice.item_count==20,"all twenty difficulty choices")
	expect(game.notation(0)=="a1" and game.notation(63)=="h8","square notation")
	expect(game.models.templates.size()==12,"twelve cached faction models")
	for square in [12,52]:
		var figure = game.pieces[square]
		var player = game.models.animation_player(figure)
		expect(player != null and player.has_animation("walk") and player.has_animation("attack"),"authored pawn has skeletal walk and attack clips")
		var skeletons = figure.find_children("*","Skeleton3D",true,false)
		expect(skeletons.size()==1 and skeletons[0].get_bone_count()==7,"pawn mesh has a real seven-bone skeleton")
		if player and skeletons.size()==1:
			var leg = skeletons[0].find_bone("LeftLeg")
			player.play("walk")
			player.advance(0.12)
			expect(skeletons[0].get_bone_pose_rotation(leg).angle_to(Quaternion.IDENTITY)>0.10,"walk clip actually rotates the skinned leg")
			player.play("idle")
			player.advance(0.01)
	var model_count = count_meshes(game)
	expect(model_count<450,"batched scene stays below 450 mesh instances: "+str(model_count))
	# Rotate the viewport and check UI bounds and projected board corners.
	for viewport_size in [Vector2i(540,960),Vector2i(960,540),Vector2i(720,1280),Vector2i(1280,720)]:
		root.size = viewport_size
		await process_frame
		game.resize_ui()
		await process_frame
		var canvas_size = game.get_viewport().get_visible_rect().size
		var portrait = canvas_size.y > canvas_size.x
		expect(game.toolbar.columns == (3 if portrait else 4),"controls reflow at "+str(viewport_size))
		for control in game.toolbar.get_children():
			var bounds = control.get_global_rect()
			expect(bounds.position.x >= 0 and bounds.end.x <= canvas_size.x+1,"touch control stays on screen: "+control.text)
		for camera_yaw in [0.0,PI/4,PI]:
			game.yaw = camera_yaw
			game.update_camera()
			var board_fits = true
			for x in [-4.5,4.5]:
				for z in [-4.5,4.5]:
					for y in [0.0,1.8]:
						var screen = game.camera.unproject_position(Vector3(x,y,z))
						board_fits = board_fits and screen.x >= 0 and screen.x <= canvas_size.x and screen.y > game.top_panel.get_global_rect().end.y and screen.y < canvas_size.y-90*game.ui.scale.y
			expect(board_fits,"board clears controls at "+str(viewport_size)+" yaw "+str(camera_yaw))
	game.yaw = 0
	game.update_camera()
	game.select_square(12)
	expect(game.selected==12 and game.highlights.size()==3,"touch selection highlights pawn and legal destinations")
	game.select_square(28)
	await create_timer(3.0).timeout
	expect(game.chess.board[28]==1,"animated human move e2-e4")
	expect(game.chess.turn==1 and not game.busy,"background AI returns to human turn")
	expect(game.history.size()==2,"human and AI moves both saved")
	game.undo_turn()
	expect(game.chess.board[12]==1 and game.chess.board[28]==0,"undo restores player turn")
	expect(game.history.is_empty() and game.chess.turn==1,"undo removes complete move pair")
	# A captured pawn remains visible until the sword's impact frame.
	game.chess.board.fill(0)
	game.chess.board[4]=6
	game.chess.board[60]=-6
	game.chess.board[27]=1
	game.chess.board[36]=-1
	game.chess.turn=1
	game.chess.rights=0
	game.chess.ep=-1
	game.human=-1 # Avoid AI after directly exercising the white capture.
	game.rebuild_pieces()
	var attacker = game.pieces[27]
	var victim = game.pieces[36]
	var capture_move: Dictionary = {}
	for move in game.chess.legal_moves():
		if move["from"]==27 and move["to"]==36:
			capture_move=move
	game.animate_move(capture_move)
	await create_timer(0.20).timeout
	expect(game.models.animation_player(attacker).current_animation=="walk","capture begins with skeletal walking")
	expect(victim.scale==Vector3.ONE,"victim stays visible while attacker approaches")
	await create_timer(0.33).timeout
	expect(game.models.animation_player(attacker).current_animation=="attack","arrival starts sword attack clip")
	expect(victim.scale==Vector3.ONE,"victim does not disappear before sword impact")
	await create_timer(0.75).timeout
	expect(not game.busy and game.chess.board[36]==1 and not game.pieces.has(27),"capture animation settles and rebuilds the board")
	game.human=1
	# Exercise promotion popup and actually choose a knight.
	game.chess.board.fill(0)
	game.chess.board[4]=6
	game.chess.board[60]=-6
	game.chess.board[48]=1
	game.chess.turn=1
	game.chess.rights=0
	game.chess.ep=-1
	game.legal=game.chess.legal_moves()
	game.rebuild_pieces()
	game.select_square(48)
	game.select_square(56)
	expect(game.promotion_pending.size()==4 and game.promotion_dialog.visible,"promotion dialog offers four figures")
	var choices=game.promotion_dialog.get_node("Choices")
	choices.get_child(3).pressed.emit()
	await create_timer(0.5).timeout
	expect(game.chess.board[56]==2,"promotion UI makes a knight")
	# Restarting during walking cancels animation targeting the old figures.
	game.start_new_game()
	game.select_square(12)
	game.select_square(28)
	await create_timer(0.10).timeout
	game.start_new_game()
	await create_timer(0.70).timeout
	expect(game.pieces.size()==32 and game.chess.board[12]==1 and game.chess.board[28]==0 and not game.busy,"new match cancels the previous pawn walk")
	# Starting a new match while an old worker finishes must discard its result.
	game.faction_choice.select(1)
	game.elo_choice.select(19)
	game.start_new_game()
	await create_timer(0.05).timeout
	game.faction_choice.select(0)
	game.start_new_game()
	await create_timer(2.5).timeout
	expect(game.chess.fullmove==1 and game.chess.board[12]==1 and game.chess.turn==1,"new-game generation rejects stale AI moves")
	game.show_help()
	game.save_game()
	expect(FileAccess.file_exists(save_path),"autosave written")
	game.queue_free()
	await process_frame
	if existing.size()>0:
		var file=FileAccess.open(save_path,FileAccess.WRITE)
		file.store_buffer(existing)
		file.close()
	elif FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	print("RESULT: ",failures," failures")
	quit(1 if failures else 0)

func count_meshes(node: Node) -> int:
	var count=1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count+=count_meshes(child)
	return count
