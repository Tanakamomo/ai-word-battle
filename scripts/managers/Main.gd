# Main.gd
extends Control

@onready var hand_area = $VBoxContainer/HandArea
@onready var execute_button = $VBoxContainer/ExecuteButton
@onready var log_label = $VBoxContainer/LogArea/ActionLog
var enemy_max_hp: int = 50
var enemy_current_hp: int = 50
var player_hp: int = 30
var player_max_hp: int = 30

var hand_cards: Array[CardUI] = []

@onready var enemy_name_label = $VBoxContainer/EnemyArea/EnemyName
@onready var enemy_hp_bar = $VBoxContainer/EnemyArea/EnemyHP
@onready var player_hp_bar = $VBoxContainer/PlayerArea/PlayerHP

func _ready():
	print("Main scene starting...")
	await get_tree().process_frame
	
	# 英語版手札カード
	var card_words = ["Attack", "Fire", "Self", "Strong", "Heal", "Defend", "Quick"]
	
	for i in range(7):
		var card = Card.new(card_words[i], randi() % 10 + 1)
		var card_ui = await create_card_ui(card)
		hand_area.add_child(card_ui)
		hand_cards.append(card_ui)
		
		# カードからのシグナルを受信
		card_ui.card_dropped.connect(_on_card_dropped)
	
	print("English hand created with 7 cards!")
	execute_button.pressed.connect(_on_execute_pressed)
	
	# 敵の初期化
	setup_enemy()
	
func _on_execute_pressed():
	print("🚀 Executing card command!")
	
	# 現在の手札順序を取得
	var card_words = []
	for card in hand_cards:
		card_words.append(card.card_data.word)
	
	print("Card sequence: ", card_words)
	
	# AIに解釈させる
	var ai_result = AiManager.interpret_cards(card_words)
	print("AI Result: ", ai_result)
	
	# バトル実行
	execute_battle_action(ai_result)

func execute_battle_action(ai_result: Dictionary):
	print("=== MULTI-EFFECT BATTLE ACTION ===")
	print("Complexity: ", ai_result.complexity)
	print("Chaos Factor: ", ai_result.chaos_factor)
	
	if ai_result.action_type == "multi_effect":
		execute_multi_effect_action(ai_result)
	else:
		# 既存のシステムにフォールバック
		match ai_result.action_type:
			"fire_attack", "lightning_strike", "attack":
				execute_attack_action(ai_result)
			"self_heal", "strong_heal", "heal":
				execute_heal_action(ai_result)
			"shield", "defend":
				execute_defend_action(ai_result)
			"strength_buff", "speed_buff", "buff":
				execute_buff_action(ai_result)
			"pain_heal", "flame_shield":
				execute_special_action(ai_result)
			"pure_chaos", "time_distortion":
				execute_chaos_action(ai_result)
			_:
				execute_unknown_action(ai_result)
			
func execute_attack_action(ai_result: Dictionary):
	var damage = calculate_damage(ai_result)
	apply_damage_to_enemy(damage)
	show_action_result(ai_result, "💥 Damage: " + str(damage))
	
	await get_tree().create_timer(1.5).timeout
	enemy_turn()

func execute_heal_action(ai_result: Dictionary):
	var heal_amount = ai_result.power + randi() % 3
	player_hp = min(player_max_hp, player_hp + heal_amount)
	player_hp_bar.value = player_hp
	
	show_action_result(ai_result, "💚 Healed: " + str(heal_amount) + " HP")
	
	await get_tree().create_timer(1.5).timeout
	enemy_turn()

func execute_multi_effect_action(ai_result: Dictionary):
	var effect_descriptions = []
	var total_damage = 0
	var total_healing = 0
	var buffs = []
	
	print("Executing ", ai_result.effects.size(), " effects...")
	
	# === 各効果を実行 ===
	for effect in ai_result.effects:
		match effect.type:
			"offensive":
				var damage = effect.power
				if effect.has("element"):
					damage += 1  # 属性ボーナス
				
				apply_damage_to_enemy(damage)
				total_damage += damage
				effect_descriptions.append("💥 " + str(damage) + " " + effect.get("element", "") + " damage")
			
			"restorative":
				var healing = effect.power
				player_hp = min(player_max_hp, player_hp + healing)
				player_hp_bar.value = player_hp
				total_healing += healing
				effect_descriptions.append("💚 +" + str(healing) + " HP")
			
			"protective":
				var defense = effect.power
				buffs.append("🛡️ Defense +" + str(defense))
				effect_descriptions.append("🛡️ Defense +" + str(defense))
			
			"magical":
				# 魔法効果は少しランダム
				if randf() > 0.5:
					var magic_damage = effect.power + randi() % 3
					apply_damage_to_enemy(magic_damage)
					effect_descriptions.append("✨ " + str(magic_damage) + " magical damage")
				else:
					var magic_healing = effect.power
					player_hp = min(player_max_hp, player_hp + magic_healing)
					player_hp_bar.value = player_hp
					effect_descriptions.append("✨ " + str(magic_healing) + " magical healing")
	
	# === 結果表示（修正版） ===
	var result_text = ai_result.narrative + "\n\n"
	result_text += "Multi-Effects:\n"
	
	# join の代わりに手動結合
	for i in range(effect_descriptions.size()):
		result_text += effect_descriptions[i]
		if i < effect_descriptions.size() - 1:
			result_text += "\n"
	
	if ai_result.chaos_factor > 0.5:
		result_text += "\n\n🌀 High chaos energy detected!"
	
	show_action_result(ai_result, result_text)
	
	await get_tree().create_timer(2.0).timeout
	enemy_turn()

func execute_special_action(ai_result: Dictionary):
	match ai_result.action_type:
		"pain_heal":
			# 敵にダメージ + 自分回復
			var damage = ai_result.power - 2
			var heal = ai_result.power / 2
			apply_damage_to_enemy(damage)
			player_hp = min(player_max_hp, player_hp + heal)
			player_hp_bar.value = player_hp
			show_action_result(ai_result, "⚡✨ Damage: " + str(damage) + ", Heal: " + str(heal))
		
		"flame_shield":
			# 防御 + 反射ダメージフラグ
			show_action_result(ai_result, "🔥🛡️ Flame shield active! Next attack will be reflected!")
	
	await get_tree().create_timer(1.5).timeout
	enemy_turn()

func execute_chaos_action(ai_result: Dictionary):
	var chaos_effects = [
		"🌀 Everyone's HP is randomly shuffled!",
		"⚡ All damage is doubled this turn!",
		"🎭 Attack and healing are swapped!",
		"💫 A random spell affects everyone!"
	]
	
	var effect = chaos_effects[randi() % chaos_effects.size()]
	
	# 実際にカオス効果を適用
	match randi() % 4:
		0:  # HP shuffle
			var temp = player_hp
			player_hp = enemy_current_hp
			enemy_current_hp = temp
			update_hp_bars()
		1:  # 大ダメージ
			apply_damage_to_enemy(ai_result.power * 2)
		2:  # 相互ダメージ
			apply_damage_to_enemy(ai_result.power)
			apply_damage_to_player(ai_result.power / 2)
		3:  # ランダム効果
			if randf() > 0.5:
				execute_heal_action(ai_result)
				return
			else:
				execute_attack_action(ai_result)
				return
	
	show_action_result(ai_result, "🌀 " + effect)
	
	await get_tree().create_timer(2.0).timeout
	enemy_turn()

# Main.gd に追加（全部まとめて）

func execute_defend_action(ai_result: Dictionary):
	# 防御効果
	var defense_power = ai_result.power
	show_action_result(ai_result, "🛡️ Defense increased by " + str(defense_power) + " for next turn!")
	
	# TODO: 実際の防御効果フラグ管理
	await get_tree().create_timer(1.5).timeout
	enemy_turn()

func execute_buff_action(ai_result: Dictionary):
	# バフ効果
	var buff_power = ai_result.power
	show_action_result(ai_result, "💪 Your abilities are enhanced by " + str(buff_power) + "!")
	
	# TODO: 実際のバフ効果フラグ管理
	await get_tree().create_timer(1.5).timeout
	enemy_turn()

func execute_unknown_action(ai_result: Dictionary):
	# 最終的なフォールバック
	print("⚠️ Unknown action type: ", ai_result.action_type)
	
	# とりあえず攻撃として処理
	show_action_result(ai_result, "❓ Something mysterious happens... it seems to have an attack-like effect!")
	
	var damage = ai_result.power / 2  # 弱めのダメージ
	apply_damage_to_enemy(damage)
	
	await get_tree().create_timer(1.5).timeout
	enemy_turn()
	
# Main.gd の execute_mystery_action を修正
func execute_mystery_action(ai_result: Dictionary):
	print("🌟 Executing mystery action!")
	
	var mystery_outcomes = [
		"heal_and_damage",
		"swap_positions", 
		"double_effect",
		"random_spell",
		"nothing_happens",
		"reverse_effect"
	]
	
	var outcome = mystery_outcomes[randi() % mystery_outcomes.size()]
	var effect_text = ""
	
	match outcome:
		"heal_and_damage":
			var heal = ai_result.power / 2
			var damage = ai_result.power
			player_hp = min(player_max_hp, player_hp + heal)
			apply_damage_to_enemy(damage)
			update_hp_bars()  # ← HPバー更新追加
			effect_text = "🌟✨ Mysterious energy heals you (" + str(heal) + ") and harms enemies (" + str(damage) + ")!"
			
		"swap_positions":
			var temp_hp = player_hp
			player_hp = min(player_max_hp, enemy_current_hp)
			enemy_current_hp = min(enemy_max_hp, temp_hp)
			update_hp_bars()  # この関数を使用
			effect_text = "🔄 Reality flips! HP values are swapped!"
			
		"double_effect":
			effect_text = "⚡x2 Next action will have DOUBLE POWER!"
			
		"random_spell":
			var random_effects = ["heal", "attack", "buff"]
			var random_effect = random_effects[randi() % random_effects.size()]
			match random_effect:
				"heal":
					var heal_result = ai_result.duplicate()
					heal_result.action_type = "self_heal"
					execute_heal_action(heal_result)
					return
				"attack":
					var attack_result = ai_result.duplicate()
					attack_result.action_type = "fire_attack"
					execute_attack_action(attack_result)
					return
				"buff":
					effect_text = "🎲 Random magic enhances your abilities!"
			
		"nothing_happens":
			effect_text = "✨ The magic fizzles beautifully but harmlessly!"
			
		"reverse_effect":
			apply_damage_to_player(ai_result.power / 2)
			effect_text = "🔄 The spell backfires! You take " + str(ai_result.power / 2) + " damage!"
	
	show_action_result(ai_result, effect_text)
	
	await get_tree().create_timer(2.0).timeout
	enemy_turn()

func update_hp_bars():
	# HPバーの表示を更新
	player_hp_bar.value = player_hp
	enemy_hp_bar.value = enemy_current_hp
	
	# アニメーション付きで更新
	var player_tween = create_tween()
	var enemy_tween = create_tween()
	
	player_tween.tween_property(player_hp_bar, "value", player_hp, 0.5)
	enemy_tween.tween_property(enemy_hp_bar, "value", enemy_current_hp, 0.5)
	
	print("HP updated - Player: ", player_hp, "/", player_max_hp, " Enemy: ", enemy_current_hp, "/", enemy_max_hp)
	
# Main.gd の calculate_damage を修正
func calculate_damage(ai_result: Dictionary) -> int:
	var base_damage = ai_result.power
	var success_roll = randf()
	
	# success_rate の代わりに accuracy または chaos_factor から計算
	var success_rate = 0.7  # デフォルト成功率
	
	if ai_result.has("accuracy"):
		success_rate = ai_result.accuracy
	elif ai_result.has("chaos_factor"):
		# chaos_factor が高いほど成功率は下がる
		success_rate = 1.0 - (ai_result.chaos_factor * 0.3)  # 0.7~1.0
	
	if success_roll <= success_rate:
		# 成功！
		var final_damage = base_damage + randi() % 3  # +0~2のランダム
		print("💥 Attack SUCCESS! Damage: ", final_damage)
		return final_damage
	else:
		# 失敗...
		var reduced_damage = max(1, base_damage / 2)  # 半減（最低1）
		print("😅 Attack MISSED! Reduced damage: ", reduced_damage)
		return reduced_damage
		
func apply_damage_to_player(damage: int):
	player_hp = max(0, player_hp - damage)
	
	# HPバーアニメーション
	var tween = create_tween()
	tween.tween_property(player_hp_bar, "value", player_hp, 0.5)
	
	print("💔 Player takes ", damage, " damage! HP: ", player_hp, "/", player_max_hp)
		
func apply_damage_to_enemy(damage: int):
	enemy_current_hp = max(0, enemy_current_hp - damage)
	enemy_hp_bar.value = enemy_current_hp
	
	print("🎯 Enemy HP: ", enemy_current_hp, "/", enemy_max_hp)
	
	# HP バーアニメーション
	var tween = create_tween()
	tween.tween_property(enemy_hp_bar, "value", enemy_current_hp, 0.5)
	


func show_battle_result(ai_result: Dictionary, damage: int):
	var log_text = "[center][font_size=18]⚔️ BATTLE RESULT ⚔️[/font_size][/center]\n\n"
	log_text += "[font_size=16]" + ai_result.narrative + "[/font_size]\n\n"
	log_text += "💥 Damage: " + str(damage) + "\n"
	log_text += "🎯 Enemy HP: " + str(enemy_current_hp) + "/" + str(enemy_max_hp)
	
	log_label.text = log_text

func create_card_ui(card: Card) -> CardUI:
	var card_ui_scene = preload("res://scenes/ui/CardUI.tscn")
	var card_ui = card_ui_scene.instantiate()
	await get_tree().process_frame
	card_ui.setup_card(card)
	return card_ui

# Main.gd に追加
func _on_card_dropped(card_ui: CardUI):
	print("Card dropped: ", card_ui.card_data.word)
	
	var drop_position = card_ui.global_position.x
	var new_index = calculate_insert_position(drop_position)
	var old_index = hand_cards.find(card_ui)
	
	print("Moving from index ", old_index, " to ", new_index)
	
	if new_index != old_index and new_index >= 0:
		# 配列内の順番を変更
		hand_cards.remove_at(old_index)
		hand_cards.insert(new_index, card_ui)
		
		# HBoxContainerから全て削除
		for card in hand_cards:
			hand_area.remove_child(card)
		
		await get_tree().process_frame
		
		# 新しい順番で再追加
		for card in hand_cards:
			hand_area.add_child(card)
			card.position = Vector2.ZERO
	else:
		# 順番変更なしの場合は普通にリセット
		rearrange_cards()

func calculate_insert_position(drop_x: float) -> int:
	# 各カードスロットの中央位置を計算
	var slot_width = 120 + 10  # カード幅 + 間隔
	var hand_start_x = hand_area.global_position.x
	
	# ドロップ位置がどのスロットに近いかを計算
	var relative_x = drop_x - hand_start_x
	var slot_index = round(relative_x / slot_width)
	
	# 範囲内に収める
	slot_index = clamp(slot_index, 0, hand_cards.size() - 1)
	return slot_index
	
# Main.gd に追加
func _on_card_dragging(card_ui: CardUI, mouse_pos: Vector2):
	var new_index = calculate_insert_position(mouse_pos.x)
	highlight_insert_position(new_index)

func highlight_insert_position(index: int):
	# TODO: 挿入位置にガイドラインを表示
	print("Will insert at position: ", index)

func rearrange_cards():
	print("Simple rearrange...")
	hand_area.queue_sort()
	await get_tree().process_frame
	
	for card in hand_cards:
		card.position = Vector2.ZERO
		
func setup_enemy():
	enemy_name_label.text = "🐉 Fire Dragon"
	enemy_hp_bar.max_value = enemy_max_hp
	enemy_hp_bar.value = enemy_current_hp
	# プレイヤーHP初期化
	player_hp_bar.max_value = player_max_hp
	player_hp_bar.value = player_hp
	
func enemy_turn():
	if enemy_current_hp <= 0:
		show_victory()
		return
	
	print("=== ENEMY TURN ===")
	
	# 敵の攻撃
	var enemy_damage = 5 + randi() % 4  # 5~8ダメージ
	apply_damage_to_player(enemy_damage)  # ← 専用関数呼び出し
	
	print("🔥 Enemy attacks for ", enemy_damage, " damage!")
	print("❤️ Player HP: ", player_hp, "/", player_max_hp)
	
	# ログ更新
	var current_log = log_label.text
	log_label.text = current_log + "\n\n[color=red]🔥 Fire Dragon attacks![/color]\n"
	log_label.text += "💔 You take " + str(enemy_damage) + " damage!\n"
	log_label.text += "❤️ Your HP: " + str(player_hp) + "/" + str(player_max_hp)
	
	# 敗北チェック
	if player_hp <= 0:
		show_defeat()

func show_victory():
	log_label.text = "[center][font_size=24][color=gold]🎉 VICTORY! 🎉[/color][/font_size][/center]\n\n"
	log_label.text += "[center]The Fire Dragon has been defeated![/center]"
	execute_button.disabled = true

func show_defeat():
	log_label.text = "[center][font_size=24][color=red]💀 DEFEAT 💀[/color][/font_size][/center]\n\n"
	log_label.text += "[center]You have been defeated...[/center]"
	execute_button.disabled = true
	
func show_action_result(ai_result: Dictionary, effect_text: String):
	var chaos_indicator = ""
	if ai_result.chaos_factor > 0.6:
		chaos_indicator = " 🌀 HIGH CHAOS!"
	elif ai_result.chaos_factor > 0.3:
		chaos_indicator = " ⚡ Chaotic!"
	
	var log_text = "[center][font_size=18]⚔️ BATTLE RESULT ⚔️[/font_size][/center]\n\n"
	log_text += "[font_size=16]" + ai_result.narrative + "[/font_size]\n\n"
	log_text += effect_text + chaos_indicator + "\n"
	log_text += "🎯 Enemy HP: " + str(enemy_current_hp) + "/" + str(enemy_max_hp) + "\n"
	log_text += "❤️ Your HP: " + str(player_hp) + "/" + str(player_max_hp)
	
	log_label.text = log_text
