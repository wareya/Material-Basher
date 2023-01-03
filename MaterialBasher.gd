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

var mat_3d = SpatialMaterial.new()
var mat_texture = preload("res://UnshadedPlain.material")

func set_uv_scale(scale : Vector3):
    mat_3d.uv1_scale = scale
    mat_texture.set_shader_param("uv1_scale", mat_3d.uv1_scale)
    mat_texture.set_shader_param("uv1_offset", mat_3d.uv1_offset)

func _ready():
    # TODO: settings for diffuse/specular model etc
    # TODO: normal lighting removal
    # TODO: depth vs height vs displacement setting
    # TODO: export
    
    $PopupDialog/VBoxContainer/CenterContainer/Button.connect("pressed", $PopupDialog, "hide")
    
    
    $"3D/MeshHolder/Mesh".global_rotation.y += 1.5
    
    
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
    
    $Tabs/Ambience/HBoxContainer3/OptionButton.connect("item_selected", self, "sky_option_picked")
    
    
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
    
    $Tabs/Export/Button.connect("pressed", self, "save_albedo")
    $Tabs/Export/Button2.connect("pressed", self, "save_normal")
    $Tabs/Export/Button3.connect("pressed", self, "save_pbr")
    
    
    
    for _type in ["normal", "depth"]:
        var type : String = _type
        var parent = get_node("Tabs/%s Map" % [type.capitalize()])
        var slider_change = "%s_slider_changed" % [type]
        
        for child in parent.get_children():
            if child is Range:
                child.connect("value_changed", self, slider_change)
        for child in parent.get_node("Freqs").get_children():
            if child is Range:
                child.connect("value_changed", self, slider_change)
        
        parent.get_node("OptionButton").connect("item_selected", self, "%s_option_picked" % type)
        
        for child in parent.get_node("Freqs/Presets").get_children():
            if child is Button:
                child.connect("pressed", self, "%s_freq_preset" % [type], [child.name.to_lower()])
    
    $"Tabs/Metal Map/HBoxContainer/HSlider".connect("value_changed", self, "metal_slider_changed")
    $"Tabs/Metal Map/HBoxContainer2/HSlider".connect("value_changed", self, "metal_slider_changed")
    $"Tabs/Metal Map/HBoxContainer3/HSlider".connect("value_changed", self, "metal_slider_changed")
    
    $"Tabs/AO Map/Slider".connect("value_changed", self, "ao_slider_changed")
    $"Tabs/AO Map/Slider2".connect("value_changed", self, "ao_slider_changed")
    $"Tabs/AO Map/Slider3".connect("value_changed", self, "ao_slider_changed")
    $"Tabs/AO Map/Slider4".connect("value_changed", self, "ao_slider_changed")
    $"Tabs/AO Map/Slider5".connect("value_changed", self, "ao_slider_changed")
    $"Tabs/AO Map/Slider6".connect("value_changed", self, "ao_slider_changed")
    $"Tabs/AO Map/Slider7".connect("value_changed", self, "ao_slider_changed")
    $"Tabs/AO Map/Slider8".connect("value_changed", self, "ao_slider_changed")
    $"Tabs/AO Map/Slider9".connect("value_changed", self, "ao_slider_changed")
    $"Tabs/AO Map/Slider10".connect("value_changed", self, "ao_slider_changed")
    
    $"Tabs/Shading Remover/Slider".connect("value_changed", self, "light_remover_slider_changed")
    $"Tabs/Shading Remover/Slider2".connect("value_changed", self, "light_remover_slider_changed")
    $"Tabs/Shading Remover/Slider3".connect("value_changed", self, "light_remover_slider_changed")
    $"Tabs/Shading Remover/Slider4".connect("value_changed", self, "light_remover_slider_changed")
    
    $"Tabs/Roughness Map/HBoxContainer/HSlider".connect("value_changed", self, "roughness_slider_changed")
    $"Tabs/Roughness Map/HBoxContainer2/HSlider".connect("value_changed", self, "roughness_slider_changed")
    $"Tabs/Roughness Map/HBoxContainer3/HSlider".connect("value_changed", self, "roughness_slider_changed")
    $"Tabs/Roughness Map/HBoxContainer4/HSlider".connect("value_changed", self, "roughness_slider_changed")
    
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
    
    set_uv_scale(Vector3(2, 1, 1))
    
    $"3D/MeshHolder/Mesh".material_override = mat_3d
    
    $"Tabs/Metal Map/Button".connect("pressed", self, "start_picking_color", ["metal", -1])
    $"Tabs/Roughness Map/Button".connect("pressed", self, "start_picking_color", ["roughness", -1])
    
    $Tabs/Shape/Button.connect("pressed", self, "set_mesh", ["sphere"])
    $Tabs/Shape/Button2.connect("pressed", self, "set_mesh", ["cube"])
    $Tabs/Shape/Button3.connect("pressed", self, "set_mesh", ["cylinder"])
    $Tabs/Shape/Button4.connect("pressed", self, "set_mesh", ["sideways cylinder"])
    $Tabs/Shape/Button5.connect("pressed", self, "set_mesh", ["plane"])
    $Tabs/Shape/Button7.connect("pressed", self, "set_mesh", ["plane slanted"])
    
    $Tabs/Config/Button.connect("pressed", self, "reset_view")

var NativeDialog = preload("res://addons/native_dialogs/native_dialogs.gd")

func save_albedo():
    save_image(albedo_image_display, "albedo.png", "Albedo", "Albedo cannot be saved until an image has been loaded.")

func save_normal():
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
    save_image(save_image, "normal.png", "Normal", "Normal cannot be saved until an albedo has been loaded.")

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
    save_image(image, "pbr.png", "PBR", "")
    
    image.unlock()
    red.unlock()
    if green != red:
        green.unlock()
    if blue != green and blue != red:
        blue.unlock()

func save_image(image : Image, default_fname : String, name_caps : String, error_text : String):
    if image == null:
        $PopupDialog/VBoxContainer/Label.text = error_text
        $PopupDialog.show()
        return
    
    var fo : Control = get_focus_owner()
    if fo:
        fo.release_focus()
    
    $NativeDialogSaveFile.initial_path = default_fname
    $NativeDialogSaveFile.title = "Save %s Image" % [name_caps]
    $NativeDialogSaveFile.show()
    var fname = yield($NativeDialogSaveFile, "file_selected")
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

func files_dropped(files : PoolStringArray, _screen : int):
    var fname : String = files[0]
    var file = File.new()
    file.open(fname, File.READ)
    var buffer = file.get_buffer(file.get_len())
    
    var image = Image.new()
    fname = fname.to_lower()
    if fname.ends_with("bmp"):
        image.load_bmp_from_buffer(buffer)
    elif fname.ends_with("png"):
        image.load_png_from_buffer(buffer)
    elif fname.ends_with("jpg") or fname.ends_with("jpeg"):
        image.load_jpg_from_buffer(buffer)
    elif fname.ends_with("tga"):
        image.load_tga_from_buffer(buffer)
    elif fname.ends_with("webp"):
        image.load_webp_from_buffer(buffer)
    elif fname.ends_with("obj"):
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
    
    albedo_image = image
    albedo_image_display = albedo_image.duplicate()
    albedo = ImageTexture.new()
    albedo.create_from_image(albedo_image_display)
    albedo.flags |= ImageTexture.FLAG_ANISOTROPIC_FILTER
    
    mat_3d.albedo_texture = albedo
    
    # FIXME clear up the rest of the material
    
    normal_slider_changed(0.0)
    depth_slider_changed(0.0)
    metal_slider_changed(0.0)


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


var ref_image = null
var ref_tex = null
func create_normal_texture(image : Image, strength, darkpoint, midpoint, midpoint_offset, lightpoint, depth_offset, microfacets, generate_normal):
    if ref_image != image or ref_tex == null:
        ref_image = image
        ref_tex = ImageTexture.new()
        ref_tex.create_from_image(image)
    
    var mat = $Helper/Quad.material_override as ShaderMaterial
    $Helper.keep_3d_linear = true
    mat.shader = preload("res://NormalGenerator.gdshader")
    mat.set_shader_param("albedo", ref_tex)
    mat.set_shader_param("strength", strength)
    mat.set_shader_param("darkpoint", darkpoint)
    mat.set_shader_param("midpoint", midpoint)
    mat.set_shader_param("midpoint_offset", midpoint_offset)
    mat.set_shader_param("lightpoint", lightpoint)
    mat.set_shader_param("depth_offset", depth_offset)
    mat.set_shader_param("microfacets", microfacets)
    mat.set_shader_param("generate_normal", generate_normal)
    
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
    
    var size = image.get_size()
    $Helper.size = size
    $Helper/Quad.scale.x = size.x / size.y
    
    $Helper.render_target_update_mode = Viewport.UPDATE_ALWAYS
    get_tree().get_root().render_target_update_mode = Viewport.UPDATE_DISABLED
    VisualServer.force_draw(false, 0.0)
    get_tree().get_root().render_target_update_mode = Viewport.UPDATE_ALWAYS
    $Helper.render_target_update_mode = Viewport.UPDATE_DISABLED
    
    return $Helper.get_texture().get_data()

func sky_option_picked(which : int):
    if which == 0:
        $"3D/WorldEnvironment".environment.background_sky = preload("res://DefaultSky.tres")
    else:
        $"3D/WorldEnvironment".environment.background_sky = PanoramaSky.new()
        ($"3D/WorldEnvironment".environment.background_sky as PanoramaSky).radiance_size = PanoramaSky.RADIANCE_SIZE_128
        if which == 1:
            $"3D/WorldEnvironment".environment.background_sky.panorama = preload("res://unfinished_office_4k.exr")
        elif which == 2:
            $"3D/WorldEnvironment".environment.background_sky.panorama = preload("res://belfast_sunset_puresky_4k.exr")

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
    
    var depth_offset = 0.0
    
    normal_image = create_normal_texture(albedo_image, strength*10.0, darkpoint, midpoint, midpoint_offset, lightpoint, depth_offset, microfacets, 1.0)
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
    
    depth_image = create_normal_texture(albedo_image, strength, darkpoint, midpoint, midpoint_offset, lightpoint, depth_offset, microfacets, 0.0)
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
    
    ao_slider_changed(0.0)


var ao_ref_image = null
var ao_ref_tex = null
func create_ao_texture(image : Image, strength, freq_high, freq_mid, freq_low, freq_balance, exponent, bias, contrast, fine_limit, rough_limit):
    if ao_ref_image != image or ao_ref_tex == null:
        ao_ref_image = image
        ao_ref_tex = ImageTexture.new()
        ao_ref_tex.create_from_image(image)
    
    var mat = $Helper/Quad.material_override as ShaderMaterial
    $Helper.keep_3d_linear = true
    mat.shader = preload("res://AOGenerator.gdshader")
    mat.set_shader_param("depth", ao_ref_tex)
    mat.set_shader_param("strength", strength)
    mat.set_shader_param("freq_low", freq_low)
    mat.set_shader_param("freq_mid", freq_mid)
    mat.set_shader_param("freq_high", freq_high)
    mat.set_shader_param("freq_balance", freq_balance)
    mat.set_shader_param("exponent", exponent)
    mat.set_shader_param("bias", bias)
    mat.set_shader_param("contrast", contrast)
    mat.set_shader_param("fine_limit", fine_limit)
    mat.set_shader_param("rough_limit", rough_limit)
    
    var size = image.get_size()
    $Helper.size = size
    $Helper/Quad.scale.x = size.x / size.y
    
    $Helper.render_target_update_mode = Viewport.UPDATE_ALWAYS
    get_tree().get_root().render_target_update_mode = Viewport.UPDATE_DISABLED
    VisualServer.force_draw(false, 0.0)
    get_tree().get_root().render_target_update_mode = Viewport.UPDATE_ALWAYS
    $Helper.render_target_update_mode = Viewport.UPDATE_DISABLED
    
    return $Helper.get_texture().get_data()


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
    var bias = read_range($"Tabs/AO Map/Slider7")
    var comparison_bias = read_range($"Tabs/AO Map/Slider7")
    var contrast = read_range($"Tabs/AO Map/Slider8")
    var fine_limit = read_range($"Tabs/AO Map/Slider9")
    var rough_limit = read_range($"Tabs/AO Map/Slider10")
    
    strength = max(0.00000001, strength*strength*100.0)
    
    ao_image = create_ao_texture(depth_image, strength, freq_high, freq_mid, freq_low, freq_balance, exponent, lerp(comparison_bias, 0.5, 0.95), contrast, fine_limit/strength*2.0, rough_limit/strength*2.0)
    
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
    
    light_remover_slider_changed(0.0)

var albedo_ref_image = null
var albedo_ref_tex = null
var albedo_ref_ao_image = null
var albedo_ref_ao_tex = null
func create_unlit_albedo_image(albedo_image : Image, ao_image : Image, normal_image : Image, depth_image, ao_strength, ao_limit, ao_gamma, ao_desat):
    if albedo_ref_image != albedo_image or albedo_ref_tex == null:
        albedo_ref_image = albedo_image
        albedo_ref_tex = ImageTexture.new()
        albedo_ref_tex.create_from_image(albedo_image)
    
    if albedo_ref_ao_image != ao_image or albedo_ref_ao_tex == null:
        albedo_ref_ao_image = ao_image
        albedo_ref_ao_tex = ImageTexture.new()
        albedo_ref_ao_tex.create_from_image(ao_image)
    
    var mat = $Helper/Quad.material_override as ShaderMaterial
    $Helper.keep_3d_linear = false
    mat.shader = preload("res://AORemover.gdshader")
    mat.set_shader_param("albedo", albedo_ref_tex)
    mat.set_shader_param("ao", albedo_ref_ao_tex)
    mat.set_shader_param("ao_strength", ao_strength)
    mat.set_shader_param("ao_limit", ao_limit)
    mat.set_shader_param("ao_gamma", ao_gamma)
    mat.set_shader_param("ao_desat", ao_desat)
    
    var size = albedo_image.get_size()
    $Helper.size = size
    $Helper/Quad.scale.x = size.x / size.y
    
    $Helper.render_target_update_mode = Viewport.UPDATE_ALWAYS
    get_tree().get_root().render_target_update_mode = Viewport.UPDATE_DISABLED
    VisualServer.force_draw(false, 0.0)
    get_tree().get_root().render_target_update_mode = Viewport.UPDATE_ALWAYS
    $Helper.render_target_update_mode = Viewport.UPDATE_DISABLED
    
    return $Helper.get_texture().get_data()

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
    
    albedo_image_display = create_unlit_albedo_image(albedo_image, ao_image, normal_image, depth_image, ao_strength, ao_limit, ao_gamma*ao_gamma*4.0, ao_desat*4.0)
    
    albedo = ImageTexture.new()
    albedo.create_from_image(albedo_image_display)
    albedo.flags |= ImageTexture.FLAG_ANISOTROPIC_FILTER
    
    mat_3d.albedo_texture = albedo
    if !indirect_update:
        var n2 = albedo.duplicate(true)
        mat_texture.set_shader_param("image", n2)

func create_metal_texture(image : Image, colors : Array, mixing_bias : float, contrast : float, shrink_radius : int, blur_radius):
    mixing_bias = mixing_bias*mixing_bias
    if ref_image != image or ref_tex == null:
        ref_image = image
        ref_tex = ImageTexture.new()
        ref_tex.create_from_image(image)
    
    if colors.size() == 0:
        colors = [Color(0, 0, 0, 0)]
    
    var img = Image.new()
    img.create(colors.size(), 1, false, Image.FORMAT_RGBA8)
    img.lock()
    for i in colors.size():
        img.set_pixel(i, 0, colors[i])
    img.unlock()
    var color_tex = ImageTexture.new()
    color_tex.create_from_image(img)
    
    var mat = $Helper/Quad.material_override as ShaderMaterial
    $Helper.keep_3d_linear = true
    mat.shader = preload("res://MetallicityGenerator.gdshader")
    mat.set_shader_param("albedo", ref_tex)
    mat.set_shader_param("colors", color_tex)
    mat.set_shader_param("mixing_bias", mixing_bias)
    mat.set_shader_param("contrast", contrast)
    mat.set_shader_param("shrink_radius", shrink_radius)
    mat.set_shader_param("blur_radius", blur_radius)
    
    var size = image.get_size()
    $Helper.size = size
    $Helper/Quad.scale.x = size.x / size.y
    
    $Helper.render_target_update_mode = Viewport.UPDATE_ALWAYS
    get_tree().get_root().render_target_update_mode = Viewport.UPDATE_DISABLED
    VisualServer.force_draw(false, 0.0)
    get_tree().get_root().render_target_update_mode = Viewport.UPDATE_ALWAYS
    $Helper.render_target_update_mode = Viewport.UPDATE_DISABLED
    
    return $Helper.get_texture().get_data()


func metal_slider_changed(_unused : float):
    if albedo_image == null:
        return
    if setting_sliders:
        return
    
    var mixing_bias = read_range($"Tabs/Metal Map/HBoxContainer/HSlider")
    var contrast = read_range($"Tabs/Metal Map/HBoxContainer2/HSlider")
    var shrink_radius = $"Tabs/Metal Map/HBoxContainer3/HSlider".value
    var blur_radius = 0
    
    var colors = []
    for c in $"Tabs/Metal Map".get_children():
        if c.get_child_count() >= 3:
            var color = (c.get_child(0) as ColorRect).color
            var slider : Range = c.get_child(2)
            colors.push_back(Color(color.r, color.g, color.b, read_range(slider)))
    
    metal_image = create_metal_texture(albedo_image, colors, mixing_bias, contrast, shrink_radius, blur_radius)
    
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
    var contrast = read_range($"Tabs/Roughness Map/HBoxContainer2/HSlider")
    var shrink_radius = $"Tabs/Roughness Map/HBoxContainer3/HSlider".value
    var blur_radius = $"Tabs/Roughness Map/HBoxContainer4/HSlider".value
    
    var colors = []
    for c in $"Tabs/Roughness Map".get_children():
        if c.get_child_count() >= 3:
            var color = (c.get_child(0) as ColorRect).color
            var slider : Range = c.get_child(2)
            colors.push_back(Color(color.r, color.g, color.b, read_range(slider)))
    
    roughness_image = create_metal_texture(albedo_image, colors, mixing_bias, contrast, shrink_radius, blur_radius)
    
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
    else:
        next_texture = albedo
    
    if current_preview_texture != next_texture:
        current_preview_texture = next_texture
        $PanelContainer/TextureRect.texture = next_texture.duplicate(true)

    processing = false

var color_picking = ""
var color_which = -1

func start_picking_color(type : String, which : int):
    Input.set_custom_mouse_cursor(preload("res://spoit.png"), Input.CURSOR_ARROW, Vector2(1, 20))
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
    
    button.texture_hover = preload("res://x.png")
    button.texture_normal = preload("res://x.png")
    button.texture_disabled = preload("res://x.png")
    button.texture_focused = preload("res://x.png")
    button.texture_pressed = preload("res://x.png")
    
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
        mesh = preload("res://cylinder_good_uvs.obj")
        $"3D/MeshHolder/Mesh".scale *= 0.7
        set_uv_scale(Vector3(1, 1, 1))
    elif which == "sideways cylinder":
        #mesh = CylinderMesh.new()
        #mesh.radial_segments = 256
        #mesh.rings = 0
        mesh = preload("res://cylinder_good_uvs.obj")
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
