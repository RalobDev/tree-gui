varying vec2 v_pos;

#ifdef VERTEX
vec4 position(mat4 transform_projection, vec4 vertex_position)
{
    v_pos = vertex_position.xy;
    return transform_projection * vertex_position;
}
#endif

#ifdef PIXEL
uniform vec4  bgColor;
uniform float drawCenter;
uniform vec2  skew;
uniform vec4  borderColor;
uniform float borderBlend;
uniform vec4  shadowColor;
uniform float shadowSize;
uniform vec2  shadowOffset;
uniform float aaSize;

uniform vec2  boxCenter;
uniform vec2  boxHalf;
uniform vec4  outerRadii;

uniform vec2  innerOffset;
uniform vec2  innerHalf;
uniform vec4  innerRadii;

uniform float cornerDetail;

float sdCorner(vec2 v, float r)
{
    if (cornerDetail < 0.5 || r <= 0.0) return length(v) - r;

    float n   = floor(cornerDetail + 0.5);
    float stp = 1.57079632679 / n;
    float k   = clamp(floor(atan(v.y, v.x) / stp), 0.0, n - 1.0);
    float a0  = k * stp;
    float am  = a0 + stp * 0.5;

    float s = dot(v, vec2(cos(am), sin(am))) - r * cos(stp * 0.5);
    if (s <= 0.0) return s;

    vec2 p0 = r * vec2(cos(a0), sin(a0));
    vec2 p1 = r * vec2(cos(a0 + stp), sin(a0 + stp));
    vec2 e  = p1 - p0;
    float t = clamp(dot(v - p0, e) / dot(e, e), 0.0, 1.0);
    return length(v - p0 - e * t);
}

float sdRoundBox(vec2 p, vec2 hs, vec4 r)
{
    float rad = (p.x > 0.0) ? ((p.y > 0.0) ? r.z : r.y)
                            : ((p.y > 0.0) ? r.w : r.x);
    vec2 q = abs(p) - hs + rad;
    if (q.x > 0.0 && q.y > 0.0) return sdCorner(q, rad);
    return max(q.x, q.y) - rad;
}

vec2 unskew(vec2 p)
{
    vec2 size = boxHalf * 2.0;
    float det = 1.0 - (skew.x * skew.y) / (size.x * size.y);
    return vec2(p.x + skew.x * p.y / size.y,
                p.y + skew.y * p.x / size.x) / det;
}

float coverage(float d)
{
    if (aaSize <= 0.0) return d < 0.0 ? 1.0 : 0.0;
    return clamp(0.5 - d / aaSize, 0.0, 1.0);
}

vec4 premul(vec4 c) { return vec4(c.rgb * c.a, c.a); }

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 sc)
{
    vec2 p = v_pos - boxCenter;
    vec2 q = unskew(p);

    float dOuter = sdRoundBox(q, boxHalf, outerRadii);
    float dInner = sdRoundBox(q - innerOffset, innerHalf, innerRadii);
    float O = coverage(dOuter);
    float I = coverage(dInner);

    vec4 bg = bgColor;
    bg.a *= drawCenter;

    vec4 ring = premul(borderColor);
    if (borderBlend > 0.5) {
        float g = clamp(-dOuter / max(dInner - dOuter, 0.0001), 0.0, 1.0);
        ring = mix(ring, premul(bg), g);
    }

    vec4 surface = ring * (1.0 - I) + premul(bg) * I;
    surface *= O;

    vec2 qs = unskew(p - shadowOffset);
    float ds = sdRoundBox(qs, boxHalf, outerRadii);
    float sh;
    if (shadowSize > 0.0)
        sh = 1.0 - smoothstep(-shadowSize * 0.5, shadowSize * 0.5, ds - shadowSize * 0.5);
    else
        sh = coverage(ds);
    vec4 shadow = premul(shadowColor) * sh;

    vec4 res = surface + shadow * (1.0 - surface.a);
    if (res.a <= 0.0001) return vec4(0.0);

    return vec4(res.rgb / res.a * color.rgb, res.a * color.a);
}
#endif
