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
	var model_count = count_meshes(game)
	expect(model_count<450,"batched scene stays below 450 mesh instances: "+str(model_count))
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
