
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
var associated_node: TooltipNode = null;

## The backdrop to be used (if TooltipLayer is disabled as an autoload).
@export var backdrop: ColorRect;

## The actual container of the tooltip.
@export var container: PanelContainer;

## The top label of the tooltip, typically the `name` of the resource.
@export var tooltip_name: Label;

## The text of the tooltip, typically the `description` of the resource.
@export var tooltip_description: RichTextLabel;

@export_group("Tooltip Settings")
## Set to `true` to have the tooltip follow the mouse around.
@export var follow_mouse: bool = true;
## The offset of the tooltip relative to the mouse/pointer.
@export var offset: Vector2 = Vector2(24.0, -16.0);
## The padding of the edges of the screen to ensure a safe distance to pivot the tooltip around.
@export var padding: Vector2 = 32.0 * Vector2.ONE;
## The duration in which to fade in the tooltip.
@export var fade_in_duration: float = 0.15;

## Returns `true` if the tooltip is currently being inspected.
var is_inspecting: bool:
	get: return self._is_inspecting;

## Returns `true` if the tooltip is nested within another tooltip.
var is_nested_tooltip: bool:
	get: return self.associated_node != null and self.associated_node._is_nested;

## A signal emitted when the player inspects this tooltip.
signal inspect_tooltip(tooltip: TooltipUI);

## A signal emitted when the player stops inspecting this tooltip.
signal stop_inspect_tooltip(tooltip: TooltipUI);

#endregion Properties

#region Godot Methods

func _ready() -> void:
	self.mouse_filter = Control.MOUSE_FILTER_IGNORE;
	self.backdrop.visible = false;
	self.container.reset_size();
	self._tooltip_size = self.container.get_rect().size;
	self._position_tooltip();

func _process(delta: float) -> void:
	if not self._is_inspecting:
		self.container.reset_size();
		self._tooltip_size = self.container.get_rect().size;
		self._position_tooltip();
	if self.visible:
		self._tooltip_size = self.container.get_rect().size;
		if not self._is_inspecting:
			if Input.is_action_just_pressed(INPUT_ACTION_TOOLTIP_INSPECT):
				self._is_inspecting = true;
				self.mouse_filter = Control.MOUSE_FILTER_STOP;
				if TooltipLayer != null:
					TooltipLayer.show_backdrop();
				else:
					self.backdrop.visible = not self.is_nested_tooltip;
				self.inspect_tooltip.emit(self);
		else:
			if Input.is_action_just_pressed(INPUT_ACTION_TOOLTIP_EXIT):
				self._is_inspecting = false;
				self.mouse_filter = Control.MOUSE_FILTER_IGNORE;
				if TooltipLayer != null:
					TooltipLayer.hide_backdrop();
				self.backdrop.visible = false;
				self.stop_inspect_tooltip.emit(self);
				if self._is_trying_to_exit or self.is_nested_tooltip:
					self.hide();
					self._is_trying_to_exit = false;
					if self._is_trying_to_free or self.is_nested_tooltip:
						self.queue_free();
	

#endregion Godot Methods

#region Public Methods

## Sets up the UI by updating the controls with whatever data is found in the resource.
## [br]
## - [param data]: The resource used to setup with.[br]
@abstract func setup(data: Resource) -> void;

## Gets global/external data to be used within the setup, this is part
## of the [method fill_text] workflow and should be updated to fit
## individual projects as it's meant to be very granular.
## [br]
## - [param _breadcrumbs]: The list of object names (in full) that the text is requesting.[br]
## - [param _index]: The current index in which the function is viewing the [param _breadcrumbs].[br]
func get_data(_breadcrumbs: Array[String], _index: int) -> Variant:
	# TODO: Get data
	return null;

## Displays the tooltip to the player.
func show_tooltip() -> void:
	self.fade_in();
	self.container.reset_size();
	self._tooltip_size = self.container.get_rect().size;
	self._position_tooltip();
	self.show();

## Fades the tooltip onto the screen.
func fade_in() -> void:
	if fade_in_duration <= 0.0: return;
	
	var tween := self.create_tween();
	var color = self.modulate;
	
	self.modulate.a = 0.0;
	tween.tween_property(self, "modulate", color, fade_in_duration);

## Fills in the text that the dev was searching for. This is meant to dynamically change the data
## for very contextual reasons. Returns an updated filled-in version of the text.
## [br][br]
## For example, if there are two characters at different skill levels; when the
## player views an item or action, the values should change between characters
## because of the skill differences. This function is how it's achieved.
## [br][br]
## To utilize this function, the text must contain the following format:
## @[lb]<object.name.like.code>[rb]. For example, @[lb]char.speed[rb] will fill
## in the character's speed directly. If it needs to revolve around text then the
## following format can be used: @[lb]<object.name.like.code>, "Text -- $ means the fill data"[rb]
## For example, @[lb]char.speed, "$ ft"[rb] will fill in as "25 ft" if the character's speed is 25.
## [br]
## - [param text]: The text to fill in.
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
