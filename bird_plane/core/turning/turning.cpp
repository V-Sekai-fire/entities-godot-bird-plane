#include "api.hpp"

const double sensitivity = 1.0;

extern "C" Variant _input_plane(Object input, Node3D plane, Vector2 input_mouse_speed) {
	if (is_editor_hint()) {
		return Nil;
	}

	Vector2 rel = input.get("relative");
	Vector2 mouse_speed = input_mouse_speed.lerp(rel / Vector2(1000), sensitivity);
	plane.call("rotate_object_local", Vector3(1, 0, 0), mouse_speed.y);
	plane.call("rotate_object_local", Vector3(0, 0, 1), mouse_speed.x);

	return Nil;
}

int main() {
	ADD_API_FUNCTION(_input_plane, "void", "InputEventMouseMotion input, Node3D plane, Vector2 input_mouse_speed", "Makes the control plane follow mouse movement smoothly");
	halt();
}
