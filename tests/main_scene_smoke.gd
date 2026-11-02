extends SceneTree

# Godot may export an APK even when main.gd has a parse error, producing
# a package that installs but cannot start a playable fight. Fail CI first.
func _initialize() -> void:
    var game_script := load("res://scripts/main.gd")
    if game_script == null or not (game_script is Script):
        push_error("Main combat script failed to parse")
        quit(1)
        return
    var scene := load("res://scenes/Main.tscn") as PackedScene
    if scene == null:
        push_error("Main combat scene failed to load")
        quit(1)
        return
    var instance := scene.instantiate()
    if instance == null or instance.get_script() == null:
        push_error("Main scene is missing a valid combat script")
        if instance != null:
            instance.free()
        quit(1)
        return
    instance.free()
    quit(0)
