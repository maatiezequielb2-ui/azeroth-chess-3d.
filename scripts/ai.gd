class_name ChessAI
extends RefCounted

# Levels are nominal, not an independently rated Elo claim.
const VALUES = [0,100,320,335,500,900,20000]
const MATE = 100000
var deadline: int
var nodes: int = 0
var stopped: bool = false
var rng = RandomNumberGenerator.new()

func choose(position: ChessRules, elo: int) -> Dictionary:
	rng.randomize()
	var moves = position.legal_moves()
	if moves.is_empty():
		return {}
	var level = clampi(elo / 100 as int, 1, 20)
	# Weak levels deliberately sample legal moves, with progressively fewer blunders.
	if rng.randf() < clampf(0.92 - float(level) * 0.062, 0.0, 0.9):
		return moves[rng.randi_range(0, moves.size()-1)]
	deadline = Time.get_ticks_msec() + 80 + level * 75
	nodes = 0
	stopped = false
	var best: Dictionary = moves[0]
	var max_depth = 1 + level / 4 as int
	order(position, moves)
	for depth in range(1, max_depth + 1):
		var iteration: Dictionary = best
		var best_score = -MATE * 2
		var alpha = -MATE * 2
		for m in moves:
			var c = position.copy()
			c.play(m)
			var score = -search(c, depth-1, -MATE*2, -alpha, 1)
			if stopped:
				break
			if score > best_score:
				best_score = score
				iteration = m
			alpha = maxi(alpha, score)
		if stopped:
			break
		best = iteration
		moves.erase(best)
		moves.push_front(best)
	return best

func order(p: ChessRules, moves: Array) -> void:
	moves.sort_custom(func(a, b): return priority(p,a) > priority(p,b))

func priority(p: ChessRules, m: Dictionary) -> int:
	return VALUES[absi(p.board[m["to"]])] * 10 - VALUES[absi(p.board[m["from"]])] + VALUES[m.get("promotion",0)] * 10

func search(p: ChessRules, depth: int, alpha_in: int, beta: int, ply: int) -> int:
	nodes += 1
	if Time.get_ticks_msec() >= deadline:
		stopped = true
		return 0
	var moves = p.legal_moves()
	if moves.is_empty():
		return -MATE + ply if p.in_check(p.turn) else 0
	if p.halfmove >= 100 or p.repetitions.get(p.position_key(),0) >= 3 or p.insufficient_material():
		return 0
	if depth <= 0:
		return quiescence(p, alpha_in, beta, 0)
	var alpha = alpha_in
	order(p, moves)
	for m in moves:
		var c = p.copy()
		c.play(m)
		var score = -search(c, depth-1, -beta, -alpha, ply+1)
		if stopped:
			return 0
		if score >= beta:
			return beta
		alpha = maxi(alpha,score)
	return alpha

func quiescence(p: ChessRules, alpha_in: int, beta: int, depth: int) -> int:
	if Time.get_ticks_msec() >= deadline:
		stopped = true
		return 0
	var moves = p.legal_moves()
	var check = p.in_check(p.turn)
	if moves.is_empty():
		return -MATE + depth if check else 0
	var alpha = alpha_in
	var score = evaluate(p)
	if not check:
		if score >= beta:
			return beta
		alpha = maxi(alpha, score)
	if depth >= 4:
		return score
	order(p,moves)
	for m in moves:
		if not check and p.board[m["to"]] == 0 and m.get("promotion",0) == 0 and not (absi(p.board[m["from"]]) == 1 and m["to"] == p.ep):
			continue
		var c = p.copy()
		c.play(m)
		score = -quiescence(c,-beta,-alpha,depth+1)
		if stopped:
			return 0
		if score >= beta:
			return beta
		alpha = maxi(alpha,score)
	return alpha

func evaluate(p: ChessRules) -> int:
	var score = 0
	for i in range(64):
		var piece = p.board[i]
		if piece == 0:
			continue
		var kind = absi(piece)
		var rank = i / 8 as int if piece > 0 else 7 - i / 8 as int
		var file = i % 8
		var center = int(14 - absf(3.5-file)*4 - absf(3.5-rank)*2)
		var bonus = 0
		match kind:
			1: bonus = rank * 9 + center
			2,3: bonus = center * 3
			4: bonus = rank * 2
			5: bonus = center
			6: bonus = -center * 2 if p.fullmove < 25 else center * 3
		score += signi(piece) * (VALUES[kind] + bonus)
	return score * p.turn
