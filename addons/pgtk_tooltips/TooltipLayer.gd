
extends CanvasLayer

#region Properties

@export var backdrop: ColorRect;

#endregion Properties

#region Godot Methods

func _ready() -> void:
	self.layer = ProjectSettings.get_setting(TooltipNode.SETTINGS_NAME_TOOLTIP_LAYER, TooltipNode.SETTINGS_VALUE_TOOLTIP_LAYER);
	self.backdrop = ColorRect.new();
	self.backdrop.name = "Backdrop";
	self.backdrop.visible = false;
	self.backdrop.color = ProjectSettings.get_setting(TooltipNode.SETTINGS_NAME_TOOLTIP_BACKDROP_COLOR, TooltipNode.SETTINGS_VALUE_TOOLTIP_BACKDROP_COLOR);
	self.backdrop.set_anchors_preset(Control.PRESET_FULL_RECT);
	self.add_child(self.backdrop, true);

#endregion Godot Methods

#region Public Methods

func show_backdrop() -> void: self.backdrop.show();
func hide_backdrop() -> void: self.backdrop.hide();

#endregion Public Methods
