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
var in_menu := true
var menu_layer: Control
var pause_button: Button
var audio_players: Array[AudioStreamPlayer] = []
var sound_library: Dictionary = {}
var sound_slot := 0
var fighter_names := ["ЯМАТО", "ЭРЗА", "АЛЬФА", "РИАС"]
var fighter_colors := [Color("#f0eceb"), Color("#b73545"), Color("#1c263f"), Color("#421c49")]
var fighter_hair := [Color("#e5f8ff"), Color("#a92736"), Color("#edcf86"), Color("#b7283f")]
var selected_fighter := 0
var enemy_fighter := 1
var selection_layer: Control
var selection_title: Label
var selection_buttons: Array[Button] = []
var player_name_label: Label
var enemy_name_label: Label

func _ready() -> void:
    sound_library["swing"] = make_sound(0.13, 220.0, 90.0, 0.14, 0)
    sound_library["hit"] = make_sound(0.19, 130.0, 45.0, 0.29, 1)
    sound_library["jump"] = make_sound(0.17, 280.0, 570.0, 0.13, 0)
    sound_library["victory"] = make_sound(0.55, 420.0, 840.0, 0.15, 0)
    sound_library["defeat"] = make_sound(0.48, 320.0, 90.0, 0.15, 0)
    sound_library["menu"] = make_sound(0.11, 470.0, 720.0, 0.11, 0)
    for i in range(6):
        var audio := AudioStreamPlayer.new()
        audio.volume_db = -7.0
        add_child(audio)
        audio_players.append(audio)
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
    player_name_label = Label.new()
    player_name_label.position = Vector2(50, 5)
    player_name_label.add_theme_font_size_override("font_size", 20)
    add_child(player_name_label)
    enemy_name_label = Label.new()
    enemy_name_label.position = Vector2(830, 5)
    enemy_name_label.add_theme_font_size_override("font_size", 20)
    add_child(enemy_name_label)
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
    pause_button = Button.new()
    pause_button.text = "MENU"
    pause_button.position = Vector2(1110, 625)
    pause_button.size = Vector2(140, 65)
    pause_button.pressed.connect(show_menu)
    add_child(pause_button)
    menu_layer = Control.new()
    menu_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(menu_layer)
    var background := TextureRect.new()
    background.texture = load("res://assets/menu_background.svg")
    background.position = Vector2.ZERO
    background.size = Vector2(1280, 720)
    background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    background.stretch_mode = TextureRect.STRETCH_SCALE
    menu_layer.add_child(background)
    var title := Label.new()
    title.text = "ECLIPSE\nARENA"
    title.position = Vector2(42, 70)
    title.size = Vector2(380, 165)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 62)
    title.add_theme_color_override("font_color", Color("#e9c8ff"))
    menu_layer.add_child(title)
    var subtitle := Label.new()
    subtitle.text = "ANIME FIGHTING ARENA"
    subtitle.position = Vector2(42, 250)
    subtitle.size = Vector2(380, 40)
    subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    subtitle.add_theme_font_size_override("font_size", 23)
    menu_layer.add_child(subtitle)
    var start_button := Button.new()
    start_button.text = "⚔  БЫСТРЫЙ БОЙ"
    start_button.position = Vector2(55, 335)
    start_button.size = Vector2(350, 75)
    start_button.add_theme_font_size_override("font_size", 29)
    start_button.pressed.connect(show_selection)
    menu_layer.add_child(start_button)
    var reset_button := Button.new()
    reset_button.text = "НОВЫЙ БОЙ"
    reset_button.position = Vector2(55, 430)
    reset_button.size = Vector2(350, 75)
    reset_button.pressed.connect(func() -> void:
        show_selection()
    )
    menu_layer.add_child(reset_button)
    var version_label := Label.new()
    version_label.text = "ANDROID PROTOTYPE  •  v0.4"
    version_label.position = Vector2(65, 650)
    version_label.add_theme_font_size_override("font_size", 18)
    menu_layer.add_child(version_label)
    selection_layer = Control.new()
    selection_layer.visible = false
    add_child(selection_layer)
    var selection_shade := ColorRect.new()
    selection_shade.color = Color("#0e1027")
    selection_shade.size = Vector2(1280, 720)
    selection_layer.add_child(selection_shade)
    selection_title = Label.new()
    selection_title.text = "ВЫБОР ПЕРСОНАЖА"
    selection_title.position = Vector2(275, 55)
    selection_title.size = Vector2(730, 80)
    selection_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    selection_title.add_theme_font_size_override("font_size", 45)
    selection_layer.add_child(selection_title)
    for i in range(fighter_names.size()):
        var fighter_button := Button.new()
        fighter_button.text = fighter_names[i]
        fighter_button.position = Vector2(75 + i * 295, 220)
        fighter_button.size = Vector2(255, 270)
        fighter_button.add_theme_font_size_override("font_size", 29)
        fighter_button.add_theme_color_override("font_color", fighter_hair[i])
        fighter_button.pressed.connect(select_fighter.bind(i))
        selection_layer.add_child(fighter_button)
        selection_buttons.append(fighter_button)
    var selection_hint := Label.new()
    selection_hint.text = "ВЫБЕРИ ГЕРОИНЮ — ПРОТИВНИК БУДЕТ ВЫБРАН АВТОМАТИЧЕСКИ"
    selection_hint.position = Vector2(155, 560)
    selection_hint.add_theme_font_size_override("font_size", 22)
    selection_layer.add_child(selection_hint)
    var back_button := Button.new()
    back_button.text = "НАЗАД"
    back_button.position = Vector2(50, 620)
    back_button.size = Vector2(180, 65)
    back_button.pressed.connect(func() -> void:
        selection_layer.visible = false
        show_menu()
    )
    selection_layer.add_child(back_button)
    show_menu()

func show_selection() -> void:
    play_sound("menu")
    in_menu = true
    menu_layer.visible = false
    selection_layer.visible = true

func select_fighter(index: int) -> void:
    selected_fighter = index
    enemy_fighter = (index + randi_range(1, 3)) % fighter_names.size()
    player_name_label.text = fighter_names[selected_fighter]
    enemy_name_label.text = fighter_names[enemy_fighter]
    selection_layer.visible = false
    restart_round()
    start_game()

func make_sound(duration: float, start_hz: float, end_hz: float, volume: float, noise_mix: int) -> AudioStreamWAV:
    var sample_rate := 22050
    var sample_count := int(duration * float(sample_rate))
    var bytes := PackedByteArray()
    bytes.resize(sample_count * 2)
    var phase := 0.0
    for i in range(sample_count):
        var t: float = float(i) / float(sample_count)
        var hz: float = lerpf(start_hz, end_hz, t)
        phase += TAU * hz / float(sample_rate)
        var envelope: float = pow(1.0 - t, 2.0) * minf(1.0, t * 80.0)
        var wave: float = sin(phase) * (1.0 - float(noise_mix) * 0.5)
        if noise_mix == 1:
            wave += randf_range(-0.6, 0.6)
        var sample: int = clampi(int(wave * envelope * volume * 32767.0), -32768, 32767)
        bytes.encode_s16(i * 2, sample)
    var sound := AudioStreamWAV.new()
    sound.format = AudioStreamWAV.FORMAT_16_BITS
    sound.mix_rate = sample_rate
    sound.stereo = false
    sound.data = bytes
    return sound

func play_sound(sound_name: String) -> void:
    if not sound_library.has(sound_name):
        return
    var player: AudioStreamPlayer = audio_players[sound_slot]
    sound_slot = (sound_slot + 1) % audio_players.size()
    player.stop()
    player.stream = sound_library[sound_name]
    player.play()

func show_menu() -> void:
    play_sound("menu")
    in_menu = true
    menu_layer.visible = true
    selection_layer.visible = false
    for key in controls.keys():
        controls[key].visible = false
    pause_button.visible = false
    cooldown_label.visible = false
    restart_button.visible = false

func start_game() -> void:
    play_sound("menu")
    in_menu = false
    menu_layer.visible = false
    for key in controls.keys():
        controls[key].visible = true
    pause_button.visible = true
    cooldown_label.visible = true
    restart_button.visible = round_over
    player_name_label.text = fighter_names[selected_fighter]
    enemy_name_label.text = fighter_names[enemy_fighter]

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
    play_sound("victory" if player_won else "defeat")
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
    if round_over or in_menu:
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
        play_sound("jump")
    velocity_y += 1700 * delta
    y_left = minf(610, y_left + velocity_y * delta)
    if y_left >= 610:
        velocity_y = 0
    if hit_pressed and attack_cooldown <= 0:
        attack_cooldown = 0.55
        player_attack_fx = 0.18
        play_sound("swing")
        if absf(x_left - x_right) < 145.0 and absf(y_left - 610.0) < 115.0:
            hp_right = maxi(0, hp_right - 10)
            enemy_hit_fx = 0.22
            play_sound("hit")
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
            play_sound("swing")
            player_hit_fx = 0.22
            play_sound("hit")
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
    draw_fighter(Vector2(x_left, y_left), Color("#ffffff") if player_hit_fx > 0.0 else fighter_colors[selected_fighter], player_attack_fx > 0.0, x_right >= x_left, player_motion, true)
    draw_fighter(Vector2(x_right, 610), Color("#ffffff") if enemy_hit_fx > 0.0 else fighter_colors[enemy_fighter], enemy_attack_fx > 0.0, x_left >= x_right, enemy_motion, false)
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
    var fighter_id: int = selected_fighter if is_player else enemy_fighter
    var hair: Color = fighter_hair[fighter_id]
    var trim: Color = Color("#a2efff") if fighter_id == 0 else Color("#f3c574") if fighter_id == 2 else Color("#ffd4df")
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
    if fighter_id == 0:
        draw_line(body + Vector2(-19, -182), body + Vector2(-29, -215), Color("#b83b37"), 11.0)
        draw_line(body + Vector2(19, -182), body + Vector2(29, -215), Color("#b83b37"), 11.0)
        draw_line(body + Vector2(15, -181), body + Vector2(37, -100), Color("#68d5db"), 12.0)
    elif fighter_id == 2:
        draw_colored_polygon(PackedVector2Array([body + Vector2(-24,-165), body + Vector2(-48,-172), body + Vector2(-25,-151)]), Color("#efc3a4"))
        draw_colored_polygon(PackedVector2Array([body + Vector2(24,-165), body + Vector2(48,-172), body + Vector2(25,-151)]), Color("#efc3a4"))
    elif fighter_id == 1:
        draw_line(body + Vector2(18,-180), body + Vector2(28,-102), hair, 15.0)
    elif fighter_id == 3:
        draw_line(body + Vector2(-20,-180), body + Vector2(-35,-100), hair, 16.0)
        draw_line(body + Vector2(20,-180), body + Vector2(35,-100), hair, 16.0)
    draw_circle(body + Vector2(-13 * facing, -160), 4.0, hair)
    draw_circle(body + Vector2(9 * facing, -158), 3.0, Color("#29243d"))
    draw_line(body + Vector2(4 * facing, -146), body + Vector2(12 * facing, -146), Color("#a45e69"), 2.0)
    draw_line(body + Vector2(-17, -128), body + Vector2(17, -128), trim, 5.0)
