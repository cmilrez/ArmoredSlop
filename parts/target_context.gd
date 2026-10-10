class_name TargetContext extends RefCounted

var list: Array[Character3D] = []
var index := -1
var tracker: Tracker3D = null

func duplicate() -> TargetContext:
	var copy = TargetContext.new()
	copy.list = self.list.duplicate()
	copy.index = self.index
	copy.tracker = self.tracker
	return copy
