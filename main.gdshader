shader_type canvas_item;

uniform int MaximumIteration : hint_range(1,500) = 150;

uniform vec2 Resolution = vec2(1024.0,600.0);

uniform vec3 Center = vec3(-0.55, 0.0, 0.0);
uniform float Radius = 1.3;
uniform vec3 Ray = vec3(0.0, 0.0, -1.0);
uniform vec3 Rotation = vec3(0.0, 0.0, 0.0);
uniform sampler2D Gradient : hint_albedo;

// Point in transformed coordinates, computed in vertex shader
varying highp vec3 Point;

vec2 similarity(vec2 x, vec2 a, vec2 b)
{
	return vec2(a.x*x.x - a.y*x.y + b.x, a.x*x.y + a.y*x.x + b.y);
}

void vertex()
{
	// Adaptats UV coordinates to be centered on the square [-1..1]x[-1..1]
	// Point = vec3(similarity(UV, vec2(1.0,0.0), vec2(-0.5)), 0.0);
	Point = 2.0*vec3(UV.x-0.5, 0.5-UV.y, 0.0);

	// Adapts the aspect ratio of UV coordinates such that at least the
	// central square is visible
	if (Resolution.x>Resolution.y)
		Point.x *= Resolution.x/Resolution.y;
	else
		Point.y *= Resolution.y/Resolution.x;

	// Rotation and zoom
	Point.xy = Radius*mat2(vec2(cos(Rotation.z), sin(Rotation.z)),
	                vec2(-sin(Rotation.z), cos(Rotation.z))) * Point.xy;

	// Translation
	Point.xy += Center.xy;



}

void fragment()
{
	vec2 p = Point.xy;
	
	// Main loop 
	vec2 z = vec2(0.0);
	int count = MaximumIteration;
	for(int i=0; i<=MaximumIteration; i++)
	{
		z = vec2(z.x*z.x - z.y*z.y, 2.0*z.x*z.y) + p;
		if(length(z)>=2.0)
		{
			count = i;
			break;
		}
	}

	// Final color assignment
	float color = float(count) / float(MaximumIteration);

	COLOR = vec4(vec3(texture(Gradient, vec2(color,color)).rgb), 1.0);
}
