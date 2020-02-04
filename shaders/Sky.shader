shader_type canvas_item;
// USING https://www.shadertoy.com/view/XtBXDw for 3dclouds and https://www.shadertoy.com/view/4dsXWn for 2d clouds
uniform float iTime;
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

lowp vec3 rotate_y(vec3 v, float angle)
{
	lowp float ca = cos(angle); lowp float sa = sin(angle);
	return v*mat3(
		vec3(+ca, +.0, -sa),
		vec3(+.0,+1.0, +.0),
		vec3(+sa, +.0, +ca));
}

lowp vec3 rotate_x(vec3 v, float angle)
{
	lowp float ca = cos(angle); lowp float sa = sin(angle);
	return v*mat3(
		vec3(+1.0, +.0, +.0),
		vec3(+.0, +ca, -sa),
		vec3(+.0, +sa, +ca));
}
lowp float rand(vec2 co) {return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);}//просто пример рандома в шейдерах из инета

lowp float noise( in vec3 pos )
{
    pos*=0.01;
	lowp float  z = pos.z*256.0;
	lowp vec2 offz = vec2(0.317,0.123);
	lowp vec2 uv = pos.xy + offz*floor(z); 
	return mix(textureLod( Noise, uv ,0.0).x,textureLod( Noise, uv+offz ,0.0).x,fract(z));
}

lowp float get_noise(vec3 p, float FBM_FREQ)
{
	lowp float
	t  = 0.51749673 * noise(p); p *= FBM_FREQ;
	t += 0.25584929 * noise(p); p *= FBM_FREQ;
	t += 0.12527603 * noise(p); p *= FBM_FREQ;
	t += 0.06255931 * noise(p);
	return t;
}

lowp vec4 draw_night_sky (float attenuation, vec4 sun_amount, vec3 rd, float cld_alpha)
{
	lowp float dist =length(MOON_POS-rd);
	lowp vec3 moon_uv = MOON_POS-rd;
	moon_uv/=moon_radius;
	moon_uv= (moon_uv*0.5+0.5); 
	lowp vec4 night_sky = vec4(0.0);
		
	if (dist<moon_radius) //Рисуем Луну
	{
		float moon_amount = mix(smoothstep(0.2,1.0,get_noise(MOON_POS - rd+0.0, 3.6)),0.0,smoothstep(moon_radius*0.8, moon_radius, dist))*attenuation;
		//float moon_amount = mix(textureLod(Moon,moon_uv.xz,0.0).r,0.0,smoothstep(moon_radius*0.7, moon_radius, dist))*attenuation;
		moon_amount = clamp(mix (0.0,moon_amount,smoothstep(0.9,1.0,0.75+length(MOON_POS-rd+MOON_PHASE))),0.003,0.99);
		night_sky = moon_color*moon_amount*(clamp(1.0-cld_alpha-0.2,0.0,1.0));
	}
	else 
	{
	if (sun_amount.r<0.01 && cld_alpha == 0.0)//Если свет от Солнца не затмевает звёзды на рассвете/закате или не закрывают облака
		if (rand(rd.zx) - rd.y*0.0033> 0.996) //Рисуем звёзды, при этом вверху рисуем их меньше, так как при такой проекции текстуры так получается равномернее
		{
		lowp float stars = rand(rd.zy)*0.5;
		stars = clamp(sin(iTime*3.0+stars*10.0),0.1,stars);
		night_sky = vec4(vec3(stars),1.0);
		}
	}
	return night_sky;
}

void fragment(){
	lowp vec2 uv = UV; //Переводим в панорамные координаты. Понятия не имею, как это, этот кусок спижжен у оригинального автора, получаем вектора ro  и rd. rd - трёхмерное положение в пространстве. ro -ХЗ, оффсет, видимо
    uv.x = 2.0 * uv.x - 1.0;
    uv.y = 2.0 * uv.y - 1.0;
	lowp vec3 rd = normalize(rotate_y(rotate_x(vec3(0.0, 0.0, 1.0),-uv.y*3.1415926535/2.0),-uv.x*3.1415926535));
	lowp vec4 sun_amount = sun_color * min(pow(max(dot(rd, SUN_POS), 0.0), 1500.0) * 5.0, 1.0) + sun_color * min(pow(max(dot(rd, SUN_POS), 0.0), 10.0) * .3, 1.0);
	lowp float skyPow = dot(rd, vec3(0.0, -1.0, 0.0));
    lowp float horizonPow =1.-pow(1.0-abs(skyPow), 5.0);
    lowp vec4 cld = texture(cloud_env_texture, SCREEN_UV);
	lowp vec4 sky;
	
	if (DAY_TIME.x==0.0) 
		{	sky.rgb = mix (sky.rgb, vec3(0.0), 0.99); //затемняем
			sky += draw_night_sky(1.0,sun_amount,rd,cld.a);
			cld.rgb = mix (cld.rgb, vec3(0.0), 0.99); //затемняем облака
		}
	if (DAY_TIME.x==1.0) 
		{	lowp float moon_dist = length(MOON_POS-rd);
			sky = mix(mix(night_color_sky, sunset_color_horizon, DAY_TIME.y), mix(night_color_sky, sunset_color_sky, DAY_TIME.y),rd.y) + sun_amount;
			sky.rgb = mix (vec3(0.0), sky.rgb, DAY_TIME.y); //постепенно осветляем с рассветом небо
			sky += draw_night_sky(1.0-DAY_TIME.y,sun_amount,rd,cld.a);
			cld.rgb = mix (vec3(0.0), cld.rgb, DAY_TIME.y); //постепенно осветляем с рассветом облака
		}
	if (DAY_TIME.x==2.0) {sky = mix(mix(sunset_color_horizon, day_color_horizon, DAY_TIME.y), mix(sunset_color_sky, day_color_sky, DAY_TIME.y),rd.y) + sun_amount;}
	if (DAY_TIME.x==3.0) {sky = mix(day_color_horizon, day_color_sky, rd.y) + sun_amount;}
	if (DAY_TIME.x==4.0) {sky = mix(mix(day_color_horizon, sunset_color_horizon, DAY_TIME.y), mix(day_color_sky, sunset_color_sky, DAY_TIME.y),rd.y) + sun_amount;}
	if (DAY_TIME.x==5.0) 
		{	sky = mix(mix(sunset_color_horizon, night_color_sky, DAY_TIME.y), mix(sunset_color_sky, night_color_sky, DAY_TIME.y),rd.y) + sun_amount;
			sky.rgb = mix (sky.rgb, vec3(0.0), DAY_TIME.y); //постепенно затемняем с закатом небо
			sky += draw_night_sky(DAY_TIME.y,sun_amount,rd,cld.a);//рисуем ночное небо
			cld.rgb = mix (cld.rgb, vec3(0.0), DAY_TIME.y); //постепенно затемняем с закатом облака
		}
	if (LIGHTING_STRENGTH.r >0.1)
	{
		lowp vec3 lighting_amount = LIGHTING_STRENGTH * min(pow(max(dot(rd,LIGHTTING_POS), 0.0), 100.0) * 1.0, 1.0);
		sky = vec4(mix (sky.rgb, LIGHTING_STRENGTH,0.8),1.0);
		cld.rgb = mix(cld.rgb,lighting_amount, .5);
	}
	sky.rgb = clamp(sky.rgb,0.0,1.0);
	sky.rgb = mix(sky.rgb, cld.rgb/(0.0001+cld.a), cld.a);
	COLOR=vec4(sky.rgb,1.0);
}