extends RefCounted

# Gamepad START must work even while paused, otherwise a controller-only
# player cannot resume the match. Never consume it in the main menu/results.
static func gamepad_pause_requested(pressed: bool, button_index: int,
        in_menu: bool, round_over: bool) -> bool:
    return pressed and button_index == JOY_BUTTON_START and not in_menu and not round_over

# Pure rules used by the 60-second defense drill on Android and Windows.
# The player must earn the same score regardless of frame rate or UI layout.
static func defense_challenge_score(parries: int, dodges: int) -> int:
    return maxi(0, parries) * 3 + maxi(0, dodges) * 2

static func defense_accuracy(parries: int, dodges: int, attempts: int) -> int:
    if attempts <= 0:
        return 0
    var defended := maxi(0, parries) + maxi(0, dodges)
    return clampi(roundi(100.0 * float(defended) / float(attempts)), 0, 100)

# A completed defense drill gets a reproducible rank. At least three dummy
# attacks are required so a single lucky parry cannot earn an S grade.
static func defense_challenge_grade(parries: int, dodges: int, attempts: int) -> String:
    if attempts < 3:
        return "—"
    var accuracy := defense_accuracy(parries, dodges, attempts)
    if accuracy >= 90:
        return "S"
    if accuracy >= 75:
        return "A"
    if accuracy >= 55:
        return "B"
    if accuracy >= 35:
        return "C"
    return "D"

# A short or abandoned challenge is useful practice, but it must not replace
# the saved personal record. This is shared by touch and keyboard builds.
static func eligible_defense_record(completed: bool, attempts: int) -> bool:
    return completed and attempts >= 3

# A hit breaks the defensive streak. Only attacks actually attempted by
# the sparring dummy count, so standing out of range cannot farm a record.
static func next_defense_streak(current: int, defended: bool) -> int:
    return mini(99999, maxi(0, current) + 1) if defended else 0


# A special attack consumes energy and pierces the sparring dummy's guard.
# Ordinary attacks scale with the combo but never exceed the +4 bonus.
# Keeping damage in one rule avoids Android/Windows training differences.
# A live training preview uses the exact same combat rules as real hits.
# The preview is informational; it never spends energy or alters records.
static func training_damage_preview(combo_hits: int, target_guarding: bool) -> Vector2i:
    return Vector2i(
        player_attack_damage(combo_hits, false, target_guarding),
        player_attack_damage(combo_hits, true, target_guarding)
    )

static func player_attack_damage(combo_hits: int, special: bool, target_guarding: bool) -> int:
    if special:
        return 18
    var base := 8 + mini(maxi(combo_hits, 0), 4)
    return maxi(1, int(base / 4)) if target_guarding else base

# Persistent ranked round history (wins, losses, draws), separate from
# practice drills. Clamp corrupted save values and prevent counter overflow.
static func next_career_record(record: Vector3i, outcome: int) -> Vector3i:
    var safe := Vector3i(
        clampi(record.x, 0, 99999),
        clampi(record.y, 0, 99999),
        clampi(record.z, 0, 99999)
    )
    if outcome > 0:
        safe.x = mini(99999, safe.x + 1)
    elif outcome < 0:
        safe.y = mini(99999, safe.y + 1)
    else:
        safe.z = mini(99999, safe.z + 1)
    return safe


# Career win percentage is computed from saved ranked results only.
# Training matches never enter the career record and ties count as rounds.
static func career_win_rate(record: Vector3i) -> int:
    var wins := clampi(record.x, 0, 99999)
    var losses := clampi(record.y, 0, 99999)
    var draws := clampi(record.z, 0, 99999)
    var total := wins + losses + draws
    if total == 0:
        return 0
    return clampi(roundi(100.0 * float(wins) / float(total)), 0, 100)


# A visible round rating encourages precise attacks and timely defense.
# Pure and platform-independent: damage, hit count and parries are the
# already recorded match statistics. Never awards currency or changes saves.
static func round_performance_score(outcome: int, landed: int, attempted: int,
        dealt: int, taken: int, parries: int) -> int:
    var accuracy := 0
    if attempted > 0:
        accuracy = clampi(roundi(100.0 * float(maxi(0, landed)) / float(attempted)), 0, 100)
    var margin := clampi(dealt - taken, -100, 100)
    var victory_bonus := 25 if outcome > 0 else (10 if outcome == 0 else 0)
    return clampi(roundi(float(accuracy) * 0.55 + float(margin) * 0.2 +
        float(clampi(parries, 0, 5)) * 4.0) + victory_bonus, 0, 100)

static func round_performance_grade(outcome: int, landed: int, attempted: int,
        dealt: int, taken: int, parries: int) -> String:
    var score := round_performance_score(outcome, landed, attempted, dealt, taken, parries)
    if score >= 90:
        return "S"
    if score >= 70:
        return "A"
    if score >= 50:
        return "B"
    if score >= 30:
        return "C"
    return "D"

# Actionable post-match coaching; the text never changes ranking or saves.
static func round_training_tip(landed: int, attempted: int, dealt: int,
        taken: int, parries: int) -> String:
    if attempted <= 0:
        return "СОВЕТ: используй обычные атаки, чтобы начать комбо."
    var accuracy := float(clampi(landed, 0, attempted)) / float(attempted)
    if accuracy < 0.5:
        return "СОВЕТ: сократи дистанцию и атакуй после открытия защиты."
    if taken > dealt:
        return "СОВЕТ: чаще уклоняйся и блокируй ответные удары."
    if parries <= 0:
        return "СОВЕТ: попробуй парирование перед контратакой."
    return "ОТЛИЧНО: сочетай парирование, комбо и спецприёмы."


# Readable guard-stamina state for the battle HUD, including accessibility
# when the small stamina bar is hard to see on an Android display.
static func guard_readiness_label(stamina: float, exhausted: bool) -> String:
    if exhausted:
        return "ЗАЩИТА: ПЕРЕГРЕВ"
    var percent := clampi(roundi(stamina), 0, 100)
    if percent < 20:
        return "ЗАЩИТА: МАЛО %d%%" % percent
    return "ЗАЩИТА: %d%%" % percent

# A text companion to HP bars for small screens and color-blind players.
# Positive values mean the player leads; never modify combat calculations.
static func health_advantage_label(player_hp: int, enemy_hp: int) -> String:
    var difference := clampi(player_hp, 0, 100) - clampi(enemy_hp, 0, 100)
    if difference == 0:
        return "HP: РАВНО"
    if difference > 0:
        return "HP: ПРЕИМУЩЕСТВО +%d" % difference
    return "HP: ОТСТАВАНИЕ %d" % -difference

# Reposition the touch joystick after mobile rotation or a desktop resize.
# Keep its old 1280x720 location, but do not leave it below the screen in
# narrow landscape/split-screen viewports. No saved control settings change.
static func joystick_center_for_viewport(viewport: Vector2) -> Vector2:
    var width := maxf(1.0, viewport.x)
    var height := maxf(1.0, viewport.y)
    return Vector2(
        minf(width * 0.5, minf(112.0, maxf(76.0, width * 0.20))),
        maxf(height * 0.5, height - 77.0)
    )

# Touch and keyboard share these directional combat rules. Screen Y increases
# downwards: up selects a head strike, down selects a low strike.
static func touch_direction(position: Vector2, center: Vector2) -> Vector2:
    var offset := (position - center) / 58.0
    var distance := offset.length()
    # Rescale the radial dead zone instead of jumping instantly to 20% speed
    # at its edge. This keeps short mobile thumb movements controllable and
    # prevents diagonal movement from exceeding the same maximum speed.
    if distance <= 0.2:
        return Vector2.ZERO
    var strength := clampf((distance - 0.2) / 0.8, 0.0, 1.0)
    return offset.normalized() * strength

# The touch dead zone is already applied by touch_direction(). Do not add
# a second 20% threshold in the main game loop: it made gentle movements
# suddenly jump to full speed and broke fine spacing on phones.
# Gamepad stick is normalized separately from touch pixels. Keep the
# 18% radial dead zone and a continuous speed curve on both Windows/Android.
static func gamepad_direction(raw: Vector2) -> Vector2:
    var distance := raw.length()
    if distance <= 0.18:
        return Vector2.ZERO
    return raw.normalized() * clampf((distance - 0.18) / 0.82, 0.0, 1.0)

# Some controllers expose the directional pad as buttons instead of axes.
# Normalize diagonal input so D-pad movement is no faster than the stick.
# Opposing directions cancel, avoiding accidental jumps or low strikes.
static func dpad_direction(left: bool, right: bool, up: bool, down: bool) -> Vector2:
    var axis := Vector2(float(int(right) - int(left)), float(int(down) - int(up)))
    return axis.normalized() if axis != Vector2.ZERO else Vector2.ZERO

static func horizontal_motion(analog_x: float, keyboard_x: float) -> float:
    return clampf(analog_x, -1.0, 1.0) if absf(analog_x) > 0.001 else clampf(keyboard_x, -1.0, 1.0)

static func attack_level(vertical_axis: float) -> int:
    if vertical_axis < -0.45:
        return 1 # head
    if vertical_axis > 0.45:
        return -1 # legs
    return 0 # torso

static func attack_level_label(level: int) -> String:
    if level > 0:
        return "ГОЛОВА"
    if level < 0:
        return "НОГИ"
    return "КОРПУС"

# Standing guard covers the head, crouching guard covers the legs. Both
# cover the torso; attacks against the wrong guard height are unblocked.
static func guard_covers_level(crouched: bool, level: int) -> bool:
    return level <= 0 if crouched else level >= 0

# Direction + HIT selects a head strike without forcing a jump. An
# explicit jump button (SPACE / touch JUMP / gamepad A) always wins, even
# while attacking. This avoids accidental aerial moves on small joysticks.
static func directional_jump_requested(up: bool, attacking: bool,
        explicit_jump: bool) -> bool:
    return explicit_jump or (up and not attacking)

# Holding up selects a head strike as well as jump. Jump only on the
# rising edge; holding up through landing must not cause repeated hops.
static func should_start_jump(pressed: bool, was_pressed: bool,
        grounded: bool, crouched: bool) -> bool:
    return pressed and not was_pressed and grounded and not crouched

# High strikes pass over crouching fighters; low strikes pass below jumps.
static func attack_connects(level: int, target_crouched: bool, target_airborne: bool) -> bool:
    if level > 0 and target_crouched:
        return false
    if level < 0 and target_airborne:
        return false
    return true

# Training dummy uses the same height rules as ranked AI. The result is
# pure, so touch and keyboard controls cannot disagree on low/high defense.
# Dodge includes moving through the hit with dash invulnerability or
# correctly crouching under a high strike / jumping over a low strike.
static func training_defense_outcome(level: int, crouched: bool,
        airborne: bool, dashing: bool, guarding: bool,
        parry_active: bool) -> String:
    if dashing or not attack_connects(level, crouched, airborne):
        return "dodge"
    if guarding and guard_covers_level(crouched, level):
        return "parry" if parry_active else "block"
    return "hit"

# Successful unguarded hits briefly interrupt the AI's movement and windup.
# A blocked hit never grants free stun; specials create a longer opening.
static func hitstun_seconds(level: int, special: bool, blocked: bool) -> float:
    if blocked:
        return 0.0
    if special:
        return 0.55
    if level > 0:
        return 0.28
    if level < 0:
        return 0.18
    return 0.22

# Breaking a depleted guard is a real opening, not a free block.
# A clean block has no stun; a guard break briefly interrupts the defender.
static func player_hitstun_on_hit(level: int, special: bool,
        blocked: bool, guard_broken: bool) -> float:
    if blocked and not guard_broken:
        return 0.0
    var duration := hitstun_seconds(level, special, false)
    return duration + 0.12 if guard_broken else duration

# A blocked head strike puts more pressure on the guard than a body jab.
# Both the player's HUD and AI use this deterministic stamina cost.
static func guard_impact_cost(level: int, special: bool) -> float:
    var base := 42.0 if special else 18.0
    return base + (6.0 if level > 0 else 2.0 if level < 0 else 0.0)

static func level_damage(base_damage: int, level: int) -> int:
    if level > 0:
        return maxi(1, base_damage + 3)
    if level < 0:
        return maxi(1, base_damage - 2)
    return maxi(1, base_damage)


# Keep fighter artwork readable on 720p mobile while maintaining a
# consistent ground contact point. Combat reach stays in world units.
static func fighter_sprite_size(crouched: bool) -> Vector2:
    # Larger readable character art while keeping the head below the 125px HUD.
    # Crouching reduces height but preserves the same visual body width.
    return Vector2(292.0, 260.0 if crouched else 430.0)


# Fit the scrollable results panel and both actions inside a small mobile
# viewport. No result statistics or buttons may extend beyond the safe inset.
# This is pure layout math, shared by Android and Windows.
# Small landscape Android viewports must not use desktop-sized result text.
# Tiny split-screen panels must not inherit desktop margins that leave
# almost no scrollable text area. Insets are in panel-local logical pixels.
# The first result screen shows the outcome and key numbers, not a wall
# of statistics covering the fighters. Players can expand the full scrollable
# report without losing any recorded accuracy, combo or career information.
static func compact_result_summary(full_report: String) -> String:
    var summary := PackedStringArray()
    for line in full_report.split("\n"):
        if line.begins_with("ПОБЕДА") or line.begins_with("ПОРАЖЕНИЕ") \
                or line.begins_with("НИЧЬЯ") or line.begins_with("МАТЧ ") \
                or line.begins_with("ПО ВРЕМЕНИ") or line.begins_with("НОКАУТ") \
                or line.begins_with("ВРЕМЯ БОЯ:") or line.begins_with("HP:") \
                or line.begins_with("УРОН:") or line.begins_with("✦ РЕЙТИНГ БОЯ:"):
            summary.append(line)
    return "\n".join(summary)


static func result_content_insets(panel_size: Vector2) -> Vector2i:
    return Vector2i(
        clampi(roundi(panel_size.x * 0.04), 2, 24),
        clampi(roundi(panel_size.y * 0.06), 2, 18)
    )

static func result_font_size(viewport: Vector2) -> int:
    if viewport.x < 200.0 or viewport.y < 140.0:
        return 11
    if viewport.y < 390.0 or viewport.x < 420.0:
        return 14
    if viewport.x < 650.0:
        return 16
    return 19

static func result_overlay_rects(viewport: Vector2) -> Dictionary:
    # Portrait/split-screen devices need two full-width actions below the
    # scrollable results card. Tiny side-by-side buttons clipped their text.
    # Landscape and desktop keep the familiar horizontal action row.
    var width := maxf(1.0, viewport.x)
    var height := maxf(1.0, viewport.y)
    var stacked := width < 420.0
    var side_margin := minf(8.0, width * 0.05)
    var panel_width := minf(720.0, width - side_margin * 2.0)
    var top := minf(70.0, height * 0.12)
    var button_height := minf(56.0, height * (0.16 if stacked else 0.22))
    var bottom_reserve := minf(20.0, height * 0.08)
    var button_gap_y := minf(8.0, height * 0.025)
    var button_rows := 2.0 if stacked else 1.0
    var panel_height := minf(438.0, maxf(0.1,
        height - top - button_height * button_rows -
        bottom_reserve - button_gap_y * button_rows))
    var left := (width - panel_width) * 0.5
    var panel := Rect2(left, top, panel_width, panel_height)
    var button_y := top + panel_height + button_gap_y
    if stacked:
        var action_width := minf(360.0, panel_width)
        var action_left := (width - action_width) * 0.5
        return {
            "panel": panel,
            "change": Rect2(action_left, button_y, action_width, button_height),
            "restart": Rect2(action_left, button_y + button_height + button_gap_y,
                action_width, button_height),
        }
    var button_gap_x := minf(8.0, panel_width * 0.08)
    var button_width := minf(210.0, (panel_width - button_gap_x) * 0.5)
    var group_width := button_width * 2.0 + button_gap_x
    var group_left := (width - group_width) * 0.5
    return {
        "panel": panel,
        "change": Rect2(group_left, button_y, button_width, button_height),
        "restart": Rect2(group_left + button_width + button_gap_x,
            button_y, button_width, button_height),
    }

# The HUD must fit a 720p mobile viewport. Shield and enemy energy have
# dedicated labels; show the most actionable combat cue here, not a giant
# concatenation that hides fighters and touch controls.
static func compact_combat_cue(enemy_windup: float, enemy_level: int,
        guard_break_flash: float, parry_window: float,
        attack_cooldown: float, dash_cooldown: float, combo_hits: int,
        player_hitstun: float = 0.0, player_hp: int = 100,
        vertical_input: float = 0.0) -> String:
    if player_hitstun > 0.0:
        return "ОГЛУШЕНИЕ %.1fс" % player_hitstun
    if enemy_windup > 0.0:
        return "⚠ ВРАГ: " + attack_level_label(enemy_level)
    if guard_break_flash > 0.0:
        return "⚡ БЛОК ПРОБИТ"
    if parry_window > 0.0:
        return "✦ ПАРИРОВАНИЕ"
    if attack_cooldown > 0.0:
        return "УДАР %.1fс" % attack_cooldown
    if dash_cooldown > 0.0:
        return "РЫВОК %.1fс" % dash_cooldown
    # A persistent low-health warning is more useful than combo text on a
    # small touch HUD. Immediate threats (stun/windup/guard break) still win.
    if player_hp <= 25:
        return "⚠ КРИТИЧЕСКОЕ HP"
    if combo_hits > 1:
        return "КОМБО %d" % combo_hits
    # Preview the actual HIT height before the button is pressed.
    # A high/low cue is only shown when no urgent combat warning is active.
    if vertical_input < -0.55:
        return "HIT: ГОЛОВА"
    if vertical_input > 0.55:
        return "HIT: НОГИ"
    return "ГОТОВО К БОЮ"
