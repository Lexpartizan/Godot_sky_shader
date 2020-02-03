shader_type canvas_item;
//////////////////////
// Fire Flame shader
uniform float iTime;
uniform sampler2D iChannel0;
uniform float up_down;
uniform float stability;
// procedural noise from IQ

lowp float noise(vec2 pos) {return textureLod( iChannel0, pos*0.01 ,1.0 - stability/10.0).x;}

lowp float fbm(vec2 p, float FBM_FREQ)
{
	lowp float
	t  = 0.51749673 * noise(p); p *= FBM_FREQ;
	t += 0.25584929 * noise(p); p *= FBM_FREQ;
	t += 0.12527603 * noise(p); p *= FBM_FREQ;
	t += 0.06255931 * noise(p);
	return t;
}

void fragment()
{
	lowp vec2 uv = UV;
	lowp vec2 q = UV;
	q.x *= .4;
	q.y *= 2.0;
	lowp float strength = floor(q.x+stability);
	lowp float T3 = max(3.,1.25*strength)*iTime;
	q.x -= .2;//mod(q.x,1.)-0.5;
	q.y -= up_down;
    
	lowp float n = fbm(strength*q - vec2(0,T3),1.76434);
	lowp float c = 1. - 16. * pow( max( 0., length(q*vec2(1.8+q.y*1.5,.75) ) - n * max( 0., q.y+.25 ) ),1.2 );
	lowp float c1 = n * c * (1.5-pow(2.50*uv.y,4.));
	c1=clamp(c1,0.,1.);
	lowp vec3 col = vec3(1.5*c1, 1.5*c1*c1*c1, c1*c1*c1*c1*c1);
	col= mix(col, pow(vec3(1.-clamp(c1, -1., 0.)) * pow(fbm(strength*q*1.25 - vec2(0,T3),1.76434),2.),vec3(2.)), .75-(col.x+col.y+col.z)/3.); // Just added this line!!! :)
	col = clamp(col,0.0,1.0);
	lowp float a = c * (1.-pow(uv.y,3.));
	col = clamp (mix(vec3(0.0),col,a),0.0, 1.0);
	if (col ==vec3 (0.0))a = 0.0; else a=clamp (a-0.3,0.0,1.0);
	COLOR = vec4(col, a);
}