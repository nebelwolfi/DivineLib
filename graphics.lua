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

float segment_distance(float2 p, float2 p1, float2 p2) {
    float2 center = (p1 + p2) * 0.5;
    float len = length(p2 - p1);
    float2 dir = (p2 - p1) / len;
    float2 rel_p = p - center;
    float dist1 = abs(dot(rel_p, float2(dir.y, -dir.x)));
    float dist2 = abs(dot(rel_p, dir)) - 0.5*len;
    return max(dist1, dist2);
}

float4 PS(VS_OUTPUT input): COLOR
{
  VS_OUTPUT output = (VS_OUTPUT) 0;
  output = input;

  float4 v = output.Position;
  
  float dist = segment_distance(v.xy, spos, epos);

  float outer = lineWidth * (1. - 1. / lineWidth);
  output.Color.xyz = color.xyz;
  if (dist < lineWidth)
    output.Color.w = 1. - 1. * smoothstep(1. - 2. / lineWidth, 1., dist / outer);
  else
    output.Color.w = 0.;

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
  if _g.circle == 0 then
    return
  end
  shadereffect.begin(_g.circle, 0, true)
  shadereffect.set_float(_g.circle, 'Is3D', 0)
  shadereffect.set_float(_g.circle, 'radius', radius)
  shadereffect.set_float(_g.circle, 'lineWidth', width)
  shadereffect.set_vec2(_g.circle, 'pos', vec2(x, y))
  shadereffect.set_color(_g.circle, 'color', color)
  shadereffect.draw(_g.circle)
end

function g.draw_circle_xyz(x, y, z, radius, width, color, pts_n)
  if _g.circle == 0 then
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
  if _g.line == 0 then
    return
  end
  shadereffect.begin(_g.line, y, true)
  shadereffect.set_float(_g.line, 'lineWidth', width + .5)
  shadereffect.set_vec2(_g.line, 'spos', vec2(x1, y1))
  shadereffect.set_vec2(_g.line, 'epos', vec2(x2, y2))
  shadereffect.set_color(_g.line, 'color', color)
  shadereffect.draw(_g.line)
end

graphics.set('draw_circle', g.draw_circle)
graphics.set('draw_circle_2D', g.draw_circle_2D)
graphics.set('draw_circle_xyz', g.draw_circle_xyz)
graphics.set('draw_line_2D', g.draw_line_2D)

return setmetatable(g, 
{
  __index = graphics
})
