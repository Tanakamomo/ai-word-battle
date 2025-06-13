extends Node

# ダミーAI応答パターン
var response_patterns = [
	{
		"keywords": ["攻撃", "炎"],
		"action": "fire_attack",
		"power": 7,
		"narrative": "🔥 炎の攻撃が敵を包み込む！"
	},
	{
		"keywords": ["回復", "自分"],
		"action": "heal",
		"power": 5,
		"narrative": "✨ 癒しの光が体を包む..."
	},
	{
		"keywords": ["防御", "全体"],
		"action": "group_defense",
		"power": 3,
		"narrative": "🛡️ protective barrier activated!"
	}
]

func interpret_cards(card_words: Array) -> Dictionary:
	# 簡単なパターンマッチング
	for pattern in response_patterns:
		var match_count = 0
		for keyword in pattern.keywords:
			if keyword in card_words:
				match_count += 1
		
		if match_count >= 1:  # 1個以上マッチすれば採用
			return {
				"action_type": pattern.action,
				"power": pattern.power + randi() % 3,  # ランダム要素
				"narrative": pattern.narrative,
				"success_rate": randf_range(0.7, 1.0),
				"card_words": card_words
			}
	
	# マッチしない場合のデフォルト
	return {
		"action_type": "confused",
		"power": 1,
		"narrative": "❓ AIは混乱している...",
		"success_rate": 0.3,
		"card_words": card_words
	}

# 将来のApple Intelligence統合用インターフェース
func interpret_cards_ai(card_words: Array) -> Dictionary:
	# TODO: Apple Intelligence統合
	return interpret_cards(card_words)
