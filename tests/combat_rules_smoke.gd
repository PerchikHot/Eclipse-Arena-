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
        and Rules.defense_challenge_grade(1, 0, 1) == "—"
        and Rules.defense_challenge_grade(9, 1, 10) == "S"
        and Rules.defense_challenge_grade(3, 1, 5) == "A"
        and Rules.defense_challenge_grade(3, 0, 5) == "B"
        and Rules.defense_challenge_grade(2, 0, 5) == "C"
        and Rules.defense_challenge_grade(0, 0, 5) == "D"
    )
    if not passed:
        push_error("Defense drill scoring regression")
        quit(1)
        return
    print("Combat rules smoke tests passed")
    quit(0)
