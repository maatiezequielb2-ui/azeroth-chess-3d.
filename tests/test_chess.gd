extends SceneTree

const Rules = preload("res://scripts/chess.gd")
const AI = preload("res://scripts/ai.gd")
var failures = 0

func expect(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error("FAIL: "+message)
	else:
		print("PASS: "+message)

func fen(text: String) -> ChessRules:
	var p = Rules.new()
	p.board.fill(0)
	var fields = text.split(" ")
	var rank = 7
	var file = 0
	for c in fields[0]:
		if c == "/":
			rank -= 1
			file = 0
		elif c.is_valid_int():
			file += int(c)
		else:
			p.board[rank*8+file] = {"p":1,"n":2,"b":3,"r":4,"q":5,"k":6}[c.to_lower()] * (1 if c == c.to_upper() else -1)
			file += 1
	p.turn = 1 if fields[1] == "w" else -1
	p.rights = 0
	for c in fields[2]:
		p.rights |= {"K":1,"Q":2,"k":4,"q":8}.get(c,0)
	p.ep = -1 if fields[3] == "-" else (fields[3].unicode_at(0)-97)+(int(fields[3][1])-1)*8
	p.halfmove = int(fields[4]) if fields.size()>4 else 0
	p.repetitions = {p.position_key():1}
	return p

func perft(p: ChessRules, depth: int) -> int:
	if depth == 0:
		return 1
	var moves = p.legal_moves()
	if depth == 1:
		return moves.size()
	var count = 0
	for m in moves:
		var c = p.copy()
		c.play(m,false)
		count += perft(c,depth-1)
	return count

func find_move(p: ChessRules, a: int, b: int, promotion: int = 0) -> Dictionary:
	for m in p.legal_moves():
		if m["from"] == a and m["to"] == b and m["promotion"] == promotion:
			return m
	return {}

func _initialize() -> void:
	var initial = Rules.new()
	var snapshot = initial.serialize()
	initial.play(find_move(initial,12,28))
	expect(snapshot["board"][12]==1 and snapshot["board"][28]==0,"history snapshots do not alias live board")
	initial.reset()
	expect(perft(initial,1)==20,"initial perft depth 1: 20")
	expect(perft(initial,2)==400,"initial perft depth 2: 400")
	expect(perft(initial,3)==8902,"initial perft depth 3: 8902")
	var kiwi = fen("r3k2r/p1ppqpb1/bn2pnp1/3PN3/1p2P3/2N2Q1p/PPPBBPPP/R3K2R w KQkq - 0 1")
	expect(perft(kiwi,1)==48,"Kiwipete perft depth 1: 48")
	expect(perft(kiwi,2)==2039,"Kiwipete perft depth 2: 2039")
	expect(perft(kiwi,3)==97862,"Kiwipete perft depth 3: 97862")
	var rook_endgame = fen("8/2p5/3p4/KP5r/1R3p1k/8/4P1P1/8 w - - 0 1")
	expect(perft(rook_endgame,3)==2812,"rook/endgame and en passant perft: 2812")
	var castles = fen("r3k2r/8/8/8/8/8/8/R3K2R w KQkq - 0 1")
	var short = find_move(castles,4,6)
	expect(not short.is_empty(),"short castle available")
	castles.play(short)
	expect(castles.board[6]==6 and castles.board[5]==4 and castles.board[7]==0,"castle moves king and rook")
	expect((castles.rights&3)==0,"castle removes both rights")
	var attacked_castle = fen("4kr2/8/8/8/8/8/8/4K2R w K - 0 1")
	expect(find_move(attacked_castle,4,6).is_empty(),"cannot castle through attacked square")
	var ep = fen("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
	var ep_move = find_move(ep,36,43)
	expect(not ep_move.is_empty(),"en passant available")
	ep.play(ep_move)
	expect(ep.board[35]==0 and ep.board[43]==1,"en passant removes bypassed pawn")
	var pinned = fen("k3r3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
	expect(find_move(pinned,36,43).is_empty(),"en passant cannot expose own king")
	var expired = fen("4k3/8/8/3pP3/8/8/8/4K3 w - d6 0 1")
	expired.play(find_move(expired,4,5))
	expect(expired.ep==-1,"en passant expires after one turn")
	var promotion = fen("4k3/P7/8/8/8/8/8/4K3 w - - 0 1")
	var promotion_moves = promotion.legal_moves().filter(func(m): return m["from"]==48 and m["to"]==56)
	expect(promotion_moves.size()==4,"all four promotion choices")
	promotion.play(find_move(promotion,48,56,2))
	expect(promotion.board[56]==2,"underpromotion to knight")
	var mate = fen("7k/6Q1/6K1/8/8/8/8/8 b - - 0 1")
	expect(mate.legal_moves().is_empty() and mate.in_check(-1),"checkmate detected")
	expect(mate.result()=="Victoria de la Alianza","checkmate winner")
	var stalemate = fen("7k/5Q2/6K1/8/8/8/8/8 b - - 0 1")
	expect(stalemate.result()=="Tablas por ahogado","stalemate")
	var material = fen("4k3/8/8/8/8/8/2B5/4K3 w - - 0 1")
	expect(material.insufficient_material(),"king bishop versus king draw")
	var fifty = fen("4k3/8/8/8/8/8/2R5/4K3 w - - 100 1")
	expect(fifty.result()=="Tablas por 50 movimientos","50-move rule")
	var repeat = Rules.new()
	for cycle in range(2):
		for pair in [[6,21],[62,45],[21,6],[45,62]]:
			repeat.play(find_move(repeat,pair[0],pair[1]))
	expect(repeat.result()=="Tablas por triple repetición","threefold repetition")
	var restore = Rules.new()
	expect(restore.restore(JSON.parse_string(JSON.stringify(repeat.serialize()))),"JSON save restores")
	expect(restore.position_key()==repeat.position_key() and restore.result()==repeat.result(),"save preserves position and draw history")
	var seed = RandomNumberGenerator.new()
	seed.seed = 82
	var random_game = Rules.new()
	for ply in range(100):
		var moves = random_game.legal_moves()
		if moves.is_empty() or not random_game.result(moves).is_empty():
			break
		var side = random_game.turn
		random_game.play(moves[seed.randi_range(0,moves.size()-1)])
		expect(not random_game.in_check(side),"random playout legality ply "+str(ply))
	for elo in range(100,2001,100):
		var move = AI.new().choose(initial.copy(),elo)
		expect(move in initial.legal_moves(),"AI returns legal move at "+str(elo)+" nominal ELO")
	var tactical = fen("7k/5Q2/6K1/8/8/8/8/8 w - - 0 1")
	var best = AI.new().choose(tactical,2000)
	tactical.play(best)
	expect(tactical.in_check(-1) and tactical.legal_moves().is_empty(),"strong AI finds mate in one")
	print("RESULT: ",failures," failures")
	quit(1 if failures>0 else 0)
