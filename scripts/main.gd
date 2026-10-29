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
var animation_clock := 0.0
var player_motion := 0.0
var enemy_motion := 0.0
var cooldown_label: Label
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
var combo_timer := 0.0
var block_timer := 0.0
var skill_energy := 0.0
var skill_cost := 40.0
var enemy_energy := 0.0
var enemy_skill_fx := 0.0
var skill_label: Label
var round_duration := 99.0
var round_seconds := 99.0
var duration_button: Button
var timer_warning_active := false
var has_game_focus := true
var round_timer_label: Label
var round_number_label: Label

func _ready() -> void:
    # Sound preference is device-local until secure cross-device sync exists.
    var saved_settings := ConfigFile.new()
    if saved_settings.load("user://settings.cfg") == OK:
        sound_muted = saved_settings.get_value("audio", "muted", false) == true
        # Restore the desktop display choice; Android keeps its own layout.
        if not OS.has_feature("mobile") and saved_settings.get_value("display", "fullscreen", false) == true:
            DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
        # Restore selection only when the stored values are valid integers.
        # Corrupted or older settings must not index outside the fighter list.
        var stored_fighter = saved_settings.get_value("selection", "fighter", 0)
        var stored_costume = saved_settings.get_value("selection", "costume", 0)
        if typeof(stored_fighter) == TYPE_INT:
            selection_choice = clampi(stored_fighter, 0, fighter_names.size() - 1)
        if typeof(stored_costume) == TYPE_INT:
            selected_costume = clampi(stored_costume, 0, costume_names.size() - 1)
        # Older saves default to the original 99-second round.
        var saved_duration = saved_settings.get_value("match", "duration", 99)
        if typeof(saved_duration) == TYPE_INT and saved_duration in [60, 99, 120]:
            round_duration = float(saved_duration)
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
    cooldown_label = Label.new()
    cooldown_label.position = Vector2(640, 650)
    cooldown_label.add_theme_font_size_override("font_size", 17)
    add_child(cooldown_label)
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
    controls_help_label.text = "УПРАВЛЕНИЕ (кнопка — скрыть)\nБой на паузе, пока открыта помощь\nДжойстик слева — движение\nПРЫЖОК / УДАР / БЛОК / СПЕЦ — справа\nПАУЗА — остановить бой  •  МЕНЮ — выйти\nПосле раунда: ЗАНОВО или СМЕНИТЬ БОЙЦА" if OS.has_feature("mobile") else "УПРАВЛЕНИЕ (F1 — скрыть)\nБой на паузе, пока открыта помощь\nA/D — движение  •  W/ПРОБЕЛ — прыжок\nJ — удар  •  K — блок  •  L — спец\nP — пауза  •  M — звук  •  ESC — закрыть помощь\nПосле раунда: R — заново  •  Q — боец"
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
        keyboard_hint.text = "A/D — движение  •  W/ПРОБЕЛ — прыжок\nJ — удар  •  K — блок  •  L — спец  •  P — пауза  •  F1 — помощь"
        keyboard_hint.position = Vector2(55, 285)
        keyboard_hint.size = Vector2(460, 44)
        keyboard_hint.add_theme_font_size_override("font_size", 14)
        menu_layer.add_child(keyboard_hint)
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
    var selection_controls := Label.new()
    selection_controls.text = "ПК: ←/→ ВЫБОР • C КОСТЮМ • ENTER В БОЙ • ESC НАЗАД"
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
    settings.save("user://settings.cfg")

# Match length is a local preference; changing it affects the next round only.
func cycle_round_duration() -> void:
    var durations := [60, 99, 120]
    var index := durations.find(int(round_duration))
    round_duration = float(durations[(index + 1) % durations.size()])
    duration_button.text = "ТАЙМЕР РАУНДА: %d СЕК" % int(round_duration)
    var settings := ConfigFile.new()
    settings.load("user://settings.cfg")
    settings.set_value("match", "duration", int(round_duration))
    settings.save("user://settings.cfg")
    play_sound("menu")

func cycle_costume() -> void:
    selected_costume = (selected_costume + 1) % costume_names.size()
    costume_button.text = "КОСТЮМ: " + costume_names[selected_costume]
    selection_preview.modulate = Color.WHITE if selected_costume == 0 else Color("#c9d7ff") if selected_costume == 1 else Color("#ffc4d9")
    save_selection_preferences()
    play_sound("menu")

func select_fighter(index: int) -> void:
    selected_fighter = index
    selection_choice = index
    save_selection_preferences()
    enemy_fighter = (index + randi_range(1, 3)) % fighter_names.size()
    # Choosing a fighter starts a new match. Never carry a previous
    # character's wins, losses or draws into the next match.
    player_wins = 0
    enemy_wins = 0
    draws = 0
    score_label.text = "ИГРОК 0 : 0 ПРОТИВНИК  •  НИЧЬИХ: 0"
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
    for key in held.keys():
        held[key] = false
    menu_layer.visible = true
    selection_layer.visible = false
    for key in controls.keys():
        controls[key].visible = false
    pause_button.visible = false
    pause_toggle_button.visible = false
    controls_help_button.visible = false
    cooldown_label.visible = false
    skill_label.visible = false
    round_timer_label.visible = false
    round_number_label.visible = false
    score_label.visible = false
    player_name_label.visible = false
    enemy_name_label.visible = false
    restart_button.visible = false
    change_fighter_button.visible = false
    result_label.visible = false

func start_game() -> void:
    controls_help_label.visible = false
    play_sound("menu")
    in_menu = false
    sync_pause_overlay()
    menu_layer.visible = false
    for key in controls.keys():
        controls[key].visible = true
    pause_button.visible = true
    pause_toggle_button.visible = true
    controls_help_button.visible = true
    cooldown_label.visible = true
    skill_label.visible = true
    round_timer_label.visible = true
    round_number_label.visible = true
    score_label.visible = true
    player_name_label.visible = true
    enemy_name_label.visible = true
    restart_button.visible = round_over
    change_fighter_button.visible = round_over
    result_label.visible = round_over
    update_health_labels()

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

func restart_round() -> void:
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
    y_left = 610.0
    velocity_y = 0.0
    attack_cooldown = 0.0
    enemy_cooldown = 0.0
    combo_hits = 0
    best_combo = 0
    combo_timer = 0.0
    block_timer = 0.0
    skill_energy = 0.0
    enemy_energy = 0.0
    enemy_skill_fx = 0.0
    # Reset HUD immediately; never show stale cooldown/combo from last round.
    skill_label.text = "ЭНЕРГИЯ 0/100"
    cooldown_label.text = "ГОТОВО"
    round_seconds = round_duration
    round_timer_label.text = str(int(round_duration))
    timer_warning_active = false
    round_timer_label.add_theme_color_override("font_color", Color.WHITE)
    round_number_label.text = "РАУНД %d" % (player_wins + enemy_wins + draws + 1)
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
    result_label.text += "\nHP: %d / %d" % [hp_left, hp_right]
    if best_combo > 1:
        result_label.text += "\nЛУЧШЕЕ КОМБО: %d" % best_combo
    score_label.text = "ИГРОК %d : %d ПРОТИВНИК  •  НИЧЬИХ: %d" % [player_wins, enemy_wins, draws]
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
    # Do not let the round timer or opponent advance during Alt-Tab or
    # Android notification interruptions.
    if round_over or in_menu or manual_paused or controls_help_label.visible or not has_game_focus:
        return
    animation_clock += delta
    round_seconds = maxf(0.0, round_seconds - delta)
    round_timer_label.text = str(ceili(round_seconds))
    # Make the last ten seconds unmistakable without changing the timer rules.
    if round_seconds <= 10.0 and not timer_warning_active:
        timer_warning_active = true
        round_timer_label.add_theme_color_override("font_color", Color("#ff8b9e"))
    if round_seconds <= 0.0:
        var outcome := 0
        if hp_left > hp_right:
            outcome = 1
        elif hp_left < hp_right:
            outcome = -1
        finish_round(outcome)
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
            best_combo = maxi(best_combo, combo_hits)
            skill_energy = minf(100.0, skill_energy + (0.0 if can_skill else 11.0))
            combo_timer = 1.3
            hp_right = maxi(0, hp_right - (18 if can_skill else 8 + mini(combo_hits, 4)))
            enemy_hit_fx = 0.22
            enemy_energy = minf(100.0, enemy_energy + 5.0)
            impact_flash = 0.15
            play_sound("hit")
            if hp_right == 0:
                finish_round(1)
                return
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
                finish_round(-1)
                return
    # Communicate when the special attack is usable and when blocking is active.
    skill_label.text = ("СПЕЦ ГОТОВ %d/100" if skill_energy >= skill_cost else "ЭНЕРГИЯ %d/100") % int(skill_energy)
    cooldown_label.text = ("БЛОК • " if block_timer > 0.0 else "") + ("КОМБО %d  " % combo_hits if combo_hits > 1 else "") + ("ГОТОВО" if attack_cooldown <= 0.0 else "УДАР %.1fс" % attack_cooldown)
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
