shader_type spatial;
render_mode unshaded, ambient_light_disabled, blend_mix, shadows_disabled, specular_disabled;
uniform sampler2D albedo : hint_albedo;
uniform float strength;
uniform float band_strength_0;
uniform float band_strength_1;
uniform float band_strength_2;
uniform float band_strength_3;
uniform float band_strength_4;
uniform float band_strength_5;
uniform float band_strength_6;

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
        vec2 off = 0.5/vec2(textureSize(tex, mip_level));
        vec4 a = sample_bicubic(tex, uv + vec2(-1, -1)*off, mip_level);
        vec4 b = sample_bicubic(tex, uv + vec2( 1, -1)*off, mip_level);
        vec4 c = sample_bicubic(tex, uv + vec2(-1,  1)*off, mip_level);
        vec4 d = sample_bicubic(tex, uv + vec2( 1,  1)*off, mip_level);
        return (a+b+d+d)*0.25;
    }
}

vec4 get_mip_level(sampler2D tex, vec2 uv, int mip_level) {
    float stride = 0.5;
    vec2 off = stride/vec2(textureSize(albedo, mip_level));
    float x1 = dot(sample_bicubic_blurry(albedo, uv + off * vec2(-1, 0), mip_level).rgb, vec3(1));
    float x2 = dot(sample_bicubic_blurry(albedo, uv + off * vec2( 1, 0), mip_level).rgb, vec3(1));
    float y1 = dot(sample_bicubic_blurry(albedo, uv + off * vec2(0, -1), mip_level).rgb, vec3(1));
    float y2 = dot(sample_bicubic_blurry(albedo, uv + off * vec2(0,  1), mip_level).rgb, vec3(1));
    
    return vec4(x1, x2, y1, y2)/stride*0.5;
}

vec4 get_octave(sampler2D tex, vec2 uv, int octave) {
    vec2 base_size = vec2(textureSize(albedo, 0));
    int max_level = int(floor(log2(max(base_size.x, base_size.y))));
    float octave_adjusted = mix(2.22, 6.0, float(octave)/6.0);
    float octave_level = mix(0.0, float(max_level), float(octave_adjusted)/6.0);
    float mip_level = float(max_level) - octave_level;
    float lower = floor(mip_level);
    float higher = ceil(mip_level);
    float between = mip_level-lower;
    
    vec4 a = get_mip_level(tex, uv, int(lower));
    vec4 b = get_mip_level(tex, uv, int(higher));
    
    return mix(a, b, between);
}

void fragment() {
    float band_strength[] = {
        band_strength_0,
        band_strength_1,
        band_strength_2,
        band_strength_3,
        band_strength_4,
        band_strength_5,
        band_strength_6
    };
    
    float energy = 0.0;
    float x1 = 0.0;
    float x2 = 0.0;
    float y1 = 0.0;
    float y2 = 0.0;
    for(int i = 0; i < 7; i++)
    {
        float amp = band_strength[i];
        vec4 data = get_octave(albedo, UV, i)*amp;
        x1 += data.x;
        x2 += data.y;
        y1 += data.z;
        y2 += data.w;
        energy += amp;
    }
    
    x1 *= strength/energy;
    x2 *= strength/energy;
    y1 *= strength/energy;
    y2 *= strength/energy;
    
    vec3 x_n = cross(vec3(0, -1, 0), normalize(vec3(1, 0, x2-x1)));
    vec3 y_n = cross(vec3(1,  0, 0), normalize(vec3(0, 1, y2-y1)));
    
    vec3 n = normalize(x_n + y_n + vec3(0, 0, 1));
    n = n*vec3(0.5, -0.5, 0.5) + vec3(0.5);
    //n = vec3(x1, x1, x1);
    
    //int level = 4;
    //vec2 size = vec2(textureSize(albedo, level));
    //ALBEDO = texelFetchSafe(albedo, ivec2(UV * size), level).rgb;
    ALBEDO = n;
    //ALBEDO = sample_bicubic(albedo, UV, 1).rgb;
}
