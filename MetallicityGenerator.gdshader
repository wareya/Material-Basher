shader_type spatial;
render_mode unshaded, ambient_light_disabled, blend_mix, shadows_disabled, specular_disabled;
uniform sampler2D albedo : hint_albedo;
uniform sampler2D colors : hint_albedo;
uniform float mixing_bias;
uniform float contrast;
uniform float bias;

void vertex() {
    UV = UV;
}

void fragment() {
    int color_count = textureSize(colors, 0).x;
    
    vec3 albedo_color = texture(albedo, UV).rgb;
    
    float mean = 0.0;
    float energy = 0.0;
    float metallicity = 0.0;
    for(int i = 0; i < color_count; i++)
    {
        vec4 data = texelFetch(colors, ivec2(i, 0), 0);
        vec3 color = data.rgb;
        float metal = data.a;
        float weight = length(color - albedo_color);
        weight = 1.0/(weight*weight + mixing_bias + 0.00001);
        metallicity += metal*weight;
        energy += weight;
        mean += metal;
    }
    
    mean /= float(color_count);
    metallicity = metallicity/max(energy, 0.000001);
    float contrast_adjusted = (contrast * 2.0);
    if (contrast_adjusted > 1.0)
        contrast_adjusted = 1.0 + (contrast_adjusted-1.0)*8.0;
    metallicity = (metallicity - mean) * contrast_adjusted + mean;
    
    ALBEDO = vec3(metallicity);
}
