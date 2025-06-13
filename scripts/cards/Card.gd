class_name Card
extends Resource

enum CardType {
	VERB,      # 動詞: 攻撃、回復、防御
	ELEMENT,   # 属性: 炎、水、雷、土
	TARGET,    # 対象: 単体、全体、自分
	MODIFIER   # 修飾: 強力、弱い、連続
}

enum Rarity {
	COMMON,    # 70%
	RARE,      # 25%
	EPIC       # 5%
}

@export var word: String = "攻撃"
@export var power: int = 5
@export var type: CardType = CardType.VERB
@export var rarity: Rarity = Rarity.COMMON

func _init(p_word: String = "攻撃", p_power: int = 5):
	word = p_word
	power = p_power
