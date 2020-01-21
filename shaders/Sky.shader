shader_type canvas_item;

// USING https://www.shadertoy.com/view/XtBXDw for 3dclouds and https://www.shadertoy.com/view/4dsXWn for 2d clouds
uniform float iTime;
uniform vec3 WIND; //wind_vec*wind_str направление ветра, вектор*силу ветра
uniform sampler2D iChannel0;
uniform vec2 DAY_TIME;
uniform vec3 SUN_POS; //normalize this vector in script!
uniform vec3 MOON_POS; //normalize this vector in script!
uniform float COVERAGE :hint_range(0,1); //0.5
uniform float HEIGHT :hint_range(0,1); //0.0
uniform float THICKNESS :hint_range(0,100); //25.
uniform float ABSORPTION :hint_range(0,10); //1.030725
uniform int STEPS :hint_range(0,100); //25
uniform vec3 LIGHTING_STRENGTH;
uniform vec3 LIGHTTING_POS; //normalize this vector in script!

uniform vec4 night_color_sky: hint_color;
uniform vec4 sunset_color_sky: hint_color;
uniform vec4 sunset_color_horizon: hint_color;
uniform vec4 day_color_sky: hint_color;
uniform vec4 day_color_horizon: hint_color;
uniform vec4 sun_color: hint_color;
uniform vec4 moon_color: hint_color;
//for 2d clouds
const float CLOUD_LOWER=7000.0;
const float CLOUD_UPPER=9000.0;

lowp float rand(vec2 co){return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);}//просто пример рандома в шейдерах из инета

lowp float noise( in vec3 pos )
{
    pos*=0.01;
	lowp float  z = pos.z*256.0;
	lowp vec2 offz = vec2(0.317,0.123);
	lowp vec2 uv = pos.xy + offz*floor(z); 
	return mix(textureLod( iChannel0, uv ,0.0).x,textureLod( iChannel0, uv+offz ,0.0).x,fract(z));
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

bool SphereIntersect(vec3 apos, float arad, vec3 ro, vec3 rd, out vec3 norm) {
    ro -= apos;
    lowp float A = dot(rd, rd);
    lowp float B = 2.0*dot(ro, rd);
    lowp float C = dot(ro, ro)-arad*arad;
    lowp float D = B*B-4.0*A*C;
    if (D < 0.0) return false;
    D = sqrt(D);
    A *= 2.0;
    lowp float t1 = (-B+D)/A;
    lowp float t2 = (-B-D)/A;
    if (t1 < 0.0) t1 = t2;
    if (t2 < 0.0) t2 = t1;
    t1 = min(t1, t2);
    if (t1 < 0.0) return false;
    norm = ro+t1*rd;
    return true;
}

lowp float density(vec3 pos, vec3 offset){
	lowp vec3 p = pos * 0.0212242 + offset;
	float dens = get_noise(p,2.76434);
	lowp float cov = 1.0 - clamp(COVERAGE,0.3,1.0);
	dens *= smoothstep (cov, cov + .05, dens);
	return clamp(dens, 0.0, 1.0);	
}

lowp vec4 clouds_3d(vec3 ro, vec3 rd, vec3 wind){
	lowp vec3 apos=vec3(0, -450, 0);
	lowp float arad=500.0;
    lowp vec3 C = vec3(0, 0, 0);
	lowp float alpha = 0.0;
    lowp vec3 norm;
    if(SphereIntersect(apos,arad,ro,rd,norm)){
        lowp int steps = STEPS;
        lowp float march_step = THICKNESS / float(steps);
        lowp vec3 dir_step = rd / rd.y * march_step;
        lowp vec3 pos =norm;
        lowp float T = 1.0;
        for (int i = 0; i < steps; i++) {
            if (length(pos) > 1e3) break;
			lowp float dens = density (pos, wind)*march_step;
			lowp float T_i = exp(-ABSORPTION * dens);
            T *= T_i;
            if (T < .01) break;
			lowp float h = float(i) / float(steps);
            C += T * (exp(h)/2.0 ) *dens;
            alpha += (1. - T_i) * (1. - alpha);
            pos += dir_step;
			}
		}
		return vec4(C, alpha);
}

lowp vec3 cube_bot(vec3 p, vec3 c1, vec3 c2)
{
	lowp float f = 0.0;
	f += .50000 * noise(.5 * (p+vec3(0.,0.,-iTime*0.275)));
	f += .25000 * noise(1. * (p+vec3(0.,0.,-iTime*0.275)));
	f += .12500 * noise(2. * (p+vec3(0.,0.,-iTime*0.275)));
	f += .06250 * noise(4. * (p+vec3(0.,0.,-iTime*0.275)));
	return  f* mix(c1, c2, p * .5 + .5);
}

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

lowp float MapSH(vec3 p, float cloudy, vec3 offset)
{
	lowp float h = -(get_noise(p*0.0003+offset, 2.76434)-cloudy-.6);
    h *= smoothstep((HEIGHT+0.1)*CLOUD_UPPER+100., (HEIGHT+0.1)*CLOUD_UPPER, p.y);
	return h;
}

lowp vec4 clouds_2d(vec3 rd,vec3 wind)
{
	lowp float cloudy = COVERAGE -0.5;
	lowp float beg = (((HEIGHT+0.1)*CLOUD_LOWER) / rd.y);
	lowp float end = (((HEIGHT+0.1)*CLOUD_UPPER) / rd.y);
	lowp vec3 p = vec3(rd * beg);
	lowp vec3 add = rd * ((end-beg) / 55.0);
	lowp vec2 shade;
	lowp vec2 shadeSum = vec2(0.0, 0.0);
	for (int i = 0; i < min(STEPS,5); i++)
	{
		if (shadeSum.y >= 1.0) break;
		lowp float h = MapSH(p,cloudy,wind);
		shade.y = max(h, 0.0); 
        shade.x = clamp(-(h-MapSH(p+MOON_POS*200.0, cloudy,wind))*2., 0.05, 1.0);//Тут магия с shadertoy, позиция Луны, потому что освещать облака надо снизу, а Солнце сверху.
		shadeSum += shade * (1.0 - shadeSum.y);
		p += add;
	}
	lowp vec3 clouds = mix(vec3(pow(shadeSum.x, .6)), sun_color.rgb, (1.0-shadeSum.y)*.4);
    clouds = clamp(mix(vec3(0.0), min(clouds, 1.0), shadeSum.y),0.0,1.0);
	return vec4(clouds, shadeSum.y);
}

lowp float star_brightness(float rnd){	return clamp(sin(iTime*3.0+rnd*10.0),0.1, rnd);}

void fragment(){
	lowp vec2 uv = UV; //Переводим в панорамные координаты. Понятия не имею, как это, этот кусок спижжен у оригинального автора, получаем вектора ro  и rd. rd - трёхмерное положение в пространстве. ro -ХЗ, оффсет, видимо
    uv.x = 2.0 * uv.x - 1.0;
    uv.y = 2.0 * uv.y - 1.0;
	lowp vec3 rd = normalize(rotate_y(rotate_x(vec3(0.0, 0.0, 1.0),-uv.y*3.1415926535/2.0),-uv.x*3.1415926535));
	lowp vec3 ro = vec3(0.0, -200.0*HEIGHT+40.0, 0.0); //тут можно регулировать высоту облаков.
	lowp vec4 sun_amount = sun_color * min(pow(max(dot(rd, SUN_POS), 0.0), 1500.0) * 5.0, 1.0) + sun_color * min(pow(max(dot(rd, SUN_POS), 0.0), 10.0) * .6, 1.0);
	lowp float moon_amount_value = pow(max(dot(rd, MOON_POS), 0.0), 3000.0) * 5.0;
	lowp vec4 moon_amount; 
	lowp float rnd = rand(rd.zx);
	lowp vec4 cld;
	lowp float skyPow = dot(rd, vec3(0.0, -1.0, 0.0));
    lowp float horizonPow =1.-pow(1.0-abs(skyPow), 5.0);
    if(rd.y>0.0)
    {
    if (STEPS < 20)	cld = clouds_2d(rd,WIND*iTime); else cld=clouds_3d(ro,rd,WIND*iTime);
	cld=clamp(cld,0.0,1.0);
	cld.rgb+=0.04*cld.rgb*horizonPow;
	cld*=clamp((  1.0 - exp(-2.3 * pow(max((0.0), horizonPow), (2.6)))),0.,1.);//растворяем облака в горизонте
    }
	else{
    cld.rgb = cube_bot(rd,vec3(1.5,1.49,1.71), vec3(1.1,1.15,1.5));
    cld.a=1.;
    cld*=clamp((  1.0 - exp(-1.3 * pow(max((0.0), horizonPow), (2.6)))),0.,1.);
    }
	lowp vec4 sky;
	switch (int(DAY_TIME.x))
	{
		case 0: {
				sky.rgb = mix (sky.rgb, vec3(0.0), 0.99); //затемняем
				if (cld.rgb == vec3 (0.0,0.0,0.0)) //Если нет облаков
					{moon_amount = moon_color*min(moon_amount_value, 0.99);
					sky = sky + moon_color*moon_amount;//Рисуем Луну
					if (moon_amount.r < 0.01 && sun_amount.r<0.01) 
						if (rnd - rd.y*0.0033> 0.996) sky.rgb = vec3(star_brightness(rand(rd.zy)/2.0));
					}
				cld.rgb = mix (cld.rgb, vec3(0.0), 0.99); //затемняем
				break;
				}
		
		case 1: {sky = mix(mix(night_color_sky, sunset_color_horizon, DAY_TIME.y), mix(night_color_sky, sunset_color_sky, DAY_TIME.y),rd.y) + sun_amount;
				sky.rgb = mix (vec3(0.0), sky.rgb, DAY_TIME.y); //постепенно осветляем с рассветом
				if (cld.rgb == vec3 (0.0)) //Если нет облаков
					{moon_amount = moon_color*min(moon_amount_value, 1.0-DAY_TIME.y);sky = sky + moon_amount;//Рисуем Луну
					if (moon_amount.r < 0.01 && sun_amount.r<0.01) //Если Луна или свет от Солнца не затмевает звёзды
						if (rnd - rd.y*0.0033> 0.996) 
							sky.rgb = mix (vec3(star_brightness(rand(rd.zy)/2.0)), sky.rgb ,DAY_TIME.y); //Рисуем звёзды
					}
				cld.rgb = mix (vec3(0.0), cld.rgb, DAY_TIME.y); //постепенно осветляем с рассветом
				break;
				}
		case 2: {sky = mix(mix(sunset_color_horizon, day_color_horizon, DAY_TIME.y), mix(sunset_color_sky, day_color_sky, DAY_TIME.y),rd.y) + sun_amount;break;}
		case 3: {sky = mix(day_color_horizon, day_color_sky, rd.y) + sun_amount; break;}
		case 4: {sky = mix(mix(day_color_horizon, sunset_color_horizon, DAY_TIME.y), mix(day_color_sky, sunset_color_sky, DAY_TIME.y),rd.y) + sun_amount;break;}
		case 5: {sky = mix(mix(sunset_color_horizon, night_color_sky, DAY_TIME.y), mix(sunset_color_sky, night_color_sky, DAY_TIME.y),rd.y) + sun_amount;
				sky = vec4 (mix (sky.rgb, vec3(0.0), DAY_TIME.y),1.0); //постепенно затемняем с закатом
				if (cld.rgb == vec3 (0.0)) //Если нет облаков
					{moon_amount=moon_color*min(moon_amount_value, DAY_TIME.y); sky = sky+moon_amount;//Рисуем Луну
					if (moon_amount.r < 0.01 && sun_amount.r<0.01) //Если Луна или свет от Солнца не затмевает звёзды
						if (rnd - rd.y*0.0033> 0.996) 
							sky.rgb = mix (sky.rgb, vec3(star_brightness(rand(rd.zy)/2.0)), DAY_TIME.y); //Рисуем звёзды
					}
				cld.rgb = mix (cld.rgb, vec3(0.0), DAY_TIME.y); //постепенно затемняем с закатом
				break;
				}
	}
	if (LIGHTING_STRENGTH.r >0.1)
	{
		lowp vec3 lighting_amount = LIGHTING_STRENGTH * min(pow(max(dot(rd,LIGHTTING_POS), 0.0), 20.0) * 1.6, 1.0);
		sky = vec4(mix (sky.rgb, LIGHTING_STRENGTH,0.8),1.0);
		cld.rgb = mix(cld.rgb,lighting_amount, .5);
	}
	sky.rgb = clamp(sky.rgb,0.0,1.0);
	sky.rgb = mix(sky.rgb, cld.rgb/(0.0001+cld.a), cld.a);
	COLOR = vec4(sky.rgb,1.0);
}