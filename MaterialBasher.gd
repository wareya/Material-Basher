extends Control

var normal_image : Image
var normal : ImageTexture

var depth_image : Image
var depth : ImageTexture

var albedo_image : Image
var albedo : ImageTexture

var mat_3d = SpatialMaterial.new()
var mat_texture = preload("res://UnshadedPlain.material")

# Called when the node enters the scene tree for the first time.
func _ready():
    $"3D/SphereHolder/Sphere".global_rotation.y += 1.5
    
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
    
    $ToggleMat.connect("pressed", self, "toggle_mat")
    get_tree().connect("files_dropped", self, "files_dropped")
    
    mat_3d.uv1_scale = Vector3(2, 1, 1)
    mat_texture.set_shader_param("uv1_scale", Vector3(2, 1, 1))
    
    $"3D/SphereHolder/Sphere".material_override = mat_3d

func toggle_mat():
    if $"3D/SphereHolder/Sphere".material_override == mat_3d:
        $"3D/SphereHolder/Sphere".material_override = mat_texture
    else:
        $"3D/SphereHolder/Sphere".material_override = mat_3d

func files_dropped(files : PoolStringArray, _screen : int):
    var fname : String = files[0]
    var file = File.new()
    file.open(fname, File.READ)
    var buffer = file.get_buffer(file.get_len())
    
    albedo_image = Image.new()
    fname = fname.to_lower()
    if fname.ends_with("bmp"):
        albedo_image.load_bmp_from_buffer(buffer)
    elif fname.ends_with("png"):
        albedo_image.load_png_from_buffer(buffer)
    elif fname.ends_with("jpg") or fname.ends_with("jpeg"):
        albedo_image.load_jpg_from_buffer(buffer)
    elif fname.ends_with("tga"):
        albedo_image.load_tga_from_buffer(buffer)
    elif fname.ends_with("webp"):
        albedo_image.load_webp_from_buffer(buffer)
    else:
        albedo_image = null
        return
    
    albedo = ImageTexture.new()
    albedo.create_from_image(albedo_image)
    albedo.flags |= ImageTexture.FLAG_ANISOTROPIC_FILTER
    
    mat_3d.albedo_texture = albedo
    
    #$"3D/SphereHolder/Sphere".material_override = mat_3d
    
    normal_slider_changed(0.0)

var setting_sliders = false
func normal_freq_preset(mode : String):
    var array = {
        "flat"   : [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 1.0],
        "smooth" : [1.0, 0.8, 0.6, 0.4, 0.2, 0.0, 0.0],
        "rough"  : [0.0, 0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
        "fuzzy"  : [1.0, 0.67, 0.33, 0.0, 0.33, 0.67, 1.0],
        "mids"   : [0.0, 0.33, 0.67, 1.0, 0.67, 0.33, 0.0],
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

func create_normal_texture(image : Image, strength, darkpoint, midpoint, midpoint_offset, lightpoint, depth_offset, generate_normal):
    var temp_tex = ImageTexture.new()
    temp_tex.create_from_image(image)
    
    var mat = $Helper/Quad.material_override as ShaderMaterial
    mat.set_shader_param("albedo", temp_tex)
    mat.set_shader_param("strength", strength)
    mat.set_shader_param("darkpoint", darkpoint)
    mat.set_shader_param("midpoint", midpoint)
    mat.set_shader_param("midpoint_offset", midpoint_offset)
    mat.set_shader_param("lightpoint", lightpoint)
    mat.set_shader_param("depth_offset", depth_offset)
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
    
    var depth_offset = 0.0;
    
    var image = albedo_image.duplicate(true)
    
    normal_image = create_normal_texture(image, strength*10.0, darkpoint, midpoint, midpoint_offset, lightpoint, depth_offset, 1.0)
    #normal_image.convert(Image.FORMAT_RGBA8)
    
    normal = ImageTexture.new()
    normal.create_from_image(normal_image)
    
    mat_3d.normal_enabled = true
    mat_3d.normal_texture = normal
    var n2 = normal.duplicate(true)
    mat_texture.set_shader_param("image", n2)
    
    mat_3d.uv1_scale = Vector3(2, 1, 1)


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
    
    var depth_offset = read_range($"Tabs/Depth Map/Slider6")
    
    var image = albedo_image.duplicate(true)
    
    depth_image = create_normal_texture(image, strength, darkpoint, midpoint, midpoint_offset, lightpoint, depth_offset, 0.0)
    #depth_image.convert(Image.FORMAT_RGBA8)
    
    depth = ImageTexture.new()
    depth.create_from_image(depth_image)
    
    mat_3d.depth_enabled = true
    mat_3d.depth_deep_parallax = true
    mat_3d.depth_texture = depth
    var n2 = depth.duplicate(true)
    mat_texture.set_shader_param("image", n2)
    
    mat_3d.uv1_scale = Vector3(2, 1, 1)


var zoom = 0
func _input(_event):
    if _event is InputEventMouseButton:
        var event : InputEventMouseButton = _event
        if event.button_index == BUTTON_WHEEL_UP:
            zoom += 1
        elif event.button_index == BUTTON_WHEEL_DOWN:
            zoom -= 1
        zoom = clamp(zoom, -16, 16)
        $"3D/CameraHolder/Camera".translation.z = 3 * pow(2, -zoom/16.0 * 1.3)
    pass


func _process(delta : float):
    $"3D/SphereHolder/Sphere".global_rotation.y += delta*0.1
    $"3D/LightHolder".global_rotation.y -= delta
    pass
