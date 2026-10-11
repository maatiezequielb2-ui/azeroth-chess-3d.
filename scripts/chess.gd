class_name ChessRules
extends RefCounted

# Positive pieces: Alliance/white. Negative: Horde/black. a1 = index 0.
const PAWN = 1
const KNIGHT = 2
const BISHOP = 3
const ROOK = 4
const QUEEN = 5
const KING = 6
var board: Array[int] = []
var turn: int = 1
var rights: int = 15 # White king/queen, black king/queen.
var ep: int = -1
var halfmove: int = 0
var fullmove: int = 1
var repetitions: Dictionary = {}

func _init() -> void:
	reset()

func reset() -> void:
	board.assign([4,2,3,5,6,3,2,4,1,1,1,1,1,1,1,1,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,
		-1,-1,-1,-1,-1,-1,-1,-1,-4,-2,-3,-5,-6,-3,-2,-4])
	turn = 1
	rights = 15
	ep = -1
	halfmove = 0
	fullmove = 1
	repetitions = {position_key(): 1}

func copy() -> ChessRules:
	var c = ChessRules.new()
	c.board = board.duplicate()
	c.turn = turn
	c.rights = rights
	c.ep = ep
	c.halfmove = halfmove
	c.fullmove = fullmove
	c.repetitions = repetitions.duplicate()
	return c

func square(file: int, rank: int) -> int:
	return rank * 8 + file if file >= 0 and file < 8 and rank >= 0 and rank < 8 else -1

func attacked(s: int, side: int) -> bool:
	var f = s % 8
	var r = s / 8 as int
	for df in [-1, 1]:
		var p = square(f + df, r - side)
		if p >= 0 and board[p] == side * PAWN:
			return true
	for d in [Vector2i(1,2),Vector2i(2,1),Vector2i(-1,2),Vector2i(-2,1),
			Vector2i(1,-2),Vector2i(2,-1),Vector2i(-1,-2),Vector2i(-2,-1)]:
		var p = square(f + d.x, r + d.y)
		if p >= 0 and board[p] == side * KNIGHT:
			return true
	for d in [Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1),
			Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)]:
		var step = 1
		var p = square(f + d.x, r + d.y)
		while p >= 0:
			if board[p] != 0:
				if signi(board[p]) == side:
					var kind = absi(board[p])
					if kind == QUEEN or (kind == KING and step == 1):
						return true
					if kind == ROOK and (d.x == 0 or d.y == 0):
						return true
					if kind == BISHOP and d.x != 0 and d.y != 0:
						return true
				break
			step += 1
			p = square(f + d.x * step, r + d.y * step)
	return false

func in_check(side: int) -> bool:
	var k = board.find(side * KING)
	return k < 0 or attacked(k, -side)

func add_move(moves: Array, a: int, b: int, promo: int = 0) -> void:
	if b < 0 or signi(board[b]) == turn or absi(board[b]) == KING:
		return
	var target_rank = b / 8
	if absi(board[a]) == PAWN and (target_rank == 0 or target_rank == 7):
		for kind in [QUEEN, ROOK, BISHOP, KNIGHT]:
			moves.append({"from": a, "to": b, "promotion": kind})
	else:
		moves.append({"from": a, "to": b, "promotion": promo})

func pseudo_moves() -> Array:
	var moves: Array = []
	for a in range(64):
		if signi(board[a]) != turn:
			continue
		var f = a % 8
		var r = a / 8 as int
		var kind = absi(board[a])
		if kind == PAWN:
			var b = square(f, r + turn)
			if b >= 0 and board[b] == 0:
				add_move(moves, a, b)
				var c = square(f, r + turn * 2)
				if r == (1 if turn == 1 else 6) and board[c] == 0:
					add_move(moves, a, c)
			for df in [-1, 1]:
				b = square(f + df, r + turn)
				if b >= 0 and (signi(board[b]) == -turn or (b == ep and board[b - turn * 8] == -turn * PAWN)):
					add_move(moves, a, b)
		elif kind == KNIGHT:
			for d in [Vector2i(1,2),Vector2i(2,1),Vector2i(-1,2),Vector2i(-2,1),
					Vector2i(1,-2),Vector2i(2,-1),Vector2i(-1,-2),Vector2i(-2,-1)]:
				add_move(moves, a, square(f + d.x, r + d.y))
		else:
			var dirs: Array = []
			if kind in [ROOK, QUEEN, KING]:
				dirs.append_array([Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)])
			if kind in [BISHOP, QUEEN, KING]:
				dirs.append_array([Vector2i(1,1),Vector2i(-1,1),Vector2i(1,-1),Vector2i(-1,-1)])
			for d in dirs:
				var step = 1
				var b = square(f + d.x, r + d.y)
				while b >= 0:
					add_move(moves, a, b)
					if board[b] != 0 or kind == KING:
						break
					step += 1
					b = square(f + d.x * step, r + d.y * step)
			if kind == KING and a == (4 if turn == 1 else 60) and not in_check(turn):
				var bit = 1 if turn == 1 else 4
				if rights & bit and board[a+3] == turn * ROOK and board[a+1] == 0 and board[a+2] == 0 and not attacked(a+1,-turn) and not attacked(a+2,-turn):
					add_move(moves, a, a+2)
				if rights & (bit * 2) and board[a-4] == turn * ROOK and board[a-1] == 0 and board[a-2] == 0 and board[a-3] == 0 and not attacked(a-1,-turn) and not attacked(a-2,-turn):
					add_move(moves, a, a-2)
	return moves

func legal_moves() -> Array:
	var result: Array = []
	for m in pseudo_moves():
		var c = copy()
		c.play(m, false)
		if not c.in_check(turn):
			result.append(m)
	return result

func play(m: Dictionary, track: bool = true) -> void:
	var a: int = m["from"]
	var b: int = m["to"]
	var p = board[a]
	var capture = board[b] != 0
	if absi(p) == PAWN and b == ep and not capture:
		board[b - turn * 8] = 0
		capture = true
	board[b] = p
	board[a] = 0
	if absi(p) == KING:
		rights &= ~ (3 if turn == 1 else 12)
		if absi(b-a) == 2:
			var rook_from = a + 3 if b > a else a - 4
			var rook_to = a + 1 if b > a else a - 1
			board[rook_to] = board[rook_from]
			board[rook_from] = 0
	for corner in [0,7,56,63]:
		if a == corner or b == corner:
			rights &= ~ ({0:2,7:1,56:8,63:4}[corner] as int)
	if m.get("promotion",0) != 0:
		board[b] = turn * m["promotion"]
	ep = (a + b) / 2 as int if absi(p) == PAWN and absi(b-a) == 16 else -1
	halfmove = 0 if capture or absi(p) == PAWN else halfmove + 1
	if turn == -1:
		fullmove += 1
	turn = -turn
	if track:
		var key = position_key()
		repetitions[key] = repetitions.get(key, 0) + 1

func position_key() -> String:
	# En-passant changes repetition identity only when a legal capture exists.
	var effective_ep = -1
	if ep >= 0:
		for df in [-1,1]:
			var a = square(ep % 8 + df, (ep / 8 as int) - turn)
			if a >= 0 and board[a] == turn * PAWN:
				var saved = board.duplicate()
				board[a] = 0
				board[ep] = turn * PAWN
				board[ep - turn*8] = 0
				if not in_check(turn):
					effective_ep = ep
				board = saved
	return str(board) + ":" + str(turn) + ":" + str(rights) + ":" + str(effective_ep)

func insufficient_material() -> bool:
	var minors: Array = []
	for i in range(64):
		var p = absi(board[i])
		if p in [PAWN,ROOK,QUEEN]:
			return false
		if p in [KNIGHT,BISHOP]:
			minors.append(i)
	if minors.size() <= 1:
		return true
	# All remaining bishops on one square colour cannot mate.
	var color = -1
	for i in minors:
		if absi(board[i]) != BISHOP:
			return false
		var current = (i % 8 + i / 8 as int) % 2
		if color >= 0 and color != current:
			return false
		color = current
	return true

func result(moves: Array = []) -> String:
	if moves.is_empty():
		moves = legal_moves()
	if moves.is_empty():
		return ("Victoria de la Horda" if turn == 1 else "Victoria de la Alianza") if in_check(turn) else "Tablas por ahogado"
	if halfmove >= 100:
		return "Tablas por 50 movimientos"
	if repetitions.get(position_key(), 0) >= 3:
		return "Tablas por triple repetición"
	if insufficient_material():
		return "Tablas por material insuficiente"
	return ""

func serialize() -> Dictionary:
	return {"board":board.duplicate(),"turn":turn,"rights":rights,"ep":ep,
		"halfmove":halfmove,"fullmove":fullmove,"repetitions":repetitions.duplicate()}

func restore(data: Dictionary) -> bool:
	var pieces = data.get("board", [])
	if not pieces is Array or pieces.size() != 64:
		return false
	var restored: Array[int] = []
	for p in pieces:
		if not (p is float or p is int) or int(p) != p or absi(int(p)) > 6:
			return false
		restored.append(int(p))
	if restored.count(KING) != 1 or restored.count(-KING) != 1:
		return false
	if int(data.get("turn",0)) not in [-1,1] or int(data.get("ep",-1)) < -1 or int(data.get("ep",-1)) > 63:
		return false
	board = restored
	turn = int(data["turn"])
	rights = int(data.get("rights",0)) & 15
	ep = int(data.get("ep",-1))
	halfmove = maxi(0, int(data.get("halfmove",0)))
	fullmove = maxi(1, int(data.get("fullmove",1)))
	repetitions = data.get("repetitions", {}).duplicate()
	return true
