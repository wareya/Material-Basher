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

uniform float darkpoint;
uniform float midpoint;
uniform float midpoint_offset;
uniform float lightpoint;

uniform float depth_offset;

uniform vec3 channel;

uniform float generate_normal;

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
    if (generate_normal > 0.5)
    {
        vec2 off = stride/vec2(textureSize(albedo, mip_level));
        float x1 = dot(sample_bicubic_blurry(albedo, uv + off * vec2(-1, 0), mip_level).rgb, channel)*3.0;
        float x2 = dot(sample_bicubic_blurry(albedo, uv + off * vec2( 1, 0), mip_level).rgb, channel)*3.0;
        float y1 = dot(sample_bicubic_blurry(albedo, uv + off * vec2(0, -1), mip_level).rgb, channel)*3.0;
        float y2 = dot(sample_bicubic_blurry(albedo, uv + off * vec2(0,  1), mip_level).rgb, channel)*3.0;
        
        return vec4(x1, x2, y1, y2)/stride*0.5;
    }
    else
    {
        return vec4(dot(sample_bicubic_blurry(albedo, uv, mip_level).rgb, channel)*3.0, 0, 0, 0);
    }
}

// TODO integrate
vec4 get_mip_level_fast(sampler2D tex, vec2 uv, int mip_level) {
    float stride = 0.5;
    if (generate_normal > 0.5)
    {
        vec2 off = stride/vec2(textureSize(albedo, mip_level));
        float x1 = dot(texture(albedo, uv + off * vec2(-1, 0), float(mip_level)).rgb, channel);
        float x2 = dot(texture(albedo, uv + off * vec2( 1, 0), float(mip_level)).rgb, channel);
        float y1 = dot(texture(albedo, uv + off * vec2(0, -1), float(mip_level)).rgb, channel);
        float y2 = dot(texture(albedo, uv + off * vec2(0,  1), float(mip_level)).rgb, channel);
        
        return vec4(x1, x2, y1, y2)/stride*0.5;
    }
    else
    {
        return vec4(dot(texture(albedo, uv, float(mip_level)).rgb, channel)*3.0, 0, 0, 0);
    }
}

vec4 get_octave(sampler2D tex, vec2 uv, int octave) {
    vec2 base_size = vec2(textureSize(albedo, 0));
    int max_level = int(floor(log2(max(base_size.x, base_size.y))));
    //float octave_adjusted = mix(2.22, 6.0, float(octave)/6.0);
    //float octave_level = mix(0.0, float(max_level), float(octave_adjusted)/6.0);
    //float mip_level = float(max_level) - octave_level;
    float mip_level = float(max_level) - float(octave+3);
    if (octave == 6 && generate_normal > 0.5)
        mip_level = 0.0;
    else if (octave == 5 && generate_normal > 0.5)
        mip_level = mix(float(max_level) - 7.0, 0.0, 0.5);
    mip_level = max(0.0, mip_level);
    
    float lower = floor(mip_level);
    float higher = ceil(mip_level);
    float between = mip_level-lower;
    
    vec4 a = get_mip_level(tex, uv, int(lower));
    vec4 b = get_mip_level(tex, uv, int(higher));
    
    vec4 c = mix(a, b, between);
    
    return c;
}

float map_to_points(float x) {
    float offset = midpoint_offset;
    if (offset < 0.001)
        offset = 0.001;
    if (offset > 0.999)
        offset = 0.999;
    if (x > offset)
        return mix(midpoint, lightpoint, (x - offset) / (1.0 - offset));
    else
        return mix(darkpoint, midpoint, x / offset);
}

void fragment() {
    vec2 base_size = vec2(textureSize(albedo, 0));
    int max_level = int(floor(log2(max(base_size.x, base_size.y))));
    
    float image_midpoint = dot(texture(albedo, vec2(0), float(max_level)).rgb, channel)*3.0;
    
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
    float mapped_midpoint = 0.0;
    for(int i = 0; i < 7; i++)
    {
        float amp = band_strength[i];
        if (i == 0)
            amp *= 2.0;
        else if (i == 1)
            amp *= 1.5;
        vec4 data = get_octave(albedo, UV, i)*abs(amp);
        mapped_midpoint += map_to_points(image_midpoint*abs(amp))*sign(amp);
        x1 += map_to_points(data.x)*sign(amp);
        x2 += map_to_points(data.y)*sign(amp);
        y1 += map_to_points(data.z)*sign(amp);
        y2 += map_to_points(data.w)*sign(amp);
        energy += abs(amp);
    }
    
    energy = max(energy, 0.000001);
    
    mapped_midpoint /= energy;
    
    x1 /= energy;
    x2 /= energy;
    y1 /= energy;
    y2 /= energy;
    
    if (generate_normal > 0.5)
    {
        x1 *= strength;
        x2 *= strength;
        y1 *= strength;
        y2 *= strength;
        
        vec3 x_n = cross(vec3(0, -1, 0), normalize(vec3(1, 0, x2-x1)));
        vec3 y_n = cross(vec3(1,  0, 0), normalize(vec3(0, 1, y2-y1)));
        
        vec3 n = normalize(x_n + y_n + vec3(0, 0, 1));
        n = n*vec3(0.5, -0.5, 0.5) + vec3(0.5);
        //n = vec3(x1, x1, x1);
        
        //int level = 4;
        //vec2 size = vec2(textureSize(albedo, level));
        //ALBEDO = texelFetchSafe(albedo, ivec2(UV * size), level).rgb;
        if (isnan(n).x)
            ALBEDO = vec3(0.5, 1.0, 0.5);
        else
            ALBEDO = n;
        //ALBEDO = sample_bicubic(albedo, UV, 1).rgb;
    }
    else
    {
        x1 += (midpoint - mapped_midpoint);
        x1 = 1.0 - x1;
        x1 *= strength;
        x1 += (depth_offset - 0.5)*2.0;
        ALBEDO = vec3(x1);
    }
}
