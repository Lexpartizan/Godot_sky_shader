shader_type canvas_item;

// USING https://www.shadertoy.com/view/XtBXDw for 3dclouds and https://www.shadertoy.com/view/4dsXWn for 2d clouds
uniform vec3 WIND; //wind_vec*wind_str направление ветра, вектор*силу ветра
uniform sampler2D Noise;

uniform vec3 SUN_POS; //normalize this vector in script!

uniform float SIZE :hint_range(0.0,10.0); //0.5
uniform float SOFTNESS :hint_range(0.0,10.0); //0.5
uniform float COVERAGE :hint_range(0.0,1.0); //0.5
uniform float HEIGHT :hint_range(0.0,1.0); //0.0
uniform float THICKNESS :hint_range(0.0,100.0); //25.
uniform float ABSORPTION :hint_range(0.0,10.0); //1.030725
uniform int STEPS :hint_range(0,100); //25

lowp vec3 rotate_y(vec3 v, float angle)
{
	lowp float ca = cos(angle); lowp float sa = sin(angle);
	return v*mat3(
		vec3(+ca, +.0, -sa),
		vec3(+.0,+1.0, +.0),
		vec3(+sa, +.0, +ca));
}

lowp vec3 rotate_x(lowp vec3 v,lowp float angle)
{
	lowp float ca = cos(angle); lowp float sa = sin(angle);
	return v*mat3(
		vec3(+1.0, +.0, +.0),
		vec3(+.0, +ca, -sa),
		vec3(+.0, +sa, +ca));
}

lowp float rand(lowp vec2 co) {return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);}//просто пример рандома в шейдерах из инета

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

bool SphereIntersect(lowp vec3 apos, lowp float arad, lowp vec3 ro, lowp vec3 rd, out lowp vec3 norm)
{
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

lowp float density(lowp vec3 pos, lowp vec3 offset)
{
	lowp vec3 p = pos * 0.02/SIZE + offset;
	lowp float dens = get_noise(p,2.0+SOFTNESS);
	dens *= smoothstep (COVERAGE, COVERAGE + .07, dens);
	return clamp(dens, 0.0, 1.0);	
}

lowp vec4 clouds_3d(lowp vec3 ro, lowp vec3 rd, lowp vec3 wind)
{
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

lowp vec3 cube_bot(lowp vec3 p, lowp vec3 c1, lowp vec3 c2, lowp float time)
{
	lowp float f = 0.0;
	f += .50000 * noise(.5 * (p+vec3(0.,0.,-time*0.275)));
	f += .25000 * noise(1. * (p+vec3(0.,0.,-time*0.275)));
	f += .12500 * noise(2. * (p+vec3(0.,0.,-time*0.275)));
	f += .06250 * noise(4. * (p+vec3(0.,0.,-time*0.275)));
	return  f* mix(c1, c2, p * .5 + .5);
}

lowp float MapSH(lowp vec3 p, lowp float cloudy,lowp vec3 offset, lowp float CLOUD_UPPER)
{
	lowp float h = -(get_noise(p*0.0003+offset, 2.76434)-cloudy-.6);
    h *= smoothstep((HEIGHT+0.1)*CLOUD_UPPER+100., (HEIGHT+0.1)*CLOUD_UPPER, p.y);
	return h;
}

lowp vec4 clouds_2d(lowp vec3 rd, lowp vec3 wind)
{
	lowp float CLOUD_LOWER=7000.0;
	lowp float CLOUD_UPPER=9000.0;
	lowp float cloudy = (1.0-COVERAGE)-0.5;
	lowp float beg = (((HEIGHT+0.1)*CLOUD_LOWER) / rd.y);
	lowp float end = (((HEIGHT+0.1)*CLOUD_UPPER) / rd.y);
	lowp vec3 p = vec3(rd * beg);
	lowp vec3 add = rd * ((end-beg) / 55.0);
	lowp vec2 shade;
	lowp vec2 shadeSum = vec2(0.0, 0.0);
	for (int i = 0; i < min(STEPS,5); i++)
	{
		if (shadeSum.y >= 1.0) break;
		lowp float h = MapSH(p,cloudy,wind,CLOUD_UPPER);
		shade.y = max(h, 0.0); 
        shade.x = clamp(-(h-MapSH(p+SUN_POS*200.0, cloudy,wind,CLOUD_UPPER))*2., 0.05, 1.0);
		shadeSum += shade * (1.0 - shadeSum.y);
		p += add;
	}
	lowp vec3 clouds = mix(vec3(pow(shadeSum.x, .6)), vec3(1.0), (1.0-shadeSum.y)*.4);
    clouds = clamp(mix(vec3(0.0), min(clouds, 1.0), shadeSum.y),0.0,1.0);
	return vec4(clouds, shadeSum.y);
}

void fragment(){
	lowp vec2 uv = UV; 
	uv.x = 2.0 * uv.x - 1.0;
	uv.y = 2.0 * uv.y - 1.0;
	lowp vec3 rd = normalize(rotate_y(rotate_x(vec3(0.0, 0.0, 1.0),-uv.y*3.1415926535/2.0),-uv.x*3.1415926535)); //transform UV to spherical panorama 3d coords
	rd.x*=-1.0; //The x-axis is inverted on the godot scene for unknown reasons
	lowp vec3 ro = vec3(0.0, -200.0*HEIGHT+40.0, 0.0); //This is the vector of displacement of the sphere relative to zero coordinates. Here you can set the height of the clouds. That is, to make a sphere with clouds higher or lower.
	lowp vec4 cld = vec4(0.0);
	lowp float skyPow = dot(rd, vec3(0.0, -1.0, 0.0));
	lowp float horizonPow =1.-pow(1.0-abs(skyPow), 5.0);
	if(rd.y>0.0)
	{
		if (STEPS < 20) cld = clouds_2d(rd,WIND*TIME); else cld=clouds_3d(ro,rd,WIND*TIME/SIZE);
		cld=clamp(cld,0.0,1.0);
		cld.rgb+=0.04*cld.rgb*horizonPow;
		cld*=clamp((  1.0 - exp(-2.3 * pow(max((0.0), horizonPow), (2.6)))),0.,1.);//Here we dissolve the clouds in the horizon for a smooth transition to the horizon line.
	}
	else
	{
	cld.rgb = cube_bot(rd,vec3(1.5,1.49,1.71), vec3(1.1,1.15,1.5),TIME);
	cld.a=1.;
	cld*=clamp((  1.0 - exp(-1.3 * pow(max((0.0), horizonPow), (2.6)))),0.,1.);
	}
	COLOR = vec4(cld.rgb/(0.0001+cld.a), cld.a);
}