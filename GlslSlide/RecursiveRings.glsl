#version 300 es

/*!
 * @brief Template GLSL file for Ray Marching.
 *
 * @author koturn
 * @date 2023 04/17
 * @file Sphere.glsl
 * @version 0.1
 */

precision highp float;
// precision mediump float;


// vscode-glsl-canvas
// https://marketplace.visualstudio.com/items?itemName=circledev.glsl-canvas
#define VSCODE 1
// Shadertoy
// https://www.shadertoy.com/new#
#define SHADERTOY 2

// Platform switch.
#define PLATFORM VSCODE
// #define PLATFORM SHADERTOY


#if PLATFORM == SHADERTOY
#    define u_time iTime
#    define u_mouse iMouse
#    define u_resolution iResolution
#endif


#if PLATFORM == VSCODE
//! Elapsed seconds.
uniform float u_time;
//! Mouse position.
uniform vec2 u_mouse;
//! Screen resolution.
uniform vec2 u_resolution;
#endif


#if PLATFORM != SHADERTOY
//! Output color
out vec4 FragColor;
#endif


//! Position of the camera.
const vec3 kCameraPos = vec3(0.0, 0.0, 55.0);
//! Z-coordinate of the target screen.
const float kScreenZ = 4.0;
//! Light direction.
const vec3 kLightDir = normalize(vec3(0.0, 1.0, 1.0));
//! Light color.
const vec3 kLightCol = vec3(1.0, 1.0, 1.0);
//! Ambient color.
const vec3 kAmbient = vec3(0.0, 0.0, 0.0);

//! Maximum loop count.
const int kMaxLoop = 128;
//! Minimum distance of the ray.
const float kMinRayLength = 0.001;
//! Maximum distance of the ray.
const float kMaxRayLength = 1000.0;
//! Marching Factor.
// const float kMarchingFactor = 1.0;
const float kMarchingFactor = 0.975;

//! Specular Power.
const float kSpecularPower = 64.0;
//! Specular Color.
const vec3 kSpecularColor = vec3(0.5, 0.5, 0.5);

//! Color of the object.
// const vec3 kAlbedo = vec3(1.0, 1.0, 1.0);
const vec3 kAlbedo = vec3(64.0 / 255.0, 73.0 / 255.0, 15.0 / 255.0);

// The ratio of the circumference of a circle to its diameter.
const float kPi = acos(-1.0);
// Twice of kPi.
const float kPi2 = kPi * 2.0;
// Reciprocal of kPi.
const float kInvPi = 1.0 / kPi;
// Reciprocal of kPi2.
const float kInvPi2 = 1.0 / kPi2;

/*!
 * @brief Output of rayMarch().
 */
struct rmout
{
    //! Length of the ray.
    float rayLength;
    //! A flag whether the ray collided with an object or not.
    bool isHit;

    vec3 color;
};


void mainImage(out vec4 fragColor, in vec2 fragCoord);
rmout rayMarch(vec3 rayOrigin, vec3 rayDir);
float map(vec3 p, out vec3 color);
float sdTorus(vec3 p, vec2 t);
float sdTorus(vec3 p, float radius, float thickness);
vec3 getNormal(vec3 p);
vec4 calcLighting(vec4 color, vec3 pos, vec3 normal, vec3 ambient);
vec2 rotate2D(vec2 pos, float angle);
vec2 pmod(vec2 p, float angle, float r);
vec2 pmod(vec2 p, float r);
float atanPos(float x);
float atanFast(float x);
float atan2Fast(float x, float y);
float pown(float x, int n);
vec3 rgb2hsv(vec3 rgb);
vec3 hsv2rgb(vec3 hsv);


#if PLATFORM != SHADERTOY
/*!
 * @brief Entry point of this fragment shader program.
 */
void main(void)
{
    mainImage(/* out */ FragColor, gl_FragCoord.xy);
}
#endif


/*!
 * @brief Body of fragment shader function.
 * @param [out] fragColor  Color of fragment.
 * @param [in] fragCoord  Coordinate of fragment.
 */
void mainImage(out vec4 fragColor, in vec2 fragCoord)
{
    vec2 position = (fragCoord.xy * 2.0 - u_resolution.xy) / min(u_resolution.x, u_resolution.y);
    vec3 rayDir = normalize(vec3(position, kScreenZ) - kCameraPos);

    rmout ro = rayMarch(kCameraPos, rayDir);
    if (!ro.isHit) {
#if PLATFORM == SHADERTOY
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
        return;
#else
        discard;
#endif
    }

    vec3 finalRayPos = kCameraPos + rayDir * ro.rayLength;

    fragColor = calcLighting(
        vec4(ro.color, 1.0),
        finalRayPos,
        getNormal(finalRayPos),
        kAmbient);
}


/*!
 * @brief Execute ray marching.
 *
 * @param [in] rayOrigin  Origin of the ray.
 * @param [in] rayDir  Direction of the ray.
 * @return Result of the ray marching.
 */
rmout rayMarch(vec3 rayOrigin, vec3 rayDir)
{
    rmout ro;
    ro.rayLength = 0.0;
    ro.isHit = false;

    // Marching Loop.
    for (int i = 0; i < kMaxLoop; i = ro.isHit || ro.rayLength > kMaxRayLength ? 0x7fffffff : i + 1) {
        // Position of the tip of the ray.
        float d = map(rayOrigin + rayDir * ro.rayLength, /* color */ ro.color);

        ro.isHit = d < kMinRayLength;
        ro.rayLength += d * kMarchingFactor;
    }

    return ro;
}


/*!
 * @brief SDF of Torus.
 * @param [in] p  Position of the tip of the ray.
 * @param [in] t  (t.x, t.y) = (radius of torus, thickness of torus).
 * @return Signed Distance to the Sphere.
 */
float sdTorus(vec3 p, vec2 t)
{
    vec2 q = vec2(length(p.xz) - t.x, p.y);
    return length(q) - t.y;
}


/*!
 * @brief SDF of Torus.
 * @param [in] p  Position of the tip of the ray.
 * @param [in] radius  Radius of torus, thickness of torus).
 * @param [in] thichness  Thickness of torus.
 * @return Signed Distance to the Torus.
 */
float sdTorus(vec3 p, float radius, float thickness)
{
    vec2 q = vec2(length(p.xz) - radius, p.y);
    return length(q) - thickness;
}


const vec3 _TorusBaseColor = vec3(0.6, 0.0, 0.0);
// const vec3 _TorusBaseColor = vec3(64.0 / 255.0, 73.0 / 255.0, 15.0 / 255.0);

const int _TorusRecursion = 2;
const float _TorusNumber  = 6.0;
const float _TorusThickness  = 0.03;
const float _TorusRadius  = 0.75;
const float _TorusRadiusDecay = 0.33;
const float _TorusThicknessDecay = 0.75;
const float _TorusAnimSpeed = 1.0;
const float _TorusAnimDecay = 0.8;

#define HUE_SHIFT

/*!
 * @brief SDF (Signed Distance Function) of objects.
 * @param [in] p  Position of the tip of the ray.
 * @return Signed Distance to the objects.
 */
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
#ifdef HUE_SHIFT
        p.xy = rotate2D(p.xy, u_time * 0.5);
        float angle = atan2Fast(p.y, p.x);
        // float angle = atan(p.y, p.x);
        p = vec3(pmod(p.xy, angle, _TorusNumber) - vec2(rt.x, 0.0), p.z);

        rt *= rtDecay;

        float d = min(minDist, sdTorus(p, rt.x, rt.y));
        if (d < minDist) {
            minDist = d;
            vec3 hsv = rgb2hsv(_TorusBaseColor);
            hsv.x += angle / kPi2;
            color = hsv2rgb(hsv);
        }
#else
        p.xy = rotate2D(p.xy, u_time * 0.5);
        p = vec3(pmod(p.xy, _TorusNumber) - vec2(rt.x, 0.0), p.z);

        rt *= rtDecay;

        minDist = min(minDist, sdTorus(p, rt.x, rt.y));
#endif

        p.xyz = p.zxy;
        rotAngle *= _TorusAnimDecay;
    }

    return minDist;
}


/*!
 * @brief Calculate normal of the objects.
 * @param [in] p  Position of the tip of the ray.
 * @return Normal of the objects.
 */
vec3 getNormal(vec3 p)
{
    const vec2 k = vec2(1.0, -1.0);
    const float h = 0.0001;
    const vec3[4] ks = vec3[](k.xyy, k.yxy, k.yyx, k.xxx);

    vec3 normal = vec3(0.0, 0.0, 0.0);
    vec3 _;

    for (int i = 0; i < 4; i++) {
        normal += ks[i] * map(p + ks[i] * h, /* out */ _);
    }

    return normalize(normal);
}


/*!
 * Calculate lighting.
 * @param [in] color  Base color.
 * @param [in] pos  Object space position.
 * @param [in] normal  Normal in object space.
 * @param [in] ambient  Ambient light.
 * @return Color with lighting applied.
 */
vec4 calcLighting(vec4 color, vec3 pos, vec3 normal, vec3 ambient)
{
    float nDotL = dot(normal, kLightDir);

    vec3 diffuse = vec3(pown(0.5 * nDotL + 0.5, 2)) * kLightCol;

    vec3 viewDir = normalize(kCameraPos - pos);
    vec3 specular = pow(max(0.0, dot(normalize(kLightDir + viewDir), normal)), kSpecularPower) * kSpecularColor.xyz * kLightCol;

    return vec4((diffuse + ambient) * color.rgb + specular, color.a);
    // return vec4((diffuse + ambient) * color.rgb + specular, color.a);
}


/*!
 * @brief Rotate on 2D plane
 * @param [in] pos  Position.
 * @param [in] angle  Rotation angle.
 * @return Rotated position.
 */
vec2 rotate2D(vec2 pos, float angle)
{
    float s = sin(angle);
    float c = cos(angle);

    return vec2(
        pos.x * c + pos.y * s,
        -pos.x * s + pos.y * c);
}


/*!
 * @brief Polar Mod (Fold Rotate) Function.
 * @param [in] p  2D-coordinate.
 * @param [in] angle  Value of atan2(p.x, p.y).
 * @param [in] r  Number of divisions.
 * @return 2D-coordinate of polar mod.
 */
vec2 pmod(vec2 p, float angle, float r)
{
    float a = angle + kPi / r;
    float n = kPi * 2.0 / r;
    return rotate2D(p, floor(a / n) * n);
}


/*!
 * @brief Polar Mod (Fold Rotate) Function.
 * @param [in] p  2D-coordinate.
 * @param [in] r  Number of divisions.
 * @return 2D-coordinate of polar mod.
 */
vec2 pmod(vec2 p, float r)
{
    // return pmod(p, atan(p.y, p.x), r);
    return pmod(p, atan2Fast(p.y, p.x), r);
}


/*!
 * @brief Calculate positive value of atan().
 * @param [in] x  The first argument of atan().
 * @return Approximate positive value of atan().
 */
float atanPos(float x)
{
    float absX = abs(x);
    // float t0 = absX < 1.0 ? absX : 1.0 / absX;
    float t0 = min(absX, 1.0 / absX);
#if 0
    float poly = (-0.269408 * t0 + 1.05863) * t0;
#else
    float t1 = t0 * t0;
    float poly = 0.0872929;
    poly = -0.301895 + poly * t1;
    poly = 1.0 + poly * t1;
    poly *= t0;
#endif

    return absX < 1.0 ? poly : (kPi * 0.5 - poly);
}


/*!
 * @brief Fast atan().
 * @param [in] x  The first argument of atan().
 * @return Approximate value of atan().
 * @see https://seblagarde.wordpress.com/2014/12/01/inverse-trigonometric-functions-gpu-optimization-for-amd-gcn-architecture/
 */
float atanFast(float x)
{
    float t0 = atanPos(x);
    return x < 0.0 ? -t0 : t0;
}

/*!
 * @brief Fast atan2().
 * @param [in] x  The first argument of atan2().
 * @param [in] y  The second argument of atan2().
 * @return Approximate value of atan().
 * @see https://seblagarde.wordpress.com/2014/12/01/inverse-trigonometric-functions-gpu-optimization-for-amd-gcn-architecture/
 */
float atan2Fast(float x, float y)
{
    return atanFast(x / y) + (y >= 0.0 ? 0.0 : x >= 0.0 ? kPi : -kPi);
}


/*!
 * @brief Calculate pow(x, n) with exponentiation by squaring.
 * @param [in] x  A value.
 * @param [in] n  Exponent.
 * @return pow(x, n)
 */
float pown(float x, int n)
{
    float v = 1.0;
    for (; n > 0; n >>= 1) {
        v *= (n & 1) == 0 ? 1.0 : x;
        x *= x;
    }

    return v;
}


/*!
 * @brief Convert from RGB to HSV.
 * @param [in] rgb  Three-dimensional vector of RGB.
 * @return Three-dimensional vector of HSV.
 */
vec3 rgb2hsv(vec3 rgb)
{
    const vec4 k = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    const float e = 1.0e-10;

#if 1
    // Optimized version.
    bool b1 = rgb.g < rgb.b;
    vec4 p = vec4(b1 ? rgb.bg : rgb.gb, b1 ? k.wz : k.xy);

    bool b2 = rgb.r < p.x;
    p.xyz = b2 ? p.xyw : p.yzx;
    vec4 q = b2 ? vec4(p.xyz, rgb.r) : vec4(rgb.r, p.xyz);

    float d = q.x - min(q.w, q.y);
    vec2 hs = vec2(q.w - q.y, d) / vec2(6.0 * d + e, q.x + e);

    return vec3(abs(q.z + hs.x), hs.y, q.x);
#else
    // Original version.
    vec4 p = rgb.g < rgb.b ? vec4(rgb.bg, k.wz) : vec4(rgb.gb, k.xy);
    vec4 q = rgb.r < p.x ? vec4(p.xyw, rgb.r) : vec4(rgb.r, p.yzx);
    float d = q.x - min(q.w, q.y);

    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
#endif
}


/*!
 * @brief Convert from HSV to RGB.
 * @param [in] hsv  Three-dimensional vector of HSV.
 * @return Three-dimensional vector of RGB.
 */
vec3 hsv2rgb(vec3 hsv)
{
    const vec4 k = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);

    vec3 p = abs(mod(hsv.xxx + k.xyz, 1.0) * 6.0 - k.www);
    return hsv.z * mix(k.xxx, clamp(p - k.xxx, 0.0, 1.0), hsv.y);
}
