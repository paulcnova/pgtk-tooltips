
@tool
extends EditorPlugin

#region Godot Methods

func _enable_plugin() -> void:
	if not ProjectSettings.has_setting(TooltipNode.SETTINGS_NAME_TOOLTIP_RES_PATH):
		ProjectSettings.set_setting(TooltipNode.SETTINGS_NAME_TOOLTIP_RES_PATH, TooltipNode.SETTINGS_VALUE_TOOLTIP_RES_PATH);
	if not ProjectSettings.has_setting(TooltipNode.SETTINGS_NAME_TOOLTIP_SUFFIX):
		ProjectSettings.set_setting(TooltipNode.SETTINGS_NAME_TOOLTIP_SUFFIX, TooltipNode.SETTINGS_VALUE_TOOLTIP_SUFFIX);
	print("INPUT");
	print("INSPECT", InputMap.has_action(TooltipUI.INPUT_ACTION_TOOLTIP_INSPECT));
	print("EXIT", InputMap.has_action(TooltipUI.INPUT_ACTION_TOOLTIP_EXIT));
	if not InputMap.has_action(TooltipUI.INPUT_ACTION_TOOLTIP_INSPECT):
		var ev := InputEventKey.new();
		
		ev.physical_keycode = Key.KEY_T;
		
		ProjectSettings.set_setting("input/%s" % TooltipUI.INPUT_ACTION_TOOLTIP_INSPECT, {
			"deadzone": 0.2,
			"events": [ev]
		});
	if not InputMap.has_action(TooltipUI.INPUT_ACTION_TOOLTIP_EXIT):
		var ev := InputEventKey.new();
		
		ev.physical_keycode = Key.KEY_ESCAPE;
		ProjectSettings.set_setting("input/%s" % TooltipUI.INPUT_ACTION_TOOLTIP_EXIT, {
			"deadzone": 0.2,
			"events": [ev]
		});
	ProjectSettings.save();

#endregion Godot Methods
