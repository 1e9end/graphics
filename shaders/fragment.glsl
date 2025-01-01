precision highp float;
uniform vec2 res;
uniform float time;

uniform int fractal;
uniform float camZ;
uniform float THICC;
uniform float specularExp;
uniform float lightAngle;

float PI = 3.14;
float EPSILON = 0.001;

// rotation matrix around origin
vec3 rotate(vec3 p, vec3 r){
    // d --> r
    r.x *= PI/180.0;
    r.y *= PI/180.0;
    r.z *= PI/180.0;
    mat3 xRot = mat3 (1,0,0,
                        0,cos(r.x),-sin(r.x),
                        0,sin(r.x), cos(r.x));
    mat3 yRot = mat3 (cos(r.y),0,sin(r.y),
                        0,1,0,
                        -sin(r.y),0,cos(r.y));
    mat3 zRot = mat3 (cos(r.z),-sin(r.z),0,
                        sin(r.z),cos(r.z),0,
                        0,0,1);
    return xRot * yRot * zRot * p;
}

//http://blog.hvidtfeldts.net/index.php/2011/08/distance-estimated-3d-fractals-iii-folding-space/
float pyramidDE(vec3 p){
    float scale = 1.75;
    float offset = 2.5;
    for (int n = 0; n < 16; ++n) {
        if(p.x + p.y < 0.0){ 
            p.xy = - p.yx;
        } 
        if(p.x + p.z < 0.0){ 
            p.xz = - p.zx;
        } 
        if(p.y + p.z < 0.0){ 
            p.zy = - p.yz;
        } 
        p = p * scale - offset*(scale - 1.0);
    }

    return length(p) * pow(scale, - 16.0);
}

float foldingLimit = 1.50;
float fixedRadius2 = 2.0;
float minRadius2 = 0.0;
void sphereFold(inout vec3 p, inout float dp) {
    float r2 = dot(p, p);
    float temp = r2 < minRadius2 ? fixedRadius2/minRadius2 : (r2 < fixedRadius2 ? fixedRadius2/r2 : 1.0);
    p *= temp;
    dp *= temp;
}

void boxFold(inout vec3 p, inout float dp) {
    p = clamp(p, -foldingLimit, foldingLimit) * 2.0 - p;
}

float mandelboxDE(vec3 p){
    float scale = 2.48;
    vec3 offset = p;
    float dr = 1.0;

    for (int n = 0; n < 7; ++n) {
        boxFold(p, dr);
        sphereFold(p, dr);
        p = scale * p + offset;
        dr = dr * abs(scale) + 1.0;
    }
    return length(p)/abs(dr);
}
    
float mandelbulbDE(vec3 p) {
    float power = 8.0;
    vec3 z = p;
    
    float dr = 1.0;
    float r;
    
    for (int n = 0; n < 20; ++n) {
        r = length(z);
        if (r > 2.0){
            break;
        }
        
        float theta = acos(z.z / r);
        float phi = atan(z.y, z.x);
        
        dr = pow(r, power - 1.0) * power * dr + 1.0;
        
        float zr = pow(r, power);
        
        theta *= power;
        phi *= power;
        
        z = p + vec3(sin(theta) * cos(phi), sin(phi) * sin(theta), cos(theta)) * zr;
    }
    
    return 0.5 * log(r) * r / dr;
}

//distance to box 
float sdBox(vec3 p, vec3 b){
    vec3 d = abs(p) - b;
    return length(max(d, 0.0)) + min(max(d.x, max(d.y, d.z)), 0.0);
}

float mengerSpongeDE(vec3 p){
    vec3 n1 = normalize(vec3(1, 0, -1));
    vec3 n2 = normalize(vec3(0, 1, -1));
    float s = 1.;
    
    for (int n = 0; n < 5; ++n) {        
        //folding
        p = abs(p);  
        p -= 2. * min(0., dot(p,n1)) * n1; 
        p -= 2. * min(0., dot(p,n2)) * n2; 
        //scale
        
        p *= 3.; 
        s /= 3.;
        
        //offset
        p.z -=  1.;
        p.z  = -abs(p.z);
        p.z +=  1.;
        p.x -= 2.;
        p.y -= 2.;      
    }

    float dis = sdBox(p, vec3(1));
            dis *= s;
    
    return dis; 
}

float DE(vec3 p){
    if (fractal == 0){
        return pyramidDE(p);
    }
    if (fractal == 1){
        return mandelboxDE(p);
    }
    if (fractal == 2){
        return mandelbulbDE(p);
    }
    if (fractal == 3){
        return mengerSpongeDE(p);
    }
}

float NORM_EPSILON = 0.001;
vec3 approxNormal(vec3 p)
{
    return normalize(vec3(
        DE(p + vec3(NORM_EPSILON, 0, 0)) - DE(p - vec3(NORM_EPSILON, 0, 0)),
        DE(p + vec3(0, NORM_EPSILON, 0)) - DE(p - vec3(0, NORM_EPSILON, 0)),
        DE(p + vec3(0, 0, NORM_EPSILON)) - DE(p - vec3(0, 0, NORM_EPSILON))));
}

float hardshadow (vec3 origin, vec3 direction, float smoothness){
    float distance = EPSILON;
    float light = 1.0;
    float eps = 0.1;
    for (float iters = 0.0; iters < 200.0; ++iters){
        vec3 pos = origin + distance * direction;
        float nextDistance = DE(pos);
        distance += nextDistance;
        light = min(light, 1.0 - (eps - distance) / eps);
        if (abs(nextDistance) < EPSILON/2.0){
            return distance * smoothness;
        }
    }
    //return max(light, 0.0);
    return 1.0;
}

vec3 raymarch(vec3 origin, vec3 direction, vec3 light){
    float distance = 0.0;
    for (float iters = 0.0; iters < 200.0; ++iters){
        vec3 pos = origin + distance * direction;
        float nextDistance = DE(pos);
        distance += nextDistance;
        if (abs(nextDistance) < THICC){ 
            vec3 normal = approxNormal(pos);
            float diffuse = max(0.0, dot(normal, light)); 
            // https://learnopengl.com/Lighting/Basic-Lighting
            vec3 reflected = reflect(direction, normal);
            float specular = pow(max(dot(reflected, light), 0.0), specularExp); 
            float shade = diffuse * 0.7 + specular * 0.3;
            float occlusion = 1.0;
            vec3 ambient = vec3(1.0, 1.0, 1.0);
            return shade * ambient * occlusion * hardshadow(pos, light, 0.1);
        }
        if (distance > 100.0){
            break;
        }
    }
    // Background blue
    return vec3(0.0, 0.0, 0.5);
}

void main(){
    // window relative -> clip space
    vec2 uv = gl_FragCoord.xy * res - 1.0;
    // directional light
    vec3 rot_axis = vec3(0.707107, 0, -0.707107);
    vec3 rot = vec3(1.0, 0.8, 1.0);
    vec3 light = normalize(rot * cos(lightAngle) + cross(rot_axis, rot) * sin(lightAngle) + rot_axis * dot(rot_axis, rot) * (1.0 - cos(lightAngle))); 

    //camera
    vec3 rotation =  vec3(0.0, mod(time, 360.0) * 30.0 + 45.0, 55.0);
    vec3 cameraPosition = vec3(0.0, 0.0, camZ);

    gl_FragColor = vec4(raymarch(rotate(cameraPosition, rotation), rotate(normalize(vec3(uv, 1.0)), rotation), light), 1.0);
}