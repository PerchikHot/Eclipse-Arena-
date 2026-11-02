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
        and Rules.guard_readiness_label(100.0, false) == "ЗАЩИТА: 100%"
        and Rules.guard_readiness_label(12.0, false) == "ЗАЩИТА: МАЛО 12%"
        and Rules.guard_readiness_label(40.0, true) == "ЗАЩИТА: ПЕРЕГРЕВ"
        and Rules.guard_readiness_label(150.0, false) == "ЗАЩИТА: 100%"
        and Rules.health_advantage_label(100, 100) == "HP: РАВНО"
        and Rules.health_advantage_label(90, 60) == "HP: ПРЕИМУЩЕСТВО +30"
        and Rules.health_advantage_label(25, 90) == "HP: ОТСТАВАНИЕ 65"
        and Rules.health_advantage_label(-10, 150) == "HP: ОТСТАВАНИЕ 100"
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
        and Rules.round_training_tip(0, 0, 0, 0, 0).begins_with("СОВЕТ:")
        and Rules.round_training_tip(1, 5, 5, 0, 0).contains("дистанцию")
        and Rules.round_training_tip(4, 5, 10, 20, 1).contains("уклоняйся")
        and Rules.round_training_tip(4, 5, 20, 5, 0).contains("парирование")
        and Rules.round_training_tip(4, 5, 20, 5, 2).begins_with("ОТЛИЧНО:")
    )
    assert(
        Rules.touch_direction(Vector2(112, 643), Vector2(112, 643)) == Vector2.ZERO
        and Rules.touch_direction(Vector2(112, 585), Vector2(112, 643)) == Vector2.UP
        and Rules.touch_direction(Vector2(112, 701), Vector2(112, 643)) == Vector2.DOWN
        and Rules.touch_direction(Vector2(170, 643), Vector2(112, 643)) == Vector2.RIGHT
        and Rules.touch_direction(Vector2(200, 643), Vector2(112, 643)).length() <= 1.0
        and Rules.should_start_jump(true, false, true, false)
        and not Rules.should_start_jump(true, true, true, false)
        and not Rules.should_start_jump(true, false, false, false)
        and not Rules.should_start_jump(true, false, true, true)
        and not Rules.should_start_jump(false, false, true, false)
        and Rules.attack_level(-1.0) == 1
        and Rules.attack_level(0.0) == 0
        and Rules.attack_level(1.0) == -1
        and Rules.attack_level_label(1) == "ГОЛОВА"
        and Rules.attack_level_label(0) == "КОРПУС"
        and Rules.attack_level_label(-1) == "НОГИ"
        and Rules.guard_covers_level(false, 1)
        and not Rules.guard_covers_level(false, -1)
        and Rules.guard_covers_level(true, -1)
        and not Rules.guard_covers_level(true, 1)
        and Rules.guard_covers_level(true, 0)
        and not Rules.attack_connects(1, true, false)
        and not Rules.attack_connects(-1, false, true)
        and Rules.attack_connects(0, true, false)
        and Rules.level_damage(8, 1) == 11
        and Rules.level_damage(8, 0) == 8
        and Rules.level_damage(8, -1) == 6
        and Rules.compact_combat_cue(0.0, 0, 0.0, 0.0, 0.0, 0.0, 0, 0.25).begins_with("ОГЛУШЕНИЕ")
        and Rules.compact_combat_cue(0.5, 1, 0.0, 0.0, 0.0, 0.0, 0, 0.0).contains("ВРАГ")
        and is_equal_approx(Rules.hitstun_seconds(1, false, false), 0.28)
        and is_equal_approx(Rules.hitstun_seconds(0, false, false), 0.22)
        and is_equal_approx(Rules.hitstun_seconds(-1, false, false), 0.18)
        and is_equal_approx(Rules.hitstun_seconds(0, true, false), 0.55)
        and Rules.hitstun_seconds(1, true, true) == 0.0
        and Rules.player_hitstun_on_hit(0, false, true, false) == 0.0
        and is_equal_approx(Rules.player_hitstun_on_hit(0, false, false, false), 0.22)
        and is_equal_approx(Rules.player_hitstun_on_hit(0, false, true, true), 0.34)
        and is_equal_approx(Rules.player_hitstun_on_hit(1, true, true, true), 0.67)
    )
    # A mobile HUD shows one urgent cue instead of overlapping long text.
    assert(Rules.compact_combat_cue(0.3, 1, 0, 0, 0.4, 0, 4) == "⚠ ВРАГ: ГОЛОВА")
    assert(Rules.compact_combat_cue(0, 0, 1, 0, 0, 0, 0) == "⚡ БЛОК ПРОБИТ")
    assert(Rules.compact_combat_cue(0, 0, 0, 0.1, 0, 0, 0) == "✦ ПАРИРОВАНИЕ")
    assert(Rules.compact_combat_cue(0, 0, 0, 0, 0, 0, 3) == "КОМБО 3")
    assert(Rules.compact_combat_cue(0, 0, 0, 0, 0, 0, 0) == "ГОТОВО К БОЮ")
    assert(Rules.compact_combat_cue(0, 0, 0, 0, 0, 0, 5, 0.0, 24) == "⚠ КРИТИЧЕСКОЕ HP")
    assert(Rules.compact_combat_cue(0, 0, 0, 0, 0, 0, 5, 0.0, 26) == "КОМБО 5")
    assert(Rules.compact_combat_cue(0.5, 1, 0, 0, 0, 0, 5, 0.0, 10) == "⚠ ВРАГ: ГОЛОВА")
    assert(Rules.joystick_center_for_viewport(Vector2(1280, 720)) == Vector2(112, 643))
    assert(Rules.joystick_center_for_viewport(Vector2(640, 360)) == Vector2(112, 283))
    assert(Rules.joystick_center_for_viewport(Vector2(320, 240)) == Vector2(76, 163))
    for screen in [Vector2(120, 90), Vector2(320, 240), Vector2(640, 360)]:
        var center := Rules.joystick_center_for_viewport(screen)
        assert(center.x >= 0.0 and center.x <= screen.x)
        assert(center.y >= 0.0 and center.y <= screen.y)
    assert(Rules.fighter_sprite_size(false) == Vector2(260, 400))
    assert(Rules.fighter_sprite_size(true) == Vector2(260, 236))
    assert(610.0 - Rules.fighter_sprite_size(false).y > 125.0)
    assert(Rules.fighter_sprite_size(false).y > Rules.fighter_sprite_size(true).y)
    assert(Rules.result_font_size(Vector2(120, 90)) == 11)
    assert(Rules.result_font_size(Vector2(160, 120)) == 11)
    assert(Rules.result_font_size(Vector2(320, 240)) == 14)
    assert(Rules.result_font_size(Vector2(640, 360)) == 14)
    assert(Rules.result_font_size(Vector2(480, 800)) == 16)
    assert(Rules.result_font_size(Vector2(1280, 720)) == 19)
    for viewport in [Vector2(120, 90), Vector2(160, 120), Vector2(200, 180), Vector2(240, 180), Vector2(300, 200), Vector2(320, 240), Vector2(640, 360), Vector2(800, 360), Vector2(360, 640), Vector2(480, 800), Vector2(1280, 720)]:
        var rects := Rules.result_overlay_rects(viewport)
        var panel: Rect2 = rects["panel"]
        var insets := Rules.result_content_insets(panel.size)
        assert(insets.x >= 2 and insets.y >= 2)
        assert(insets.x * 2 + 12 < panel.size.x)
        assert(insets.y * 2 < panel.size.y)
        var change: Rect2 = rects["change"]
        var restart: Rect2 = rects["restart"]
        assert(panel.position.x >= 0.0 and panel.position.y >= 0.0)
        assert(panel.end.x <= viewport.x and panel.end.y < viewport.y)
        assert(change.position.x >= 0.0 and restart.end.x <= viewport.x)
        assert(change.end.x < restart.position.x)
        assert(change.position.y >= panel.end.y)
        assert(restart.end.y <= viewport.y)
    print("Combat rules smoke tests passed")
    quit(0)
