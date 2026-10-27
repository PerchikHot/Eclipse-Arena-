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
var fighter_textures: Array[Texture2D] = []
var costume_names := ["КАНОН", "БОЕВОЙ", "ПЛЯЖНЫЙ"]
var selected_costume := 0
var costume_button: Button
var selection_preview: TextureRect
var selection_name: Label
var selection_choice := 0
var impact_flash := 0.0
var joystick_center := Vector2(112, 643)
var joystick_axis := 0.0
var joystick_touch := -1
var combo_hits := 0
var combo_timer := 0.0
var block_timer := 0.0
var skill_energy := 0.0
var skill_cost := 40.0
var enemy_energy := 0.0
var enemy_skill_fx := 0.0
var skill_label: Label
var round_seconds := 99.0
var round_timer_label: Label
var round_number_label: Label

func _ready() -> void:
    for character in ["yamato", "erza", "alpha", "rias"]:
        fighter_textures.append(load("res://assets/fighters/%s.svg" % character))
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
    for label in ["JUMP", "HIT", "BLOCK", "SKILL"]:
        var button := Button.new()
        button.text = {"JUMP": "ПРЫЖОК", "HIT": "УДАР", "BLOCK": "БЛОК", "SKILL": "СПЕЦ"}[label]
        var positions := {"JUMP": Vector2(1110, 550), "HIT": Vector2(1000, 610), "BLOCK": Vector2(910, 535), "SKILL": Vector2(1160, 625)}
        button.position = positions[label]
        button.size = Vector2(92, 92)
        button.add_theme_font_size_override("font_size", 16)
        var normal := StyleBoxFlat.new()
        normal.bg_color = Color("#41375e")
        normal.border_color = Color("#c8a5f7")
        normal.set_border_width_all(2)
        normal.set_corner_radius_all(46)
        button.add_theme_stylebox_override("normal", normal)
        var pressed := normal.duplicate()
        pressed.bg_color = Color("#7650ac")
        button.add_theme_stylebox_override("pressed", pressed)
        button.add_theme_stylebox_override("hover", pressed)
        add_child(button)
        controls[label] = button
        held[label] = false
        button.button_down.connect(func(): held[label] = true)
        button.button_up.connect(func(): held[label] = false)
    player_name_label = Label.new()
    player_name_label.position = Vector2(55, 10)
    player_name_label.add_theme_font_size_override("font_size", 20)
    add_child(player_name_label)
    enemy_name_label = Label.new()
    enemy_name_label.position = Vector2(850, 10)
    enemy_name_label.add_theme_font_size_override("font_size", 20)
    add_child(enemy_name_label)
    round_timer_label = Label.new()
    round_timer_label.position = Vector2(590, 42)
    round_timer_label.size = Vector2(100, 48)
    round_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    round_timer_label.add_theme_font_size_override("font_size", 40)
    add_child(round_timer_label)
    round_number_label = Label.new()
    round_number_label.position = Vector2(540, 5)
    round_number_label.size = Vector2(200, 30)
    round_number_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    round_number_label.add_theme_font_size_override("font_size", 22)
    add_child(round_number_label)
    score_label = Label.new()
    score_label.position = Vector2(545, 97)
    score_label.add_theme_font_size_override("font_size", 16)
    score_label.text = "ИГРОК 0 : 0 ПРОТИВНИК"
    add_child(score_label)
    result_label = Label.new()
    result_label.position = Vector2(500, 280)
    result_label.add_theme_font_size_override("font_size", 42)
    result_label.visible = false
    add_child(result_label)
    restart_button = Button.new()
    restart_button.text = "ЗАНОВО"
    restart_button.position = Vector2(740, 625)
    restart_button.size = Vector2(145, 65)
    restart_button.visible = false
    restart_button.pressed.connect(restart_round)
    add_child(restart_button)
    skill_label = Label.new()
    skill_label.position = Vector2(650, 615)
    skill_label.size = Vector2(240, 30)
    skill_label.add_theme_font_size_override("font_size", 20)
    add_child(skill_label)
    cooldown_label = Label.new()
    cooldown_label.position = Vector2(640, 650)
    cooldown_label.add_theme_font_size_override("font_size", 17)
    add_child(cooldown_label)
    pause_button = Button.new()
    pause_button.text = "МЕНЮ"
    pause_button.position = Vector2(1100, 132)
    pause_button.size = Vector2(155, 52)
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
    version_label.text = "ECLIPSE ARENA  •  v0.6.1"
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
        fighter_button.icon = fighter_textures[i]
        fighter_button.expand_icon = true
        fighter_button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
        fighter_button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
        fighter_button.position = Vector2(75 + i * 295, 220)
        fighter_button.size = Vector2(255, 270)
        fighter_button.add_theme_font_size_override("font_size", 29)
        fighter_button.add_theme_color_override("font_color", fighter_hair[i])
        fighter_button.pressed.connect(preview_fighter.bind(i))
        selection_layer.add_child(fighter_button)
        selection_buttons.append(fighter_button)
    selection_preview = TextureRect.new()
    selection_preview.position = Vector2(520, 485)
    selection_preview.size = Vector2(75, 118)
    selection_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    selection_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    selection_layer.add_child(selection_preview)
    selection_name = Label.new()
    selection_name.position = Vector2(600, 492)
    selection_name.size = Vector2(240, 38)
    selection_name.add_theme_font_size_override("font_size", 24)
    selection_layer.add_child(selection_name)
    costume_button = Button.new()
    costume_button.position = Vector2(600, 530)
    costume_button.size = Vector2(245, 56)
    costume_button.pressed.connect(cycle_costume)
    selection_layer.add_child(costume_button)
    var confirm_button := Button.new()
    confirm_button.text = "В БОЙ"
    confirm_button.position = Vector2(930, 620)
    confirm_button.size = Vector2(260, 70)
    confirm_button.add_theme_font_size_override("font_size", 25)
    confirm_button.pressed.connect(func() -> void: select_fighter(selection_choice))
    selection_layer.add_child(confirm_button)
    var selection_hint := Label.new()
    selection_hint.text = "ВЫБЕРИ ГЕРОИНЮ — ПРОТИВНИК БУДЕТ ВЫБРАН АВТОМАТИЧЕСКИ"
    selection_hint.position = Vector2(95, 150)
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
    preview_fighter(selection_choice)

func preview_fighter(index: int) -> void:
    selection_choice = index
    selection_preview.texture = fighter_textures[index]
    selection_name.text = fighter_names[index]
    costume_button.text = "КОСТЮМ: " + costume_names[selected_costume]
    for i in range(selection_buttons.size()):
        selection_buttons[i].modulate = Color("#ffffff") if i == index else Color("#85849a")

func cycle_costume() -> void:
    selected_costume = (selected_costume + 1) % costume_names.size()
    costume_button.text = "КОСТЮМ: " + costume_names[selected_costume]
    selection_preview.modulate = Color.WHITE if selected_costume == 0 else Color("#c9d7ff") if selected_costume == 1 else Color("#ffc4d9")
    play_sound("menu")

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
    # Release touch and button states when leaving combat so returning to
    # the arena cannot trigger a stuck attack, block, or movement.
    joystick_touch = -1
    joystick_axis = 0.0
    for key in held.keys():
        held[key] = false
    menu_layer.visible = true
    selection_layer.visible = false
    for key in controls.keys():
        controls[key].visible = false
    pause_button.visible = false
    cooldown_label.visible = false
    skill_label.visible = false
    round_timer_label.visible = false
    round_number_label.visible = false
    score_label.visible = false
    player_name_label.visible = false
    enemy_name_label.visible = false
    restart_button.visible = false

func start_game() -> void:
    play_sound("menu")
    in_menu = false
    menu_layer.visible = false
    for key in controls.keys():
        controls[key].visible = true
    pause_button.visible = true
    cooldown_label.visible = true
    skill_label.visible = true
    round_timer_label.visible = true
    round_number_label.visible = true
    score_label.visible = true
    player_name_label.visible = true
    enemy_name_label.visible = true
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
    combo_hits = 0
    combo_timer = 0.0
    block_timer = 0.0
    skill_energy = 0.0
    enemy_energy = 0.0
    enemy_skill_fx = 0.0
    round_seconds = 99.0
    round_timer_label.text = "99"
    round_number_label.text = "РАУНД %d" % (player_wins + enemy_wins + 1)
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
        result_label.text = "ПОБЕДА!"
    else:
        enemy_wins += 1
        result_label.text = "ПОРАЖЕНИЕ!"
    score_label.text = "ИГРОК %d : %d ПРОТИВНИК" % [player_wins, enemy_wins]
    result_label.visible = true
    restart_button.visible = true

func make_rig() -> Dictionary:
    var anchors := {}
    for name in ["head", "torso", "pelvis", "chest_left", "chest_right", "glute_left", "glute_right", "arm_left", "arm_right", "leg_left", "leg_right", "hair", "pelvic_attachment", "pelvic_secondary_left", "pelvic_secondary_right"]:
        anchors[name] = Vector2.ZERO
    return anchors

func _input(event: InputEvent) -> void:
    if in_menu:
        return
    if event is InputEventScreenTouch:
        if event.pressed and event.position.distance_to(joystick_center) < 105.0 and joystick_touch == -1:
            joystick_touch = event.index
            joystick_axis = clampf((event.position.x - joystick_center.x) / 58.0, -1.0, 1.0)
        elif not event.pressed and event.index == joystick_touch:
            joystick_touch = -1
            joystick_axis = 0.0
    elif event is InputEventScreenDrag and event.index == joystick_touch:
        joystick_axis = clampf((event.position.x - joystick_center.x) / 58.0, -1.0, 1.0)

func _process(delta: float) -> void:
    if round_over or in_menu:
        return
    animation_clock += delta
    round_seconds = maxf(0.0, round_seconds - delta)
    round_timer_label.text = str(ceili(round_seconds))
    if round_seconds <= 0.0:
        finish_round(hp_left >= hp_right)
        return
    impact_flash = maxf(0.0, impact_flash - delta)
    combo_timer = maxf(0.0, combo_timer - delta)
    block_timer = maxf(0.0, block_timer - delta)
    if combo_timer <= 0.0:
        combo_hits = 0
    player_motion = 0.0
    enemy_motion = 0.0
    player_attack_fx = maxf(0.0, player_attack_fx - delta)
    enemy_attack_fx = maxf(0.0, enemy_attack_fx - delta)
    enemy_skill_fx = maxf(0.0, enemy_skill_fx - delta)
    player_hit_fx = maxf(0.0, player_hit_fx - delta)
    enemy_hit_fx = maxf(0.0, enemy_hit_fx - delta)
    ai_timer -= delta
    attack_cooldown = maxf(0, attack_cooldown - delta)
    enemy_cooldown = maxf(0, enemy_cooldown - delta)
    var left_pressed: bool = Input.is_key_pressed(KEY_A) or joystick_axis < -0.2
    var right_pressed: bool = Input.is_key_pressed(KEY_D) or joystick_axis > 0.2
    var jump_pressed: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or held["JUMP"]
    var hit_pressed: bool = Input.is_key_pressed(KEY_J) or held["HIT"]
    player_motion = joystick_axis if absf(joystick_axis) > 0.2 else float(right_pressed) - float(left_pressed)
    if held["BLOCK"] or Input.is_key_pressed(KEY_K):
        block_timer = 0.15
        player_motion *= 0.35
    x_left += player_motion * 330 * delta
    x_left = clampf(x_left, 50, 1230)
    if jump_pressed and y_left >= 610:
        velocity_y = -740
        play_sound("jump")
    velocity_y += 1700 * delta
    y_left = minf(610, y_left + velocity_y * delta)
    if y_left >= 610:
        velocity_y = 0
    var skill_pressed: bool = held["SKILL"] or Input.is_key_pressed(KEY_L)
    var can_skill: bool = skill_pressed and skill_energy >= skill_cost
    if (hit_pressed or can_skill) and attack_cooldown <= 0 and block_timer <= 0.0:
        if can_skill:
            skill_energy -= skill_cost
        attack_cooldown = 0.8 if can_skill else 0.43
        player_attack_fx = 0.18
        play_sound("swing")
        if absf(x_left - x_right) < (195.0 if can_skill else 155.0) and absf(y_left - 610.0) < 115.0:
            combo_hits += 1
            skill_energy = minf(100.0, skill_energy + (0.0 if can_skill else 11.0))
            combo_timer = 1.3
            hp_right = maxi(0, hp_right - (18 if can_skill else 8 + mini(combo_hits, 4)))
            enemy_hit_fx = 0.22
            enemy_energy = minf(100.0, enemy_energy + 5.0)
            impact_flash = 0.15
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
            var enemy_special: bool = enemy_energy >= skill_cost and randf() < 0.55
            if enemy_special:
                enemy_energy -= skill_cost
                enemy_skill_fx = 0.35
            enemy_cooldown = 1.3 if enemy_special else 0.95
            enemy_attack_fx = 0.3 if enemy_special else 0.18
            play_sound("swing")
            player_hit_fx = 0.22
            impact_flash = 0.15
            play_sound("hit")
            hp_left = maxi(0, hp_left - ((4 if enemy_special else 2) if block_timer > 0.0 else (15 if enemy_special else 7)))
            enemy_energy = minf(100.0, enemy_energy + (0.0 if enemy_special else 9.0))
            skill_energy = minf(100.0, skill_energy + 4.0)
            if hp_left == 0:
                finish_round(false)
    skill_label.text = "ЭНЕРГИЯ %d/100" % int(skill_energy)
    cooldown_label.text = ("КОМБО %d  " % combo_hits if combo_hits > 1 else "") + ("ГОТОВО" if attack_cooldown <= 0.0 else "УДАР %.1fс" % attack_cooldown)
    queue_redraw()

func _draw() -> void:
    draw_rect(Rect2(0, 0, 1280, 720), Color("#10152e"))
    for i in range(8):
        var px := float(i * 195 - 80)
        draw_colored_polygon(PackedVector2Array([Vector2(px, 610), Vector2(px + 110, 280 + (i % 3) * 42), Vector2(px + 210, 610)]), Color("#1c1a3b"))
    draw_circle(Vector2(640, 180), 110, Color("#42396e"))
    draw_rect(Rect2(0, 610, 1280, 110), Color("#2a2544"))
    draw_line(Vector2(0, 610), Vector2(1280, 610), Color("#8e84be"), 4)
    if not in_menu:
        draw_circle(joystick_center, 72.0, Color("#3b3558", 0.78))
        draw_arc(joystick_center, 72.0, 0.0, TAU, 48, Color("#aa9bcf"), 3.0)
        draw_circle(joystick_center + Vector2(joystick_axis * 43.0, 0), 32.0, Color("#9788c2", 0.9))
    draw_sprite_fighter(Vector2(x_left, y_left), selected_fighter, x_right >= x_left, player_motion, player_attack_fx, player_hit_fx, hp_left)
    draw_sprite_fighter(Vector2(x_right, 610), enemy_fighter, x_left >= x_right, enemy_motion, enemy_attack_fx, enemy_hit_fx, hp_right)
    if enemy_skill_fx > 0.0:
        draw_arc(Vector2(x_right, 480), 115.0 + 25.0 * enemy_skill_fx, 0.0, TAU, 56, Color("#ff9f75", enemy_skill_fx * 2.0), 8.0)
    if enemy_hit_fx > 0.0:
        draw_circle(Vector2(x_right, 470), 12.0 + enemy_hit_fx * 55.0, Color("#ffd56c", enemy_hit_fx * 3.0))
    if player_hit_fx > 0.0:
        draw_circle(Vector2(x_left, y_left - 140.0), 12.0 + player_hit_fx * 55.0, Color("#ffd56c", player_hit_fx * 3.0))
    if impact_flash > 0.0:
        draw_rect(Rect2(0, 0, 1280, 610), Color(1.0, 0.9, 0.96, impact_flash))
    # Верхняя панель: здоровье, энергия, таймер и текущий раунд.
    draw_rect(Rect2(0, 0, 1280, 125), Color("#0c0c20", 0.89))
    draw_rect(Rect2(35, 39, 460, 30), Color("#353248"))
    draw_rect(Rect2(785, 39, 460, 30), Color("#353248"))
    draw_rect(Rect2(40, 44, float(hp_left) * 4.5, 20), Color("#64e5ae"))
    draw_rect(Rect2(1240 - float(hp_right) * 4.5, 44, float(hp_right) * 4.5, 20), Color("#f27d98"))
    draw_rect(Rect2(35, 78, 460, 14), Color("#29253f"))
    draw_rect(Rect2(785, 78, 460, 14), Color("#29253f"))
    draw_rect(Rect2(40, 81, skill_energy * 4.5, 8), Color("#b49aff"))
    draw_rect(Rect2(1240 - enemy_energy * 4.5, 81, enemy_energy * 4.5, 8), Color("#ffb184"))
    draw_line(Vector2(35, 100), Vector2(495, 100), Color("#8173b0"), 2)
    draw_line(Vector2(785, 100), Vector2(1245, 100), Color("#8173b0"), 2)
    draw_rect(Rect2(525, 5, 230, 115), Color("#211b39", 0.92))
    draw_arc(Vector2(640, 62), 49, 0.0, TAU, 48, Color("#b49aff"), 3)

func draw_sprite_fighter(origin: Vector2, fighter_id: int, face_right: bool, motion: float, attack_fx: float, hit_fx: float, health: int) -> void:
    if fighter_id >= fighter_textures.size() or fighter_textures[fighter_id] == null:
        return
    var bob := sin(animation_clock * 12.0) * 3.0 if absf(motion) > 0.1 else sin(animation_clock * 2.0) * 1.7
    var direction := 1.0 if face_right else -1.0
    var body_height := 235.0
    var body_width := 145.0
    var lean := attack_fx * 95.0 * direction - hit_fx * 80.0 * direction
    var squash := 1.0 + 0.035 * sin(animation_clock * 9.0) if absf(motion) > 0.1 else 1.0
    body_height *= squash
    var destination := Rect2(origin.x - body_width * 0.5 + lean, origin.y - body_height - bob, body_width, body_height)
    var costume_tint := Color.WHITE
    if fighter_id == selected_fighter and origin.x == x_left:
        if selected_costume == 1:
            costume_tint = Color("#d5ddff")
        elif selected_costume == 2:
            costume_tint = Color("#ffcedb")
    draw_texture_rect(fighter_textures[fighter_id], destination, false, Color("#ffd6d6") if hit_fx > 0.0 else costume_tint)
    if attack_fx > 0.0:
        var glow := Color("#9eeaff") if fighter_id == 0 else Color("#ff9da7") if fighter_id == 1 else Color("#f9d799") if fighter_id == 2 else Color("#caa1ff")
        var hand := origin + Vector2(42.0 * direction, -135.0)
        var tip := hand + Vector2(110.0 * direction, -42.0)
        draw_line(hand, tip, glow, 9.0)
        draw_line(hand, tip, Color.WHITE, 2.0)
        draw_arc(tip, 35.0, 0.0, TAU, 24, Color(glow, 0.45), 5.0)
        draw_arc(hand, 70.0, -1.0, 1.0, 28, Color(glow, attack_fx * 3.0), 5.0)
    if health < 60:
        draw_line(origin + Vector2(-12, -91), origin + Vector2(9, -72), Color("#7e334b"), 3.0)
    if health < 30:
        draw_line(origin + Vector2(18, -129), origin + Vector2(33, -109), Color("#a9545d"), 4.0)

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
    if attacking:
        var weapon_color := Color("#bdeeff") if fighter_id == 0 else Color("#ffb1bb") if fighter_id == 1 else Color("#f4d6a0") if fighter_id == 2 else Color("#d4a3ff")
        draw_line(body + Vector2(84 * facing, -105), body + Vector2(140 * facing, -154), weapon_color, 9.0)
        draw_line(body + Vector2(135 * facing, -150), body + Vector2(151 * facing, -165), Color.WHITE, 4.0)
    draw_circle(body + Vector2(0, -159), 26.0, Color("#f2d0b3"))
    var remaining_hp: int = hp_left if is_player else hp_right
    if remaining_hp < 60:
        draw_line(body + Vector2(-15,-113), body + Vector2(5,-97), Color("#5d2d49"), 3.0)
    if remaining_hp < 30:
        draw_line(body + Vector2(8,-87), body + Vector2(24,-77), Color("#b35c65"), 3.0)
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
