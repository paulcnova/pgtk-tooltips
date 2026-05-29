
@tool
extends EditorPlugin

#region Godot Methods

func _enable_plugin() -> void:
	if not ProjectSettings.has_setting(TooltipNode.SETTINGS_NAME_TOOLTIP_RES_PATH):
		ProjectSettings.set_setting(TooltipNode.SETTINGS_NAME_TOOLTIP_RES_PATH, TooltipNode.SETTINGS_VALUE_TOOLTIP_RES_PATH);
	if not ProjectSettings.has_setting(TooltipNode.SETTINGS_NAME_TOOLTIP_SUFFIX):
		ProjectSettings.set_setting(TooltipNode.SETTINGS_NAME_TOOLTIP_SUFFIX, TooltipNode.SETTINGS_VALUE_TOOLTIP_SUFFIX);
	if not ProjectSettings.has_setting(TooltipNode.SETTINGS_NAME_TOOLTIP_LAYER):
		ProjectSettings.set_setting(TooltipNode.SETTINGS_NAME_TOOLTIP_LAYER, TooltipNode.SETTINGS_VALUE_TOOLTIP_LAYER);
	if not ProjectSettings.has_setting(TooltipNode.SETTINGS_NAME_TOOLTIP_BACKDROP_COLOR):
		ProjectSettings.set_setting(TooltipNode.SETTINGS_NAME_TOOLTIP_BACKDROP_COLOR, TooltipNode.SETTINGS_VALUE_TOOLTIP_BACKDROP_COLOR);
	
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

func _enter_tree() -> void:
	self.add_autoload_singleton("TooltipLayer", "res://addons/pgtk_tooltips/TooltipLayer.gd");

func _exit_tree() -> void:
	self.remove_autoload_singleton("TooltipLayer");

#endregion Godot Methods
