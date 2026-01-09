shader_type canvas_item;

// Général
uniform float time_scale : hint_range(0.1, 5.0) = 1.0;
uniform float world_scale : hint_range(0.0001, 0.01) = 0.001;

// Couleurs
uniform vec4 base_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 fog_color : source_color = vec4(0.1, 0.05, 0.15, 1.0);
uniform vec4 sparkle_color : source_color = vec4(0.3, 0.2, 0.5, 1.0);

// Brouillard
uniform float fog_intensity : hint_range(0.0, 1.0) = 0.6;
uniform float fog_speed : hint_range(0.0, 2.0) = 0.3;
uniform float fog_scale : hint_range(0.5, 10.0) = 3.0;
uniform float fog_softness : hint_range(0.0, 1.0) = 0.5;

// Noise / Static
uniform float noise_intensity : hint_range(0.0, 1.0) = 0.3;
uniform float noise_speed : hint_range(0.0, 200.0) = 100.0;

// Ondulation
uniform float wave_intensity : hint_range(0.0, 0.1) = 0.02;
uniform float wave_speed : hint_range(0.0, 5.0) = 2.0;
uniform float wave_frequency : hint_range(1.0, 30.0) = 10.0;

// Étoiles
uniform float sparkle_intensity : hint_range(0.0, 2.0) = 0.4;
uniform float sparkle_density : hint_range(1.0, 50.0) = 8.0;
uniform float sparkle_size : hint_range(0.01, 0.5) = 0.15;
uniform float sparkle_speed : hint_range(0.0, 5.0) = 1.0;

// Texture
uniform float texture_mix : hint_range(0.0, 1.0) = 0.3;
uniform float texture_brightness : hint_range(0.0, 1.0) = 0.1;

// Permutation pour simplex
vec3 mod289(vec3 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec2 mod289_2(vec2 x) { return x - floor(x * (1.0 / 289.0)) * 289.0; }
vec3 permute(vec3 x) { return mod289(((x * 34.0) + 1.0) * x); }

// Simplex noise 2D - pas d'angles droits
float simplex_noise(vec2 v) {
	const vec4 C = vec4(
		0.211324865405187,   // (3.0-sqrt(3.0))/6.0
		0.366025403784439,   // 0.5*(sqrt(3.0)-1.0)
		-0.577350269189626,  // -1.0 + 2.0 * C.x
		0.024390243902439    // 1.0 / 41.0
	);
	
	// First corner
	vec2 i = floor(v + dot(v, C.yy));
	vec2 x0 = v - i + dot(i, C.xx);
	
	// Other corners
	vec2 i1 = (x0.x > x0.y) ? vec2(1.0, 0.0) : vec2(0.0, 1.0);
	vec4 x12 = x0.xyxy + C.xxzz;
	x12.xy -= i1;
	
	// Permutations
	i = mod289_2(i);
	vec3 p = permute(permute(i.y + vec3(0.0, i1.y, 1.0)) + i.x + vec3(0.0, i1.x, 1.0));
	
	vec3 m = max(0.5 - vec3(dot(x0, x0), dot(x12.xy, x12.xy), dot(x12.zw, x12.zw)), 0.0);
	m = m * m;
	m = m * m;
	
	// Gradients
	vec3 x = 2.0 * fract(p * C.www) - 1.0;
	vec3 h = abs(x) - 0.5;
	vec3 ox = floor(x + 0.5);
	vec3 a0 = x - ox;
	
	m *= 1.79284291400159 - 0.85373472095314 * (a0 * a0 + h * h);
	
	// Compute final noise value
	vec3 g;
	g.x = a0.x * x0.x + h.x * x0.y;
	g.yz = a0.yz * x12.xz + h.yz * x12.yw;
	return 130.0 * dot(m, g);
}

// FBM avec simplex
float fbm_simplex(vec2 p, int octaves) {
	float value = 0.0;
	float amplitude = 0.5;
	float frequency = 1.0;
	
	for (int i = 0; i < octaves; i++) {
		value += amplitude * simplex_noise(p * frequency);
		frequency *= 2.0;
		amplitude *= 0.5;
	}
	
	return value * 0.5 + 0.5; // Normaliser entre 0 et 1
}

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float sparkles(vec2 uv, float time) {
	float sparkle = 0.0;
	
	vec2 grid_uv = uv * sparkle_density;
	vec2 grid_id = floor(grid_uv);
	vec2 grid_pos = fract(grid_uv);
	
	for (int x = -1; x <= 1; x++) {
		for (int y = -1; y <= 1; y++) {
			vec2 neighbor_id = grid_id + vec2(float(x), float(y));
			vec2 neighbor_offset = vec2(float(x), float(y));
			
			vec2 star_pos = vec2(
				hash(neighbor_id) * 0.6 + 0.2,
				hash(neighbor_id + vec2(1.0, 0.0)) * 0.6 + 0.2
			);
			
			float pulse_speed = hash(neighbor_id + vec2(0.0, 1.0)) * 2.0 + 1.0;
			float pulse = sin(time * sparkle_speed * pulse_speed + hash(neighbor_id) * 6.28) * 0.5 + 0.5;
			
			vec2 star_world_pos = star_pos + neighbor_offset;
			float dist = distance(grid_pos, star_world_pos);
			
			sparkle += smoothstep(sparkle_size, 0.0, dist) * pulse;
		}
	}
	
	return sparkle;
}

void fragment() {
	float time = TIME * time_scale;
	
	vec2 world_uv = FRAGCOORD.xy * world_scale;
	
	// 1. Ondulation
	vec2 wave_offset = vec2(
		sin(world_uv.y * wave_frequency + time * wave_speed) * wave_intensity,
		cos(world_uv.x * wave_frequency + time * wave_speed * 0.75) * wave_intensity
	);
	vec2 distorted_uv = world_uv + wave_offset;
	
	// 2. Brouillard avec Simplex (plus organique)
	vec2 fog_uv = distorted_uv * fog_scale + vec2(time * fog_speed, time * fog_speed * 0.7);
	float fog = fbm_simplex(fog_uv, 6) * fog_intensity;
	
	// 3. Static noise
	float static_noise = hash(world_uv * 500.0 + time * noise_speed) * noise_intensity;
	
	// 4. Étoiles
	float sparkle = sparkles(world_uv, time) * sparkle_intensity;
	
	// Combiner
	vec4 final_color = base_color;
	final_color.rgb += fog_color.rgb * fog;
	final_color.rgb += vec3(static_noise);
	final_color.rgb += sparkle_color.rgb * sparkle;
	
	// Texture
	vec2 tex_uv = UV + wave_offset * 0.5;
	vec4 tex = texture(TEXTURE, tex_uv);
	final_color.rgb = mix(final_color.rgb, tex.rgb * texture_brightness, texture_mix);
	final_color.a = tex.a;
	
	COLOR = final_color;
}