extends Node2D
class_name Entity

# --- Signals ---
## Fired whenever a component is discovered/added/removed, so other systems can react.
signal component_added(component: Node)
signal component_removed(component: Node)

# --- Component Registry ---
## Stores child components by their class_name (e.g., "HealthComponent" -> Node)
var components: Dictionary = {} # Key: class_name(String), Value: Node

# --- Methods ---

func _ready() -> void:
    _collect_components()

## Collect all existing children that are components.
## Called on _ready so editor-placed components are registered automatically.
func _collect_components() -> void:
    components.clear()
    for child in get_children():
        if _is_component(child):
            components[child.get_class()] = child
            child._on_entity_ready(self)
            emit_signal("component_added", child)

## Public API: check if a component of a given class name exists.
func has_component(type_name: String) -> bool:
    return components.has(type_name)

## Public API: fetch a component by its class name.
## Example: var health := entity.get_component("HealthComponent") as HealthComponent
func get_component(type_name: String) -> Node:
    return components.get(type_name, null)

## Public API: fetch multiple components by their class names.
## Example: var comps := entity.get_components(["HealthComponent", "InventoryComponent"])
func get_components(type_names: Array) -> Array:
    var result: Array[Node] = []
    for type_name in type_names:
        if components.has(type_name):
            result.append(components[type_name])
    return result

## Public API: add a component at runtime and register it.
## You can pass in a newly instantiated Node with a *Component script attached.
func add_component(component: Node) -> void:
    add_child(component)
    if _is_component(component):
        components[component.get_class()] = component
        component._on_entity_ready(self) # Notify component of its entity.
        component_added.emit(component)

## Public API: remove a component (does not free it; you may queue_free() yourself).
func remove_component(type_name: String) -> void:
    if components.has(type_name):
        var component: Node = components[type_name]
        remove_child(component)
        components.erase(type_name)
        component_removed.emit(component)

## Internal helper: "Is this node a component?"
## Convention-based: any Node who has the method "_on_entity_ready" is considered a component.
func _is_component(node: Node) -> bool:
    return node.has_method("_on_entity_ready")