extends RefCounted

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
