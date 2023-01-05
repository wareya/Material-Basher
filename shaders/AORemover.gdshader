shader_type spatial;
render_mode unshaded, ambient_light_disabled, blend_mix, shadows_disabled, specular_disabled;
uniform sampler2D albedo : source_color;
uniform sampler2D ao : hint_default_white;
uniform sampler2D normal : hint_normal;

uniform float ao_strength;
uniform float ao_limit;
uniform float ao_gamma;
uniform float ao_desat;

void vertex() {
    UV = UV;
}

void fragment() {
    float ao_amp = min(1.0, ao_strength);
    float ao_mix = max(1.0, ao_strength);
    
    vec3 orig_albedo_color = texture(albedo, UV).rgb;
    vec3 albedo_color = orig_albedo_color;
    float ao_color = texture(ao, UV).r;
    float real_ao_limit = clamp(ao_limit, 1.0/255.0, 254.0/255.0);
    ao_color = pow(ao_color, ao_gamma);
    ao_color = max(ao_color, 1.0 - real_ao_limit);
    ao_color = mix(1.0, ao_color, ao_amp);
    albedo_color = mix(albedo_color, albedo_color/vec3(ao_color), ao_mix);
    vec3 grey = vec3(dot(albedo_color, vec3(1.0/3.0)));
    float desat_basis = (1.0-ao_color);
    desat_basis = sqrt(desat_basis);
    float desat_amount = clamp(desat_basis*ao_desat*ao_amp, 0.0, 1.0);
    albedo_color = mix(albedo_color, grey, desat_amount);
    ALBEDO = albedo_color;
}
