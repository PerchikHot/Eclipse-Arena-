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

func make_rig() -> Dictionary:
    var anchors := {}
    for name in ["head", "torso", "pelvis", "chest_left", "chest_right", "glute_left", "glute_right", "arm_left", "arm_right", "leg_left", "leg_right", "hair", "pelvic_attachment", "pelvic_secondary_left", "pelvic_secondary_right"]:
        anchors[name] = Vector2.ZERO
    return anchors

func _process(delta: float) -> void:
    attack_cooldown = maxf(0, attack_cooldown - delta)
    enemy_cooldown = maxf(0, enemy_cooldown - delta)
    var left_pressed: bool = Input.is_key_pressed(KEY_A) or held["LEFT"]
    var right_pressed: bool = Input.is_key_pressed(KEY_D) or held["RIGHT"]
    var jump_pressed: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or held["JUMP"]
    var hit_pressed: bool = Input.is_key_pressed(KEY_J) or held["HIT"]
    x_left += (float(right_pressed) - float(left_pressed)) * 330 * delta
    x_left = clampf(x_left, 50, 1230)
    if jump_pressed and y_left >= 610:
        velocity_y = -740
    velocity_y += 1700 * delta
    y_left = minf(610, y_left + velocity_y * delta)
    if y_left >= 610:
        velocity_y = 0
    if hit_pressed and attack_cooldown <= 0:
        attack_cooldown = 0.35
        if absf(x_left - x_right) < 145:
            hp_right = maxi(0, hp_right - 10)
    if hp_left > 0 and hp_right > 0:
        x_right += signf(x_left - x_right) * 170 * delta if absf(x_left - x_right) > 110 else 0.0
        if absf(x_left - x_right) < 140 and enemy_cooldown <= 0:
            enemy_cooldown = 0.85
            hp_left = maxi(0, hp_left - 7)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color("#10152e"))
    draw_circle(Vector2(640, 180), 110, Color("#42396e"))
    draw_rect(Rect2(0, 610, 1280, 110), Color("#2a2544"))
    draw_line(Vector2(0, 610), Vector2(1280, 610), Color("#8e84be"), 4)
    draw_fighter(Vector2(x_left, y_left), Color("#cdb879"))
    draw_fighter(Vector2(x_right, 610), Color("#b44363"))
    draw_rect(Rect2(50, 35, hp_left * 4, 26), Color("#80d6ae"))
    draw_rect(Rect2(830, 35, hp_right * 4, 26), Color("#df738f"))

func draw_fighter(origin: Vector2, color: Color) -> void:
    draw_rect(Rect2(origin + Vector2(-24, -125), Vector2(48, 75)), color)
    draw_circle(origin + Vector2(0, -160), 25, Color("#f2d0b3"))
    draw_line(origin + Vector2(-15, -50), origin + Vector2(-20, -5), color, 19)
    draw_line(origin + Vector2(15, -50), origin + Vector2(20, -5), color, 19)
    draw_line(origin + Vector2(-20, -115), origin + Vector2(-38, -73), color, 15)
    draw_line(origin + Vector2(20, -115), origin + Vector2(38, -73), color, 15)
