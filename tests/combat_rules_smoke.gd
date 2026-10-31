extends SceneTree

const Rules = preload("res://scripts/combat_rules.gd")

func _initialize() -> void:
    var passed := (
        Rules.defense_challenge_score(0, 0) == 0
        and Rules.defense_challenge_score(2, 3) == 12
        and Rules.defense_challenge_score(-1, 1) == 2
        and Rules.defense_accuracy(0, 0, 0) == 0
        and Rules.defense_accuracy(1, 1, 4) == 50
        and Rules.defense_accuracy(3, 3, 3) == 100
        and Rules.defense_accuracy(-1, 1, 2) == 50
    )
    if not passed:
        push_error("Defense drill scoring regression")
        quit(1)
        return
    print("Combat rules smoke tests passed")
    quit(0)
