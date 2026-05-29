
@abstract
class_name TooltipUI
extends Control

#region Properties

const INPUT_ACTION_TOOLTIP_INSPECT: String = "ttp_inspect";
const INPUT_ACTION_TOOLTIP_EXIT: String = "ttp_exit";

var _tooltip_size: Vector2;
var _is_inspecting: bool = false;
var _is_trying_to_exit: bool = false;
var _is_trying_to_free: bool = false;

@export var backdrop: ColorRect;
@export var container: PanelContainer;
@export var tooltip_name: Label;
@export var tooltip_description: RichTextLabel;

@export_group("Tooltip Settings")
@export var delay_time: float = 0.0;
@export var follow_mouse: bool = true;
@export var offset: Vector2 = Vector2(24.0, -16.0);
@export var padding: Vector2 = 32.0 * Vector2.ONE;
@export var fade_in_duration: float = 0.15;

var is_inspecting: bool:
	get: return self._is_inspecting;

var is_nested_tooltip: bool:
	get:
		var parent: Node = self.get_parent();
		
		while parent != null:
			if parent is TooltipUI: return true;
			parent = parent.get_parent();
		return false;

signal inspect_tooltip(tooltip: TooltipUI);
signal stop_inspect_tooltip(tooltip: TooltipUI);

#endregion Properties

#region Godot Methods

func _ready() -> void:
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE;
	self.backdrop.visible = false;
	self._position_tooltip();

func _process(delta: float) -> void:
	if not self._is_inspecting:
		# self.container.reset_size();
		# self._tooltip_size = self.container.get_rect().size;
		self._position_tooltip();
	if self.visible:
		# self._tooltip_size = self.container.get_rect().size;
		if not self._is_inspecting:
			if Input.is_action_just_pressed(INPUT_ACTION_TOOLTIP_INSPECT):
				self._is_inspecting = true;
				self.mouse_filter = Control.MOUSE_FILTER_STOP;
				self.backdrop.visible = not self.is_nested_tooltip;
				self.inspect_tooltip.emit(self);
		else:
			if Input.is_action_just_pressed(INPUT_ACTION_TOOLTIP_EXIT):
				self._is_inspecting = false;
				self.mouse_filter = Control.MOUSE_FILTER_IGNORE;
				self.backdrop.visible = false;
				self.stop_inspect_tooltip.emit(self);
				if self._is_trying_to_exit or self.is_nested_tooltip:
					self.hide();
					self._is_trying_to_exit = false;
					if self._is_trying_to_free:
						self.queue_free();
	

#endregion Godot Methods

#region Public Methods

@abstract func setup(data: Resource) -> void;

func get_data(_breadcrumbs: Array[String], _index: int) -> Variant:
	# TODO: Get data
	return null;

func show_tooltip() -> void:
	self.show();

func fill_text(text: String) -> String:
	var regex: RegEx = RegEx.create_from_string("@\\[([a-zA-Z0-9][\\.a-zA-Z0-9]+)\\,\\s*\"([^\"]*)\"\\]");
	var entries: Array[RegExMatch] = regex.search_all(text);
	var converted: String = text;
	
	entries.reverse();
	for entry in entries:
		var breadcrumbs: Array[String] = entry.strings[1].split('.');
		
		for i in range(0, breadcrumbs.size()):
			breadcrumbs[i] = breadcrumbs[i].to_lower();
		var data: Variant = self.get_data(breadcrumbs, 0);
		var filled: String = entry.strings[2].replace("$", str(data));
		
		converted = converted.substr(0, entry.get_start()) + filled + converted.substr(entry.get_start() + entry.get_end() + 1);
	return converted;

#endregion Public Methods

#region Private Methods

func _try_to_enter() -> void: self._is_trying_to_exit = false;
func _try_to_exit() -> void: self._is_trying_to_exit = true;
func _try_to_hide() -> void:
	if self._is_inspecting: return;
	self.hide();

func _extract(data: Resource, property: String, default: Variant) -> Variant:
	if data == null: return default;
	if data.has_meta(property): return data.get_meta(property);
	
	var prop := data.get(property);
	
	if prop == null: return default;
	return prop;

func _position_tooltip() -> void:
	var border: Vector2 = self.get_viewport().get_visible_rect().size - self.padding;
	var pos: Vector2 = self._get_tooltip_position();
	var final_x: float = pos.x + self.offset.x;
	var final_y: float = pos.y + self.offset.y;
	
	if final_x + self._tooltip_size.x > border.x:
		final_x = pos.x - self.offset.x - self._tooltip_size.x;
	if final_y + self._tooltip_size.y > border.y:
		final_y = pos.y - self.offset.y - self._tooltip_size.y;
	self.container.position = Vector2(final_x, final_y);

func _get_tooltip_position() -> Vector2:
	if self.follow_mouse:
		return self.get_viewport().get_mouse_position();
	
	var pos: Vector2 = Vector2.ZERO;
	var parent: Node = self.get_parent();
	
	if parent is Node2D:
		pos = (parent as Node2D).get_global_transform_with_canvas().origin;
	elif parent is Control:
		pos = (parent as Control).get_global_transform_with_canvas().origin;
	return pos;

#endregion Private Methods
