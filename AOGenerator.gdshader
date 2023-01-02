shader_type spatial;
render_mode unshaded, ambient_light_disabled, blend_mix, shadows_disabled, specular_disabled;
uniform sampler2D depth : hint_albedo;

uniform float strength;

uniform float freq_low;
uniform float freq_mid;
uniform float freq_high;
uniform float freq_balance;

void vertex() {
    UV = UV;
}

float weight_1(float i) {
    return -2.0*i*i*i + 3.0*i*i;
}

float weight_2(float i) {
    return i*i*i - i*i;
}

vec4 bicubic(vec4 a, vec4 b, vec4 c, vec4 d, float i) {
    a = c-a;
    d = d-b;
    float a_w = -weight_2(1.0 - i);
    float b_w = 1.0 - weight_1(i);
    float c_w = 1.0 - b_w;
    float d_w = weight_2(i);
    
    //return mix(b, c, i);
    return a*a_w + b*b_w + c*c_w + d*d_w;
}

vec4 texelFetchSafe(sampler2D tex, ivec2 uv, int mip_level) {
    ivec2 s = textureSize(tex, mip_level);
    //uv += s/2;
    uv.x = ((uv.x % s.x) + s.x) % s.x;
    uv.y = ((uv.y % s.y) + s.y) % s.y;
    return texelFetch(tex, uv, mip_level);
}

vec4 bicubic_stride(sampler2D tex, ivec2 b, ivec2 c, int mip_level, float i) {
    vec4 h_a = texelFetchSafe(tex, b + (b-c), mip_level);
    vec4 h_b = texelFetchSafe(tex, b        , mip_level);
    vec4 h_c = texelFetchSafe(tex, c        , mip_level);
    vec4 h_d = texelFetchSafe(tex, c + (c-b), mip_level);
    
    return bicubic(h_a, h_b, h_c, h_d, i);
    //return h_b;// bicubic(h_a, h_b, h_c, h_d, i);
}

vec4 sample_bicubic(sampler2D tex, vec2 uv, int mip_level) {
    vec2 px = 1.0/vec2(textureSize(tex, mip_level));
    
    uv -= px*0.5;
    
    ivec2 uv_start = ivec2(floor(uv / px));
    float x_i = (uv.x/px.x - float(uv_start.x));
    float y_i = (uv.y/px.y - float(uv_start.y));
    
    vec4 a = bicubic_stride(tex, uv_start + ivec2(0, -1), uv_start + ivec2(1, -1), mip_level, x_i);
    vec4 b = bicubic_stride(tex, uv_start + ivec2(0,  0), uv_start + ivec2(1,  0), mip_level, x_i);
    vec4 c = bicubic_stride(tex, uv_start + ivec2(0,  1), uv_start + ivec2(1,  1), mip_level, x_i);
    vec4 d = bicubic_stride(tex, uv_start + ivec2(0,  2), uv_start + ivec2(1,  2), mip_level, x_i);
    
    vec4 done = bicubic(a, b, c, d, y_i);
    
    return done;
}

vec4 sample_bicubic_blurry(sampler2D tex, vec2 uv, int mip_level) {
    if(mip_level == 0)
        return sample_bicubic(tex, uv, mip_level);
    else
    {
        mip_level -= 1;
        vec2 off = 0.25/vec2(textureSize(tex, mip_level));
        vec4 c00 = sample_bicubic(tex, uv + vec2(-1, -1)*off, mip_level);
        vec4 c20 = sample_bicubic(tex, uv + vec2( 1, -1)*off, mip_level);
        vec4 c02 = sample_bicubic(tex, uv + vec2(-1,  1)*off, mip_level);
        vec4 c22 = sample_bicubic(tex, uv + vec2( 1,  1)*off, mip_level);
        return (c00+c20+c02+c22)/4.0;
    }
}
vec4 sample_bicubic_super_blurry(sampler2D tex, vec2 uv, int mip_level) {
    if(mip_level == 0)
        return sample_bicubic(tex, uv, mip_level);
    else if(mip_level == 1)
        return sample_bicubic_blurry(tex, uv, mip_level);
    else
    {
        mip_level -= 2;
        vec2 off = 0.25/vec2(textureSize(tex, mip_level));
        vec4 ret = vec4(0);
        for (int y = -3; y <= 3; y += 2)
        {
            for (int x = -3; x <= 3; x += 2)
            {
                ret += sample_bicubic(tex, uv + vec2(ivec2(x, y))*off, mip_level);
            }
        }
        return ret/16.0;
    }
}

vec4 get_mip_level(sampler2D tex, vec2 uv, int mip_level) {
    float stride = 0.5;
    return vec4(sample_bicubic_super_blurry(tex, uv, mip_level).r, 0, 0, 0);
}

// TODO integrate
vec4 get_mip_level_fast(sampler2D tex, vec2 uv, int mip_level) {
    float stride = 0.5;
    return vec4(texture(tex, uv, float(mip_level)).r, 0, 0, 0);
}

vec4 get_octave(sampler2D tex, vec2 uv, float octave) {
    vec2 base_size = vec2(textureSize(tex, 0));
    int max_level = int(floor(log2(max(base_size.x, base_size.y))));
    //float octave_adjusted = mix(2.22, 6.0, float(octave)/6.0);
    //float octave_level = mix(0.0, float(max_level), float(octave_adjusted)/6.0);
    //float mip_level = float(max_level) - octave_level;
    //float mip_level = float(max_level) - float(octave+3.0);
    //if (octave == 6)
    //    mip_level = 0.0;
    //else if (octave == 5)
    //    mip_level = mix(float(max_level) - 7.0, 0.0, 0.5);
    octave = float(max_level) - octave;
    float mip_level = clamp(octave, 0.0, float(max_level));
    
    float lower = floor(mip_level);
    float higher = ceil(mip_level);
    float between = mip_level-lower;
    
    vec4 a = get_mip_level(tex, uv, int(lower));
    vec4 b = get_mip_level(tex, uv, int(higher));
    
    vec4 c = mix(a, b, between);
    
    return c;
}

void fragment() {
    vec2 base_size = vec2(textureSize(depth, 0));
    int max_level = int(floor(log2(max(base_size.x, base_size.y))));
    
    float real_freq_mid = freq_mid * freq_high;
    float real_freq_low = freq_low * real_freq_mid;
    
    float fine = get_octave(depth, UV, float(max_level)*freq_high).r;
    float mid  = get_octave(depth, UV, float(max_level)*real_freq_mid).r;
    float low  = get_octave(depth, UV, float(max_level)*real_freq_low).r;
    
    float ao_fine  = 1.0 - max(0, fine-mid)*strength;
    float ao_broad = 1.0 - max(0, mid -low)*strength;
    
    ALBEDO = vec3(mix(ao_fine, ao_broad, freq_balance));
}
