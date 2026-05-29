
class_name NestedTooltipRichTextLabel
extends RichTextLabel

#region Godot Methods

func _ready() -> void:
	self.meta_hover_started.connect(self._on_link_hover_started);
	self.meta_hover_ended.connect(self._on_link_hover_ended);

#endregion Godot Methods

#region Private Methods

func _is_appropriate_link(meta: Variant) -> bool:
	var text := str(meta);
	
	return (
		text.begins_with("res://")
		or text.begins_with("user://")
		or text.begins_with("mod://")
	);

func _on_link_hover_started(meta: Variant) -> void:
	if not self._is_appropriate_link(meta): return;
	
	var id: String = self._identify(meta);
	
	if not self.has_node(id):
		var tooltip_node := TooltipNode.new();
		
		tooltip_node.hook_signals_on_ready = false;
		tooltip_node.tooltip_data_path = meta;
		tooltip_node.name = id;
		tooltip_node._is_nested = true;
		self.add_child(tooltip_node, true);
	
	var tooltip := self.get_node(id) as TooltipNode;
	
	if not tooltip.has_ui: tooltip.instantiate_tooltip();
	if not tooltip.is_inspecting:
		tooltip.show_tooltip();

func _on_link_hover_ended(meta: Variant) -> void:
	var id: String = self._identify(meta);
	
	if self.has_node(id):
		var tooltip := self.get_node(id) as TooltipNode;
		
		if not tooltip.is_inspecting:
			tooltip.hide_tooltip();

func _identify(meta: Variant) -> String:
	var text := str(meta);
	return text.replace_chars("\\/:.", '-'.unicode_at(0));

#endregion Private Methods
