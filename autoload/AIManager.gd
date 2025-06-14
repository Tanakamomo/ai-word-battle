extends Node

enum ActionType {
	ATTACK,
	HEAL, 
	DEFEND,
	BUFF,
	DEBUFF,
	SPECIAL,
	CHAOS
}

enum CardCategory {
	ACTION,
	TARGET, 
	ELEMENT,
	MODIFIER
}

var card_database = {
	# アクション
	"Attack": {"category": CardCategory.ACTION, "type": "offensive", "base_power": 5},
	"Strike": {"category": CardCategory.ACTION, "type": "offensive", "base_power": 6},
	"Heal": {"category": CardCategory.ACTION, "type": "restorative", "base_power": 4},
	"Defend": {"category": CardCategory.ACTION, "type": "protective", "base_power": 3},
	"Guard": {"category": CardCategory.ACTION, "type": "protective", "base_power": 3},
	"Cast": {"category": CardCategory.ACTION, "type": "magical", "base_power": 4},
	
	# ターゲット
	"Self": {"category": CardCategory.TARGET, "scope": "self"},
	"All": {"category": CardCategory.TARGET, "scope": "all"},
	"Single": {"category": CardCategory.TARGET, "scope": "single"},
	"Enemy": {"category": CardCategory.TARGET, "scope": "enemy"},
	
	# 属性
	"Fire": {"category": CardCategory.ELEMENT, "element": "fire", "power_bonus": 2},
	"Water": {"category": CardCategory.ELEMENT, "element": "water", "power_bonus": 1},
	"Thunder": {"category": CardCategory.ELEMENT, "element": "thunder", "power_bonus": 3},
	"Ice": {"category": CardCategory.ELEMENT, "element": "ice", "power_bonus": 2},
	"Earth": {"category": CardCategory.ELEMENT, "element": "earth", "power_bonus": 1},
	"Light": {"category": CardCategory.ELEMENT, "element": "light", "power_bonus": 2},
	"Dark": {"category": CardCategory.ELEMENT, "element": "dark", "power_bonus": 2},
	
	# 修飾語
	"Strong": {"category": CardCategory.MODIFIER, "power_multiplier": 1.5, "description": "enhances power"},
	"Weak": {"category": CardCategory.MODIFIER, "power_multiplier": 0.7, "description": "reduces power"},
	"Quick": {"category": CardCategory.MODIFIER, "speed_bonus": 3, "description": "increases speed"},
	"Slow": {"category": CardCategory.MODIFIER, "speed_penalty": 2, "description": "decreases speed"},
	"Sure": {"category": CardCategory.MODIFIER, "accuracy_bonus": 0.2, "description": "improves accuracy"},
	"Chaos": {"category": CardCategory.MODIFIER, "chaos_bonus": 0.8, "description": "adds unpredictability"}
}

var response_patterns = [
	# === 攻撃系 ===
	{
		"keywords": ["Attack", "Fire"],
		"action": "fire_attack",
		"type": ActionType.ATTACK,
		"power": 7,
		"chaos": 0.1,
		"narrative": "🔥 Blazing strike burns the enemy!"
	},
	{
		"keywords": ["Strike", "Thunder"], 
		"action": "lightning_strike",
		"type": ActionType.ATTACK,
		"power": 8,
		"chaos": 0.2,
		"narrative": "⚡ Lightning bolt crackles through the air!"
	},
	
	# === 回復系 ===
	{
		"keywords": ["Heal", "Self"],
		"action": "self_heal",
		"type": ActionType.HEAL,
		"power": 5,
		"chaos": 0.0,
		"narrative": "✨ Healing light mends your wounds!"
	},
	{
		"keywords": ["Heal", "Strong"],
		"action": "strong_heal",
		"type": ActionType.HEAL,
		"power": 8,
		"chaos": 0.1,
		"narrative": "🌟 Powerful restoration magic flows through you!"
	},
	
	# === 防御系 ===
	{
		"keywords": ["Defend", "Self"],
		"action": "shield",
		"type": ActionType.DEFEND,
		"power": 4,
		"chaos": 0.0,
		"narrative": "🛡️ Protective barrier surrounds you!"
	},
	
	# === バフ系 ===
	{
		"keywords": ["Strong", "Self"],
		"action": "strength_buff",
		"type": ActionType.BUFF,
		"power": 3,
		"chaos": 0.1,
		"narrative": "💪 Your muscles surge with power!"
	},
	{
		"keywords": ["Quick", "Self"],
		"action": "speed_buff",
		"type": ActionType.BUFF,
		"power": 4,
		"chaos": 0.2,
		"narrative": "💨 Time seems to slow as you accelerate!"
	}
]

# === 矛盾組み合わせパターン ===
var paradox_patterns = [
	{
		"contradiction": ["Heal", "Attack"],
		"action": "pain_heal",
		"type": ActionType.SPECIAL,
		"power": 6,
		"chaos": 0.7,
		"narrative": "⚡✨ Painful healing magic damages enemies while healing you!"
	},
	{
		"contradiction": ["Defend", "Fire"],
		"action": "flame_shield",
		"type": ActionType.SPECIAL,
		"power": 5,
		"chaos": 0.6,
		"narrative": "🔥🛡️ Burning shield reflects damage back to attackers!"
	},
	{
		"contradiction": ["Quick", "Slow"],
		"action": "time_distortion",
		"type": ActionType.CHAOS,
		"power": "random",
		"chaos": 0.9,
		"narrative": "🌀 Time warps chaotically around you!"
	}
]

func interpret_cards(card_words: Array) -> Dictionary:
	print("=== MULTI-EFFECT INTERPRETATION ===")
	print("Input cards: ", card_words)
	
	var categorized = categorize_cards(card_words)
	print("Categorized: ", categorized)
	
	return generate_multi_effect_action(categorized, card_words)

# AIManager.gd の generate_multi_effect_action を修正
func generate_multi_effect_action(categorized: Dictionary, all_cards: Array) -> Dictionary:
	var effects = []
	var narrative_parts = []
	var total_power = 0
	var chaos_factor = 0.1
	
	# === 基本となるアクション効果を生成 ===
	for action_info in categorized.actions:
		var action_word = action_info.word
		var action_data = action_info.data
		
		var effect = create_base_effect(action_word, action_data, categorized)
		effects.append(effect)
		
		narrative_parts.append(effect.narrative_part)
		total_power += effect.power
	
	# === 属性による効果強化 ===
	for element_info in categorized.elements:
		var element_word = element_info.word
		var element_data = element_info.data
		
		enhance_effects_with_element(effects, element_word, element_data)
		narrative_parts.append("with " + element_word.to_lower() + " energy")
	
	# === 修飾語による調整 ===
	for modifier_info in categorized.modifiers:
		var modifier_word = modifier_info.word
		var modifier_data = modifier_info.data
		
		apply_modifier_to_effects(effects, modifier_word, modifier_data)
		narrative_parts.append(modifier_data.description)
		
		if modifier_data.has("chaos_bonus"):
			chaos_factor += modifier_data.chaos_bonus
	
	# === 複雑度ボーナス ===
	var complexity = all_cards.size()
	if complexity >= 5:
		chaos_factor += 0.1
		narrative_parts.append("in a complex magical display")
	
	if complexity >= 7:
		chaos_factor += 0.1
		total_power += 2
		narrative_parts.append("with overwhelming power")
	
	# === 最終結果（修正版） ===
	var final_narrative = "✨ You " + join_array(narrative_parts, ", ") + "!"
	
	return {
		"action_type": "multi_effect",
		"effects": effects,
		"total_power": total_power,
		"chaos_factor": clamp(chaos_factor, 0.0, 1.0),
		"success_rate": 0.8 - (chaos_factor * 0.3),
		"narrative": final_narrative,
		"complexity": complexity,
		"card_words": all_cards
	}

# 新しいヘルパー関数
func join_array(arr: Array, separator: String) -> String:
	if arr.size() == 0:
		return ""
	
	var result = str(arr[0])
	for i in range(1, arr.size()):
		result += separator + str(arr[i])
	
	return result

func create_base_effect(action_word: String, action_data: Dictionary, categorized: Dictionary) -> Dictionary:
	var effect = {
		"action": action_word,
		"type": action_data.type,
		"power": action_data.base_power,
		"target": "enemy"  # デフォルト
	}
	
	# ターゲット決定
	if categorized.targets.size() > 0:
		var target_data = categorized.targets[0].data
		effect.target = target_data.scope
	
	# ナラティブパート生成
	match action_data.type:
		"offensive":
			effect.narrative_part = "strike with " + action_word.to_lower() + "ing force"
		"restorative":
			effect.narrative_part = "channel healing energy"
			effect.target = "self"  # ヒールは自分対象
		"protective":
			effect.narrative_part = "raise defensive barriers"
			effect.target = "self"
		"magical":
			effect.narrative_part = "weave mystical magic"
	
	return effect

func enhance_effects_with_element(effects: Array, element_word: String, element_data: Dictionary):
	for effect in effects:
		effect.power += element_data.power_bonus
		effect.element = element_word.to_lower()

func apply_modifier_to_effects(effects: Array, modifier_word: String, modifier_data: Dictionary):
	for effect in effects:
		if modifier_data.has("power_multiplier"):
			effect.power = int(effect.power * modifier_data.power_multiplier)
		
		if modifier_data.has("speed_bonus"):
			effect.speed_bonus = modifier_data.speed_bonus
		
		if modifier_data.has("accuracy_bonus"):
			effect.accuracy_bonus = modifier_data.get("accuracy_bonus", 0)

func generate_pure_chaos(card_words: Array) -> Dictionary:
	var chaos_effects = [
		"🌀 Reality melts and reshapes itself!",
		"⚡💥 Chaotic energy erupts in all directions!",
		"🎭 The laws of magic become suggestions!",
		"🌪️ Probability itself goes haywire!"
	]
	
	return {
		"action_type": "pure_chaos",
		"power": randi() % 15 + 1,  # 1-15完全ランダム
		"chaos_factor": 1.0,
		"narrative": chaos_effects[randi() % chaos_effects.size()],
		"special_effects": ["random_all"],
		"card_words": card_words
	}

# AIManager.gd の generate_paradox_result を修正
func generate_paradox_result(pattern: Dictionary, card_words: Array) -> Dictionary:
	var power: int
	
	# 型チェック付き
	if typeof(pattern.power) == TYPE_STRING and pattern.power == "random":
		power = randi() % 12 + 3  # 3-14
	elif typeof(pattern.power) == TYPE_INT:
		power = pattern.power
	else:
		# フォールバック
		power = 5
		print("⚠️ Unknown power type in pattern: ", pattern.power)
	
	return {
		"action_type": pattern.action,
		"power": power,
		"chaos_factor": pattern.chaos,
		"narrative": pattern.narrative,
		"special_effects": ["paradox"],
		"card_words": card_words
	}
	
func calculate_match_score(keywords: Array, card_words: Array) -> int:
	var score = 0
	for keyword in keywords:
		if keyword in card_words:
			score += 1
	return score

func generate_result_with_chaos(pattern: Dictionary, card_words: Array, match_score: int) -> Dictionary:
	var base_power = pattern.power
	var chaos_modifier = pattern.chaos
	
	# カード数が多いほどカオス度アップ
	if card_words.size() > 5:
		chaos_modifier += 0.2
	
	# マッチ度が低いほどカオス度アップ
	if match_score == 1:
		chaos_modifier += 0.3
	
	# カオス度に応じてパワー調整
	var final_power = base_power
	if chaos_modifier > 0.5:
		final_power += randi() % 5 - 2  # -2 to +2 ランダム変動
	
	return {
		"action_type": pattern.action,
		"power": max(1, final_power),
		"chaos_factor": min(1.0, chaos_modifier),
		"narrative": pattern.narrative,
		"special_effects": [],
		"card_words": card_words
	}
	
# AIManager.gd に追加
func generate_unknown_combination(card_words: Array) -> Dictionary:
	print("Unknown combination detected: ", card_words)
	
	var unknown_effects = [
		"❓ The cards resonate with mysterious energy...",
		"🌟 Ancient magic awakens from forgotten words!",
		"🎲 The spell weaves itself in unexpected ways!",
		"✨ Reality bends to accommodate your strange request!",
		"🔮 The magic interpreter struggles with this combination...",
		"💫 Cosmic forces align in peculiar patterns!",
		"🌈 A rainbow of chaotic energy swirls around you!"
	]
	
	var mystery_actions = [
		"mysterious_magic",
		"unknown_spell",
		"cosmic_weirdness", 
		"reality_glitch",
		"magic_confusion"
	]
	
	# カード数に応じてパワー調整
	var base_power = card_words.size()  # カードが多いほど強力
	var random_modifier = randi() % 6 + 1  # +1~6
	var final_power = base_power + random_modifier
	
	# 完全未知なので高いカオス度
	var chaos_level = 0.6 + randf() * 0.4  # 0.6~1.0
	
	return {
		"action_type": mystery_actions[randi() % mystery_actions.size()],
		"power": final_power,
		"chaos_factor": chaos_level,
		"narrative": unknown_effects[randi() % unknown_effects.size()],
		"special_effects": ["mystery", "unpredictable"],
		"card_words": card_words
	}
	
func categorize_cards(card_words: Array) -> Dictionary:
	var categorized = {
		"actions": [],
		"targets": [],
		"elements": [],
		"modifiers": []
	}
	
	for word in card_words:
		if word in card_database:
			var card_data = card_database[word]
			match card_data.category:
				CardCategory.ACTION:
					categorized.actions.append({"word": word, "data": card_data})
				CardCategory.TARGET:
					categorized.targets.append({"word": word, "data": card_data})
				CardCategory.ELEMENT:
					categorized.elements.append({"word": word, "data": card_data})
				CardCategory.MODIFIER:
					categorized.modifiers.append({"word": word, "data": card_data})
		else:
			print("⚠️ Unknown card: ", word)
	
	return categorized
