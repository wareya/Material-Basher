extends Control

var normal_image : Image
var normal : ImageTexture

var albedo_image : Image
var albedo : ImageTexture

var mat_3d = SpatialMaterial.new()
var mat_texture = preload("res://UnshadedPlain.material")

# Called when the node enters the scene tree for the first time.
func _ready():
    $"3D/SphereHolder/Sphere".global_rotation.y += 1.5
# warning-ignore:return_value_discarded
    $"Tabs/Normal Map/Slider".connect("value_changed", self, "normal_slider_changed")
    $"Tabs/Normal Map/Freqs/VSlider1".connect("value_changed", self, "normal_slider_changed")
    $"Tabs/Normal Map/Freqs/VSlider2".connect("value_changed", self, "normal_slider_changed")
    $"Tabs/Normal Map/Freqs/VSlider3".connect("value_changed", self, "normal_slider_changed")
    $"Tabs/Normal Map/Freqs/VSlider4".connect("value_changed", self, "normal_slider_changed")
    $"Tabs/Normal Map/Freqs/VSlider5".connect("value_changed", self, "normal_slider_changed")
    $"Tabs/Normal Map/Freqs/VSlider6".connect("value_changed", self, "normal_slider_changed")
    $"Tabs/Normal Map/Freqs/VSlider7".connect("value_changed", self, "normal_slider_changed")
    $ToggleMat.connect("pressed", self, "toggle_mat")
# warning-ignore:return_value_discarded
    get_tree().connect("files_dropped", self, "files_dropped")
    
    mat_3d.uv1_scale = Vector3(2, 1, 1)
    mat_texture.set_shader_param("uv1_scale", Vector3(2, 1, 1))

func toggle_mat():
    if $"3D/SphereHolder/Sphere".material_override == mat_3d:
        $"3D/SphereHolder/Sphere".material_override = mat_texture
    else:
        $"3D/SphereHolder/Sphere".material_override = mat_3d
    

func files_dropped(files : PoolStringArray, screen : int):
    var fname : String = files[0]
    var file = File.new()
    file.open(fname, File.READ)
    var buffer = file.get_buffer(file.get_len())
    
    albedo_image = Image.new()
    fname = fname.to_lower()
    if fname.ends_with("bmp"):
# warning-ignore:return_value_discarded
        albedo_image.load_bmp_from_buffer(buffer)
    elif fname.ends_with("png"):
# warning-ignore:return_value_discarded
        albedo_image.load_png_from_buffer(buffer)
    elif fname.ends_with("jpg") or fname.ends_with("jpeg"):
# warning-ignore:return_value_discarded
        albedo_image.load_jpg_from_buffer(buffer)
    elif fname.ends_with("tga"):
# warning-ignore:return_value_discarded
        albedo_image.load_tga_from_buffer(buffer)
    elif fname.ends_with("webp"):
# warning-ignore:return_value_discarded
        albedo_image.load_webp_from_buffer(buffer)
    
    albedo = ImageTexture.new()
    albedo.create_from_image(albedo_image)
    albedo.flags |= ImageTexture.FLAG_ANISOTROPIC_FILTER
    
    mat_3d.albedo_texture = albedo
    
    $"3D/SphereHolder/Sphere".material_override = mat_3d


func normal_slider_changed(_unused : float):
    if albedo_image == null:
        return
    
    var strength_slider = $"Tabs/Normal Map/Slider"
    var strength = strength_slider.value / strength_slider.max_value
    
    var temp_image = albedo_image.duplicate(true)
    var mat = $Helper/Quad.material_override as ShaderMaterial
    
    var temp_tex = ImageTexture.new()
    temp_tex.create_from_image(temp_image, 3)
    
    mat.set_shader_param("albedo", temp_tex)
    mat.set_shader_param("strength", strength*10.0)
    
    for i in 7:
        var slider_name = "Tabs/Normal Map/Freqs/VSlider" + str(i+1)
        var slider = get_node(slider_name)
        var v = slider.value / slider.max_value
        mat.set_shader_param("band_strength_"+str(i), v)
    
    var size = temp_image.get_size()
    $Helper.size = size
    $Helper/Quad.scale.x = size.x / size.y
    
    $Helper.render_target_update_mode = Viewport.UPDATE_ALWAYS
    get_tree().get_root().render_target_update_mode = Viewport.UPDATE_DISABLED
    VisualServer.force_draw(false, 0.0)
    get_tree().get_root().render_target_update_mode = Viewport.UPDATE_ALWAYS
    $Helper.render_target_update_mode = Viewport.UPDATE_DISABLED
    
    normal_image = $Helper.get_texture().get_data()
    
    normal = ImageTexture.new()
    normal.create_from_image(normal_image)
    #normal.flags |= ImageTexture.FLAG_ANISOTROPIC_FILTER
    
    mat_3d.normal_enabled = true
    mat_3d.normal_texture = normal
    var n2 = normal.duplicate(true)
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
