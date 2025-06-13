# Main.gd
extends Control

@onready var hand_area = $HandArea
var hand_cards: Array[CardUI] = []

func _ready():
	print("Main scene starting...")
	await get_tree().process_frame
	
	# 英語版手札カード
	var card_words = ["Attack", "Fire", "All", "Strong", "Heal", "Defend", "Quick"]
	
	for i in range(7):
		var card = Card.new(card_words[i], randi() % 10 + 1)
		var card_ui = await create_card_ui(card)
		hand_area.add_child(card_ui)
		hand_cards.append(card_ui)
		
		# カードからのシグナルを受信
		card_ui.card_dropped.connect(_on_card_dropped)
	
	print("English hand created with 7 cards!")

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
