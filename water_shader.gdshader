shader_type spatial;

uniform vec4 primary_color : source_color;
uniform vec4 secoundary_color : source_color;

uniform float roughness = 0.2;

uniform sampler2D normalmap_a : hint_normal;
uniform sampler2D normalmap_b : hint_normal;
uniform float normalmap_a_strength : hint_range(0.0, 1.0, 0.01) = 0.5;
uniform float normalmap_b_strength : hint_range(0.0, 1.0, 0.01) = 0.25;

uniform vec2 movment_direction = vec2(0.2, 0.1);
uniform float movment_strength = 0.12;

uniform float uv_scale = 0.1;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;
uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

// Depth-related values
uniform float depth_distance : hint_range(0.0, 20.0, 0.1) = 4.0;
uniform float beers_law : hint_range(0.0, 20.0, 0.1) = 12.0;
uniform float water_transparency : hint_range(0.0, 1.0, 0.01) = 0.0;

uniform float refraction_strength : hint_range(0.0, 8.0, 0.001) = 0.5;

float fresnel(float amount, vec3 normal, vec3 view) {
    return pow(1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0), amount);
}

void fragment() {
    // Get depth
    float depth_clean = textureLod(depth_texture, SCREEN_UV, 0.0).r;
    
    vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth_clean);
    vec3 ndc_clean = vec3(SCREEN_UV * 2.0 - 1.0, depth_clean);
	// get depth in view matrix
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = -view.z + VERTEX.z;
	vec4 world;
	if (linear_depth < 0.00001) {
		world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc_clean, 1.0);
	} else {
		world = INV_VIEW_MATRIX * INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	}
	// world
    float depth_texture_y = world.y / world.w;
    float vertex_y = (INV_VIEW_MATRIX * vec4(VERTEX, 1.0)).y;

    // Compute depth blend
    float depth_blend = clamp((vertex_y - depth_texture_y) / depth_distance, 0.0, 1.0);
    depth_blend = exp(-depth_blend * beers_law);

    // Compute Fresnel effect
    float basic_fresnel = fresnel(3.0, NORMAL, VIEW);

    // UV manipulation
    vec2 uv_movment = movment_direction * TIME * movment_strength;

    vec3 normalmap = texture(normalmap_a, UV + uv_movment).rgb * normalmap_a_strength;
    normalmap += texture(normalmap_b, UV - uv_movment).rgb * normalmap_b_strength;

    // Compute refraction offset
    vec3 ref_normalmap = normalize(normalmap * 2.0 - vec3(1.0));
    vec3 ref_normal = mix(NORMAL, TANGENT * ref_normalmap + BINORMAL * ref_normalmap + NORMAL * ref_normalmap, 1.0);
    vec2 ref_ofs = SCREEN_UV - ref_normal.xy * refraction_strength;

    // Sample textures with refraction offset
    float depth = textureLod(depth_texture, ref_ofs, 0.0).r;
    vec3 screen = texture(screen_texture, ref_ofs).rgb;
	vec3 refraction_texture = textureLod(screen_texture, ref_ofs, ROUGHNESS * 2.0).rgb;
    // Compute final color
    vec3 depth_color = mix(secoundary_color, primary_color, depth_blend).rgb;
	if (linear_depth < 0.00001) {
		refraction_texture = textureLod(screen_texture, SCREEN_UV, ROUGHNESS * 2.0).rgb;
	} else {
		refraction_texture = textureLod(screen_texture, ref_ofs, ROUGHNESS * 2.0).rgb;
	}
	vec3 final_color = mix(depth_color, refraction_texture, water_transparency * depth_blend);

    ALBEDO = final_color;
    ROUGHNESS = roughness * (1.0 - basic_fresnel);
    NORMAL_MAP = normalmap;
}
