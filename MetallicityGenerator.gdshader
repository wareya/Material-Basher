shader_type spatial;
render_mode unshaded, ambient_light_disabled, blend_mix, shadows_disabled, specular_disabled;
uniform sampler2D height : hint_albedo;
uniform sampler2D albedo : hint_albedo;
uniform sampler2D colors : hint_albedo;
uniform float mixing_bias;
uniform float contrast;
uniform float bias;
uniform int shrink_radius;
uniform int blur_radius;

void vertex() {
    UV = UV;
}

float get_metallicity(vec2 uv) {
    vec3 albedo_color = texture(albedo, uv).rgb;
    int color_count = textureSize(colors, 0).x;
    
    float mean = 0.0;
    float energy = 0.0;
    float metallicity = 0.0;
    for(int i = 0; i < color_count; i++)
    {
        vec4 data = texelFetch(colors, ivec2(i, 0), 0);
        vec3 color = data.rgb;
        float metal = data.a;
        float weight = length(color - albedo_color);
        weight = 1.0/(weight*weight + mixing_bias/10.0 + 0.00001);
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
    
    return metallicity;
}

float get_expanded(vec2 uv) {
    vec2 px = 1.0/vec2(textureSize(albedo, 0));
    bool expand = shrink_radius < 0;
    int radius = abs(shrink_radius);
    float metallicity = expand ? 0.0 : 1.0;
    for(int x = -radius; x <= radius; x += 1)
    {
        for(int y = -radius; y <= radius; y += 1)
        {
            if(sqrt(float(x*x + y*y)) > float(radius))
                continue;
            float metal = get_metallicity(uv + vec2(ivec2(x, y))*px);
            if (expand)
                metallicity = max(metallicity, metal);
            else
                metallicity = min(metallicity, metal);
        }
    }
    return metallicity;
}
float gauss_raw(float x) {
    return exp(-(x*x));
}
float gauss(float x) {
    float d = gauss_raw(1.5);
    float r = gauss_raw(x*1.5);
    return r - d; // normalization will take care of the energy lost by this later
}
float get_blurred(vec2 uv) {
    vec2 px = 1.0/vec2(textureSize(albedo, 0));
    int radius = abs(blur_radius);
    float metallicity = 0.0;
    float energy = 0.0;
    for(int x = -radius; x <= radius; x += 1)
    {
        for(int y = -radius; y <= radius; y += 1)
        {
            float r = sqrt(float(x*x + y*y));
            if(r > float(radius))
                continue;
            float metal = get_expanded(uv + vec2(ivec2(x, y))*px);
            float amp = 1.0;//gauss(r/float(radius));
            metallicity += metal * amp;
            energy += amp;
        }
    }
    return metallicity / energy;
}

void fragment() {
    float metallicity = get_blurred(UV);
    ALBEDO = vec3(metallicity);
}
