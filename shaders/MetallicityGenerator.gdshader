shader_type spatial;
render_mode unshaded, ambient_light_disabled, blend_mix, shadows_disabled, specular_disabled;
uniform sampler2D albedo : hint_albedo;
uniform sampler2D colors : hint_albedo;
uniform float mixing_bias;
uniform float mixing_exponent;
uniform float contrast;
uniform float bias;
uniform int shrink_radius;
uniform int blur_radius;
uniform bool is_roughness;

uniform float supersample;

vec3 toLinear(vec3 sRGB)
{
    bvec3 cutoff = lessThan(sRGB, vec3(0.04045));
    vec3 higher = pow((sRGB + vec3(0.055))/vec3(1.055), vec3(2.4));
    vec3 lower = sRGB/vec3(12.92);

    return mix(higher, lower, cutoff);
}
vec3 toSrgb(vec3 linearRGB)
{
    bvec3 cutoff = lessThan(linearRGB, vec3(0.0031308));
    vec3 higher = vec3(1.055)*pow(linearRGB, vec3(1.0/2.4)) - vec3(0.055);
    vec3 lower = linearRGB * vec3(12.92);

    return mix(higher, lower, cutoff);
}

void vertex() {
    UV = UV;
}

float get_metallicity(vec2 uv) {
    vec3 albedo_color = toSrgb(texture(albedo, uv).rgb);
    int color_count = textureSize(colors, 0).x;
    
    float mean = 0.0;
    float energy = 0.0;
    float metallicity = 0.0;
    for(int i = 0; i < color_count; i++)
    {
        vec4 data = texelFetch(colors, ivec2(i, 0), 0);
        vec3 color = toSrgb(data.rgb);
        float metal = data.a;
        float weight = length(color - albedo_color) + mixing_bias/10.0*mixing_exponent + 0.0000001;
        weight = pow(1.0/weight, mixing_exponent);
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
    
    return clamp(metallicity, 0.0, 1.0);
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
            
            float metal = 0.0;
            if (supersample > 0.0)
            {
                for(int _y = -1; _y <= 1; _y += 1)
                {
                    for(int _x = -1; _x <= 1; _x += 1)
                    {
                        metal += get_metallicity(uv + vec2(ivec2(x, y))*px + vec2(ivec2(_x, _y))*px*supersample);
                    }
                }
                metal /= 9.0;
            }
            else
                metal = get_metallicity(uv + vec2(ivec2(x, y))*px);
            
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
