gl = initGL("canvas");

let program = createProgram("vts", "fts");
gl.useProgram(program);

let posL = gl.getAttribLocation(program, "position");
let posBuffer = gl.createBuffer();
gl.bindBuffer(gl.ARRAY_BUFFER, posBuffer);

let positions = [
    -1, -1, 
    +1, -1,
    -1, +1, 
    -1, +1, 
    +1, -1, 
    +1, +1
];

gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(positions), gl.STATIC_DRAW);

resize(gl.canvas, false, false, true);
clearColor();

gl.enableVertexAttribArray(posL);
gl.vertexAttribPointer(posL, 2, gl.FLOAT, false, 0, 0);

let config = {
    fractal: 3,
    specular_exp: 16,
    light_angle: 0.0,
    fps: 60,
};

let resL = gl.getUniformLocation(program, "res");
gl.uniform2f(resL, 2.0/gl.drawingBufferWidth, 2.0/gl.drawingBufferHeight);
let timeL = gl.getUniformLocation(program, "time");
let fractalL = gl.getUniformLocation(program, "fractal");
let camZL = gl.getUniformLocation(program, "camZ");
let THICCL = gl.getUniformLocation(program, "THICC");
let specularExpL = gl.getUniformLocation(program, "specularExp");
let lightAngleL = gl.getUniformLocation(program, "lightAngle");

function updateFractal(){
    // let fractalN = document.getElementById("fractals").value;
    let camZ, THICC;
    switch(+config.fractal){
        case 3:
            camZ = -3.0;
            THICC = 0.001;
        break;
        case 2:
            camZ = -2.0;
            THICC = 0.001;
        break;
        case 1:
            camZ = -16.0;
            THICC = 0.03;
        break;
        case 0: default:
            camZ = -6.0;
            THICC = 0.001;
    }
    gl.uniform1i(fractalL, config.fractal);
    gl.uniform1f(camZL, camZ);
    gl.uniform1f(THICCL, THICC);
    gl.uniform1f(specularExpL, config.specular_exp);
    gl.uniform1f(lightAngleL, config.light_angle);
}

updateFractal();

let gui = new dat.GUI({ width: 300 });

gui.add(config, 'fractal', {
    'Menger Sponge': 3,
    'Sierpenski Pyramid': 0,
    'Mandelbox': 1,
    'Mandelbulb': 2,
}).name('Fractal').onFinishChange(updateFractal);

gui.add(config, 'specular_exp', 0.5, 16, 0.5).name('Specular Exponent').onFinishChange(updateFractal);

gui.add(config, 'light_angle', 0.0, 1, 0.1).name('Lighting Angle').onFinishChange(updateFractal);

//let perfFolder = gui.addFolder("Performance");
//perfFolder.add(config, 'fps', 0, 120).name('Target FPS').step(1);

// Choose best requestAnimationFrame
window.reqAnimationFrame = (function(callback){
    return window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame ||
    function(callback) {
      window.setTimeout(callback, 1000 / config.fps);
    };
})();

let stats = new Stats();
stats.showPanel(0); // 0: fps, 1: ms, 2: mb, 3+: custom
document.body.appendChild(stats.dom);

let startTime = performance.now();

function draw(){
    let time = performance.now();

    stats.begin();

    gl.drawArrays(gl.TRIANGLES, 0, 6);
    gl.uniform1f(timeL, (time - startTime)/2000);

    stats.end();

    window.reqAnimationFrame(draw, 1000/ config.fps);
}

/**
function animate(newtime) {
    // request another frame
    window.reqAnimationFrame(animate);

    // elapsed time since last loop
    now = newtime;
    elapsed = now - then;

    // if enough time has elapsed, draw the next frame

    if (elapsed > fpsInterval) {

        // Get ready for next frame by setting then=now, but...
        // Also, adjust for fpsInterval not being multiple of 16.67
        then = now - (elapsed % fpsInterval);

        // draw stuff here


        // TESTING...Report #seconds since start and achieved fps.
        var sinceStart = now - startTime;
        var currentFps = Math.round(1000 / (sinceStart / ++frameCount) * 100) / 100;
        $results.text("Elapsed time= " + Math.round(sinceStart / 1000 * 100) / 100 + " secs @ " + currentFps + " fps.");

    }
}**/

window.addEventListener("load", draw, false);