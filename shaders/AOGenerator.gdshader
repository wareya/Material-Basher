shader_type spatial;
render_mode unshaded, ambient_light_disabled, blend_mix, shadows_disabled, specular_disabled;
uniform sampler2D depth;
uniform sampler2D octave_0;
uniform sampler2D octave_1;
uniform sampler2D octave_2;

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
    vec2 base_size = vec2(textureSize(depth, 0));
    int max_level = int(floor(log2(max(base_size.x, base_size.y))));
    
    float fine = texture(octave_0, UV).r;
    float mid  = texture(octave_1, UV).r;
    float low  = texture(octave_2, UV).r;
    
    float real_bias = bias-0.5;
    
    float raw_ao_fine  = min( fine_limit, fine-mid);
    float raw_ao_broad = min(rough_limit, mid -low);
    
    float ao_fine  = 1.0 - max(0, raw_ao_fine  - real_bias)*strength;
    float ao_broad = 1.0 - max(0, raw_ao_broad - real_bias)*strength;
    
    float f = mix(ao_fine, ao_broad, freq_balance);
    
    f = (f-1.0)*contrast*2.0+1.0;
    
    float real_exponent = clamp(exponent, 0.01, 0.99)*2.0;
    if (real_exponent > 1.0)
    {
        real_exponent = 2.0-real_exponent;
        f = 1.0-pow(1.0-f, 1.0/real_exponent);
    }
    else
        f = pow(f, 1.0/real_exponent);
    
    ALBEDO = vec3(f);
}
