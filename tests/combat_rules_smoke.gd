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
        and not Rules.eligible_defense_record(false, 10)
        and not Rules.eligible_defense_record(true, 2)
        and Rules.eligible_defense_record(true, 3)
        and Rules.eligible_defense_record(true, 10)
        and Rules.next_defense_streak(0, true) == 1
        and Rules.next_defense_streak(3, true) == 4
        and Rules.next_defense_streak(4, false) == 0
        and Rules.next_defense_streak(-1, true) == 1
        and Rules.next_defense_streak(99999, true) == 99999
        and Rules.player_attack_damage(1, false, false) == 9
        and Rules.player_attack_damage(4, false, false) == 12
        and Rules.player_attack_damage(100, false, false) == 12
        and Rules.player_attack_damage(1, false, true) == 2
        and Rules.player_attack_damage(4, false, true) == 3
        and Rules.player_attack_damage(4, true, true) == 18
        and Rules.player_attack_damage(-1, false, false) == 8
        and Rules.training_damage_preview(0, false) == Vector2i(8, 18)
        and Rules.training_damage_preview(4, false) == Vector2i(12, 18)
        and Rules.training_damage_preview(4, true) == Vector2i(3, 18)
        and Rules.career_win_rate(Vector3i.ZERO) == 0
        and Rules.career_win_rate(Vector3i(1, 1, 0)) == 50
        and Rules.career_win_rate(Vector3i(3, 1, 0)) == 75
        and Rules.career_win_rate(Vector3i(1, 1, 2)) == 25
        and Rules.career_win_rate(Vector3i(-10, 2, 0)) == 0
        and Rules.career_win_rate(Vector3i(99999, 0, 0)) == 100
        and Rules.next_career_record(Vector3i.ZERO, 1) == Vector3i(1, 0, 0)
        and Rules.next_career_record(Vector3i(2, 1, 0), -1) == Vector3i(2, 2, 0)
        and Rules.next_career_record(Vector3i(2, 1, 0), 0) == Vector3i(2, 1, 1)
        and Rules.next_career_record(Vector3i(-2, 0, 0), 1) == Vector3i(1, 0, 0)
        and Rules.next_career_record(Vector3i(99999, 0, 0), 1) == Vector3i(99999, 0, 0)
    )
    if not passed:
        push_error("Defense drill scoring regression")
        quit(1)
        return
    assert(
        Rules.round_performance_score(1, 10, 10, 100, 0, 5) == 100
        and Rules.round_performance_grade(1, 10, 10, 100, 0, 5) == "S"
        and Rules.round_performance_grade(-1, 0, 0, 0, 100, 0) == "D"
        and Rules.round_performance_score(0, 0, 0, 0, 0, 0) == 10
        and Rules.round_performance_score(1, 100, 1, 0, 0, -4) <= 100
        and Rules.round_performance_score(1, 0, -1, 0, 0, 0) == 25
    )
    print("Combat rules smoke tests passed")
    quit(0)
