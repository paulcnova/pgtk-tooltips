
class_name TooltipNode
extends Node

#region Properties

const META_TOOLTIP_DATA: String = "tooltip_data";
const PROPERTY_TOOLTIP_OFFSET: String = "tooltip_offset";
const PROPERTY_TOOLTIP_CATEGORY: String = "tooltip_category";
const NODE_NAME_TOOLTIP: String = "Tooltip";
const NODE_NAME_KILL_TIMER: String = "Kill Timer";
const SETTINGS_NAME_TOOLTIP_RES_PATH: String = "gui/tooltips/tooltip_res_path";
const SETTINGS_VALUE_TOOLTIP_RES_PATH: String = "res://interface/tooltips";
const SETTINGS_NAME_TOOLTIP_SUFFIX: String = "gui/tooltips/tooltip_suffix";
const SETTINGS_VALUE_TOOLTIP_SUFFIX: String = ".tooltip.tscn";

var _tooltip: TooltipUI;
var _delay_timer: Timer;
var _is_hovering: bool = false;

var has_ui: bool:
	get: return self._tooltip != null;

## Set to `true` to automatically hook signals on `_ready`.
@export var hook_signals_on_ready: bool = true;

## Set to `true` to have the tooltip follow the mouse.
@export var follow_mouse: bool = true;

## The default offset of the tooltip from the mouse/pointer to place it at.
## To override it, the data can have a variable/metadata named `tooltip_offset`.
@export var offset: Vector2 = Vector2(24.0, -16.0);

## The amount of time to delay before showing the tooltip,
## this is to give the engine enough time to instantiate and
## place the tooltip before rendering it, as it will cause some glitching.
@export var delay_duration: float = 0.0;

## The data of the tooltip. For best practice, have the parent node hold
## the tooltip's data in a metadata named `tooltip_data`; this is so that
## the parent and any other object can manipulate the data much easier.
## This variable is here in case it's not guaranteed to have a metadata.
## This will be checked first, as it can be set in-editor easily.
@export var tooltip_data: Resource;
@export var tooltip_data_path: String;

#endregion Properties

#region Godot Methods

func _ready() -> void:
	if self.hook_signals_on_ready:
		if not self._hook_to_signal():
			printerr("Nothing was connected, please use this node on a Control, CollisionObject2D, or CollisionObject3D");
			self.queue_free();
			return;
	self._delay_timer = Timer.new();
	self._delay_timer.timeout.connect(self.show_tooltip);
	self.add_child(self._delay_timer);

#endregion // Godot Methods

#region Public Methods

func show_tooltip() -> void:
	if self._tooltip == null:
		return;
	if not self._delay_timer.is_stopped():
		return;
	self._delay_timer.stop();
	self._tooltip.show_tooltip();

func hide_tooltip() -> void:
	if self._tooltip == null:
		return;
	self._delay_timer.stop();
	self._tooltip.hide();

func get_data() -> Resource:
	if self.tooltip_data != null: return self.tooltip_data;
	if self.tooltip_data_path != null and self.tooltip_data_path != "":
		if ResourceLoader.exists(self.tooltip_data_path):
			var data := load(self.tooltip_data_path);
			
			if data != null: return data;
	
	var parent := self.get_parent();
	
	if parent == null or not parent.has_meta(META_TOOLTIP_DATA):
		return null;
	return parent.get_meta(META_TOOLTIP_DATA);

func instantiate_tooltip() -> void:
	if self.has_node(NODE_NAME_TOOLTIP):
		self._tooltip = self.get_node(NODE_NAME_TOOLTIP);
		(self._tooltip.get_node(NODE_NAME_KILL_TIMER) as Timer).stop();
		
		var data := self.get_data();
		
		self._tooltip.setup(data);
		
		return;
	
	var data := self.get_data();
	var tooltip := _instantiate((
		ProjectSettings.get_setting(SETTINGS_NAME_TOOLTIP_RES_PATH, SETTINGS_VALUE_TOOLTIP_RES_PATH)
		+ self._extract(data, PROPERTY_TOOLTIP_CATEGORY, "basic")
		+ ProjectSettings.get_setting(SETTINGS_NAME_TOOLTIP_SUFFIX, SETTINGS_VALUE_TOOLTIP_SUFFIX)
	)) as TooltipUI;
	
	if tooltip == null:
		tooltip = _instantiate("res://addons/pgtk_tooltips/basic.tooltip.tscn") as TooltipUI;
	
	if tooltip == null:
		printerr("General Tooltip prefab doesn't exist: could not create tooltip");
		push_warning("General Tooltip prefab doesn't exist: could not create tooltip");
		return;
	tooltip.top_level = true;
	tooltip.name = NODE_NAME_TOOLTIP;
	
	var kill_timer := Timer.new();
	
	kill_timer.timeout.connect(func(): tooltip.queue_free());
	kill_timer.name = NODE_NAME_KILL_TIMER;
	tooltip.add_child(kill_timer);
	
	tooltip.setup(data);
	
	self.add_child(tooltip, true);
	self._tooltip = tooltip;

#endregion Public Methods

#region Private Methods

func _hook_to_signal() -> bool:
	var parent := self.get_parent();
	var is_hooked := false;
	
	if parent is Control or parent is CollisionObject2D or parent is CollisionObject3D:
		parent.mouse_entered.connect(self._on_entered);
		parent.mouse_exited.connect(self._on_exited);
		is_hooked = true;
	if parent is RigidBody3D or parent is RigidBody2D:
		parent.sleeping_state_changed.connect(self._on_sleep_state_changed);
	
	return is_hooked;

func _on_entered() -> void:
	self._is_hovering = true;
	# if TooltipNode.inspecting_tooltip != null: return;
	if self._is_moving_rigid_body(): return;
	if self._tooltip == null:
		self.instantiate_tooltip();
	else:
		var data := self.get_data();
		
		self._tooltip.setup(data);
	if self._tooltip._is_inspecting:
		self._tooltip._try_to_enter();
		return;
	if self.delay_duration > 0.0:
		self._delay_timer.start(self.delay_duration);
	else:
		self.show_tooltip();

func _on_exited() -> void:
	self._is_hovering = false;
	
	if self._tooltip == null: return;
	
	if self._is_moving_rigid_body(): return;
	if self._tooltip._is_inspecting:
		self._tooltip._try_to_exit();
		return;
	self._delay_timer.stop();
	self._tooltip._try_to_hide();
	if self._tooltip.has_node(NODE_NAME_KILL_TIMER):
		(self._tooltip.get_node(NODE_NAME_KILL_TIMER) as Timer).start(10.0);
		self._tooltip = null;

func _extract(data: Resource, property: String, default: Variant) -> Variant:
	if data == null: return default;
	if data.has_meta(property): return data.get_meta(property);
	
	var prop := data.get(property);
	
	if prop == null: return default;
	return prop;

func _on_sleep_state_changed() -> void:
	var parent := self.get_parent();
	
	if parent.sleeping and self._is_hovering:
		self._on_entered();

func _is_moving_rigid_body() -> bool:
	var parent := self.get_parent();
	
	if parent is RigidBody3D or parent is RigidBody2D:
		return not parent.sleeping;
	return false;

static func _instantiate(path: String) -> Node:
	if not ResourceLoader.exists(path): return null;
	var scene := ResourceLoader.load(path) as PackedScene;
	
	if scene == null: return null;
	return scene.instantiate();


#endregion Private Methods
