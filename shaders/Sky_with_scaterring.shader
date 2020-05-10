shader_type canvas_item;
// USING Non physical based atmospheric scattering made by robobo1221 https://www.shadertoy.com/view/Ml2cWG
uniform sampler2D Noise;
uniform vec3 SUN_POS; //normalize this vector in script!
uniform vec3 MOON_POS; //normalize this vector in script!
uniform float MOON_PHASE:hint_range(-0.2,0.2);
uniform float moon_radius:hint_range(0.0,1.0);
uniform float sun_radius:hint_range(0.0,0.3);
uniform float attenuation:hint_range(0.0,1.0);

uniform vec3 LIGHTING_STRENGTH;
uniform vec3 LIGHTTING_POS; //normalize this vector in script!
uniform float sky_tone:hint_range(0.0,10.0);
uniform float sky_density:hint_range(0.0,2.0);
uniform float sky_rayleig_coeff:hint_range(0.0,10.0);
uniform float sky_mie_coeff:hint_range(0.0,10.0);

uniform float multiScatterPhase: hint_range(0.0,2.0);
uniform float anisotropicIntensity: hint_range(-2.0,2.0);

uniform vec4 color_sky: hint_color;
uniform vec4 moon_color: hint_color;

uniform sampler2D cloud_env_texture;

lowp vec3 rotate_y(lowp vec3 v, lowp float angle)
{
	lowp float ca = cos(angle); lowp float sa = sin(angle);
	return v*mat3(
		vec3(+ca, +.0, -sa),
		vec3(+.0,+1.0, +.0),
		vec3(+sa, +.0, +ca));
}

lowp vec3 rotate_x(lowp vec3 v, lowp float angle)
{
	lowp float ca = cos(angle); lowp float sa = sin(angle);
	return v*mat3(
		vec3(+1.0, +.0, +.0),
		vec3(+.0, +ca, -sa),
		vec3(+.0, +sa, +ca));
}
lowp float rand(lowp vec2 co) {return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);}//just random function. Used for stars.

lowp float noise( in lowp vec3 pos )
{
    pos*=0.01;
	lowp float  z = pos.z*256.0;
	lowp vec2 offz = vec2(0.317,0.123);
	lowp vec2 uv = pos.xy + offz*floor(z); 
	return mix(textureLod( Noise, uv ,0.0).x,textureLod( Noise, uv+offz ,0.0).x,fract(z));
}

lowp float get_noise(lowp vec3 p, lowp float FBM_FREQ)
{
	lowp float
	t  = 0.51749673 * noise(p); p *= FBM_FREQ;
	t += 0.25584929 * noise(p); p *= FBM_FREQ;
	t += 0.12527603 * noise(p); p *= FBM_FREQ;
	t += 0.06255931 * noise(p);
	return t;
}

lowp vec3 draw_night_sky (lowp float sky_amount, lowp vec3 rd, lowp float cld_alpha, lowp float time)
{
	lowp vec3 night_sky = vec3(0.0);
	lowp float moon_amount = min(pow(max(dot(rd, MOON_POS), 0.0), 500.0/moon_radius) * 100.0, 1.0);
	moon_amount *= smoothstep(0.1,0.99,get_noise(MOON_POS - rd, 3.1415926536));//some noise, if you want
	if (sky_amount<0.01 && cld_alpha == 0.0 && moon_amount < 0.01)//If the light from the Sun does not obscure the stars at sunrise/sunset and does not cover the clouds and moon
		if (rand(rd.zx) - rd.y*0.0033> 0.996) //the higher the stars, the fewer they are. Since the spherical panorama does not allow uniform coverage, the pixel density at height is higher.
			{
			lowp float stars = rand(rd.zy)*0.5;
			stars = clamp(sin(time*3.0+stars*10.0),0.1,stars);
			night_sky.rgb = vec3(stars);
			}
	moon_amount*=1.0 - attenuation; //attenuation of the brightness of the moon (for sunrise and sunset).
	moon_amount = clamp(mix (0.0,moon_amount,smoothstep(0.9,1.0,0.75+length(MOON_POS-rd+MOON_PHASE))),0.001,1.0);//here we cast a shadow on the moon. moon phase. 
	night_sky.rgb += moon_color.rgb*moon_amount*(clamp(1.0-cld_alpha-0.2,0.0,1.0));//Here we mix with the clouds so that there is no black border. But so that the Moon does not Shine through the clouds.
	return night_sky;
}

lowp vec3 getSkyAbsorption(lowp vec3 color, lowp float h){return exp2(color * -h) * 2.0;}
lowp float horizon_limiter (lowp float h){return clamp(abs(h),0.1+smoothstep(0.0,0.3,SUN_POS.y)*0.2,1.0);}// eliminate the dark line and other artefacts on the horizon with clamp
lowp float zenithDensity(lowp float dens){return sky_density/pow(max(dens, 0.0), 0.75);}
lowp float getSunPoint(lowp vec3 p, lowp vec3 lp) {return smoothstep(sun_radius, sun_radius*0.9, distance(p, lp)) * 5.0;}
lowp float getRayleigMultiplier(lowp vec3 p, lowp vec3 lp){return sky_rayleig_coeff + pow(1.0 - clamp(distance(p, lp), 0.0, 1.0), 2.0) * 3.14159265359 * 0.5;}
lowp float getMie(lowp vec3 p, lowp vec3 lp)
{
	lowp float disk = clamp(1.0 - pow(distance(p, lp), 0.1), 0.0, 1.0);
	return disk*disk*(3.0 - 2.0 * disk) * sky_mie_coeff * 3.14159265359;
}
lowp vec3 jodieReinhardTonemap(lowp vec3 color)
{	
	lowp vec3 tc = color / (color + 1.0);
	return mix(color / (dot(color, vec3(0.2126, 0.7152, 0.0722)) + 1.0), tc, tc);
}

lowp vec3 getAtmosphericScattering(lowp vec3 p, lowp vec3 lp){
	lowp vec3 skyColor = color_sky.rgb * (1.0 + anisotropicIntensity);
	lowp float zenith = zenithDensity(horizon_limiter(p.y));
	lowp float sunPointDistMult =  clamp(max(lp.y + multiScatterPhase, 0.0), 0.0, 1.0);
	lowp vec3 absorption = getSkyAbsorption(skyColor, zenith);
    lowp vec3 sunAbsorption = getSkyAbsorption(skyColor, zenithDensity(lp.y + multiScatterPhase));
	lowp vec3 sky = skyColor * zenith *getRayleigMultiplier(p, lp);
	sky = mix(sky * absorption, sky / (sky + 0.5), sunPointDistMult) + getSunPoint(p, lp) * absorption + getMie(p, lp) * sunAbsorption;
	sky *= sunAbsorption * 0.5 + 0.5 * length(sunAbsorption);
	sky = jodieReinhardTonemap(sky);
	sky = pow(sky, vec3(sky_tone));
	return sky;
}

void fragment(){
	lowp vec2 uv = UV; 
    uv.x = 2.0 * uv.x - 1.0;
    uv.y = 2.0 * uv.y - 1.0;
	lowp vec3 rd = normalize(rotate_y(rotate_x(vec3(0.0, 0.0, 1.0),-uv.y*3.1415926535/2.0),-uv.x*3.1415926535)); //transform UV to spherical panorama 3d coords
	lowp vec4 cld = texture(cloud_env_texture, SCREEN_UV);
	cld.rgb *=attenuation; //lighten the clouds depending on the height of the Sun, calculated in the script
	lowp vec3 sky;
	sky = getAtmosphericScattering(rd,SUN_POS);
	sky += draw_night_sky(max(max(sky.b,sky.r),sky.g),rd,cld.a,TIME) ;
	if (LIGHTING_STRENGTH.r >0.1)
	{
		sky = mix (sky.rgb, LIGHTING_STRENGTH,0.8); //flash of light in the sky simulates a lightning strike
		lowp vec3 lighting_amount = LIGHTING_STRENGTH * min(pow(max(dot(rd,LIGHTTING_POS), 0.0), 100.0) * 1.0, 1.0); // you don't need to light up the clouds. I just wanted to make the place where the lightning flashed a little bit visible and highlight the clouds there. This is a rather dubious decision.
		cld.rgb = mix(cld.rgb,lighting_amount, .5);
	}
	sky.rgb = mix(sky.rgb, cld.rgb/(0.0001+cld.a), cld.a);
	sky = mix(sky, cld.rgb/(0.0001+cld.a), cld.a);
	COLOR=vec4(sky,1.0);
}