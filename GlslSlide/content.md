## GLSL Slide

reveal.jsでWebGLのデモを行うサンプルスライド

------

## スフィアトレーシング (1)

ただの球

<canvas id="canvas01" width="512" height="512" data-fragment-url="./Sphere.glsl"></canvas>

---

## スフィアトレーシング (2)

再帰的な形状

<canvas id="canvas02" width="512" height="512" data-fragment-url="./RecursiveRings.glsl"></canvas>

---

## スフィアトレーシング (3)

```c
float map(vec3 p, out vec3 color)
{
    color = vec3(0.8, 0.8, 0.8);

    vec2 mrot = (u_mouse * 2.0 - 1.0) * kPi;
    p.zx *= mat2(cos(mrot.x), sin(mrot.x), -sin(mrot.x), cos(mrot.x));
    p.xy *= mat2(cos(mrot.y), sin(mrot.y), -sin(mrot.y), cos(mrot.y));

    vec2 rt = vec2(_TorusRadius, _TorusThickness);
    vec2 rtDecay = vec2(_TorusRadiusDecay, _TorusThicknessDecay);
    float minDist = sdTorus(p.xzy, rt.x, rt.y);
    float rotAngle = u_time * _TorusAnimSpeed;
    for (int i = 0; i < _TorusRecursion; i++) {
        p.xy = rotate2D(p.xy, u_time * 0.5);
        float angle = atan(p.y, p.x);
        p = vec3(pmod(p.xy, angle, _TorusNumber) - vec2(rt.x, 0.0), p.z);

        rt *= rtDecay;

        float d = min(minDist, sdTorus(p, rt.x, rt.y));
        if (d < minDist) {
            minDist = d;
            vec3 hsv = rgb2hsv(_TorusBaseColor);
            hsv.x += angle / kPi2;
            color = hsv2rgb(hsv);
        }

        p.xyz = p.zxy;
        rotAngle *= _TorusAnimDecay;
    }

    return minDist;
}
```
