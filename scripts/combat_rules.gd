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
static func player_attack_damage(combo_hits: int, special: bool, target_guarding: bool) -> int:
    if special:
        return 18
    var base := 8 + mini(maxi(combo_hits, 0), 4)
    return maxi(1, int(base / 4)) if target_guarding else base
