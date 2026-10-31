extends Node2D

const CombatRules = preload("res://scripts/combat_rules.gd")

var hp_left := 100
var hp_right := 100
var x_left := 300.0
var x_right := 900.0
var y_left := 610.0
var velocity_y := 0.0
var attack_cooldown := 0.0
var enemy_cooldown := 0.0
var enemy_windup := 0.0
var enemy_pending_special := false
var left_rig := {}
var right_rig := {}
var controls := {}
var held := {}
var round_over := false
var player_wins := 0
var enemy_wins := 0
var draws := 0
var score_label: Label
var result_label: Label
var restart_button: Button
var change_fighter_button: Button
var player_attack_fx := 0.0
var enemy_attack_fx := 0.0
var player_hit_fx := 0.0
var enemy_hit_fx := 0.0
var ai_timer := 0.0
var ai_retreat := false
var ai_difficulty := 1  # 0: novice, 1: normal, 2: master
var animation_clock := 0.0
var player_motion := 0.0
var enemy_motion := 0.0
var cooldown_label: Label
var accuracy_label: Label
var in_menu := true
var menu_layer: Control
var pause_button: Button
var pause_toggle_button: Button
var pause_overlay: Label
var controls_help_label: Label
var controls_help_button: Button
var manual_paused := false
var audio_players: Array[AudioStreamPlayer] = []
var sound_muted := false
var sound_button: Button
var sound_library: Dictionary = {}
var sound_slot := 0
var fighter_names := ["ЯМАТО", "ЭРЗА", "АЛЬФА", "РИАС"]
var fighter_colors := [Color("#f0eceb"), Color("#b73545"), Color("#1c263f"), Color("#421c49")]
var fighter_hair := [Color("#e5f8ff"), Color("#a92736"), Color("#edcf86"), Color("#b7283f")]
var selected_fighter := 0
var enemy_fighter := 1
# -1 = random rival; otherwise the selected fighter index (mirror matches allowed).
var selected_opponent := -1
var opponent_button: Button
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
var best_combo := 0
var personal_best_combo := 0
var personal_record_label: Label
var damage_dealt := 0
var damage_taken := 0
var hits_landed := 0
var attacks_attempted := 0
var hits_received := 0
var blocked_hits := 0
var guard_breaks := 0
var guard_break_flash := 0.0
# A short, edge-triggered parry rewards timing instead of holding block.
var parry_window := 0.0
var parry_cooldown := 0.0
var guard_was_pressed := false
var successful_parries := 0
var combo_timer := 0.0
var block_timer := 0.0
# Guard cannot be held indefinitely: it must recover after exhaustion.
var guard_stamina := 100.0
var guard_exhausted := false
# A timed evasive dash uses guard stamina; it cannot be spammed while held.
var dash_cooldown := 0.0
var dash_invulnerable := 0.0
var dash_queued := false
var dash_button: Button
var skill_energy := 0.0
var skill_cost := 40.0
var enemy_energy := 0.0
var enemy_skill_fx := 0.0
var skill_label: Label
var enemy_energy_label: Label
var round_duration := 99.0
var round_seconds := 99.0
var duration_button: Button
var difficulty_button: Button
var match_button: Button
var match_target_wins := 2 # 0 = endless rounds
var match_finished := false
var training_mode := false
var training_knockouts := 0
var training_elapsed := 0.0
var training_hud_last := 0.0
# Optional moving target for practicing spacing; it never attacks.
var training_target_moves := false
var training_target_speed := 1 # 1 = slow, 2 = fast
var training_target_direction := 1.0
var training_target_button: Button
var training_reset_button: Button
var training_guard_button: Button
var training_attack_button: Button
var training_attack_label: Label
var training_attack_enabled := false
var training_attack_pace := 1 # 0 slow, 1 normal, 2 fast
var training_pace_button: Button
var training_attack_timer := 2.0
var training_attack_windup := 0.0
var training_range_label: Label
var training_target_guarding := false
var training_guarded_hits := 0
var training_attack_attempts := 0
var training_dodges := 0
# Timed defensive drill is separate from ranked matches and their records.
var training_challenge_button: Button
var training_challenge_running := false
var training_challenge_remaining := 60.0
var training_challenge_best := 0
var training_challenge_result := ""
var timer_warning_active := false
var final_countdown_active := false
var has_game_focus := true
var round_timer_label: Label
var round_number_label: Label
var fps_label: Label
var fps_elapsed := 0.0
var fps_enabled := false

func _ready() -> void:
    # Sound preference is device-local until secure cross-device sync exists.
    var saved_settings := ConfigFile.new()
    if saved_settings.load("user://settings.cfg") == OK:
        sound_muted = saved_settings.get_value("audio", "muted", false) == true
        # Restore the desktop display choice; Android keeps its own layout.
        if not OS.has_feature("mobile"):
            if saved_settings.get_value("display", "fullscreen", false) == true:
                DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
            fps_enabled = saved_settings.get_value("display", "show_fps", false) == true
        # Restore selection only when the stored values are valid integers.
        # Corrupted or older settings must not index outside the fighter list.
        var stored_fighter = saved_settings.get_value("selection", "fighter", 0)
        var stored_costume = saved_settings.get_value("selection", "costume", 0)
        if typeof(stored_fighter) == TYPE_INT:
            selection_choice = clampi(stored_fighter, 0, fighter_names.size() - 1)
        if typeof(stored_costume) == TYPE_INT:
            selected_costume = clampi(stored_costume, 0, costume_names.size() - 1)
        var stored_opponent = saved_settings.get_value("selection", "opponent", -1)
        if typeof(stored_opponent) == TYPE_INT and stored_opponent >= -1 and stored_opponent < fighter_names.size():
            selected_opponent = stored_opponent
        # Older saves default to the original 99-second round; new presets are optional.
        var saved_duration = saved_settings.get_value("match", "duration", 99)
        if typeof(saved_duration) == TYPE_INT and saved_duration in [30, 60, 99, 120, 180]:
            round_duration = float(saved_duration)
        # The AI level is local to this device and does not alter save data.
        var saved_challenge = saved_settings.get_value("training", "best_defense_60s", 0)
        if typeof(saved_challenge) == TYPE_INT and saved_challenge >= 0 and saved_challenge <= 99999:
            training_challenge_best = saved_challenge
        var stored_training_pace = saved_settings.get_value("training", "attack_pace", 1)
        if typeof(stored_training_pace) == TYPE_INT and stored_training_pace in [0, 1, 2]:
            training_attack_pace = stored_training_pace
        var stored_difficulty = saved_settings.get_value("match", "ai_difficulty", 1)
        if typeof(stored_difficulty) == TYPE_INT and stored_difficulty in [0, 1, 2]:
            ai_difficulty = stored_difficulty
        var stored_match_target = saved_settings.get_value("match", "target_wins", 2)
        if typeof(stored_match_target) == TYPE_INT and stored_match_target in [0, 2]:
            match_target_wins = stored_match_target
        # Personal records are local until secure account sync is implemented.
        var stored_best = saved_settings.get_value("records", "best_combo", 0)
        if typeof(stored_best) == TYPE_INT and stored_best >= 0 and stored_best <= 9999:
            personal_best_combo = stored_best
    for character in ["yamato", "erza", "alpha", "rias"]:
        fighter_textures.append(load("res://assets/fighters/%s.svg" % character))
    sound_library["swing"] = make_sound(0.13, 220.0, 90.0, 0.14, 0)
    sound_library["hit"] = make_sound(0.19, 130.0, 45.0, 0.29, 1)
    sound_library["jump"] = make_sound(0.17, 280.0, 570.0, 0.13, 0)
    sound_library["victory"] = make_sound(0.55, 420.0, 840.0, 0.15, 0)
    sound_library["defeat"] = make_sound(0.48, 320.0, 90.0, 0.15, 0)
    sound_library["menu"] = make_sound(0.11, 470.0, 720.0, 0.11, 0)
    # One brief warning at ten seconds; respects the saved mute setting.
    sound_library["countdown"] = make_sound(0.12, 750.0, 520.0, 0.12, 0)
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
    dash_button = Button.new()
    dash_button.text = "РЫВОК" if OS.has_feature("mobile") else "РЫВОК (SHIFT)"
    dash_button.position = Vector2(785, 540)
    dash_button.size = Vector2(115, 68)
    dash_button.pressed.connect(func() -> void:
        if not in_menu and not manual_paused and not round_over:
            dash_queued = true
    )
    add_child(dash_button)
    training_target_button = Button.new()
    training_target_button.position = Vector2(515, 137)
    training_target_button.size = Vector2(250, 48)
    training_target_button.visible = false
    training_target_button.pressed.connect(toggle_training_target)
    add_child(training_target_button)
    training_reset_button = Button.new()
    training_reset_button.text = "СБРОС ТРЕНИРОВКИ" if OS.has_feature("mobile") else "СБРОС ТРЕНИРОВКИ (R)"
    training_reset_button.position = Vector2(515, 191)
    training_reset_button.size = Vector2(250, 46)
    training_reset_button.visible = false
    training_reset_button.pressed.connect(reset_training_session)
    add_child(training_reset_button)
    training_guard_button = Button.new()
    training_guard_button.position = Vector2(515, 245)
    training_guard_button.size = Vector2(250, 46)
    training_guard_button.visible = false
    training_guard_button.pressed.connect(toggle_training_guard)
    add_child(training_guard_button)
    training_attack_button = Button.new()
    training_attack_button.position = Vector2(515, 340)
    training_attack_button.size = Vector2(250, 46)
    training_attack_button.visible = false
    training_attack_button.pressed.connect(toggle_training_attacks)
    add_child(training_attack_button)
    training_pace_button = Button.new()
    training_pace_button.position = Vector2(515, 395)
    training_pace_button.size = Vector2(250, 46)
    training_pace_button.visible = false
    training_pace_button.pressed.connect(cycle_training_attack_pace)
    add_child(training_pace_button)
    training_challenge_button = Button.new()
    training_challenge_button.position = Vector2(780, 395)
    training_challenge_button.size = Vector2(260, 46)
    training_challenge_button.visible = false
    training_challenge_button.text = "ЗАЩИТА 60 С • СТАРТ"
    training_challenge_button.pressed.connect(toggle_training_challenge)
    add_child(training_challenge_button)
    training_attack_label = Label.new()
    training_attack_label.position = Vector2(780, 345)
    training_attack_label.size = Vector2(260, 38)
    training_attack_label.add_theme_color_override("font_color", Color("#ffd17a"))
    training_attack_label.visible = false
    add_child(training_attack_label)
    # Training-only spacing guide, shared by keyboard and touch controls.
    training_range_label = Label.new()
    training_range_label.position = Vector2(515, 297)
    training_range_label.size = Vector2(450, 35)
    training_range_label.add_theme_font_size_override("font_size", 17)
    training_range_label.visible = false
    add_child(training_range_label)
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
    # Optional desktop performance diagnostic; disabled by default.
    fps_label = Label.new()
    fps_label.position = Vector2(1110, 94)
    fps_label.add_theme_font_size_override("font_size", 18)
    fps_label.add_theme_color_override("font_color", Color("#58c9ff"))
    fps_label.visible = fps_enabled and not OS.has_feature("mobile")
    add_child(fps_label)
    result_label = Label.new()
    result_label.position = Vector2(500, 280)
    # Round statistics fit on mobile without overlapping rematch buttons.
    result_label.add_theme_font_size_override("font_size", 30)
    result_label.visible = false
    add_child(result_label)
    restart_button = Button.new()
    restart_button.text = "ЗАНОВО" if OS.has_feature("mobile") else "ЗАНОВО (R)"
    restart_button.position = Vector2(740, 625)
    restart_button.size = Vector2(145, 65)
    restart_button.visible = false
    restart_button.pressed.connect(restart_round)
    add_child(restart_button)
    change_fighter_button = Button.new()
    change_fighter_button.text = "СМЕНИТЬ БОЙЦА" if OS.has_feature("mobile") else "БОЕЦ (Q)"
    change_fighter_button.position = Vector2(510, 625)
    change_fighter_button.size = Vector2(210, 65)
    change_fighter_button.visible = false
    change_fighter_button.pressed.connect(show_selection)
    add_child(change_fighter_button)
    skill_label = Label.new()
    skill_label.position = Vector2(650, 615)
    skill_label.size = Vector2(240, 30)
    skill_label.add_theme_font_size_override("font_size", 20)
    add_child(skill_label)
    # Numeric enemy energy makes the special-attack threat readable on mobile.
    enemy_energy_label = Label.new()
    enemy_energy_label.position = Vector2(925, 75)
    enemy_energy_label.size = Vector2(310, 22)
    enemy_energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    enemy_energy_label.add_theme_font_size_override("font_size", 13)
    enemy_energy_label.add_theme_color_override("font_color", Color("#fff0d7"))
    enemy_energy_label.text = "ЭНЕРГИЯ ВРАГА: 0/100"
    add_child(enemy_energy_label)
    cooldown_label = Label.new()
    cooldown_label.position = Vector2(640, 650)
    cooldown_label.add_theme_font_size_override("font_size", 17)
    add_child(cooldown_label)
    # Live accuracy feedback during the round, not only on the result screen.
    accuracy_label = Label.new()
    # Two-line adaptive combat stats avoid clipping combos on small screens.
    accuracy_label.position = Vector2(400, 663)
    accuracy_label.size = Vector2(570, 54)
    accuracy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    accuracy_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    accuracy_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    accuracy_label.add_theme_font_size_override("font_size", 15)
    accuracy_label.add_theme_color_override("font_color", Color("#80d9ff"))
    add_child(accuracy_label)
    pause_button = Button.new()
    pause_button.text = "МЕНЮ" if OS.has_feature("mobile") else "МЕНЮ (ESC)"
    pause_button.position = Vector2(1100, 132)
    pause_button.size = Vector2(155, 52)
    pause_button.pressed.connect(show_menu)
    add_child(pause_button)
    pause_toggle_button = Button.new()
    pause_toggle_button.text = "ПАУЗА" if OS.has_feature("mobile") else "ПАУЗА (P)"
    pause_toggle_button.position = Vector2(910, 132)
    pause_toggle_button.size = Vector2(180, 52)
    pause_toggle_button.pressed.connect(toggle_pause)
    add_child(pause_toggle_button)
    controls_help_button = Button.new()
    controls_help_button.text = "УПРАВЛЕНИЕ" if OS.has_feature("mobile") else "ПОМОЩЬ (F1)"
    controls_help_button.position = Vector2(735, 132)
    controls_help_button.size = Vector2(165, 52)
    controls_help_button.pressed.connect(toggle_controls_help)
    add_child(controls_help_button)
    pause_overlay = Label.new()
    pause_overlay.text = "ПАУЗА\nP — ПРОДОЛЖИТЬ" if not OS.has_feature("mobile") else "ПАУЗА\nНАЖМИ ПРОДОЛЖИТЬ"
    pause_overlay.position = Vector2(430, 250)
    pause_overlay.size = Vector2(420, 150)
    pause_overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    pause_overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    pause_overlay.add_theme_font_size_override("font_size", 34)
    pause_overlay.add_theme_color_override("font_color", Color("#b8d9ff"))
    pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    pause_overlay.visible = false
    add_child(pause_overlay)
    # Desktop-only help can be opened during a match or while paused.
    controls_help_label = Label.new()
    controls_help_label.text = "УПРАВЛЕНИЕ (кнопка — скрыть)\nБой на паузе, пока открыта помощь\nДжойстик слева — движение\nПРЫЖОК / УДАР / БЛОК / СПЕЦ — справа\nРЫВОК — уклонение (30 щита)  •  ПАУЗА — остановить бой  •  МЕНЮ — выйти\nВ тренировке: ЩИТ — защита мишени, СБРОС — заново\nПосле раунда: ЗАНОВО или СМЕНИТЬ БОЙЦА" if OS.has_feature("mobile") else "УПРАВЛЕНИЕ (F1 — скрыть)\nБой на паузе, пока открыта помощь\nA/D — движение  •  W/ПРОБЕЛ — прыжок\nJ — удар  •  K — блок  •  L — спец\nSHIFT — рывок  •  P — пауза  •  M — звук  •  F3 — FPS  •  ESC — помощь\nТренировка: T — скорость мишени  •  G — щит  •  R — сброс\nПосле раунда: R — заново  •  Q — боец"
    controls_help_label.position = Vector2(355, 185)
    controls_help_label.size = Vector2(580, 240)
    controls_help_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    controls_help_label.add_theme_font_size_override("font_size", 22)
    controls_help_label.add_theme_color_override("font_color", Color("#e7f0ff"))
    controls_help_label.add_theme_color_override("font_shadow_color", Color("#050b20"))
    controls_help_label.add_theme_constant_override("shadow_offset_x", 2)
    controls_help_label.add_theme_constant_override("shadow_offset_y", 2)
    controls_help_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
    controls_help_label.visible = false
    add_child(controls_help_label)
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
    if not OS.has_feature("mobile"):
        var keyboard_hint := Label.new()
        keyboard_hint.text = "A/D — движение  •  W/ПРОБЕЛ — прыжок\nJ — удар  •  K — блок  •  L — спец  •  P — пауза  •  F1 — помощь  •  F3 — FPS"
        keyboard_hint.position = Vector2(55, 285)
        keyboard_hint.size = Vector2(460, 44)
        keyboard_hint.add_theme_font_size_override("font_size", 14)
        menu_layer.add_child(keyboard_hint)
    var start_button := Button.new()
    start_button.text = "⚔  БЫСТРЫЙ БОЙ"
    start_button.position = Vector2(55, 335)
    start_button.size = Vector2(350, 75)
    start_button.add_theme_font_size_override("font_size", 29)
    start_button.pressed.connect(func() -> void:
        training_mode = false
        show_selection()
    )
    menu_layer.add_child(start_button)
    # Practice with a stationary, respawning dummy and no round timer.
    # It cannot improve the ranked personal combo record.
    var training_button := Button.new()
    training_button.text = "ТРЕНИРОВКА • БЕЗ ТАЙМЕРА"
    training_button.position = Vector2(470, 430)
    training_button.size = Vector2(390, 75)
    training_button.add_theme_font_size_override("font_size", 22)
    training_button.pressed.connect(func() -> void:
        training_mode = true
        show_selection()
    )
    menu_layer.add_child(training_button)
    var reset_button := Button.new()
    reset_button.text = "НОВЫЙ БОЙ"
    reset_button.position = Vector2(55, 430)
    reset_button.size = Vector2(350, 75)
    reset_button.pressed.connect(func() -> void:
        # A new match starts at 0:0; round restart keeps the existing score.
        player_wins = 0
        enemy_wins = 0
        draws = 0
        score_label.text = "ИГРОК 0 : 0 ПРОТИВНИК  •  НИЧЬИХ: 0"
        show_selection()
    )
    menu_layer.add_child(reset_button)
    sound_button = Button.new()
    sound_button.text = ("ЗВУК: ВЫКЛ" if sound_muted else "ЗВУК: ВКЛ") + ("  •  M" if not OS.has_feature("mobile") else "")
    sound_button.position = Vector2(55, 530)
    sound_button.size = Vector2(350, 60)
    sound_button.add_theme_font_size_override("font_size", 22)
    sound_button.pressed.connect(toggle_sound)
    menu_layer.add_child(sound_button)
    duration_button = Button.new()
    duration_button.text = "ТАЙМЕР РАУНДА: %d СЕК" % int(round_duration)
    duration_button.position = Vector2(55, 595)
    duration_button.size = Vector2(350, 46)
    duration_button.add_theme_font_size_override("font_size", 19)
    duration_button.pressed.connect(cycle_round_duration)
    menu_layer.add_child(duration_button)
    difficulty_button = Button.new()
    difficulty_button.text = "СЛОЖНОСТЬ ИИ: " + ["НОВИЧОК", "СТАНДАРТ", "МАСТЕР"][ai_difficulty]
    difficulty_button.position = Vector2(470, 530)
    difficulty_button.size = Vector2(390, 60)
    difficulty_button.add_theme_font_size_override("font_size", 22)
    difficulty_button.pressed.connect(cycle_ai_difficulty)
    menu_layer.add_child(difficulty_button)
    match_button = Button.new()
    match_button.text = "МАТЧ: ДО 2 ПОБЕД" if match_target_wins == 2 else "МАТЧ: БЕЗ ЛИМИТА"
    match_button.position = Vector2(870, 530)
    match_button.size = Vector2(350, 60)
    match_button.add_theme_font_size_override("font_size", 20)
    match_button.pressed.connect(cycle_match_target)
    menu_layer.add_child(match_button)
    var version_label := Label.new()
    version_label.text = "ECLIPSE ARENA  •  v%s" % str(ProjectSettings.get_setting("application/config/version", "0.6.5"))
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
    opponent_button = Button.new()
    opponent_button.position = Vector2(600, 600)
    opponent_button.size = Vector2(245, 55)
    opponent_button.pressed.connect(cycle_opponent)
    selection_layer.add_child(opponent_button)
    var confirm_button := Button.new()
    confirm_button.text = "В БОЙ"
    confirm_button.position = Vector2(930, 620)
    confirm_button.size = Vector2(260, 70)
    confirm_button.add_theme_font_size_override("font_size", 25)
    confirm_button.pressed.connect(func() -> void: select_fighter(selection_choice))
    selection_layer.add_child(confirm_button)
    # Show the saved record before a match, on Windows and Android.
    personal_record_label = Label.new()
    personal_record_label.position = Vector2(930, 550)
    personal_record_label.size = Vector2(270, 50)
    personal_record_label.add_theme_font_size_override("font_size", 18)
    personal_record_label.add_theme_color_override("font_color", Color("#80d9ff"))
    selection_layer.add_child(personal_record_label)
    var selection_hint := Label.new()
    selection_hint.text = "ВЫБЕРИ БОЙЦА И СОПЕРНИКА — СЛУЧАЙНЫЙ ИЛИ КОНКРЕТНЫЙ"
    selection_hint.position = Vector2(95, 150)
    selection_hint.add_theme_font_size_override("font_size", 22)
    selection_layer.add_child(selection_hint)
    var selection_controls := Label.new()
    selection_controls.text = "ПК: ←/→ БОЕЦ • C КОСТЮМ • O СОПЕРНИК • ENTER В БОЙ • ESC НАЗАД"
    selection_controls.position = Vector2(95, 188)
    selection_controls.add_theme_font_size_override("font_size", 17)
    selection_layer.add_child(selection_controls)
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
    personal_record_label.text = "ЛИЧНЫЙ РЕКОРД КОМБО: x%d" % personal_best_combo
    play_sound("menu")
    in_menu = true
    menu_layer.visible = false
    selection_layer.visible = true
    dash_button.visible = false
    training_target_button.visible = false
    training_reset_button.visible = false
    training_guard_button.visible = false
    training_attack_button.visible = false
    training_pace_button.visible = false
    training_attack_label.visible = false
    training_challenge_button.visible = false
    training_range_label.visible = false
    dash_queued = false
    preview_fighter(selection_choice)

func preview_fighter(index: int) -> void:
    selection_choice = index
    selection_preview.texture = fighter_textures[index]
    selection_name.text = fighter_names[index]
    costume_button.text = "КОСТЮМ: " + costume_names[selected_costume]
    opponent_button.text = "СОПЕРНИК: " + ("СЛУЧАЙНЫЙ" if selected_opponent < 0 else fighter_names[selected_opponent])
    # Reflect the restored costume immediately on the selection screen.
    selection_preview.modulate = Color.WHITE if selected_costume == 0 else Color("#c9d7ff") if selected_costume == 1 else Color("#ffc4d9")
    for i in range(selection_buttons.size()):
        selection_buttons[i].modulate = Color("#ffffff") if i == index else Color("#85849a")

func save_selection_preferences() -> void:
    # Keep audio and any future settings intact when saving fighter choices.
    var settings := ConfigFile.new()
    settings.load("user://settings.cfg")
    settings.set_value("selection", "fighter", selection_choice)
    settings.set_value("selection", "costume", selected_costume)
    settings.set_value("selection", "opponent", selected_opponent)
    settings.save("user://settings.cfg")

# Match length is a local preference; changing it affects the next round only.
func cycle_round_duration() -> void:
    var durations := [30, 60, 99, 120, 180]
    var index := durations.find(int(round_duration))
    round_duration = float(durations[(index + 1) % durations.size()])
    duration_button.text = "ТАЙМЕР РАУНДА: %d СЕК" % int(round_duration)
    var settings := ConfigFile.new()
    settings.load("user://settings.cfg")
    settings.set_value("match", "duration", int(round_duration))
    settings.save("user://settings.cfg")
    play_sound("menu")

# A full gameplay setting: opponent movement, decisions and attack recovery
# scale together. Changes apply to the next frame and persist across restarts.
func cycle_ai_difficulty() -> void:
    ai_difficulty = (ai_difficulty + 1) % 3
    difficulty_button.text = "СЛОЖНОСТЬ ИИ: " + ["НОВИЧОК", "СТАНДАРТ", "МАСТЕР"][ai_difficulty]
    var settings := ConfigFile.new()
    settings.load("user://settings.cfg")
    settings.set_value("match", "ai_difficulty", ai_difficulty)
    settings.save("user://settings.cfg")
    play_sound("menu")

func cycle_match_target() -> void:
    match_target_wins = 0 if match_target_wins == 2 else 2
    match_button.text = "МАТЧ: ДО 2 ПОБЕД" if match_target_wins == 2 else "МАТЧ: БЕЗ ЛИМИТА"
    var settings := ConfigFile.new()
    settings.load("user://settings.cfg")
    settings.set_value("match", "target_wins", match_target_wins)
    settings.save("user://settings.cfg")
    play_sound("menu")

func cycle_costume() -> void:
    selected_costume = (selected_costume + 1) % costume_names.size()
    costume_button.text = "КОСТЮМ: " + costume_names[selected_costume]
    selection_preview.modulate = Color.WHITE if selected_costume == 0 else Color("#c9d7ff") if selected_costume == 1 else Color("#ffc4d9")
    save_selection_preferences()
    play_sound("menu")

func cycle_opponent() -> void:
    selected_opponent = (selected_opponent + 2) % (fighter_names.size() + 1) - 1
    opponent_button.text = "СОПЕРНИК: " + ("СЛУЧАЙНЫЙ" if selected_opponent < 0 else fighter_names[selected_opponent])
    save_selection_preferences()
    play_sound("menu")

func select_fighter(index: int) -> void:
    selected_fighter = index
    selection_choice = index
    save_selection_preferences()
    enemy_fighter = selected_opponent if selected_opponent >= 0 else (index + randi_range(1, 3)) % fighter_names.size()
    # Choosing a fighter starts a new match. Never carry a previous
    # character's wins, losses or draws into the next match.
    player_wins = 0
    enemy_wins = 0
    draws = 0
    training_knockouts = 0
    training_guarded_hits = 0
    training_attack_attempts = 0
    training_dodges = 0
    training_challenge_running = false
    training_challenge_remaining = 60.0
    training_challenge_result = ""
    training_attack_timer = training_attack_interval()
    training_attack_windup = 0.0
    training_elapsed = 0.0
    training_hud_last = 0.0
    score_label.text = "МИШЕНЕЙ: 0 • УРОН: 0 • DPS: 0 • БЛОК: 0 • ПАРИР: 0/0 • УКЛ: 0" if training_mode else "ИГРОК 0 : 0 ПРОТИВНИК  •  НИЧЬИХ: 0"
    update_health_labels()
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

func toggle_sound() -> void:
    sound_muted = not sound_muted
    sound_button.text = ("ЗВУК: ВЫКЛ" if sound_muted else "ЗВУК: ВКЛ") + ("  •  M" if not OS.has_feature("mobile") else "")
    # Preserve unrelated settings and avoid resetting the user's preference.
    var saved_settings := ConfigFile.new()
    saved_settings.load("user://settings.cfg")
    saved_settings.set_value("audio", "muted", sound_muted)
    saved_settings.save("user://settings.cfg")
    if sound_muted:
        for player in audio_players:
            player.stop()
    else:
        play_sound("menu")

func play_sound(sound_name: String) -> void:
    if sound_muted or not sound_library.has(sound_name):
        return
    var player: AudioStreamPlayer = audio_players[sound_slot]
    sound_slot = (sound_slot + 1) % audio_players.size()
    player.stop()
    player.stream = sound_library[sound_name]
    player.play()

# Stop any lingering impact or victory sound when gameplay is interrupted.
func stop_active_sounds() -> void:
    for player in audio_players:
        player.stop()

# Display the reason for a stopped round, including desktop Alt-Tab
# and Android notification interruptions. No gameplay resumes until focused.
func sync_pause_overlay() -> void:
    if pause_overlay == null:
        return
    if in_menu or round_over:
        pause_overlay.visible = false
    elif manual_paused:
        pause_overlay.text = "ПАУЗА\nНАЖМИ ПРОДОЛЖИТЬ" if OS.has_feature("mobile") else "ПАУЗА\nP — ПРОДОЛЖИТЬ"
        pause_overlay.visible = true
    elif not has_game_focus:
        pause_overlay.text = "ПАУЗА\nВЕРНИСЬ В ИГРУ"
        pause_overlay.visible = true
    else:
        pause_overlay.visible = false

func toggle_pause() -> void:
    if in_menu or round_over:
        return
    manual_paused = not manual_paused
    sync_pause_overlay()
    pause_toggle_button.text = ("ПРОДОЛЖИТЬ" if OS.has_feature("mobile") else "ПРОДОЛЖИТЬ (P)") if manual_paused else ("ПАУЗА" if OS.has_feature("mobile") else "ПАУЗА (P)")
    if manual_paused:
        stop_active_sounds()
        dash_queued = false
        joystick_touch = -1
        joystick_axis = 0.0
        for key in held.keys():
            held[key] = false

func toggle_controls_help() -> void:
    if in_menu:
        return
    controls_help_label.visible = not controls_help_label.visible
    # Reading the controls must not cost round time or let the AI attack.
    # Release held inputs so closing help cannot resume a stuck action.
    if controls_help_label.visible:
        stop_active_sounds()
        joystick_touch = -1
        joystick_axis = 0.0
        for key in held.keys():
            held[key] = false


func show_menu() -> void:
    controls_help_label.visible = false
    play_sound("menu")
    manual_paused = false
    pause_overlay.visible = false
    pause_toggle_button.text = "ПАУЗА" if OS.has_feature("mobile") else "ПАУЗА (P)"
    in_menu = true
    sync_pause_overlay()
    # Release touch and button states when leaving combat so returning to
    # the arena cannot trigger a stuck attack, block, or movement.
    joystick_touch = -1
    joystick_axis = 0.0
    dash_queued = false
    for key in held.keys():
        held[key] = false
    menu_layer.visible = true
    selection_layer.visible = false
    for key in controls.keys():
        controls[key].visible = false
    pause_button.visible = false
    dash_button.visible = false
    training_target_button.visible = false
    training_reset_button.visible = false
    training_guard_button.visible = false
    training_attack_button.visible = false
    training_pace_button.visible = false
    training_attack_label.visible = false
    training_range_label.visible = false
    pause_toggle_button.visible = false
    controls_help_button.visible = false
    cooldown_label.visible = false
    skill_label.visible = false
    enemy_energy_label.visible = false
    round_timer_label.visible = false
    round_number_label.visible = false
    score_label.visible = false
    player_name_label.visible = false
    enemy_name_label.visible = false
    restart_button.visible = false
    change_fighter_button.visible = false
    result_label.visible = false

func training_target_caption() -> String:
    if not training_target_moves:
        return "МИШЕНЬ: СТОИТ"
    return "МИШЕНЬ: БЫСТРО" if training_target_speed == 2 else "МИШЕНЬ: МЕДЛЕННО"

func update_training_range() -> void:
    if not training_mode:
        return
    var distance := absf(x_left - x_right)
    var aligned := absf(y_left - 610.0) < 115.0
    var normal_hit := distance < 155.0 and aligned
    var special_hit := distance < 195.0 and aligned
    training_range_label.text = "ДИСТ: %d • УДАР: %s • СПЕЦ: %s" % [
        roundi(distance), "ДА" if normal_hit else "НЕТ",
        "ДА" if special_hit else "НЕТ"]
    training_range_label.add_theme_color_override("font_color",
        Color("#76e5b0") if normal_hit else
        Color("#ffd17a") if special_hit else Color("#ff8b9e"))

func toggle_training_guard() -> void:
    if not training_mode or in_menu or round_over or manual_paused:
        return
    training_target_guarding = not training_target_guarding
    training_guard_button.text = "ЩИТ МИШЕНИ: ВКЛ" if training_target_guarding else "ЩИТ МИШЕНИ: ВЫКЛ"
    play_sound("menu")

func training_attack_interval() -> float:
    return 4.0 if training_attack_pace == 0 else 1.5 if training_attack_pace == 2 else 2.5

func training_attack_telegraph() -> float:
    return 1.0 if training_attack_pace == 0 else 0.4 if training_attack_pace == 2 else 0.65

func training_pace_caption() -> String:
    return "ТЕМП МИШЕНИ: " + ["МЕДЛЕННЫЙ", "ОБЫЧНЫЙ", "БЫСТРЫЙ"][training_attack_pace]

func cycle_training_attack_pace() -> void:
    if not training_mode or in_menu or round_over or manual_paused:
        return
    if training_challenge_running:
        return
    training_attack_pace = (training_attack_pace + 1) % 3
    training_pace_button.text = training_pace_caption()
    training_attack_timer = training_attack_interval()
    training_attack_windup = 0.0
    var settings := ConfigFile.new()
    settings.load("user://settings.cfg")
    settings.set_value("training", "attack_pace", training_attack_pace)
    settings.save("user://settings.cfg")
    play_sound("menu")

func toggle_training_attacks() -> void:
    if not training_mode or in_menu or round_over or manual_paused:
        return
    if training_challenge_running:
        return # Keep the 60-second drill's attack pattern fixed.
    training_attack_enabled = not training_attack_enabled
    training_attack_timer = training_attack_interval()
    training_attack_windup = 0.0
    training_attack_button.text = "МИШЕНЬ АТАКУЕТ: ДА" if training_attack_enabled else "МИШЕНЬ АТАКУЕТ: НЕТ"
    training_attack_label.text = "Тренировка парирования" if training_attack_enabled else ""
    play_sound("menu")

func toggle_training_challenge() -> void:
    if not training_mode or in_menu or round_over or manual_paused:
        return
    if training_challenge_running:
        finish_training_challenge(false)
        return
    # Start with fresh counters; keep normal training records separate.
    reset_training_session()
    training_challenge_running = true
    training_challenge_remaining = 60.0
    training_challenge_result = ""
    training_attack_enabled = true
    training_attack_timer = training_attack_interval()
    training_attack_windup = 0.0
    training_attack_button.text = "МИШЕНЬ АТАКУЕТ: ДА"
    training_challenge_button.text = "ЗАЩИТА 60 С • ЗАВЕРШИТЬ"
    play_sound("menu")

func finish_training_challenge(completed: bool) -> void:
    if not training_challenge_running:
        return
    training_challenge_running = false
    training_attack_enabled = false
    training_attack_windup = 0.0
    training_attack_button.text = "МИШЕНЬ АТАКУЕТ: НЕТ"
    training_challenge_button.text = "ЗАЩИТА 60 С • СТАРТ"
    round_timer_label.text = "∞"
    var score := CombatRules.defense_challenge_score(successful_parries, training_dodges)
    if completed and score > training_challenge_best:
        training_challenge_best = score
        var settings := ConfigFile.new()
        settings.load("user://settings.cfg")
        settings.set_value("training", "best_defense_60s", training_challenge_best)
        settings.save("user://settings.cfg")
    training_challenge_result = ("ИТОГ" if completed else "ПРЕРВАНО") + " • ЗАЩИТА: %d • РЕКОРД: %d" % [score, training_challenge_best]
    training_attack_label.text = training_challenge_result
    play_sound("victory" if completed else "menu")

func toggle_training_target() -> void:
    if not training_mode or in_menu or round_over or manual_paused:
        return
    # Cycle stationary -> slow -> fast -> stationary for a repeatable
    # spacing drill on keyboard and touch devices.
    if not training_target_moves:
        training_target_moves = true
        training_target_speed = 1
    elif training_target_speed == 1:
        training_target_speed = 2
    else:
        training_target_moves = false
    training_target_button.text = training_target_caption()
    play_sound("menu")

# Reset the entire training drill without changing the chosen fighter or
# accidentally modifying ranked combo records.
func reset_training_session() -> void:
    if not training_mode or in_menu or manual_paused or round_over:
        return
    training_knockouts = 0
    training_guarded_hits = 0
    training_attack_attempts = 0
    training_dodges = 0
    training_challenge_running = false
    training_challenge_remaining = 60.0
    training_challenge_result = ""
    training_challenge_button.text = "ЗАЩИТА 60 С • СТАРТ"
    training_elapsed = 0.0
    training_hud_last = 0.0
    score_label.text = "ТРЕНИРОВКА • МИШЕНЕЙ: 0 • УРОН: 0 • DPS: 0 • БЛОК: 0 • ПАРИР: 0/0 • УКЛ: 0"
    restart_round()
    play_sound("menu")

func start_game() -> void:
    controls_help_label.visible = false
    play_sound("menu")
    in_menu = false
    sync_pause_overlay()
    menu_layer.visible = false
    for key in controls.keys():
        controls[key].visible = true
    pause_button.visible = true
    dash_button.visible = true
    training_target_button.visible = training_mode
    training_reset_button.visible = training_mode
    training_guard_button.visible = training_mode
    training_attack_button.visible = training_mode
    training_pace_button.visible = training_mode
    training_pace_button.text = training_pace_caption()
    training_attack_label.visible = training_mode
    training_challenge_button.visible = training_mode
    training_range_label.visible = training_mode
    update_training_range()
    training_target_button.text = training_target_caption()
    training_guard_button.text = "ЩИТ МИШЕНИ: ВКЛ" if training_target_guarding else "ЩИТ МИШЕНИ: ВЫКЛ"
    training_attack_button.text = "МИШЕНЬ АТАКУЕТ: ДА" if training_attack_enabled else "МИШЕНЬ АТАКУЕТ: НЕТ"
    training_attack_label.text = "" if not training_attack_enabled else "Тренировка парирования"
    pause_toggle_button.visible = true
    controls_help_button.visible = true
    cooldown_label.visible = true
    skill_label.visible = true
    enemy_energy_label.visible = true
    round_timer_label.visible = true
    round_number_label.visible = true
    score_label.visible = true
    player_name_label.visible = true
    enemy_name_label.visible = true
    restart_button.visible = round_over
    change_fighter_button.visible = round_over
    result_label.visible = round_over
    update_health_labels()

# Warn before the opponent has enough energy for a special attack.
# The text as well as the color changes, so the warning is accessible on mobile.
func update_enemy_energy_label() -> void:
    var ready := enemy_energy >= skill_cost
    enemy_energy_label.text = ("СПЕЦ ВРАГА ГОТОВ: %d/100" if ready else "ЭНЕРГИЯ ВРАГА: %d/100") % int(enemy_energy)
    enemy_energy_label.add_theme_color_override("font_color",
        Color("#ff737e") if ready else Color("#fff0d7"))

# Keep the exact HP visible alongside the colored bars on both platforms.
func update_health_labels() -> void:
    player_name_label.text = "%s  •  %d HP" % [fighter_names[selected_fighter], hp_left]
    enemy_name_label.text = "%s  •  %d HP" % [fighter_names[enemy_fighter], hp_right]
    # Low-health warnings are visible without relying on the HP bar alone.
    # Reset the color at the start of every new round.
    player_name_label.add_theme_color_override("font_color",
        Color("#ff737e") if hp_left <= 25 else Color("#e7f0ff"))
    enemy_name_label.add_theme_color_override("font_color",
        Color("#ff737e") if hp_right <= 25 else Color("#e7f0ff"))

func update_accuracy_label() -> void:
    var accuracy := 0
    if attacks_attempted > 0:
        accuracy = roundi(float(hits_landed) * 100.0 / float(attacks_attempted))
    if attacks_attempted == 0:
        accuracy_label.text = "ТОЧНОСТЬ: — (нет атак)"
    else:
        accuracy_label.text = "ТОЧНОСТЬ: %d/%d (%d%%)  •  ПРОМАХИ: %d" % [hits_landed, attacks_attempted, accuracy, maxi(0, attacks_attempted - hits_landed)]
    # Make an active combo visible without permanently changing HUD colors.
    accuracy_label.add_theme_color_override("font_color",
        Color("#ffd47d") if combo_hits > 1 else Color("#80d9ff"))
    if combo_hits > 1:
        accuracy_label.text += "\nКОМБО x%d  •  РЕКОРД x%d" % [combo_hits, best_combo]
    elif best_combo > 1:
        accuracy_label.text += "\nРЕКОРД КОМБО x%d" % best_combo
    # Keep stats within two lines even when the current combo has ended.
    if blocked_hits > 0:
        accuracy_label.text += ("%sБЛОКИ: %d" % ["  •  " if combo_hits > 1 or best_combo > 1 else "\n", blocked_hits])


func restart_round() -> void:
    # The rematch action starts a fresh score only after a finished match.
    # Ordinary round restarts retain the score, including drawn rounds.
    if match_finished:
        player_wins = 0
        enemy_wins = 0
        draws = 0
        match_finished = false
        score_label.text = "ИГРОК 0 : 0 ПРОТИВНИК  •  НИЧЬИХ: 0"
    controls_help_label.visible = false
    manual_paused = false
    pause_overlay.visible = false
    pause_toggle_button.text = "ПАУЗА" if OS.has_feature("mobile") else "ПАУЗА (P)"
    # A new round must never inherit held attacks or a captured joystick touch.
    joystick_touch = -1
    joystick_axis = 0.0
    for key in held.keys():
        held[key] = false
    hp_left = 100
    hp_right = 100
    update_health_labels()
    x_left = 300.0
    x_right = 900.0
    training_target_direction = 1.0
    training_attack_timer = training_attack_interval()
    training_attack_windup = 0.0
    y_left = 610.0
    velocity_y = 0.0
    attack_cooldown = 0.0
    enemy_cooldown = 0.0
    enemy_windup = 0.0
    enemy_pending_special = false
    combo_hits = 0
    best_combo = 0
    damage_dealt = 0
    training_guarded_hits = 0
    training_attack_attempts = 0
    training_dodges = 0
    damage_taken = 0
    hits_landed = 0
    attacks_attempted = 0
    hits_received = 0
    blocked_hits = 0
    guard_breaks = 0
    guard_break_flash = 0.0
    parry_window = 0.0
    parry_cooldown = 0.0
    guard_was_pressed = false
    successful_parries = 0
    update_accuracy_label()
    combo_timer = 0.0
    block_timer = 0.0
    guard_stamina = 100.0
    guard_exhausted = false
    dash_cooldown = 0.0
    dash_invulnerable = 0.0
    dash_queued = false
    skill_energy = 0.0
    enemy_energy = 0.0
    enemy_skill_fx = 0.0
    # Reset HUD immediately; never show stale cooldown/combo from last round.
    skill_label.text = "ЭНЕРГИЯ 0/100"
    update_enemy_energy_label()
    cooldown_label.text = "ГОТОВО"
    round_seconds = round_duration
    round_timer_label.text = "∞" if training_mode else str(int(round_duration))
    timer_warning_active = false
    final_countdown_active = false
    round_timer_label.add_theme_color_override("font_color", Color.WHITE)
    round_number_label.text = "ТРЕНИРОВКА • МИШЕНЕЙ: %d" % training_knockouts if training_mode else "РАУНД %d" % (player_wins + enemy_wins + draws + 1)
    round_over = false
    sync_pause_overlay()
    player_attack_fx = 0.0
    enemy_attack_fx = 0.0
    player_hit_fx = 0.0
    enemy_hit_fx = 0.0
    ai_timer = 0.0
    ai_retreat = false
    result_label.visible = false
    restart_button.visible = false
    change_fighter_button.visible = false
    queue_redraw()

# outcome: 1 = victory, -1 = defeat, 0 = draw (equal HP at timeout).
func finish_round(outcome: int) -> void:
    if round_over:
        return
    round_over = true
    update_health_labels()
    if outcome > 0:
        play_sound("victory")
        player_wins += 1
        result_label.text = "ПОБЕДА!"
    elif outcome < 0:
        play_sound("defeat")
        enemy_wins += 1
        result_label.text = "ПОРАЖЕНИЕ!"
    else:
        play_sound("menu")
        draws += 1
        result_label.text = "НИЧЬЯ!"
    # Distinguish a time-limit decision from a knockout for both platforms.
    if round_seconds <= 0.0:
        result_label.text += "\nПО ВРЕМЕНИ"
    elif hp_left <= 0 or hp_right <= 0:
        result_label.text += "\nНОКАУТ"
    # Explain timeout victories and narrow defeats with exact remaining HP.
    # Time spent in active combat excludes pauses and background interruptions.
    # A knockout and a time-limit decision now show comparable durations.
    var elapsed_seconds := clampi(ceili(round_duration - round_seconds), 0, int(round_duration))
    result_label.text += "\nВРЕМЯ БОЯ: %d / %d сек" % [elapsed_seconds, int(round_duration)]
    result_label.text += "\nHP: %d / %d" % [hp_left, hp_right]
    result_label.text += "\nУРОН: %d нанесено / %d получено" % [damage_dealt, damage_taken]
    result_label.text += "\nПОПАДАНИЯ: %d / %d  •  БЛОК: %d  •  ПРОБОЕВ: %d  •  ПАРИРОВАНИЙ: %d" % [hits_landed, hits_received, blocked_hits, guard_breaks, successful_parries]
    # Accuracy is based on actual attacks, not key presses during cooldown.
    # No attacks means no accuracy measurement, not a 0% miss rate.
    if attacks_attempted == 0:
        result_label.text += "\nТОЧНОСТЬ: — (нет атак)"
    else:
        var accuracy := roundi(float(hits_landed) * 100.0 / float(attacks_attempted))
        result_label.text += "\nТОЧНОСТЬ: %d%% (%d из %d)" % [accuracy, hits_landed, attacks_attempted]
    if best_combo > 1:
        result_label.text += "\nКОМБО: %d  •  ЛИЧНЫЙ РЕКОРД: %d" % [best_combo, personal_best_combo]
    # Write only at the end of a round to avoid disk I/O on every hit.
    if personal_best_combo > 1:
        var record_settings := ConfigFile.new()
        record_settings.load("user://settings.cfg")
        record_settings.set_value("records", "best_combo", personal_best_combo)
        record_settings.save("user://settings.cfg")
    score_label.text = "ИГРОК %d : %d ПРОТИВНИК  •  НИЧЬИХ: %d" % [player_wins, enemy_wins, draws]
    match_finished = match_target_wins > 0 and (player_wins >= match_target_wins or enemy_wins >= match_target_wins)
    if match_finished:
        result_label.text = ("МАТЧ ВЫИГРАН!\n" if player_wins >= match_target_wins else "МАТЧ ПРОИГРАН!\n") + result_label.text
        restart_button.text = "НОВЫЙ МАТЧ" if OS.has_feature("mobile") else "НОВЫЙ МАТЧ (R)"
    else:
        restart_button.text = "СЛЕД. РАУНД" if OS.has_feature("mobile") else "СЛЕД. РАУНД (R)"
    result_label.visible = true
    restart_button.visible = true
    change_fighter_button.visible = true

func make_rig() -> Dictionary:
    var anchors := {}
    for name in ["head", "torso", "pelvis", "chest_left", "chest_right", "glute_left", "glute_right", "arm_left", "arm_right", "leg_left", "leg_right", "hair", "pelvic_attachment", "pelvic_secondary_left", "pelvic_secondary_right"]:
        anchors[name] = Vector2.ZERO
    return anchors

# Releasing focus must also release held touch/attack inputs. Otherwise
# returning from Android notifications or desktop Alt-Tab can resume a
# stuck movement, block or attack without a fresh press.
func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_IN or what == NOTIFICATION_WM_WINDOW_FOCUS_IN:
        has_game_focus = true
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
        has_game_focus = false
        stop_active_sounds()
        joystick_touch = -1
        joystick_axis = 0.0
        dash_queued = false
        guard_was_pressed = false
        parry_window = 0.0
        for key in held.keys():
            held[key] = false
    sync_pause_overlay()

func _unhandled_key_input(event: InputEvent) -> void:
    if not (event is InputEventKey) or not event.pressed or event.echo:
        return
    # Desktop-only fullscreen shortcut works in menus and during combat.
    if not OS.has_feature("mobile") and event.keycode == KEY_F11:
        var mode := DisplayServer.window_get_mode()
        var next_mode := DisplayServer.WINDOW_MODE_FULLSCREEN
        if mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
            next_mode = DisplayServer.WINDOW_MODE_WINDOWED
        DisplayServer.window_set_mode(next_mode)
        # Save only the display setting, preserving audio and fighter choices.
        var display_settings := ConfigFile.new()
        display_settings.load("user://settings.cfg")
        display_settings.set_value("display", "fullscreen", next_mode == DisplayServer.WINDOW_MODE_FULLSCREEN)
        display_settings.save("user://settings.cfg")
        get_viewport().set_input_as_handled()
        return
    # F3 keeps the optional desktop FPS counter across restarts.
    if not OS.has_feature("mobile") and event.keycode == KEY_F3:
        fps_enabled = not fps_label.visible
        fps_label.visible = fps_enabled
        fps_elapsed = 1.0
        var fps_settings := ConfigFile.new()
        fps_settings.load("user://settings.cfg")
        fps_settings.set_value("display", "show_fps", fps_enabled)
        fps_settings.save("user://settings.cfg")
        get_viewport().set_input_as_handled()
        return
    # Audio can be toggled even during combat or character selection.
    if not OS.has_feature("mobile") and event.keycode == KEY_M:
        toggle_sound()
        get_viewport().set_input_as_handled()
        return
    if not OS.has_feature("mobile") and event.keycode == KEY_F1 and not in_menu:
        toggle_controls_help()
        get_viewport().set_input_as_handled()
        return
    # Escape closes the help overlay first, instead of accidentally
    # abandoning the match while the player is reading controls.
    if event.keycode == KEY_ESCAPE and controls_help_label.visible:
        toggle_controls_help()
        get_viewport().set_input_as_handled()
        return
    # The selection screen is a menu too, but Escape should go back.
    if event.keycode == KEY_ESCAPE and selection_layer.visible:
        show_menu()
        get_viewport().set_input_as_handled()
        return
    if in_menu:
        return
    if event.keycode == KEY_R and training_mode and not manual_paused and not round_over:
        reset_training_session()
        get_viewport().set_input_as_handled()
        return
    if event.keycode == KEY_T and training_mode and not manual_paused and not round_over:
        toggle_training_target()
        get_viewport().set_input_as_handled()
        return
    if event.keycode == KEY_G and training_mode and not manual_paused and not round_over:
        toggle_training_guard()
        get_viewport().set_input_as_handled()
        return
    if event.keycode == KEY_B and training_mode and not manual_paused and not round_over:
        cycle_training_attack_pace()
        get_viewport().set_input_as_handled()
        return
    if event.keycode == KEY_SHIFT and not manual_paused and not round_over:
        dash_queued = true
        get_viewport().set_input_as_handled()
        return
    if event.keycode == KEY_P:
        toggle_pause()
        get_viewport().set_input_as_handled()
        return
    if event.keycode == KEY_ESCAPE:
        show_menu()
        get_viewport().set_input_as_handled()
    elif round_over and event.keycode == KEY_Q:
        show_selection()
        get_viewport().set_input_as_handled()
    elif round_over and event.keycode in [KEY_R, KEY_ENTER, KEY_KP_ENTER]:
        restart_round()
        get_viewport().set_input_as_handled()

func _input(event: InputEvent) -> void:
    # Capture selection shortcuts before UI buttons consume arrow/Enter keys.
    if selection_layer.visible and event is InputEventKey and event.pressed and not event.echo:
        match event.keycode:
            KEY_LEFT:
                preview_fighter((selection_choice + fighter_names.size() - 1) % fighter_names.size())
            KEY_RIGHT:
                preview_fighter((selection_choice + 1) % fighter_names.size())
            KEY_C:
                cycle_costume()
            KEY_O:
                cycle_opponent()
            KEY_ENTER, KEY_KP_ENTER:
                select_fighter(selection_choice)
            KEY_ESCAPE:
                show_menu()
            _:
                return
        get_viewport().set_input_as_handled()
        return
    if in_menu or manual_paused or controls_help_label.visible:
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
    if fps_label.visible:
        fps_elapsed += delta
        if fps_elapsed >= 0.5:
            var current_fps := Engine.get_frames_per_second()
            fps_label.text = "FPS: %d" % current_fps
            # Readable performance warning without a permanent overlay.
            # Red: under 30 FPS; amber: under 50; blue: smooth gameplay.
            fps_label.add_theme_color_override("font_color",
                Color("#ff737e") if current_fps < 30 else
                Color("#ffd17a") if current_fps < 50 else Color("#58c9ff"))
            fps_elapsed = 0.0
    # Do not let the round timer or opponent advance during Alt-Tab or
    # Android notification interruptions.
    if round_over or in_menu or manual_paused or controls_help_label.visible or not has_game_focus:
        return
    if training_mode:
        if training_challenge_running:
            training_challenge_remaining = maxf(0.0, training_challenge_remaining - delta)
            round_timer_label.text = str(ceili(training_challenge_remaining))
            if training_challenge_remaining <= 0.0:
                finish_training_challenge(true)
        training_elapsed += delta
        if training_elapsed - training_hud_last >= 0.5:
            training_hud_last = training_elapsed
            # The damage total survives dummy respawns but resets with the
            # training session; no training stats affect ranked records.
            var average_dps := 0.0 if training_elapsed <= 0.0 else float(damage_dealt) / training_elapsed
            score_label.text = "МИШЕНЕЙ: %d • УРОН: %d • DPS: %.1f • БЛОК: %d • ПАРИР: %d/%d • УКЛ: %d" % [training_knockouts, damage_dealt, average_dps, training_guarded_hits, successful_parries, training_attack_attempts, training_dodges]
            if training_challenge_running:
                # Live scoring helps players adjust timing during the 60s
                # drill. Count only attacks actually attempted by the dummy.
                var accuracy := CombatRules.defense_accuracy(
                    successful_parries, training_dodges, training_attack_attempts)
                score_label.text += " • ОЧКИ: %d • ЗАЩИТА: %d%%" % [
                    CombatRules.defense_challenge_score(successful_parries, training_dodges),
                    accuracy]
            if training_challenge_result != "":
                score_label.text += " • " + training_challenge_result
            update_training_range()
    animation_clock += delta
    if not training_mode:
        round_seconds = maxf(0.0, round_seconds - delta)
        # A text marker supplements the red final countdown for color-blind
        # players and low-contrast mobile displays. Reset happens each round.
        if round_seconds <= 3.0:
            round_timer_label.text = "! %d !" % ceili(round_seconds)
        else:
            round_timer_label.text = str(ceili(round_seconds))
        # Make the last ten seconds unmistakable without changing the timer rules.
        if round_seconds <= 10.0 and not timer_warning_active:
            timer_warning_active = true
            round_timer_label.add_theme_color_override("font_color", Color("#ff8b9e"))
            # If a long frame skips directly into the last three seconds,
            # avoid playing two warning sounds in the same frame.
            if round_seconds > 3.0:
                play_sound("countdown")
        if round_seconds <= 3.0 and not final_countdown_active:
            final_countdown_active = true
            round_timer_label.add_theme_color_override("font_color", Color("#ff4d6d"))
            play_sound("countdown")
        if round_seconds <= 0.0:
            var outcome := 0
            if hp_left > hp_right:
                outcome = 1
            elif hp_left < hp_right:
                outcome = -1
            finish_round(outcome)
            return
    else:
        round_timer_label.text = "∞"
    impact_flash = maxf(0.0, impact_flash - delta)
    combo_timer = maxf(0.0, combo_timer - delta)
    block_timer = maxf(0.0, block_timer - delta)
    guard_break_flash = maxf(0.0, guard_break_flash - delta)
    parry_window = maxf(0.0, parry_window - delta)
    parry_cooldown = maxf(0.0, parry_cooldown - delta)
    if combo_timer <= 0.0 and combo_hits != 0:
        combo_hits = 0
        update_accuracy_label()
    player_motion = 0.0
    enemy_motion = 0.0
    player_attack_fx = maxf(0.0, player_attack_fx - delta)
    enemy_attack_fx = maxf(0.0, enemy_attack_fx - delta)
    enemy_skill_fx = maxf(0.0, enemy_skill_fx - delta)
    player_hit_fx = maxf(0.0, player_hit_fx - delta)
    enemy_hit_fx = maxf(0.0, enemy_hit_fx - delta)
    ai_timer -= delta
    attack_cooldown = maxf(0, attack_cooldown - delta)
    dash_cooldown = maxf(0.0, dash_cooldown - delta)
    dash_invulnerable = maxf(0.0, dash_invulnerable - delta)
    enemy_cooldown = maxf(0, enemy_cooldown - delta)
    var left_pressed: bool = Input.is_key_pressed(KEY_A) or joystick_axis < -0.2
    var right_pressed: bool = Input.is_key_pressed(KEY_D) or joystick_axis > 0.2
    var jump_pressed: bool = Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or held["JUMP"]
    var hit_pressed: bool = Input.is_key_pressed(KEY_J) or held["HIT"]
    player_motion = joystick_axis if absf(joystick_axis) > 0.2 else float(right_pressed) - float(left_pressed)
    var guard_requested: bool = held["BLOCK"] or Input.is_key_pressed(KEY_K)
    if guard_requested and not guard_was_pressed and not guard_exhausted and parry_cooldown <= 0.0:
        parry_window = 0.20
        parry_cooldown = 0.85
    if not guard_requested:
        parry_window = 0.0
    guard_was_pressed = guard_requested
    if guard_requested and not guard_exhausted:
        guard_stamina = maxf(0.0, guard_stamina - 24.0 * delta)
        if guard_stamina <= 0.0:
            guard_exhausted = true
            block_timer = 0.0
        else:
            block_timer = 0.15
            player_motion *= 0.35
    elif not guard_requested:
        guard_stamina = minf(100.0, guard_stamina + 20.0 * delta)
        if guard_exhausted and guard_stamina >= 35.0:
            guard_exhausted = false
    else:
        block_timer = 0.0
    x_left += player_motion * 330 * delta
    if dash_queued:
        dash_queued = false
        if dash_cooldown <= 0.0 and guard_stamina >= 30.0 and not guard_exhausted:
            var dash_direction := signf(player_motion)
            if dash_direction == 0.0:
                dash_direction = 1.0 if x_left <= x_right else -1.0
            x_left += dash_direction * 145.0
            guard_stamina -= 30.0
            dash_cooldown = 1.8
            dash_invulnerable = 0.22
            play_sound("jump")
    x_left = clampf(x_left, 50, 1230)
    if jump_pressed and y_left >= 610:
        velocity_y = -740
        play_sound("jump")
    velocity_y += 1700 * delta
    y_left = minf(610, y_left + velocity_y * delta)
    if y_left >= 610:
        velocity_y = 0
    # A reversible training drill: practice timing against a moving target
    # without enabling AI attacks, a timer, or ranked combo records.
    if training_mode and training_target_moves:
        x_right += training_target_direction * (240.0 if training_target_speed == 2 else 90.0) * delta
        if x_right >= 1060.0:
            x_right = 1060.0
            training_target_direction = -1.0
        elif x_right <= 470.0:
            x_right = 470.0
            training_target_direction = 1.0
        enemy_motion = training_target_direction
    # Optional sparring drill: the dummy telegraphs low-damage attacks so
    # parry, guard and dash can be practiced without losing a ranked round.
    if training_mode and training_attack_enabled:
        if training_attack_windup > 0.0:
            training_attack_windup = maxf(0.0, training_attack_windup - delta)
            training_attack_label.text = "ЗАМАХ: %.1f с" % training_attack_windup
            if training_attack_windup <= 0.0:
                enemy_attack_fx = 0.3
                training_attack_timer = training_attack_interval()
                training_attack_label.text = "УДАР МИШЕНИ"
                if absf(x_left - x_right) < 150.0 and absf(y_left - 610.0) < 120.0:
                    training_attack_attempts += 1
                    if dash_invulnerable > 0.0:
                        training_dodges += 1
                        training_attack_label.text = "УКЛОНЕНИЕ: %d" % training_dodges
                    elif block_timer > 0.0 and parry_window > 0.0:
                        parry_window = 0.0
                        successful_parries += 1
                        guard_stamina = maxf(0.0, guard_stamina - 12.0)
                        skill_energy = minf(100.0, skill_energy + 15.0)
                        training_attack_label.text = "ПАРИРОВАНО: %d" % successful_parries
                        play_sound("menu")
                    else:
                        var damage := 2 if block_timer > 0.0 else 6
                        hp_left = maxi(1, hp_left - damage)
                        damage_taken += damage
                        hits_received += 1
                        player_hit_fx = 0.2
                        play_sound("hit")
                        update_health_labels()
        else:
            training_attack_timer -= delta
            training_attack_label.text = "АТАКА ЧЕРЕЗ: %.1f с" % maxf(0.0, training_attack_timer)
            if training_attack_timer <= 0.0 and absf(x_left - x_right) < 195.0:
                training_attack_windup = training_attack_telegraph()
    var skill_pressed: bool = held["SKILL"] or Input.is_key_pressed(KEY_L)
    var can_skill: bool = skill_pressed and skill_energy >= skill_cost
    if (hit_pressed or can_skill) and attack_cooldown <= 0 and block_timer <= 0.0:
        if can_skill:
            skill_energy -= skill_cost
        attack_cooldown = 0.8 if can_skill else 0.43
        attacks_attempted += 1
        update_accuracy_label()
        player_attack_fx = 0.18
        play_sound("swing")
        if absf(x_left - x_right) < (195.0 if can_skill else 155.0) and absf(y_left - 610.0) < 115.0:
            combo_hits += 1
            hits_landed += 1
            best_combo = maxi(best_combo, combo_hits)
            if not training_mode:
                personal_best_combo = maxi(personal_best_combo, combo_hits)
            update_accuracy_label()
            skill_energy = minf(100.0, skill_energy + (0.0 if can_skill else 11.0))
            combo_timer = 1.3
            var hp_before_hit := hp_right
            var attack_damage := 18 if can_skill else 8 + mini(combo_hits, 4)
            # Practice ordinary hits against guard; specials break through.
            if training_mode and training_target_guarding and not can_skill:
                attack_damage = maxi(1, int(attack_damage / 4))
                training_guarded_hits += 1
            hp_right = maxi(0, hp_right - attack_damage)
            damage_dealt += hp_before_hit - hp_right
            enemy_hit_fx = 0.22
            enemy_energy = minf(100.0, enemy_energy + 5.0)
            impact_flash = 0.15
            play_sound("hit")
            if hp_right == 0:
                if training_mode:
                    training_knockouts += 1
                    hp_right = 100
                    enemy_energy = 0.0
                    round_number_label.text = "ТРЕНИРОВКА • МИШЕНЕЙ: %d" % training_knockouts
                    score_label.text = "МИШЕНЕЙ: %d • УРОН: %d • DPS: %.1f • БЛОК: %d • ПАРИР: %d/%d • УКЛ: %d" % [training_knockouts, damage_dealt, float(damage_dealt) / maxf(0.1, training_elapsed), training_guarded_hits, successful_parries, training_attack_attempts, training_dodges]
                else:
                    finish_round(1)
                    return
    if not training_mode and hp_left > 0 and hp_right > 0:
        var distance: float = absf(x_left - x_right)
        if ai_timer <= 0.0:
            ai_timer = [1.8, 1.1, 0.6][ai_difficulty]
            ai_retreat = distance < 185.0 and randf() < [0.18, 0.35, 0.50][ai_difficulty]
        if enemy_windup > 0.0:
            enemy_motion = 0.0
        elif ai_retreat and distance < 240.0:
            enemy_motion = -signf(x_left - x_right)
            x_right += enemy_motion * [85.0, 110.0, 145.0][ai_difficulty] * delta
        elif distance > 110.0:
            enemy_motion = signf(x_left - x_right)
            x_right += enemy_motion * [125.0, 170.0, 210.0][ai_difficulty] * delta
        x_right = clampf(x_right, 50.0, 1230.0)
        if absf(x_left - x_right) < 84.0 and absf(y_left - 610.0) < 115.0:
            var separation: float = 1.0 if x_left <= x_right else -1.0
            var midpoint: float = (x_left + x_right) * 0.5
            x_left = clampf(midpoint - separation * 42.0, 50.0, 1230.0)
            x_right = clampf(midpoint + separation * 42.0, 50.0, 1230.0)
        # Telegraph each attack so the player has time to dodge or block.
        # Resolve damage only after the windup, not at the first AI decision.
        if enemy_windup > 0.0:
            enemy_windup = maxf(0.0, enemy_windup - delta)
            if enemy_windup <= 0.0:
                enemy_attack_fx = 0.3 if enemy_pending_special else 0.18
                play_sound("swing")
                if dash_invulnerable <= 0.0 and absf(x_left - x_right) < 145.0 and absf(y_left - 610.0) < 120.0:
                    if block_timer > 0.0 and parry_window > 0.0:
                        # A well-timed fresh block cancels the telegraphed hit.
                        # The cooldown prevents rapidly tapping block for free.
                        parry_window = 0.0
                        successful_parries += 1
                        guard_stamina = maxf(0.0, guard_stamina - 12.0)
                        skill_energy = minf(100.0, skill_energy + 15.0)
                        enemy_cooldown = maxf(enemy_cooldown, 0.9)
                        impact_flash = 0.12
                        play_sound("menu")
                    else:
                        player_hit_fx = 0.22
                        impact_flash = 0.15
                        play_sound("hit")
                        var hp_before_enemy_hit := hp_left
                        var was_blocking := block_timer > 0.0
                        var guard_broken := false
                        if was_blocking:
                            blocked_hits += 1
                            # Blocking a real hit costs additional stamina. A
                            # special attack is much harder to absorb than a jab.
                            guard_stamina = maxf(0.0, guard_stamina - (42.0 if enemy_pending_special else 18.0))
                            if guard_stamina <= 0.0:
                                guard_exhausted = true
                                guard_broken = true
                                guard_breaks += 1
                                guard_break_flash = 1.25
                                block_timer = 0.0
                        var enemy_damage := 15 if enemy_pending_special else 7
                        if was_blocking:
                            enemy_damage = (10 if enemy_pending_special else 5) if guard_broken else (4 if enemy_pending_special else 2)
                        hp_left = maxi(0, hp_left - enemy_damage)
                        damage_taken += hp_before_enemy_hit - hp_left
                        hits_received += 1
                        combo_hits = 0
                        combo_timer = 0.0
                        update_accuracy_label()
                        enemy_energy = minf(100.0, enemy_energy + (0.0 if enemy_pending_special else 9.0))
                        skill_energy = minf(100.0, skill_energy + 4.0)
                        if hp_left == 0:
                            finish_round(-1)
                            return
                enemy_pending_special = false
        elif absf(x_left - x_right) < 140.0 and absf(y_left - 610.0) < 120.0 and enemy_cooldown <= 0.0:
            enemy_pending_special = enemy_energy >= skill_cost and randf() < 0.55
            if enemy_pending_special:
                enemy_energy -= skill_cost
            # Novice is easier to read, master reacts faster.
            enemy_windup = [0.65, 0.45, 0.30][ai_difficulty]
            enemy_cooldown = (1.3 if enemy_pending_special else 0.95) * [1.35, 1.0, 0.78][ai_difficulty]
    # Communicate when the special attack is usable and when blocking is active.
    skill_label.text = ("СПЕЦ ГОТОВ %d/100" if skill_energy >= skill_cost else "ЭНЕРГИЯ %d/100") % int(skill_energy)
    update_enemy_energy_label()
    cooldown_label.text = ("РЫВОК %.1fс • " % dash_cooldown if dash_cooldown > 0.0 else "РЫВОК ГОТОВ • ") + ("✦ ПАРИРОВАНИЕ! • " if parry_window > 0.0 else "") + ("⚡ ПРОБИТ БЛОК! • " if guard_break_flash > 0.0 else "") + ("⚠ ВРАГ ГОТОВИТ УДАР!  " if enemy_windup > 0.0 else "") + ("ЩИТ ИСТОЩЕН • " if guard_exhausted else "ЩИТ %d/100 • " % int(guard_stamina)) + ("БЛОК • " if block_timer > 0.0 else "") + ("КОМБО %d  " % combo_hits if combo_hits > 1 else "") + ("ГОТОВО" if attack_cooldown <= 0.0 else "УДАР %.1fс" % attack_cooldown)
    update_health_labels()
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
    if parry_window > 0.0:
        draw_arc(Vector2(x_left, y_left - 115.0), 92.0, 0.0, TAU, 40,
            Color("#8ef2d6", 0.95), 7.0)
    if dash_invulnerable > 0.0:
        draw_arc(Vector2(x_left, y_left - 115.0), 85.0, 0.0, TAU, 40,
            Color("#5be7ff", 0.85), 6.0)
    if enemy_windup > 0.0:
        # Red windup ring is a visual dodge/block cue on touch and keyboard.
        draw_arc(Vector2(x_right, 485), 88.0, 0.0, TAU, 48,
            Color("#ff6a80", 0.85), 5.0)
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
    # Highlight critical HP for both fighters without changing damage rules.
    var player_hp_color := Color("#ffb36c") if hp_left <= 25 else Color("#64e5ae")
    var enemy_hp_color := Color("#ff556e") if hp_right <= 25 else Color("#f27d98")
    draw_rect(Rect2(40, 44, float(hp_left) * 4.5, 20), player_hp_color)
    draw_rect(Rect2(1240 - float(hp_right) * 4.5, 44, float(hp_right) * 4.5, 20), enemy_hp_color)
    draw_rect(Rect2(35, 78, 460, 14), Color("#29253f"))
    draw_rect(Rect2(785, 78, 460, 14), Color("#29253f"))
    draw_rect(Rect2(40, 81, skill_energy * 4.5, 8), Color("#b49aff"))
    # Separate guard bar: releasing block restores stamina, holding drains it.
    draw_rect(Rect2(35, 104, 460, 8), Color("#29253f"))
    draw_rect(Rect2(40, 106, guard_stamina * 4.5, 4),
        Color("#ff737e") if guard_exhausted else Color("#71d7ff"))
    draw_rect(Rect2(1240 - enemy_energy * 4.5, 81, enemy_energy * 4.5, 8), Color("#ffb184"))
    draw_line(Vector2(35, 100), Vector2(495, 100), Color("#8173b0"), 2)
    draw_line(Vector2(785, 100), Vector2(1245, 100), Color("#8173b0"), 2)
    draw_rect(Rect2(525, 5, 230, 115), Color("#211b39", 0.92))
    draw_arc(Vector2(640, 62), 49, 0.0, TAU, 48, Color("#b49aff"), 3)
    # A visual countdown helps on small screens and respects 60/99/120s rounds.
    # The bar freezes with the existing pause/focus/help logic.
    draw_rect(Rect2(570, 110, 140, 6), Color("#39314f"))
    var time_fraction: float = clampf(round_seconds / maxf(round_duration, 1.0), 0.0, 1.0)
    var time_color := Color("#ff8b9e") if round_seconds <= 10.0 else Color("#71d7ff")
    draw_rect(Rect2(570, 110, 140.0 * time_fraction, 6), time_color)

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
