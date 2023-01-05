@tool
extends Container
class_name AllTabContainer

@export var panel_bg : StyleBox = null
@export var tab_bg : StyleBox = null
@export var tab_inactive_bg : StyleBox = null

var panel : Panel = null
func _ready():
    var i = 0
    for _child in get_children():
        if _child == panel:
            continue
        var child : Node = _child
        var button = Button.new()
        button.text = child.name
        button_tabs[button] = child
        button.connect("pressed", self._button_pressed.bind(button))
        add_child(button)
        move_child(button, i)
        i += 1
    
    if i > 0:
        active_button = button_tabs.keys()[0]
    
    panel = Panel.new()
    panel.add_theme_stylebox_override("panel", panel_bg)
    add_child(panel)
    move_child(panel, 0)

var button_tabs = {}
var active_button = null

func _button_pressed(which):
    active_button = which
    for _child in get_children():
        var child : Node = _child
        if child in button_tabs or child == panel:
            continue
        child.visible = child == button_tabs[active_button]

func _process(delta):
    for _button in button_tabs.keys():
        var button : Button = _button
        if button == active_button:
            button.add_theme_color_override("font_color", Color(0.88, 0.88, 0.88, 1))
            button.add_theme_stylebox_override("normal", tab_bg)
            button.add_theme_stylebox_override("hover", tab_bg)
            button.add_theme_stylebox_override("focus", tab_bg)
            button.add_theme_stylebox_override("pressed", tab_bg)
            button.add_theme_stylebox_override("disabled", tab_bg)
        else:
            button.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75, 1))
            button.add_theme_stylebox_override("normal", tab_inactive_bg)
            button.add_theme_stylebox_override("hover", tab_inactive_bg)
            button.add_theme_stylebox_override("focus", tab_inactive_bg)
            button.add_theme_stylebox_override("pressed", tab_inactive_bg)
            button.add_theme_stylebox_override("disabled", tab_inactive_bg)
    
func _notification(what):
    var margin_left = panel_bg.get_margin(SIDE_LEFT)
    var margin_right = panel_bg.get_margin(SIDE_RIGHT)
    var margin_top = panel_bg.get_margin(SIDE_TOP)
    var margin_bottom = panel_bg.get_margin(SIDE_BOTTOM)
    
    if what == NOTIFICATION_SORT_CHILDREN:
        var width = size.x
        for _child in get_children():
            var child : Node = _child
            if child in button_tabs or child == panel:
                continue
            if child.visible:
                width = child.size.x
        
        var cursor_x = 0
        var cursor_y = 0
        
        var row_height = 0
        for _button in button_tabs.keys():
            var button : Button = _button
            var child_size = button.get_minimum_size()
            row_height = max(child_size.y, row_height)
            var over_size = false
            var done_wrap = false
            if child_size.x + cursor_x > size.x and cursor_x > 0:
                cursor_y += row_height
                cursor_x = 0
                done_wrap = true
            button.position = Vector2(cursor_x, cursor_y)
            cursor_x += child_size.x
            if cursor_x > size.x and !done_wrap:
                cursor_y += row_height
                cursor_x = 0
        
        cursor_y += row_height
        
        for _child in get_children():
            var child : Node = _child
            if child in button_tabs or child == panel:
                continue
            fit_child_in_rect(child, Rect2(margin_left, cursor_y + margin_top, size.x, 0))
            if child.visible:
                size.y = cursor_y + child.size.y
                size.x = child.size.x
        
        if panel:
            panel.position = Vector2(0, cursor_y)
            panel.size = Vector2(size.x + margin_left + margin_right, size.y - cursor_y + margin_top + margin_bottom)
            panel.show_behind_parent = true

