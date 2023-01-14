shader_type spatial;
render_mode unshaded, ambient_light_disabled, blend_mix, shadows_disabled, specular_disabled;
uniform sampler2D octave_0 : hint_white;
uniform sampler2D octave_1 : hint_white;
uniform sampler2D octave_2 : hint_white;

uniform float strength;

uniform float freq_balance;

uniform float exponent;
uniform float bias;
uniform float contrast;
uniform float fine_limit;
uniform float rough_limit;

void vertex() {
    UV = UV;
}

void fragment() {
    vec2 base_size = vec2(textureSize(octave_0, 0));
    int max_level = int(floor(log2(max(base_size.x, base_size.y))));
    
    float fine = texture(octave_0, UV).r;
    float mid  = texture(octave_1, UV).r;
    float low  = texture(octave_2, UV).r;
    
    
    float raw_ao_fine  = clamp(fine-mid, -fine_limit, fine_limit);
    float raw_ao_broad = clamp(mid -low, -rough_limit, rough_limit);
    
    float ao_fine  = 1.0 - max(0, raw_ao_fine  - bias)*strength;
    float ao_broad = 1.0 - max(0, raw_ao_broad - bias)*strength;
    
    float f = mix(ao_fine, ao_broad, freq_balance);
    
    f = (f-1.0)*contrast*2.0+1.0;
    
    float real_exponent = clamp(1.0-exponent, 0.0, 1.0)*2.0;
    if (real_exponent > 1.0)
        f = pow(f, pow(2.0, (real_exponent-1.0)*2.0));
    else
        f = 1.0-pow(1.0-f, pow(2.0, (1.0-real_exponent)*6.0));
    
    ALBEDO = vec3(f);
}
