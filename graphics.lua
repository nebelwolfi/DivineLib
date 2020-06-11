local circlebytes = [[
struct VS_OUTPUT
{
    float4 Input    : POSITION;
    float4 Color    : COLOR0;
    float4 Position : TEXCOORD0;
};

float4x4 Transform;
float2 pos;
float radius;
float4 color;
float lineWidth;
float Is3D;

VS_OUTPUT VS(VS_OUTPUT input) {
  VS_OUTPUT output = (VS_OUTPUT) 0;
  output.Input = mul(input.Input, Transform);
  output.Color = input.Color;
  output.Position = input.Input;
  return output;
}

float4 PS(VS_OUTPUT input): COLOR
{
  VS_OUTPUT output = (VS_OUTPUT) 0;
  output = input;

  float4 v = output.Position;
  
  float dist = distance(Is3D ? v.xz : v.xy, pos);

  output.Color.xyz = color.xyz;
  output.Color.w = color.w * (smoothstep(radius + lineWidth * .5, radius, dist) - smoothstep(radius, radius - lineWidth * .5, dist));

  return output.Color;
}

technique Movement
{
  pass P0 {
    ZEnable = FALSE;
    AlphaBlendEnable = TRUE;
    DestBlend = InvSrcAlpha;
    SrcBlend = SrcAlpha;
    VertexShader = compile vs_3_0 VS();
    PixelShader = compile ps_3_0 PS();
  }
}
]]

local linebytes = [[
struct VS_OUTPUT
{
    float4 Input    : POSITION;
    float4 Color    : COLOR0;
    float4 Position : TEXCOORD0;
};

float4x4 Transform;
float2 spos;
float2 epos;
float4 color;
float lineWidth;

VS_OUTPUT VS(VS_OUTPUT input) {
  VS_OUTPUT output = (VS_OUTPUT) 0;
  output.Input = mul(input.Input, Transform);
  output.Color = input.Color;
  output.Position = input.Input;
  return output;
}

float GetPointDistanceToLine(float x1, float z1, float x2, float z2, float x3, float z3)
{
	float dz = z3 - z2;
	float dx = x3 - x2;
	return ((z3 - z2) * x1 - (x3 - x2) * z1 + x3 * z2 - z3 * x2) / sqrt(dz * dz + dx * dx);
}

float4 PS(VS_OUTPUT input): COLOR
{
  VS_OUTPUT output = (VS_OUTPUT) 0;
  output = input;

  float4 v = output.Position;
  
  float2 perp = float2(-(epos.y - spos.y), epos.x - spos.x);
  perp = perp / sqrt(perp.x * perp.x + perp.y * perp.y);
  float lineRadius = lineWidth * .5;
  float2 edge0 = float2(spos.x - perp.x * lineRadius, spos.y - perp.y * lineRadius);
  float2 edge1 = float2(spos.x + perp.x * lineRadius, spos.y + perp.y * lineRadius);
  float2 edge2 = float2(epos.x + perp.x * lineRadius, epos.y + perp.y * lineRadius);
  float2 edge3 = float2(epos.x - perp.x * lineRadius, epos.y - perp.y * lineRadius);
  float dist = GetPointDistanceToLine(v.x, v.y, edge0.x, edge0.y, edge1.x, edge1.y);
  if (dist < 0.)
    return output.Color;
  float d = GetPointDistanceToLine(v.x, v.y, edge1.x, edge1.y, edge2.x, edge2.y);
  if (d < 0.)
    return output.Color;
  dist = min(d, dist);
  d = GetPointDistanceToLine(v.x, v.y, edge2.x, edge2.y, edge3.x, edge3.y);
  if (d < 0.)
    return output.Color;
  dist = min(d, dist);
  d = GetPointDistanceToLine(v.x, v.y, edge3.x, edge3.y, edge0.x, edge0.y);
  if (d < 0.)
    return output.Color;
  dist = min(d, dist);
  
  output.Color.xyz = color.xyz;
  if (spos.x != epos.x && spos.y != epos.y)
    output.Color.w = color.w - color.w * smoothstep(.95, 1., 1. - dist / lineRadius);
  else
    output.Color.w = color.w;

  return output.Color;
}

technique Movement
{
  pass P0 {
    ZEnable = FALSE;
    AlphaBlendEnable = TRUE;
    DestBlend = InvSrcAlpha;
    SrcBlend = SrcAlpha;
    VertexShader = compile vs_3_0 VS();
    PixelShader = compile ps_3_0 PS();
  }
}
]]

local _g, g = {
  circle = shadereffect.construct(circlebytes, false),
  line = shadereffect.construct(linebytes, false),
}, {}

function _g.color_to_vec4(color)
  return vec4(
    bit.band(bit.rshift(color, 0), 0xff) / 255,
    bit.band(bit.rshift(color, 8), 0xff) / 255,
    bit.band(bit.rshift(color, 16), 0xff) / 255,
    bit.band(bit.rshift(color, 24), 0xff) / 255
  )
end

function g.draw_circle_2D(x, y, radius, width, color, pts_n)
  if not _g.circle then
    return
  end
  shadereffect.begin(_g.circle, 0, false)
  shadereffect.set_float(_g.circle, 'Is3D', 0)
  shadereffect.set_float(_g.circle, 'radius', radius)
  shadereffect.set_float(_g.circle, 'lineWidth', width)
  shadereffect.set_vec2(_g.circle, 'pos', vec2(x, y))
  shadereffect.set_color(_g.circle, 'color', color)
  shadereffect.draw(_g.circle)
end

function g.draw_circle_xyz(x, y, z, radius, width, color, pts_n)
  if not _g.circle then
    return
  end
  shadereffect.begin(_g.circle, y, true)
  shadereffect.set_float(_g.circle, 'Is3D', 1)
  shadereffect.set_float(_g.circle, 'radius', radius)
  shadereffect.set_float(_g.circle, 'lineWidth', width + 5.5)
  shadereffect.set_vec2(_g.circle, 'pos', vec2(x, z))
  shadereffect.set_color(_g.circle, 'color', color)
  shadereffect.draw(_g.circle)
end

function g.draw_circle(v1, radius, width, color, pts_n)
  g.draw_circle_xyz(v1.x, v1.y, v1.z, radius, width + 5.5, color)
end

function g.draw_line_2D(x1, y1, x2, y2, width, color)
  if not _g.line then
    return
  end
  shadereffect.begin(_g.line, 0, false)
  shadereffect.set_float(_g.line, 'lineWidth', width)
  shadereffect.set_vec2(_g.line, 'spos', vec2(x1, y1))
  shadereffect.set_vec2(_g.line, 'epos', vec2(x2, y2))
  shadereffect.set_color(_g.line, 'color', color)
  shadereffect.draw(_g.line)
end

if _g.circle then
  graphics.set('draw_circle', g.draw_circle)
  graphics.set('draw_circle_2D', g.draw_circle_2D)
  graphics.set('draw_circle_xyz', g.draw_circle_xyz)
end
if _g.line then
  graphics.set('draw_line_2D', g.draw_line_2D)
end

return setmetatable(g, 
{
  __index = graphics
})
