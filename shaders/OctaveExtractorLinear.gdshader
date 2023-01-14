shader_type spatial;
render_mode unshaded, ambient_light_disabled, blend_mix, shadows_disabled, specular_disabled;
uniform sampler2D input : hint_white;

uniform vec3 channel;
uniform int octave;
uniform float raw_mip_ratio;
uniform float microfacets;
uniform bool nowrap;

void vertex() {
    UV = UV;
}

float weight_1(float i) { // smoothstep
    return -2.0*i*i*i + 3.0*i*i;
}

float weight_2(float i) { // tangent
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
    if(nowrap)
    {
        uv.x = clamp(uv.x, 0, s.x-1);
        uv.y = clamp(uv.y, 0, s.y-1);
    }
    else
    {
        uv.x = ((uv.x % s.x) + s.x) % s.x;
        uv.y = ((uv.y % s.y) + s.y) % s.y;
    }
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

vec4 sample_smoothstepped(sampler2D tex, vec2 uv, int mip_level) {
    vec2 px = 1.0/vec2(textureSize(tex, mip_level));
    
    uv -= px*0.5;
    
    ivec2 uv_start = ivec2(floor(uv / px));
    float x_i = (uv.x/px.x - float(uv_start.x));
    float y_i = (uv.y/px.y - float(uv_start.y));
    
    vec4 a = texelFetchSafe(tex, uv_start + ivec2(0, 0), mip_level);
    vec4 b = texelFetchSafe(tex, uv_start + ivec2(1, 0), mip_level);
    vec4 c = texelFetchSafe(tex, uv_start + ivec2(0, 1), mip_level);
    vec4 d = texelFetchSafe(tex, uv_start + ivec2(1, 1), mip_level);
    
    vec4 a_b = mix(a, b, x_i);
    vec4 c_d = mix(c, d, x_i);
    
    return mix(a_b, c_d, y_i);
}

vec4 sample_bicubic_super_blurry(sampler2D tex, vec2 uv, int mip_level) {
    if(mip_level == 0)
        return sample_bicubic(tex, uv, mip_level);
    else if(mip_level == 1)
    {
        mip_level -= 1;
        vec2 off = 0.5/vec2(textureSize(tex, mip_level));
        vec4 ret = vec4(0);
        for (int y = -1; y <= 1; y += 2)
        {
            for (int x = -1; x <= 1; x += 2)
            {
                ret += sample_bicubic(tex, uv + vec2(ivec2(x, y))*off, mip_level);
            }
        }
        return ret/4.0;
    }
    else
    {
        mip_level -= 2;
        vec2 off = 0.25/vec2(textureSize(tex, mip_level));
        vec4 ret = vec4(0);
        for (int y = -3; y <= 3; y += 2)
        {
            for (int x = -3; x <= 3; x += 2)
            {
                ret += sample_smoothstepped(tex, uv + vec2(ivec2(x, y))*off, mip_level);
            }
        }
        return ret/16.0;
    }
}

void fragment() {
    vec2 base_size = vec2(textureSize(input, 0));
    int max_level = int(floor(log2(max(base_size.x, base_size.y))));
    
    float offset = 2.0;
    float mip_level = float(max_level) - float(octave) - offset;
    float with_microfacets = mip_level;
    if (octave == 6)
        with_microfacets = 0.0;
    else if (octave == 5)
        with_microfacets = mix(float(max_level) - 4.0 - offset, 0.0, 0.33);
    mip_level = mix(mip_level, with_microfacets, microfacets);
    
    mip_level = max(0.0, mip_level);
    
    if(raw_mip_ratio >= 0.0)
        mip_level = mix(float(max_level), 0.0, raw_mip_ratio);
    
    float lower = floor(mip_level);
    float higher = ceil(mip_level);
    float between = mip_level-lower;
    
    vec4 a = sample_bicubic_super_blurry(input, UV, int(lower));
    vec4 b = sample_bicubic_super_blurry(input, UV, int(higher));
    
    vec4 c = mix(a, b, between);
    
    ALBEDO = c.rgb;
}
