# CardUI.gd
class_name CardUI
extends Control

signal card_dropped(card_ui: CardUI)

@onready var background = $Background
@onready var word_label = $WordLabel
@onready var power_label = $PowerLabel

var card_data: Card
var is_dragging: bool = false
var drag_offset: Vector2
var original_position: Vector2
var pending_card: Card  # 待機用

func _ready():
	print("=== CardUI Ready ===")
	mouse_filter = Control.MOUSE_FILTER_PASS
	
	# 待機中のカードがあれば設定
	if pending_card:
		setup_card(pending_card)

func setup_card(card: Card):
	card_data = card
	
	# ノードがまだ準備できてない場合は待機
	if not word_label or not power_label:
		pending_card = card
		return
	
	# 実際の設定
	word_label.text = card.word
	power_label.text = "Power: " + str(card.power)
	pending_card = null

func _gui_input(event):
	print("Input received: ", event)  # これが出るかチェック
	if event is InputEventMouseButton:
		print("Mouse button: ", event.button_index, " pressed: ", event.pressed)
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# ドラッグ開始
				is_dragging = true
				drag_offset = event.position
				original_position = global_position
				# 手前に表示
				z_index = 10
				# 少し大きくする
				scale = Vector2(1.1, 1.1)
				print("Dragging: " + card_data.word)
			else:
				# ドラッグ終了
				is_dragging = false
				z_index = 0
				scale = Vector2(1.0, 1.0)
				print("Dropped: " + card_data.word)
				card_dropped.emit(self)  # ← この行を追加

func _input(event):
	if is_dragging and event is InputEventMouseMotion:
		global_position = event.global_position - drag_offset
		
		# ドラッグ中の位置をメインに通知
		get_parent().get_parent()._on_card_dragging(self, event.global_position)
		
