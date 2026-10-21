extends Node2D

var hp_left := 100
var hp_right := 100
var x_left := 300.0
var x_right := 900.0
var y_left := 610.0
var velocity_y := 0.0
var attack_cooldown := 0.0
var enemy_cooldown := 0.0
var left_rig := {}
var right_rig := {}
var controls := {}
var held := {}
var round_over := false
var player_wins := 0
var enemy_wins := 0
var score_label: Label
var result_label: Label
var restart_button: Button
var player_attack_fx := 0.0
var enemy_attack_fx := 0.0
var player_hit_fx := 0.0
var enemy_hit_fx := 0.0
var ai_timer := 0.0
var ai_retreat := false
var animation_clock := 0.0
var player_motion := 0.0
var enemy_motion := 0.0
var cooldown_label: Label

func _ready() -> void:
    left_rig = make_rig()
    right_rig = make_rig()
    for label in ["LEFT", "RIGHT", "JUMP", "HIT"]:
        var button := Button.new()
        button.text = label
        button.position = Vector2(30 + controls.size() * 145, 620)
        button.size = Vector2(130, 80)
        button.modulate.a = 0.8
        add_child(button)
        controls[label] = button
        held[label] = false
        button.button_down.connect(func(): held[label] = true)
        button.button_up.connect(func(): held[label] = false)
    score_label = Label.new()
    score_label.position = Vector2(495, 20)
    score_label.add_theme_font_size_override("font_size", 22)
    score_label.text = "PLAYER 0 : 0 ENEMY"
    add_child(score_label)
    result_label = Label.new()
    result_label.position = Vector2(500, 280)
    result_label.add_theme_font_size_override("font_size", 42)
    result_label.visible = false
    add_child(result_label)
    restart_button = Button.new()
    restart_button.text = "RESTART"
    restart_button.position = Vector2(760, 620)
    restart_button.size = Vector2(170, 80)
    restart_button.visible = false
    restart_button.pressed.connect(restart_round)
    add_child(restart_button)
    cooldown_label = Label.new()
    cooldown_label.position = Vector2(620, 625)
    cooldown_label.add_theme_font_size_override("font_size", 17)
    add_child(cooldown_label)

func restart_round() -> void:
    hp_left = 100
    hp_right = 100
    x_left = 300.0
    x_right = 900.0
    y_left = 610.0
    velocity_y = 0.0
    attack_cooldown = 0.0
    enemy_cooldown = 0.0
    round_over = false
    player_attack_fx = 0.0
    enemy_attack_fx = 0.0
    player_hit_fx = 0.0
    enemy_hit_fx = 0.0
    ai_timer = 0.0
    ai_retreat = false
    result_label.visible = false
    restart_button.visible = false
    queue_redraw()

func finish_round(player_won: bool) -> void:
    if round_over:
        return
    round_over = true
    if player_won:
        player_wins += 1
        result_label.text = "YOU WIN!"
    else:
        enemy_wins += 1
        result_label.text = "YOU LOSE!"
    score_label.text = "PLAYER %d : %d ENEMY" % [player_wins, enemy_wins]
    result_label.visible = true
    restart_button.visible = true

func make_rig() -> Dictionary:
    var anchors := {}
    for name in ["head", "torso", "pelvis", "chest_left", "chest_right", "glute_left", "glute_right", "arm_left", "arm_right", "leg_left", "leg_right", "hair", "pelvic_attachment", "pelvic_secondary_left", "pelvic_secondary_right"]:
        anchors[name] = Vector2.ZERO
    return anchors

func _process(delta: float) -> void:
    if round_over:
        return
    animation_clock += delta
    player_motion = 0.0
    enemy_motion = 0.0
    player_attack_fx = maxf(0.0, player_attack_fx - delta)
    enemy_attack_fx = maxf(0.0, enemy_attack_fx - delta)
    player_hit_fx = maxf(0.0, player_hit_fx - delta)
    enemy_hit_fx = maxf(0.0, enemy_hit_fx - delta)
    ai_timer -= delta
    attack_cooldown = maxf(0, attack_cooldown - delta)
    enemy_cooldown = maxf(0, enemy_cooldown - delta)
    var left_pressed: bool = Input.is_key_pressed(KEY_A) or held["LEFT"]
    var right_pressed: bool = Input.is_key_pressed(KEY_D) or held["RIGHT"]
    var jump_pressed: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or held["JUMP"]
    var hit_pressed: bool = Input.is_key_pressed(KEY_J) or held["HIT"]
    player_motion = float(right_pressed) - float(left_pressed)
    x_left += player_motion * 330 * delta
    x_left = clampf(x_left, 50, 1230)
    if jump_pressed and y_left >= 610:
        velocity_y = -740
    velocity_y += 1700 * delta
    y_left = minf(610, y_left + velocity_y * delta)
    if y_left >= 610:
        velocity_y = 0
    if hit_pressed and attack_cooldown <= 0:
        attack_cooldown = 0.55
        player_attack_fx = 0.18
        if absf(x_left - x_right) < 145.0 and absf(y_left - 610.0) < 115.0:
            hp_right = maxi(0, hp_right - 10)
            enemy_hit_fx = 0.22
            if hp_right == 0:
                finish_round(true)
    if hp_left > 0 and hp_right > 0:
        var distance: float = absf(x_left - x_right)
        if ai_timer <= 0.0:
            ai_timer = 1.1
            ai_retreat = distance < 185.0 and randf() < 0.35
        if ai_retreat and distance < 240.0:
            enemy_motion = -signf(x_left - x_right)
            x_right += enemy_motion * 110.0 * delta
        elif distance > 110.0:
            enemy_motion = signf(x_left - x_right)
            x_right += enemy_motion * 170.0 * delta
        x_right = clampf(x_right, 50.0, 1230.0)
        if absf(x_left - x_right) < 84.0 and absf(y_left - 610.0) < 115.0:
            var separation: float = 1.0 if x_left <= x_right else -1.0
            var midpoint: float = (x_left + x_right) * 0.5
            x_left = clampf(midpoint - separation * 42.0, 50.0, 1230.0)
            x_right = clampf(midpoint + separation * 42.0, 50.0, 1230.0)
        if absf(x_left - x_right) < 140 and absf(y_left - 610.0) < 120.0 and enemy_cooldown <= 0:
            enemy_cooldown = 0.95
            enemy_attack_fx = 0.18
            player_hit_fx = 0.22
            hp_left = maxi(0, hp_left - 7)
            if hp_left == 0:
                finish_round(false)
    cooldown_label.text = "HIT READY" if attack_cooldown <= 0.0 else "HIT %.1fs" % attack_cooldown
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color("#10152e"))
    draw_circle(Vector2(640, 180), 110, Color("#42396e"))
    draw_rect(Rect2(0, 610, 1280, 110), Color("#2a2544"))
    draw_line(Vector2(0, 610), Vector2(1280, 610), Color("#8e84be"), 4)
    draw_fighter(Vector2(x_left, y_left), Color("#ffffff") if player_hit_fx > 0.0 else Color("#cdb879"), player_attack_fx > 0.0, x_right >= x_left, player_motion, true)
    draw_fighter(Vector2(x_right, 610), Color("#ffffff") if enemy_hit_fx > 0.0 else Color("#b44363"), enemy_attack_fx > 0.0, x_left >= x_right, enemy_motion, false)
    if enemy_hit_fx > 0.0:
        draw_circle(Vector2(x_right, 470), 12.0 + enemy_hit_fx * 55.0, Color("#ffd56c", enemy_hit_fx * 3.0))
    if player_hit_fx > 0.0:
        draw_circle(Vector2(x_left, y_left - 140.0), 12.0 + player_hit_fx * 55.0, Color("#ffd56c", player_hit_fx * 3.0))
    draw_rect(Rect2(50, 35, 400, 26), Color("#393349"))
    draw_rect(Rect2(830, 35, 400, 26), Color("#393349"))
    draw_rect(Rect2(50, 35, hp_left * 4, 26), Color("#80d6ae"))
    draw_rect(Rect2(830, 35, hp_right * 4, 26), Color("#df738f"))

func draw_fighter(origin: Vector2, color: Color, attacking: bool, face_right: bool, motion: float, is_player: bool) -> void:
    var facing: float = 1.0 if face_right else -1.0
    var step: float = sin(animation_clock * 12.0) * 10.0 if absf(motion) > 0.1 else 0.0
    var bob: float = absf(sin(animation_clock * 12.0)) * 3.0 if absf(motion) > 0.1 else sin(animation_clock * 2.0) * 2.0
    var body: Vector2 = origin + Vector2(0, -bob)
    var hair: Color = Color("#d7a04d") if is_player else Color("#312245")
    var trim: Color = Color("#fff0c7") if is_player else Color("#f4b6db")
    var boot: Color = Color("#38304c")
    draw_line(body + Vector2(-13, -48), body + Vector2(-17 + step, -5), boot, 20.0)
    draw_line(body + Vector2(13, -48), body + Vector2(17 - step, -5), boot, 20.0)
    draw_colored_polygon(PackedVector2Array([body + Vector2(-25, -123), body + Vector2(25, -123), body + Vector2(30, -53), body + Vector2(-30, -53)]), color)
    draw_line(body + Vector2(-22, -108), body + Vector2(-37, -72 + step * 0.35), color, 17.0)
    if attacking:
        draw_line(body + Vector2(20 * facing, -110), body + Vector2(83 * facing, -105), color, 18.0)
        draw_circle(body + Vector2(86 * facing, -105), 11.0, trim)
    else:
        draw_line(body + Vector2(22, -108), body + Vector2(37, -73 - step * 0.35), color, 17.0)
    draw_line(body + Vector2(-22, -72), body + Vector2(22, -72), trim, 5.0)
    draw_colored_polygon(PackedVector2Array([body + Vector2(-27, -76), body + Vector2(27, -76), body + Vector2(36, -45), body + Vector2(-36, -45)]), color.darkened(0.12))
    draw_circle(body + Vector2(0, -159), 26.0, Color("#f2d0b3"))
    draw_arc(body + Vector2(0, -164), 27.0, PI, TAU, 18, hair, 12.0)
    draw_circle(body + Vector2(-13 * facing, -160), 4.0, hair)
    draw_circle(body + Vector2(9 * facing, -158), 3.0, Color("#29243d"))
    draw_line(body + Vector2(4 * facing, -146), body + Vector2(12 * facing, -146), Color("#a45e69"), 2.0)
    draw_line(body + Vector2(-17, -128), body + Vector2(17, -128), trim, 5.0)
