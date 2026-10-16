#include "api.hpp"

static float smoothness = 0.9f;

SANDBOXED_PROPERTIES(1, {
	.name = "smoothness",
	.type = Variant::FLOAT,
	.getter = []() -> Variant { return smoothness; },
	.setter = [](Variant value) -> Variant { smoothness = value; return smoothness; },
	.default_value = smoothness,
});

static Transform3D last_transform = Transform3D::identity();

extern "C" Variant _process_parent_child(double delta, Node3D parent, Node3D child) {
	if (is_editor_hint()) {
		return Nil;
	}

	Transform3D parent_transform = parent.get_transform();
	last_transform = last_transform.interpolate_with(parent_transform, smoothness);
	last_transform.set_basis(parent_transform.get_basis().slerp(last_transform.get_basis(), smoothness / 2));
	child.set_transform(last_transform);

	return Nil;
}

int main() {
	ADD_API_FUNCTION(_process_parent_child, "void", "double delta, Node3D parent, Node3D child", "Makes the plane smoothly follow the camera direction");
	halt();
}
