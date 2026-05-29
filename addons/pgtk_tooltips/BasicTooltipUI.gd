
class_name BasicTooltipUI
extends TooltipUI

#region Public Methods

func setup(data: Resource) -> void:
	self.tooltip_name.text = self.fill_text(data.get("name"));
	self.tooltip_description.text = self.fill_text(data.get("desc"));

#endregion Public Methods
