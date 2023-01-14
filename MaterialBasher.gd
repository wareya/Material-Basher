extends Control

var normal_image : Image
var normal : ImageTexture

var depth_image : Image
var depth : ImageTexture

var metal_image : Image
var metal : ImageTexture

var roughness_image : Image
var roughness : ImageTexture

var ao_image : Image
var ao : ImageTexture

var albedo_image : Image
var albedo_image_display : Image
var albedo : ImageTexture
var albedo_display : ImageTexture

var mat_3d = SpatialMaterial.new()
var mat_texture = preload("res://resources/UnshadedPlain.material")

var wrapping_enabled = false

func set_uv_scale(scale : Vector3):
    mat_3d.flags_transparent = true
    mat_3d.uv1_scale = scale
    mat_texture.set_shader_param("uv1_scale", mat_3d.uv1_scale)
    mat_texture.set_shader_param("uv1_offset", mat_3d.uv1_offset)

func config_reset_to_default():
    $Tabs/Config/HSlider.value = 50
    $Tabs/Config/HSlider4.value = 100
    $Tabs/Config/HSlider2.value = 100
    $Tabs/Config/HSlider2.value = 25
    $Tabs/Config/CheckButton.pressed = false

onready var _option_connections = {
    $"Tabs/Ambience"   : "sky_option_picked",
    $"Tabs/Normal Map" : "normal_option_picked",
    $"Tabs/Depth Map"  : "depth_option_picked",
}
onready var _button_connections = {
    $"Tabs/Normal Map" : "normal_freq_preset",
    $"Tabs/Depth Map" : "depth_freq_preset",
}
onready var _range_connections = {
    $"Tabs/Normal Map" : "normal_slider_changed",
    $"Tabs/Depth Map" : "depth_slider_changed",
    $"Tabs/Metal Map" : "metal_slider_changed",
    $"Tabs/Roughness Map" : "roughness_slider_changed",
    $"Tabs/AO Map" : "ao_slider_changed",
    $"Tabs/Shading Remover" : "light_remover_slider_changed",
}

func visit_controls(node : Node):
    if node is OptionButton:
        for page in _option_connections.keys():
            if page.is_a_parent_of(node):
                node.connect("item_selected", self, _option_connections[page][0])
    elif node is Button and node.get_class() == "Button":
        for page in _button_connections.keys():
            if page.is_a_parent_of(node):
                var fn = _button_connections[page]
                node.connect("pressed", self, fn, [node.name.to_lower().split(" ")[0]])
                break
    elif node is Range:
        for page in _range_connections.keys():
            if page.is_a_parent_of(node):
                var fn = _range_connections[page]
                node.connect("value_changed", self, fn)
                break
    
    for child in node.get_children():
        visit_controls(child)

func _ready():
    # TODO: settings for diffuse/specular model etc
    # TODO: normal lighting removal
    # TODO: gradient removal
    # TODO: depth vs height vs displacement setting
    # TODO: save/load parameters to json
    
    # first-time model setup
    set_uv_scale(Vector3(2, 1, 1))
    $"3D/MeshHolder/Mesh".material_override = mat_3d
    $"3D/MeshHolder/Mesh".global_rotation.y += 1.5
    
    # finish building controls
    
    $"Tabs/Normal Map/OptionButton".add_item("Grey")
    $"Tabs/Normal Map/OptionButton".add_item("Red")
    $"Tabs/Normal Map/OptionButton".add_item("Green")
    $"Tabs/Normal Map/OptionButton".add_item("Blue")
    $"Tabs/Normal Map/OptionButton".add_item("Yellow")
    
    $"Tabs/Depth Map/OptionButton".add_item("Grey")
    $"Tabs/Depth Map/OptionButton".add_item("Red")
    $"Tabs/Depth Map/OptionButton".add_item("Green")
    $"Tabs/Depth Map/OptionButton".add_item("Blue")
    $"Tabs/Depth Map/OptionButton".add_item("Yellow")
    
    $Tabs/Ambience/HBoxContainer3/OptionButton.add_item("Procedural")
    $Tabs/Ambience/HBoxContainer3/OptionButton.add_item("Office")
    $Tabs/Ambience/HBoxContainer3/OptionButton.add_item("Sunset")
    
    for button in $Tabs/Export/GridContainer.get_children():
        if not button is OptionButton:
            continue
        button.add_item("Metallicity")
        button.add_item("Roughness")
        button.add_item("AO")
        button.add_item("Depth")
    $Tabs/Export/GridContainer/OptionButton.selected = 0
    $Tabs/Export/GridContainer/OptionButton2.selected = 1
    $Tabs/Export/GridContainer/OptionButton3.selected = 2
    
    $Tabs/Config/OptionButton.add_item("Burley")
    $Tabs/Config/OptionButton.add_item("Lambert")
    $Tabs/Config/OptionButton.add_item("Lambert Wrap")
    $Tabs/Config/OptionButton.add_item("Oren Nayar")
    $Tabs/Config/OptionButton.selected = 0
    
    # connect generic control signals
    
    visit_controls(self)
    
    # non-generic control signals
    
    $PopupDialog/VBoxContainer/CenterContainer/Button.connect("pressed", $PopupDialog, "hide")
    
    $Tabs/Export/Button.connect("pressed", self, "save_albedo")
    $Tabs/Export/Button2.connect("pressed", self, "save_normal")
    $Tabs/Export/Button3.connect("pressed", self, "save_pbr")
    
    $"Tabs/Depth Map/CheckBox" .connect("pressed", self, "depth_slider_changed",  [0.0])
    $"Tabs/Normal Map/CheckBox".connect("pressed", self, "normal_slider_changed", [0.0])
    $"Tabs/Metal Map/CheckBox".connect("pressed", self, "metal_slider_changed", [0.0])
    $"Tabs/Roughness Map/CheckBox".connect("pressed", self, "roughness_slider_changed", [0.0])
    
    $ToggleMat.connect("pressed", self, "toggle_mat")
    $ToggleAlbedo.connect("pressed", self, "show_albedo")
    $ToggleUI.connect("pressed", self, "toggle_ui")
    get_tree().connect("files_dropped", self, "files_dropped")
    
    $"Tabs/Ambience/ColorPicker".connect("color_changed", self, "color_changed", ["ambient"])
    $"Tabs/Light/ColorPicker".connect("color_changed", self, "color_changed", ["light"])
    
    $Tabs/Light/HBoxContainer/HSlider.connect("value_changed", self, "light_angle_update")
    $Tabs/Light/HBoxContainer2/HSlider.connect("value_changed", self, "light_rotation_update")
    
    $Tabs/Shape/HBoxContainer/HSlider.connect("value_changed", self, "shape_rotation_update")
    $Tabs/Shape/HBoxContainer3/HSlider.connect("value_changed", self, "shape_slant_update")
    $Tabs/Shape/HBoxContainer2/HSlider.connect("value_changed", self, "shape_size_update")
    
    $"Tabs/Metal Map/Button".connect("pressed", self, "start_picking_color", ["metal", -1])
    $"Tabs/Roughness Map/Button".connect("pressed", self, "start_picking_color", ["roughness", -1])
    
    $Tabs/Shape/Button.connect("pressed", self, "set_mesh", ["sphere"])
    $Tabs/Shape/Button2.connect("pressed", self, "set_mesh", ["cube"])
    $Tabs/Shape/Button3.connect("pressed", self, "set_mesh", ["cylinder"])
    $Tabs/Shape/Button4.connect("pressed", self, "set_mesh", ["sideways cylinder"])
    $Tabs/Shape/Button5.connect("pressed", self, "set_mesh", ["plane"])
    $Tabs/Shape/Button7.connect("pressed", self, "set_mesh", ["plane slanted"])
    
    $Tabs/Config/Button.connect("pressed", self, "reset_view")
    
    $Tabs/Config/OptionButton.connect("item_selected", self, "set_diffuse_mode")

func set_diffuse_mode(which : int):
    mat_3d.params_diffuse_mode = which

var NativeDialog = preload("res://addons/native_dialogs/native_dialogs.gd")

func save_albedo():
    var fname_parts = loaded_fname.split(".")
    if fname_parts.size() >= 2:
        #fname_parts[-2] = fname_parts[-2] + "_albedo"
        fname_parts[-1] = "png"
    else:
        fname_parts[-1] += ".png"
    var fname = fname_parts.join(".")
    
    save_image(albedo_image_display, fname, "Albedo", "Albedo cannot be saved until an image has been loaded.")

func save_normal():
    var fname_parts = loaded_fname.split(".")
    if fname_parts.size() >= 2:
        fname_parts[-2] = fname_parts[-2] + "_n"
        fname_parts[-1] = "png"
    else:
        fname_parts[-1] += ".png"
    var fname = fname_parts.join(".")
    
    var save_image : Image = normal_image
    if $Tabs/Export/CheckBox.pressed:
        save_image = normal_image.duplicate()
        var size = save_image.get_size()
        save_image.lock()
        for y in size.y:
            for x in size.x:
                var r = save_image.get_pixel(x, y).r
                var g = save_image.get_pixel(x, y).g
                var b = save_image.get_pixel(x, y).b
                g = 1.0-g
                save_image.set_pixel(x, y, Color(r, g, b))
        save_image.unlock()
    save_image(save_image, fname, "Normal", "Normal cannot be saved until an albedo has been loaded.")

func pbr_pick_image(selection):
    if selection == 0:
        return metal_image
    elif selection == 1:
        return roughness_image
    elif selection == 2:
        return ao_image
    elif selection == 3:
        return depth_image

func save_pbr():
    var fname_parts = loaded_fname.split(".")
    if fname_parts.size() >= 2:
        fname_parts[-2] = fname_parts[-2] + "_spec"
        fname_parts[-1] = "png"
    else:
        fname_parts[-1] += ".png"
    var fname = fname_parts.join(".")
    
    var size = albedo_image.get_size()
    var image = Image.new()
    image.create(size.x, size.y, false, Image.FORMAT_RGB8)
    var red = pbr_pick_image($Tabs/Export/GridContainer/OptionButton.selected)
    var green = pbr_pick_image($Tabs/Export/GridContainer/OptionButton2.selected)
    var blue = pbr_pick_image($Tabs/Export/GridContainer/OptionButton3.selected)
    if !red or !green or !blue:
        $PopupDialog/VBoxContainer/Label.text = "PBR map cannot be saved until an albedo has been loaded."
        $PopupDialog.show()
        return
    
    image.lock()
    red.lock()
    if green != red:
        green.lock()
    if blue != green and blue != red:
        blue.lock()
    for y in size.y:
        for x in size.x:
            var r = red.get_pixel(x, y).r
            var g = green.get_pixel(x, y).r
            var b = blue.get_pixel(x, y).r
            if $Tabs/Export/GridContainer/CheckBox.pressed:
                if red == roughness_image:
                    r = 1.0 - r
                if green == roughness_image:
                    g = 1.0 - g
                if blue == roughness_image:
                    b = 1.0 - b
            image.set_pixel(x, y, Color(r, g, b))
    save_image(image, fname, "PBR", "")
    
    image.unlock()
    red.unlock()
    if green != red:
        green.unlock()
    if blue != green and blue != red:
        blue.unlock()

func save_tga(image : Image, fname : String):
    var bytes = PoolByteArray()
    bytes.append(0) # id field length (no id field)
    bytes.append(0) # color map type (none)
    
    bytes.append(2) # uncompressed rgb
    
    bytes.append(0) # color map stuff (blank)
    bytes.append(0) # color map stuff (blank)
    bytes.append(0) # color map stuff (blank)
    bytes.append(0) # color map stuff (blank)
    bytes.append(0) # color map stuff (blank)
    
    bytes.append(0) # x origin
    bytes.append(0) # x origin
    bytes.append(0) # y origin
    bytes.append(0) # y origin
    
    var w = image.get_width()
    var h = image.get_height()
    
    bytes.append(w & 0xFF)
    bytes.append((w>>8) & 0xFF)
    
    bytes.append(h & 0xFF)
    bytes.append((h>>8) & 0xFF)
    
    bytes.append(32)
    
    bytes.append(8)
    
    image.lock()
    for y in h:
        for x in w:
            var color = image.get_pixel(x, h-y-1)
            bytes.append(color.b8)
            bytes.append(color.g8)
            bytes.append(color.r8)
            bytes.append(color.a8)
    image.unlock()
    
    var f = File.new()
    f.open(fname, File.WRITE)
    
    f.store_buffer(bytes)
    f.close()

func save_image(image : Image, default_fname : String, name_caps : String, error_text : String):
    if image == null:
        $PopupDialog/VBoxContainer/Label.text = error_text
        $PopupDialog.show()
        return
    
    var fo : Control = get_focus_owner()
    if fo:
        fo.release_focus()
    
    $NativeDialogSaveFile.filters = PoolStringArray(["*.png, *.tga; Supported Images"])
    $NativeDialogSaveFile.initial_path = default_fname
    $NativeDialogSaveFile.title = "Save %s Image" % [name_caps]
    $NativeDialogSaveFile.show()
    
    var fname = yield($NativeDialogSaveFile, "file_selected")
    if fname == "":
        return
    
    if !fname.ends_with(".tga") and !fname.ends_with(".png"):
        fname += ".png"
    
    if fname.ends_with(".tga"):
        save_tga(image, fname)
    elif fname.ends_with(".png"):
        image.save_png(fname)
        

func reset_view():
    $"3D/CameraHolder".global_translation = Vector3()
    $"3D/CameraHolder".rotation = Vector3()
    zoom = 0
    $"3D/CameraHolder/Camera".translation.z = 3 * pow(2, -zoom/16.0 * 1.3)

func color_changed(new_color : Color, which : String):
    if which == "ambient":
        $"3D/WorldEnvironment".environment.ambient_light_color = new_color
    elif which == "light":
        $"3D/LightHolder/DirectionalLight".light_color = new_color

func toggle_mat():
    if $"3D/MeshHolder/Mesh".material_override == mat_3d:
        $"3D/MeshHolder/Mesh".material_override = mat_texture
    else:
        $"3D/MeshHolder/Mesh".material_override = mat_3d

var albedo_shown = false
func show_albedo():
    if albedo_image:
        if !albedo_shown:
            var texture = ImageTexture.new()
            texture.create_from_image(albedo_image)
            $TextureRect.texture = texture
            albedo_shown = true
            $TextureRect.visible = true
        else:
            albedo_shown = false
            $TextureRect.visible = false

func toggle_ui():
    $Tabs.visible = !$Tabs.visible
    $PanelContainer.visible = $Tabs.visible
    $Warnings.visible = $Tabs.visible
    $ToggleMat.visible = $Tabs.visible
    $ToggleAlbedo.visible = $Tabs.visible
    $TextureRect.visible = $Tabs.visible and albedo_shown

var loaded_fname : String
func files_dropped(files : PoolStringArray, _screen : int):
    var fname : String = files[0]
    
    var file = File.new()
    file.open(fname, File.READ)
    var buffer = file.get_buffer(file.get_len())
    
    var image = Image.new()
    fname = fname.to_lower()
    if fname.ends_with(".bmp"):
        image.load_bmp_from_buffer(buffer)
    elif fname.ends_with(".png"):
        image.load_png_from_buffer(buffer)
    elif fname.ends_with(".jpg") or fname.ends_with(".jpeg"):
        image.load_jpg_from_buffer(buffer)
    elif fname.ends_with(".tga"):
        image.load_tga_from_buffer(buffer)
    elif fname.ends_with(".webp"):
        image.load_webp_from_buffer(buffer)
    elif fname.ends_with(".obj"):
        var f = File.new()
        f.open(fname, File.READ)
        var text = f.get_as_text()
        $"3D/MeshHolder/Mesh".mesh = ObjLoader.parse_obj(text)
        set_uv_scale(Vector3(1,1,1))
        $"3D/MeshHolder/Mesh".scale = Vector3(1,1,1)
        $"3D/MeshHolder/Mesh".rotation_degrees.x = 0
        $Tabs/Shape/HBoxContainer2/HSlider.value = 10 * $"3D/MeshHolder/Mesh".scale.x
        $Tabs/Shape/HBoxContainer3/HSlider.value = $"3D/MeshHolder/Mesh".rotation_degrees.x
        return
    else:
        return
    
    loaded_fname = fname
    
    albedo_image = image
    albedo = ImageTexture.new()
    albedo.create_from_image(albedo_image)
    
    albedo_image_display = albedo_image.duplicate()
    albedo_display = ImageTexture.new()
    albedo_display.create_from_image(albedo_image_display)
    albedo_display.flags |= ImageTexture.FLAG_ANISOTROPIC_FILTER
    
    mat_3d.albedo_texture = albedo_display
    
    no_recurse = true
    normal_slider_changed(0.0)
    depth_slider_changed(0.0)
    metal_slider_changed(0.0)
    roughness_slider_changed(0.0)
    ao_slider_changed(0.0)
    light_remover_slider_changed(0.0)
    no_recurse = false

var no_recurse

var setting_sliders = false
func normal_freq_preset(mode : String):
    for enemy in get_tree().get_nodes_in_group("Enemy"):
        enemy.connect("enemy_dead", self, "notify_enemy_dead")
    get_local_mouse_position()
    var array = {
        "flat"   : [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
        "smooth" : [1.0, 0.8, 0.6, 0.4, 0.2, 0.0, 0.0],
        "rough"  : [0.0, 0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
        "fuzzy"  : [1.0, 0.67, 0.33, 0.0, 0.33, 0.67, 1.0],
        "mids"   : [0.0, 0.33, 0.67, 1.0, 0.67, 0.33, 0.0],
        "zero"   : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    }[mode]
    
    var list = $"Tabs/Normal Map/Freqs".get_children()
    setting_sliders = true
    for i in array.size():
        var val = array[i]
        var slider : Range = list[i]
        slider.value = slider.max_value * val
    setting_sliders = false
    normal_slider_changed(0.0)

func depth_freq_preset(mode : String):
    var array = {
        "flat"   : [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
        "smooth" : [1.0, 0.8, 0.6, 0.4, 0.2, 0.0, 0.0],
        "rough"  : [0.0, 0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
        "fuzzy"  : [1.0, 0.67, 0.33, 0.0, 0.33, 0.67, 1.0],
        "mids"   : [0.0, 0.33, 0.67, 1.0, 0.67, 0.33, 0.0],
        "zero"   : [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    }[mode]
    
    var list = $"Tabs/Depth Map/Freqs".get_children()
    setting_sliders = true
    for i in array.size():
        var val = array[i]
        var slider : Range = list[i]
        slider.value = slider.max_value * val
    setting_sliders = false
    depth_slider_changed(0.0)

func read_range(_range : Range) -> float:
    return _range.value / _range.max_value
    
func write_range(_range : Range, val : float):
    _range.value = _range.max_value*val

func min_v2(a : Vector2, b : Vector2):
    if a.x > a.y:
        b.y = floor(b.x*a.y/a.x)
    else:
        b.x = floor(b.y*a.x/a.y)
    return Vector2(min(a.x, b.x), min(a.y, b.y))

func force_draw_subviewports(viewports : Array):
    var old_update_modes = []
    for _viewport in viewports:
        var viewport : Viewport = _viewport
        old_update_modes.push_back(viewport.render_target_update_mode)
        viewport.render_target_update_mode = Viewport.UPDATE_ALWAYS
    
    get_tree().get_root().render_target_update_mode = Viewport.UPDATE_DISABLED
    
    disable_limiter()
    VisualServer.force_draw(false, 0.0)
    reset_limiter()
    
    get_tree().get_root().render_target_update_mode = Viewport.UPDATE_ALWAYS
    
    for i in viewports.size():
        var viewport = viewports[i]
        var old_update_mode = old_update_modes[i]
        viewport.render_target_update_mode = old_update_mode

func create_normal_texture(albedo : Texture, strength, darkpoint, midpoint, midpoint_offset, lightpoint, depth_offset, microfacets, generate_normal, early_adjust):
    var size = albedo.get_size()
    
    $HelperNormal.keep_3d_linear = true
    if $HelperNormal/Quad.material_override == null:
        $HelperNormal/Quad.material_override = ShaderMaterial.new()
    
    var mat = $HelperNormal/Quad.material_override
    if mat.shader != preload("res://shaders/NormalGenerator.gdshader"):
        mat.shader = preload("res://shaders/NormalGenerator.gdshader")
    
    var start = OS.get_ticks_usec()
    
    #var viewports = []
    for i in 7:
        var path = "HelperOctaveAlbedo"
        var viewport : Viewport = get_node(path)
        var quad = viewport.get_node("Quad")
        viewport.size = size
        if i == 0:
            viewport.size = min_v2(viewport.size, Vector2(32, 32))
        elif i == 1:
            viewport.size = min_v2(viewport.size, Vector2(64, 64))
        elif i == 2:
            viewport.size = min_v2(viewport.size, Vector2(128, 128))
        elif i == 3:
            viewport.size = min_v2(viewport.size, Vector2(256, 256))
        elif i == 4:
            viewport.size = min_v2(viewport.size, Vector2(512, 512))
        elif i == 5:
            viewport.size = min_v2(viewport.size, Vector2(1024, 1024))
        quad.scale.x = size.x / size.y
        quad.force_update_transform()
        
        if quad.material_override == null:
            var mat2 = ShaderMaterial.new()
            quad.material_override = mat2
        var mat2 = quad.material_override
        
        viewport.keep_3d_linear = false
        viewport.hdr = false
        
        if mat2.shader != preload("res://shaders/OctaveExtractor.gdshader"):
            mat2.shader = preload("res://shaders/OctaveExtractor.gdshader")
        
        mat2.set_shader_param("input", albedo)
        mat2.set_shader_param("octave", i)
        mat2.set_shader_param("microfacets", microfacets)
        mat2.set_shader_param("raw_mip_ratio", -1.0)
        
        force_draw_subviewports([viewport])
        var img : Image = viewport.get_texture().get_data()
        var texture = ImageTexture.new()
        texture.create_from_image(img)
        mat.set_shader_param("octave_"+str(i), texture)
        mat2.set_shader_param("input", null)
        
    $HelperOctaveAlbedo.size = Vector2(2, 2)
    force_draw_subviewports([$HelperOctaveAlbedo])
    
    
    var end = OS.get_ticks_usec()
    print("normal/depth update time... ", (end-start)/1000.0, "ms")
    
    $HelperNormal.keep_3d_linear = true
    mat.set_shader_param("albedo", albedo)
    mat.set_shader_param("strength", strength)
    mat.set_shader_param("darkpoint", darkpoint)
    mat.set_shader_param("midpoint", midpoint)
    mat.set_shader_param("midpoint_offset", midpoint_offset)
    mat.set_shader_param("lightpoint", lightpoint)
    mat.set_shader_param("depth_offset", depth_offset)
    mat.set_shader_param("microfacets", microfacets)
    mat.set_shader_param("generate_normal", generate_normal)
    mat.set_shader_param("early_adjust", early_adjust)
    
    var parent = get_node("Tabs/%s Map" % [["Depth"], ["Normal"]][int(generate_normal)])
    
    var channel_id = parent.get_node("OptionButton").selected
    var channel = {
        0 : Vector3(0.333, 0.333, 0.333),
        1 : Vector3(1, 0, 0),
        2 : Vector3(0, 1, 0),
        3 : Vector3(0, 0, 1),
        4 : Vector3(0.5, 0.5, 0),
    }[channel_id]
    mat.set_shader_param("channel", channel)
    
    for i in 7:
        var slider_name = "Freqs/VSlider" + str(i+1)
        var slider = parent.get_node(slider_name)
        var v = slider.value / slider.max_value
        mat.set_shader_param("band_strength_"+str(i), v)
    
    $HelperNormal.size = size
    $HelperNormal/Quad.scale.x = size.x / size.y
    $HelperNormal/Quad.force_update_transform()
    
    force_draw_subviewports([$HelperNormal])
    var img = $HelperNormal.get_texture().get_data()
    
    # free up vram
    for i in 7:
        mat.set_shader_param("octave_"+str(i), null)
    $HelperNormal.size = Vector2(2, 2)
    force_draw_subviewports([$HelperNormal])
    
    return img

func sky_option_picked(which : int):
    if which == 0:
        $"3D/WorldEnvironment".environment.background_sky = preload("res://resources/DefaultSky.tres")
    else:
        $"3D/WorldEnvironment".environment.background_sky = PanoramaSky.new()
        ($"3D/WorldEnvironment".environment.background_sky as PanoramaSky).radiance_size = PanoramaSky.RADIANCE_SIZE_128
        if which == 1:
            $"3D/WorldEnvironment".environment.background_sky.panorama = preload("res://resources/unfinished_office_4k.exr")
        elif which == 2:
            $"3D/WorldEnvironment".environment.background_sky.panorama = preload("res://resources/belfast_sunset_puresky_2k.exr")

func normal_option_picked(_unused : int):
    normal_slider_changed(0.0)
func normal_slider_changed(_unused : float):
    if albedo_image == null:
        return
    if setting_sliders:
        return
    
    var strength = read_range($"Tabs/Normal Map/Slider")
    var darkpoint = read_range($"Tabs/Normal Map/Slider2")
    var midpoint = read_range($"Tabs/Normal Map/Slider3")
    var midpoint_offset = read_range($"Tabs/Normal Map/Slider5")
    var lightpoint = read_range($"Tabs/Normal Map/Slider4")
    var microfacets = read_range($"Tabs/Normal Map/Slider6")
    var early_adjust = $"Tabs/Normal Map/CheckBox".pressed
    
    var depth_offset = 0.0
    
    normal_image = create_normal_texture(albedo, strength*10.0, darkpoint, midpoint, midpoint_offset, lightpoint, depth_offset, microfacets, 1.0, early_adjust)
    #normal_image.convert(Image.FORMAT_RGBA8)
    
    normal = ImageTexture.new()
    normal.create_from_image(normal_image)
    normal.flags |= ImageTexture.FLAG_ANISOTROPIC_FILTER
    
    mat_3d.normal_enabled = true
    mat_3d.normal_texture = normal
    if !indirect_update:
        var n2 = normal.duplicate(true)
        mat_texture.set_shader_param("image", n2)
    
var indirect_update = false

func depth_option_picked(_unused : int):
    depth_slider_changed(0.0)
func depth_slider_changed(_unused : float):
    if albedo_image == null:
        return
    if setting_sliders:
        return
    
    var strength = read_range($"Tabs/Depth Map/Slider")
    var darkpoint = read_range($"Tabs/Depth Map/Slider2")
    var midpoint = read_range($"Tabs/Depth Map/Slider3")
    var midpoint_offset = read_range($"Tabs/Depth Map/Slider5")
    var lightpoint = read_range($"Tabs/Depth Map/Slider4")
    var microfacets = read_range($"Tabs/Depth Map/Slider7")
    
    var depth_offset = read_range($"Tabs/Depth Map/Slider6")
    
    var early_adjust = $"Tabs/Depth Map/CheckBox".pressed
    
    depth_image = create_normal_texture(albedo, strength, darkpoint, midpoint, midpoint_offset, lightpoint, depth_offset, microfacets, 0.0, early_adjust)
    #depth_image.convert(Image.FORMAT_RGBA8)
    
    depth = ImageTexture.new()
    depth.create_from_image(depth_image)
    depth.flags |= ImageTexture.FLAG_ANISOTROPIC_FILTER
    depth.flags |= ImageTexture.FLAG_FILTER
    
    mat_3d.depth_enabled = true
    mat_3d.depth_deep_parallax = true
    mat_3d.depth_texture = depth
    
    if !indirect_update:
        var n2 = depth.duplicate(true)
        mat_texture.set_shader_param("image", n2)
    
    indirect_update = true
    
    if !no_recurse:
        ao_slider_changed(0.0)


func get_default_fps_setting():
    return Engine.target_fps
onready var fps_default = get_default_fps_setting()

var disabled = 0
func disable_limiter():
    disabled += 1
    Engine.target_fps = 0

func reset_limiter():
    disabled -= 1
    if disabled <= 0:
        Engine.target_fps = fps_default

func create_ao_texture(depth : Texture, strength, freq_high, freq_mid, freq_low, freq_balance, exponent, bias, contrast, fine_limit, rough_limit):
    var size = depth.get_size()
    
    $HelperAO.keep_3d_linear = true
    if $HelperAO/Quad.material_override == null:
        $HelperAO/Quad.material_override = ShaderMaterial.new()
    var mat = $HelperAO/Quad.material_override
    if mat.shader != preload("res://shaders/AOGenerator.gdshader"):
        mat.shader = preload("res://shaders/AOGenerator.gdshader")
    
    var start = OS.get_ticks_usec()
    
    var i = 0
    for freq in [freq_high, freq_high*freq_mid, freq_high*freq_mid*freq_low]:
        var path = "HelperOctaveDepth"
        var viewport : Viewport = get_node(path)
        var quad = viewport.get_node("Quad")
        if viewport.size != size:
            viewport.size = size
        quad.scale.x = size.x / size.y
        quad.force_update_transform()
        
        if quad.material_override == null:
            var mat2 = ShaderMaterial.new()
            quad.material_override = mat2
        var mat2 = quad.material_override
        
        viewport.keep_3d_linear = false
        viewport.hdr = true
        
        if mat2.shader != preload("res://shaders/OctaveExtractorLinear.gdshader"):
            mat2.shader = preload("res://shaders/OctaveExtractorLinear.gdshader")
        
        mat2.set_shader_param("input", depth)
        mat2.set_shader_param("octave", 0)
        mat2.set_shader_param("microfacets", 0.0)
        mat2.set_shader_param("raw_mip_ratio", freq)
        
        force_draw_subviewports([viewport])
        var img : Image = viewport.get_texture().get_data()
        var texture = ImageTexture.new()
        texture.create_from_image(img)
        mat.set_shader_param("octave_"+str(i), texture)
        
        mat2.set_shader_param("input", null)
        
        i += 1
    
    $HelperOctaveDepth.size = Vector2(2, 2)
    force_draw_subviewports([$HelperOctaveDepth])
    
    var end = OS.get_ticks_usec()
    print("ao update time... ", (end-start)/1000.0, "ms")
    
    mat.set_shader_param("strength", strength)
    mat.set_shader_param("freq_balance", freq_balance)
    mat.set_shader_param("exponent", exponent)
    mat.set_shader_param("bias", (bias-0.5)*16.0)
    mat.set_shader_param("contrast", contrast)
    mat.set_shader_param("fine_limit", fine_limit)
    mat.set_shader_param("rough_limit", rough_limit)
    
    $HelperAO.size = size
    $HelperAO/Quad.scale.x = size.x / size.y
    $HelperAO/Quad.force_update_transform()
    
    force_draw_subviewports([$HelperAO])
    var img = $HelperAO.get_texture().get_data()
    # extra contrast
    img.srgb_to_linear()
    
    for j in 3:
        mat.set_shader_param("octave_"+str(j), null)
    
    # free up vram
    $HelperAO.size = Vector2(2, 2)
    force_draw_subviewports([$HelperAO])
    
    return img


func ao_option_picked(_unused : int):
    ao_slider_changed(0.0)
func ao_slider_changed(_unused : float):
    if depth_image == null:
        return
    if setting_sliders:
        return
    
    var strength = read_range($"Tabs/AO Map/Slider")
    var freq_high = read_range($"Tabs/AO Map/Slider2")
    var freq_mid = read_range($"Tabs/AO Map/Slider5")
    var freq_low = read_range($"Tabs/AO Map/Slider3")
    var freq_balance = read_range($"Tabs/AO Map/Slider4")
    var exponent = read_range($"Tabs/AO Map/Slider6")
    var comparison_bias = read_range($"Tabs/AO Map/Slider7")
    var contrast = read_range($"Tabs/AO Map/Slider8")
    var fine_limit = read_range($"Tabs/AO Map/Slider9")
    var rough_limit = read_range($"Tabs/AO Map/Slider10")
    
    strength = max(0.00000001, strength*strength*100.0)
    
    ao_image = create_ao_texture(depth, strength, freq_high, freq_mid, freq_low, freq_balance, exponent, lerp(comparison_bias, 0.5, 0.95), contrast, fine_limit/strength*2.0, rough_limit/strength*2.0)
    
    ao = ImageTexture.new()
    ao.create_from_image(ao_image)
    ao.flags |= ImageTexture.FLAG_ANISOTROPIC_FILTER
    ao.flags |= ImageTexture.FLAG_FILTER
    
    mat_3d.ao_enabled = true
    mat_3d.ao_texture = ao
    
    if !indirect_update:
        var n2 = ao.duplicate(true)
        mat_texture.set_shader_param("image", n2)
    
    indirect_update = true
    
    if !no_recurse:
        light_remover_slider_changed(0.0)

func create_unlit_albedo_image(albedo : Texture, ao : Texture, _normal_image : Image, _depth_image, ao_strength, ao_limit, ao_gamma, ao_desat):
    var start = OS.get_ticks_usec()
    
    $HelperUnlit.keep_3d_linear = false
    if $HelperUnlit/Quad.material_override == null:
        $HelperUnlit/Quad.material_override = ShaderMaterial.new()
    var mat = $HelperUnlit/Quad.material_override
    if mat.shader != preload("res://shaders/AORemover.gdshader"):
        mat.shader = preload("res://shaders/AORemover.gdshader")
    
    mat.set_shader_param("albedo", albedo)
    mat.set_shader_param("ao", ao)
    mat.set_shader_param("ao_strength", ao_strength)
    mat.set_shader_param("ao_limit", ao_limit)
    mat.set_shader_param("ao_gamma", ao_gamma)
    mat.set_shader_param("ao_desat", ao_desat)
    
    var size = albedo_image.get_size()
    $HelperUnlit.size = size
    $HelperUnlit/Quad.scale.x = size.x / size.y
    $HelperUnlit/Quad.force_update_transform()
    
    force_draw_subviewports([$HelperUnlit])
    var img = $HelperUnlit.get_texture().get_data()
    
    var end = OS.get_ticks_usec()
    print("shading removal update time... ", (end-start)/1000.0, "ms")
    
    # free up vram
    mat.set_shader_param("albedo", null)
    mat.set_shader_param("ao", null)
    $HelperUnlit.size = Vector2(2, 2)
    force_draw_subviewports([$HelperUnlit])
    
    return img

func light_remover_slider_changed(_unused : float):
    if albedo_image == null:
        return
    if setting_sliders:
        return
    
    var ao_strength = read_range($"Tabs/Shading Remover/Slider")
    var ao_limit = read_range($"Tabs/Shading Remover/Slider2")
    var ao_gamma = read_range($"Tabs/Shading Remover/Slider3")
    var ao_desat = read_range($"Tabs/Shading Remover/Slider4")
    
    ao_desat = ao_desat*ao_desat
    
    ao_strength = ao_strength*ao_strength*16.0
    
    albedo_image_display = create_unlit_albedo_image(albedo, ao, normal_image, depth_image, ao_strength, ao_limit, ao_gamma*ao_gamma*4.0, ao_desat*4.0)
    
    albedo_display = ImageTexture.new()
    albedo_display.create_from_image(albedo_image_display)
    albedo_display.flags |= ImageTexture.FLAG_ANISOTROPIC_FILTER
    
    mat_3d.albedo_texture = albedo_display
    if !indirect_update:
        var n2 = albedo_display.duplicate(true)
        mat_texture.set_shader_param("image", n2)

func create_metal_texture(albedo : Texture, colors : Array, mixing_bias : float, contrast : float, shrink_radius : int, blur_radius, is_roughness, mixing_exponent : float, supersample):
    mixing_bias = mixing_bias*mixing_bias
    
    if colors.size() == 0:
        if is_roughness:
            colors = [Color(0, 0, 0, 1)]
        else:
            colors = [Color(0, 0, 0, 0)]
    
    var color_img = Image.new()
    color_img.create(colors.size(), 1, false, Image.FORMAT_RGBA8)
    color_img.lock()
    for i in colors.size():
        color_img.set_pixel(i, 0, colors[i])
    color_img.unlock()
    var color_tex = ImageTexture.new()
    color_tex.create_from_image(color_img)
    
    $HelperDistance.keep_3d_linear = true
    if $HelperDistance/Quad.material_override == null:
        $HelperDistance/Quad.material_override = ShaderMaterial.new()
    var mat = $HelperDistance/Quad.material_override
    
    if mat.shader != preload("res://shaders/MetallicityGenerator.gdshader"):
        mat.shader = preload("res://shaders/MetallicityGenerator.gdshader")
    
    mat.set_shader_param("albedo", albedo)
    mat.set_shader_param("colors", color_tex)
    mat.set_shader_param("mixing_bias", mixing_bias)
    mat.set_shader_param("mixing_exponent", mixing_exponent)
    mat.set_shader_param("contrast", contrast)
    mat.set_shader_param("shrink_radius", shrink_radius)
    mat.set_shader_param("blur_radius", blur_radius)
    mat.set_shader_param("is_roughness", is_roughness)
    mat.set_shader_param("supersample", supersample)
    
    var size = albedo.get_size()
    $HelperDistance.size = size
    $HelperDistance/Quad.scale.x = size.x / size.y
    $HelperDistance/Quad.force_update_transform()
    
    force_draw_subviewports([$HelperDistance])
    var img = $HelperDistance.get_texture().get_data()
    
    # free up vram
    mat.set_shader_param("albedo", null)
    $HelperDistance.size = Vector2(2, 2)
    force_draw_subviewports([$HelperDistance])
    
    return img


func metal_slider_changed(_unused : float):
    if albedo_image == null:
        return
    if setting_sliders:
        return
    
    var mixing_bias = read_range($"Tabs/Metal Map/HBoxContainer/HSlider")
    var mixing_exponent = read_range($"Tabs/Metal Map/HBoxContainer4/HSlider")*4.0
    var contrast = read_range($"Tabs/Metal Map/HBoxContainer2/HSlider")
    var shrink_radius = $"Tabs/Metal Map/HBoxContainer3/HSlider".value
    var blur_radius = 0
    var supersample = 0.333 if $"Tabs/Metal Map/CheckBox".pressed else 0.0
    
    mixing_exponent *= mixing_exponent
    
    var colors = []
    for c in $"Tabs/Metal Map".get_children():
        if c.get_child_count() >= 3:
            var color = (c.get_child(0) as ColorRect).color
            var slider : Range = c.get_child(2)
            colors.push_back(Color(color.r, color.g, color.b, read_range(slider)))
    
    metal_image = create_metal_texture(albedo, colors, mixing_bias, contrast, shrink_radius, blur_radius, false, mixing_exponent, supersample)
    
    metal = ImageTexture.new()
    metal.create_from_image(metal_image)
    
    mat_3d.metallic = 1.0
    mat_3d.metallic_texture = metal
    mat_3d.metallic_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_RED
    
    if !indirect_update:
        var n2 = metal.duplicate(true)
        mat_texture.set_shader_param("image", n2)


func roughness_slider_changed(_unused : float):
    if albedo_image == null:
        return
    if setting_sliders:
        return
    
    var mixing_bias = read_range($"Tabs/Roughness Map/HBoxContainer/HSlider")
    var mixing_exponent = read_range($"Tabs/Roughness Map/HBoxContainer5/HSlider")*4.0
    var contrast = read_range($"Tabs/Roughness Map/HBoxContainer2/HSlider")
    var shrink_radius = $"Tabs/Roughness Map/HBoxContainer3/HSlider".value
    var blur_radius = $"Tabs/Roughness Map/HBoxContainer4/HSlider".value
    var supersample = 0.333 if $"Tabs/Roughness Map/CheckBox".pressed else 0.0
    
    mixing_exponent *= mixing_exponent
    
    var colors = []
    for c in $"Tabs/Roughness Map".get_children():
        if c.get_child_count() >= 3:
            var color = (c.get_child(0) as ColorRect).color
            var slider : Range = c.get_child(2)
            colors.push_back(Color(color.r, color.g, color.b, read_range(slider)))
    
    roughness_image = create_metal_texture(albedo, colors, mixing_bias, contrast, shrink_radius, blur_radius, true, mixing_exponent, supersample)
    
    roughness = ImageTexture.new()
    roughness.create_from_image(roughness_image)
    
    mat_3d.roughness = 1.0
    mat_3d.roughness_texture = roughness
    mat_3d.roughness_texture_channel = SpatialMaterial.TEXTURE_CHANNEL_GREEN
    
    if !indirect_update:
        var n2 = roughness.duplicate(true)
        mat_texture.set_shader_param("image", n2)


var zoom = 0
func _input(_event):
    if _event is InputEventMouseButton:
        var event : InputEventMouseButton = _event
        var zoom_changed = false
        if event.button_index == BUTTON_WHEEL_UP:
            zoom += 1
            zoom_changed = true
        elif event.button_index == BUTTON_WHEEL_DOWN:
            zoom -= 1
            zoom_changed = true
        if zoom_changed:
            zoom = clamp(zoom, -16, 16)
            $"3D/CameraHolder/Camera".translation.z = 3 * pow(2, -zoom/16.0 * 1.3)
        
        if color_picking:
            if event.button_index == BUTTON_RIGHT:
                cancel_picking_color()
            elif event.button_index == BUTTON_LEFT:
                end_picking_color()
    if _event is InputEventKey:
        var event : InputEventKey = _event
        if color_picking:
            if event.scancode == KEY_ESCAPE:
                cancel_picking_color()
    if _event is InputEventMouseMotion:
        var event : InputEventMouseMotion = _event
        var sensitivity = 0.22 * 0.75
        var x = $"3D/CameraHolder".rotation_degrees.x
        if (event.button_mask & BUTTON_MASK_MIDDLE):
            if !event.shift:
                x -= event.relative.y * sensitivity
                $"3D/CameraHolder".rotation_degrees.y -= event.relative.x * sensitivity
            else:
                var d = $"3D/CameraHolder/Camera".global_transform.basis
                var right = d.xform(Vector3.RIGHT)
                var up = d.xform(Vector3.UP)
                var whee = $"3D/CameraHolder/Camera".translation.z
                var sens = 0.002
                $"3D/CameraHolder".global_translation += up*event.relative.y * whee * sens
                $"3D/CameraHolder".global_translation -= right*event.relative.x * whee * sens
        x = clamp(x, -90, 90)
        $"3D/CameraHolder".rotation_degrees.x = x


var processing = false
var current_preview_texture = null
func _process(delta : float):
    indirect_update = false
    processing = true
    
    mat_3d.metallic_specular = read_range($"Tabs/Config/HSlider")
    mat_3d.roughness = read_range($"Tabs/Config/HSlider4")
    mat_3d.normal_scale = read_range($"Tabs/Config/HSlider2")
    mat_3d.depth_scale = read_range($"Tabs/Config/HSlider3") * 0.05 * 4.0
    mat_3d.depth_flip_binormal = $Tabs/Config/CheckButton.pressed
    mat_3d.depth_flip_tangent = $Tabs/Config/CheckButton.pressed
    
    $"3D/WorldEnvironment".environment.ambient_light_sky_contribution = read_range($Tabs/Ambience/HBoxContainer/HSlider)
    $"3D/WorldEnvironment".environment.background_energy = read_range($Tabs/Ambience/HBoxContainer2/HSlider)
    
    var which = $Tabs/Ambience/HBoxContainer3/OptionButton.selected
    if which > 0:
        $"3D/WorldEnvironment".environment.background_energy *= 0.5
    
    if $Tabs/Shape/CheckBox.pressed:
        $"3D/MeshHolder/Mesh".rotation.y += delta*0.1
        
        var v = fmod($"3D/MeshHolder/Mesh".rotation.y + PI*2.0, PI*2.0)
        v = fmod(v + PI*2.0, PI*2.0)
        $"3D/MeshHolder/Mesh".rotation.y = v
        
        write_range($Tabs/Shape/HBoxContainer/HSlider, v/PI/2.0)
        
    if $Tabs/Light/CheckBox.pressed:
        $"3D/LightHolder".rotation.y -= delta
        var v = fmod($"3D/LightHolder".rotation.y + PI*2.0, PI*2.0)
        v = fmod(v + PI*2.0, PI*2.0)
        $"3D/LightHolder".rotation.y = v
        
        write_range($Tabs/Light/HBoxContainer2/HSlider, v/PI/2.0)
    
    if color_picking != "":
        update()
    
    var current_tab = $Tabs.button_tabs[$Tabs.active_button]
    
    $"Warnings".text = ""
    if !normal_image:
        $"Warnings".text += "Note: You must load an albedo texture by drag-and-dropping it onto the window before you can do anything.\n"
    if mat_3d.uv1_triplanar:
        $"Warnings".text += "Warning: Depth maps don't display with triplanar-mapped objects (triplanar sphere and cylinders).\n"
    
    var zero_roughness_found = false
    if $Tabs/Config/HSlider4.value == 0:
        zero_roughness_found = true
    for slider in get_tree().get_nodes_in_group("RoughnessSliders"):
        if slider.value == 0:
            zero_roughness_found = true
    
    if zero_roughness_found:
        $"Warnings".text += "Warning: Unless you're creating materials for a raytracer, exactly zero roughness is ill-advised, because it will hide point light reflections.\n"
    
    var next_texture = null
    var confirmed = true
    if normal and current_tab == $"Tabs/Normal Map":
        next_texture = normal
    elif depth and current_tab == $"Tabs/Depth Map":
        next_texture = depth
    elif metal and current_tab == $"Tabs/Metal Map":
        next_texture = metal
    elif roughness and current_tab == $"Tabs/Roughness Map":
        next_texture = roughness
    elif ao and current_tab == $"Tabs/AO Map":
        next_texture = ao
    elif ao and current_tab == $"Tabs/Shading Remover":
        next_texture = albedo_display
    else:
        next_texture = albedo
        confirmed = false
    
    if current_preview_texture != next_texture:
        current_preview_texture = next_texture
        var data : Image = next_texture.get_data()
        #print(data.get_format())
        var tex = ImageTexture.new()
        tex.create_from_image(data)
        tex.flags |= ImageTexture.FLAG_ANISOTROPIC_FILTER
        
        mat_texture.set_shader_param("image", tex)
        
        $PanelContainer/TextureRect.texture = tex

    processing = false

var color_picking = ""
var color_which = -1

func start_picking_color(type : String, which : int):
    Input.set_custom_mouse_cursor(preload("res://resources/spoit.png"), Input.CURSOR_ARROW, Vector2(1, 20))
    color_picking = type
    color_which = which

func end_picking_color():
    var vp = get_viewport()
    var mouse_pos = vp.get_mouse_position()
    var screen = vp.get_texture().get_data()
    screen.lock()
    mouse_pos.y = screen.get_size().y - mouse_pos.y
    var color = screen.get_pixelv(mouse_pos)
    screen.unlock()
    
    var box = HBoxContainer.new()
    var icon = ColorRect.new()
    var label = Label.new()
    var slider = HSlider.new()
    var button = TextureButton.new()
    icon.color = color
    icon.rect_min_size = Vector2(16, 16)
    
    if color_picking == "metal":
        label.text = "Metallicity:"
    elif color_picking == "roughness":
        label.text = "Roughness:"
    
    slider.max_value = 100
    slider.size_flags_horizontal |= SIZE_EXPAND
    
    button.texture_hover = preload("res://resources/x.png")
    button.texture_normal = preload("res://resources/x.png")
    button.texture_disabled = preload("res://resources/x.png")
    button.texture_focused = preload("res://resources/x.png")
    button.texture_pressed = preload("res://resources/x.png")
    
    if color_picking == "metal":
        slider.connect("value_changed", self, "metallicity_update")
        button.connect("pressed", self, "delete_color", [box, "metal"])
    elif color_picking == "roughness":
        slider.connect("value_changed", self, "roughness_update")
        slider.add_to_group("RoughnessSliders")
        button.connect("pressed", self, "delete_color", [box, "roughness"])
    
    box.add_child(icon)
    box.add_child(label)
    box.add_child(slider)
    box.add_child(button)
    
    if color_picking == "metal":
        $"Tabs/Metal Map".add_child(box)
        metal_slider_changed(0.0)
    elif color_picking == "roughness":
        $"Tabs/Roughness Map".add_child(box)
        roughness_slider_changed(0.0)
    
    cancel_picking_color()

func metallicity_update(_unused):
    metal_slider_changed(0.0)

func roughness_update(_unused):
    roughness_slider_changed(0.0)

func delete_color(which, type):
    which.queue_free()
    if type == "metal":
        $"Tabs/Metal Map".remove_child(which)
        metal_slider_changed(0.0)
    elif type == "roughness":
        $"Tabs/Roughness Map".remove_child(which)
        roughness_slider_changed(0.0)

func cancel_picking_color():
    color_picking = ""
    color_which = -1
    update()
    Input.set_custom_mouse_cursor(null, Input.CURSOR_ARROW)

func _draw():
    if color_picking != "":
        var vp = get_viewport()
        var mouse_pos = vp.get_mouse_position()
        var screen = vp.get_texture().get_data()
        screen.lock()
        mouse_pos.y = screen.get_size().y - mouse_pos.y
        var color = screen.get_pixelv(mouse_pos)
        screen.unlock()
        mouse_pos.y = screen.get_size().y - mouse_pos.y
        
        var gray = color.gray()
        var contrasted = Color.white
        if gray > 0.5:
            contrasted = Color.black
        
        draw_arc(mouse_pos + Vector2(0, -32), 13.3, 0.0, PI*2.0, 32, contrasted, 1.0, true)
        draw_arc(mouse_pos + Vector2(0, -32), 6.2, 0.0, PI*2.0, 32, color, 12.5, true)
        
func light_angle_update(_unused):
    $"3D/LightHolder/DirectionalLight".rotation_degrees.x = -90+180*read_range($Tabs/Light/HBoxContainer/HSlider)

func light_rotation_update(_unused):
    if processing:
        return
    $"3D/LightHolder".rotation_degrees.y = 360*read_range($Tabs/Light/HBoxContainer2/HSlider)

func shape_rotation_update(_unused):
    if processing:
        return
    $"3D/MeshHolder/Mesh".rotation_degrees.y = 360*read_range($Tabs/Shape/HBoxContainer/HSlider)

func shape_slant_update(_unused):
    if processing:
        return
    $"3D/MeshHolder/Mesh".rotation_degrees.x = $Tabs/Shape/HBoxContainer3/HSlider.value

func shape_size_update(_unused):
    if processing:
        return
    $"3D/MeshHolder/Mesh".scale = Vector3(1,1,1)*read_range($Tabs/Shape/HBoxContainer2/HSlider)*100.0

func set_mesh(which : String):
    $"3D/MeshHolder/Mesh".translation.y = 0
    $"3D/MeshHolder/Mesh".rotation.x = 0
    $"3D/MeshHolder/Mesh".scale = Vector3(1, 1, 1)
    mat_3d.uv1_triplanar = false
    mat_3d.uv1_triplanar_sharpness = 16.0
    mat_3d.uv1_offset = Vector3(0.0, 0.0, 0.0)
    set_uv_scale(Vector3(3, 2, 2))
    var mesh = null
    if which == "sphere":
        mesh = SphereMesh.new()
        mesh.radial_segments = 256
        mesh.rings = 128
        set_uv_scale(Vector3(2, 1, 1))
    elif which == "cube":
        mesh = CubeMesh.new()
        $"3D/MeshHolder/Mesh".scale *= 0.7
    elif which == "cylinder":
        mesh = preload("res://resources/cylinder_good_uvs.obj")
        $"3D/MeshHolder/Mesh".scale *= 0.7
        set_uv_scale(Vector3(1, 1, 1))
    elif which == "sideways cylinder":
        #mesh = CylinderMesh.new()
        #mesh.radial_segments = 256
        #mesh.rings = 0
        mesh = preload("res://resources/cylinder_good_uvs.obj")
        $"3D/MeshHolder/Mesh".scale *= 0.7
        set_uv_scale(Vector3(1, 1, 1))
        $"3D/MeshHolder/Mesh".rotation_degrees.x = 90
    elif which == "plane":
        mesh = CubeMesh.new()
        mesh.size.z = 0
        $"3D/MeshHolder/Mesh".rotation_degrees.x = 90
        $"3D/MeshHolder/Mesh".translation.y = -0.1
    elif which == "plane slanted":
        mesh = CubeMesh.new()
        mesh.size.z = 0
        $"3D/MeshHolder/Mesh".rotation_degrees.x = 45
    $Tabs/Shape/HBoxContainer2/HSlider.value = 10 * $"3D/MeshHolder/Mesh".scale.x
    $Tabs/Shape/HBoxContainer3/HSlider.value = $"3D/MeshHolder/Mesh".rotation_degrees.x
    $"3D/MeshHolder/Mesh".mesh = mesh
