shader_type canvas_item;
// USING https://www.shadertoy.com/view/XtBXDw for 3dclouds and https://www.shadertoy.com/view/4dsXWn for 2d clouds
uniform sampler2D Noise;
uniform vec2 DAY_TIME;
uniform vec3 SUN_POS; //normalize this vector in script!
uniform vec3 MOON_POS; //normalize this vector in script!
uniform float MOON_PHASE:hint_range(-0.2,0.2);
uniform vec3 LIGHTING_STRENGTH;
uniform vec3 LIGHTTING_POS; //normalize this vector in script!

uniform vec4 night_color_sky: hint_color;
uniform vec4 sunset_color_sky: hint_color;
uniform vec4 sunset_color_horizon: hint_color;
uniform vec4 day_color_sky: hint_color;
uniform vec4 day_color_horizon: hint_color;
uniform vec4 sun_color: hint_color;
uniform vec4 moon_color: hint_color;
uniform float moon_radius;

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

lowp vec4 draw_night_sky (lowp float attenuation,lowp float sun_amount,lowp vec3 rd, lowp float cld_alpha, lowp float time)
{
	lowp vec4 night_sky = vec4(0.0);
	float moon_amount = min(pow(max(dot(rd, MOON_POS), 0.0), 500.0/moon_radius) * 100.0, 1.0);
	moon_amount *= get_noise(MOON_POS - rd, 3.1415926536);//some noise, if you want
	moon_amount*=attenuation; //attenuation of the brightness of the moon (for sunrise and sunset).
	if (sun_amount<0.01 && cld_alpha == 0.0 && moon_amount < 0.01)//If the light from the Sun does not obscure the stars at sunrise/sunset and does not cover the clouds and moon
		if (rand(rd.zx) - rd.y*0.0033> 0.996) //the higher the stars, the fewer they are. Since the spherical panorama does not allow uniform coverage, the pixel density at height is higher.
			{
			lowp float stars = rand(rd.zy)*0.5;
			stars = clamp(sin(time*3.0+stars*10.0),0.1,stars);
			night_sky.rgb = vec3(stars);
			}
	moon_amount = clamp(mix (0.0,moon_amount,smoothstep(0.9,1.0,0.75+length(MOON_POS-rd+MOON_PHASE))),0.001,1.0);//here we cast a shadow on the moon. moon phase. 
	night_sky.rgb += moon_color.rgb*moon_amount*(clamp(1.0-cld_alpha-0.2,0.0,1.0));//Here we mix with the clouds so that there is no black border. But so that the Moon does not Shine through the clouds.
	return vec4(night_sky.rgb,1.0);
}

void fragment(){
	lowp vec2 uv = UV; 
    uv.x = 2.0 * uv.x - 1.0;
    uv.y = 2.0 * uv.y - 1.0;
	lowp vec3 rd = normalize(rotate_y(rotate_x(vec3(0.0, 0.0, 1.0),-uv.y*3.1415926535/2.0),-uv.x*3.1415926535)); //transform UV to spherical panorama 3d coords
	lowp vec4 sun_amount = sun_color * min(pow(max(dot(rd, SUN_POS), 0.0), 1500.0) * 5.0, 1.0) + sun_color * min(pow(max(dot(rd, SUN_POS), 0.0), 10.0) * .3, 1.0);
	lowp float skyPow = dot(rd, vec3(0.0, -1.0, 0.0));
    lowp float horizonPow =1.-pow(1.0-abs(skyPow), 5.0);
    lowp vec4 cld = texture(cloud_env_texture, SCREEN_UV);
	lowp vec4 sky;
	
	switch(int(DAY_TIME.x))
	{
	case 0:
		{	sky = night_color_sky;
			sky += draw_night_sky(1.0,sun_amount.r,rd,cld.a,TIME);
			cld.rgb = mix (cld.rgb, vec3(0.0), 0.99); //darken the clouds, becouse night
			break;
		}
	case 1:
		{	sky = mix(mix(night_color_sky, sunset_color_horizon, DAY_TIME.y), mix(night_color_sky, sunset_color_sky, DAY_TIME.y),rd.y) + sun_amount;
			sky.rgb = mix (vec3(0.0), sky.rgb, DAY_TIME.y); //gradually brighten the sky with sunrise
			sky += draw_night_sky(1.0-DAY_TIME.y,sun_amount.r,rd,cld.a,TIME);
			cld.rgb = mix (vec3(0.0), cld.rgb, DAY_TIME.y); //gradually brighten the clouds with sunrise
			break;
		}
	case 2: {sky = mix(mix(sunset_color_horizon, day_color_horizon, DAY_TIME.y), mix(sunset_color_sky, day_color_sky, DAY_TIME.y),rd.y) + sun_amount;break;}
	case 3: {sky = mix(day_color_horizon, day_color_sky, rd.y) + sun_amount;break;}
	case 4: {sky = mix(mix(day_color_horizon, sunset_color_horizon, DAY_TIME.y), mix(day_color_sky, sunset_color_sky, DAY_TIME.y),rd.y) + sun_amount;break;}
	case 5: 
		{	sky = mix(mix(sunset_color_horizon, night_color_sky, DAY_TIME.y), mix(sunset_color_sky, night_color_sky, DAY_TIME.y),rd.y) + sun_amount;
			sky.rgb = mix (sky.rgb, vec3(0.0), DAY_TIME.y); //gradually darken the sky with sunset
			sky += draw_night_sky(DAY_TIME.y,sun_amount.r,rd,cld.a,TIME);
			cld.rgb = mix (cld.rgb, vec3(0.0), DAY_TIME.y); //gradually darken the clouds with sunset
			break;
		}
	}
	if (LIGHTING_STRENGTH.r >0.1)
	{
		sky = vec4(mix (sky.rgb, LIGHTING_STRENGTH,0.8),1.0); //flash of light in the sky simulates a lightning strike
		lowp vec3 lighting_amount = LIGHTING_STRENGTH * min(pow(max(dot(rd,LIGHTTING_POS), 0.0), 100.0) * 1.0, 1.0); // you don't need to light up the clouds. I just wanted to make the place where the lightning flashed a little bit visible and highlight the clouds there. This is a rather dubious decision.
		cld.rgb = mix(cld.rgb,lighting_amount, .5);
	}
	sky.rgb = clamp(sky.rgb,0.0,1.0);
	sky.rgb = mix(sky.rgb, cld.rgb/(0.0001+cld.a), cld.a);
	COLOR=vec4(sky.rgb,1.0);
}