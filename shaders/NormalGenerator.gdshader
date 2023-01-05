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

uniform sampler2D octave_0 : hint_albedo;
uniform sampler2D octave_1 : hint_albedo;
uniform sampler2D octave_2 : hint_albedo;
uniform sampler2D octave_3 : hint_albedo;
uniform sampler2D octave_4 : hint_albedo;
uniform sampler2D octave_5 : hint_albedo;
uniform sampler2D octave_6 : hint_albedo;

uniform float darkpoint;
uniform float midpoint;
uniform float midpoint_offset;
uniform float lightpoint;

uniform float depth_offset;

uniform vec3 channel;

uniform float generate_normal;

uniform float microfacets;

uniform bool early_adjust;

void vertex() {
    UV = UV;
}

float octave_to_mip_level(int octave) {
    vec2 base_size = vec2(textureSize(albedo, 0));
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
    
    return mip_level;
}

const float stride = 0.25;
vec4 get_mip_level(sampler2D tex, vec2 uv, int octave) {
    float mip_level = octave_to_mip_level(octave);
    if (generate_normal > 0.5)
    {
        float low = floor(mip_level);
        float high = ceil(mip_level);
        vec2 size_low  = stride/vec2(textureSize(albedo, int(low)));
        vec2 size_high = stride/vec2(textureSize(albedo, int(high)));
        vec2 off = mix(size_low, size_high, mip_level - low);
        float x1 = dot(texture(tex, uv + off * vec2(-1, 0)).rgb, channel)*3.0;
        float x2 = dot(texture(tex, uv + off * vec2( 1, 0)).rgb, channel)*3.0;
        float y1 = dot(texture(tex, uv + off * vec2(0, -1)).rgb, channel)*3.0;
        float y2 = dot(texture(tex, uv + off * vec2(0,  1)).rgb, channel)*3.0;
        
        return vec4(x1, x2, y1, y2);
    }
    else
    {
        return vec4(dot(texture(tex, uv).rgb, channel)*3.0, 0, 0, 0);
    }
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
    
    vec4 samples[] = {
        get_mip_level(octave_0, UV, 0),
        get_mip_level(octave_1, UV, 1),
        get_mip_level(octave_2, UV, 2),
        get_mip_level(octave_3, UV, 3),
        get_mip_level(octave_4, UV, 4),
        get_mip_level(octave_5, UV, 5),
        get_mip_level(octave_6, UV, 6)
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
        if (early_adjust)
        {
            vec4 data = samples[i];
            mapped_midpoint += map_to_points(image_midpoint)*abs(amp);
            x1 += map_to_points(data.x)*abs(amp);
            x2 += map_to_points(data.y)*abs(amp);
            y1 += map_to_points(data.z)*abs(amp);
            y2 += map_to_points(data.w)*abs(amp);
        }
        else
        {
            vec4 data = samples[i]*abs(amp);
            mapped_midpoint += map_to_points(image_midpoint*abs(amp))*sign(amp);
            x1 += map_to_points(data.x)*sign(amp);
            x2 += map_to_points(data.y)*sign(amp);
            y1 += map_to_points(data.z)*sign(amp);
            y2 += map_to_points(data.w)*sign(amp);
        }
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
        x1 *= strength*0.5/stride;
        x2 *= strength*0.5/stride;
        y1 *= strength*0.5/stride;
        y2 *= strength*0.5/stride;
        
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
