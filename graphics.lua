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

local _g, g = {
  circle = shadereffect.construct(circlebytes, false)
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

graphics.set('draw_circle', g.draw_circle)
graphics.set('draw_circle_2D', g.draw_circle_2D)
graphics.set('draw_circle_xyz', g.draw_circle_xyz)

return setmetatable(g, 
{
  __index = graphics
})
