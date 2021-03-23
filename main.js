var gl;
gl = initGL("canvas");
var program = createProgram("vts", "fts");
gl.useProgram(program);

var posL = gl.getAttribLocation(program, "position");
var posBuffer = gl.createBuffer();
gl.bindBuffer(gl.ARRAY_BUFFER, posBuffer);

var positions = [
    -1, -1, 
    +1, -1,
    -1, +1, 
    -1, +1, 
    +1, -1, 
    +1, +1
];

gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(positions), gl.STATIC_DRAW);

resize(gl.canvas, false, false, true);
document.getElementById("ui").style.width = window.innerWidth - window.innerHeight + "px";
clearColor();

gl.enableVertexAttribArray(posL);
gl.vertexAttribPointer(posL, 2, gl.FLOAT, false, 0, 0);

var resL = gl.getUniformLocation(program, "res");
gl.uniform2f(resL, 2.0/gl.drawingBufferWidth, 2.0/gl.drawingBufferHeight);
var timeL = gl.getUniformLocation(program, "time");
var fractalL = gl.getUniformLocation(program, "fractal");
var camZL = gl.getUniformLocation(program, "camZ");
var THICCL = gl.getUniformLocation(program, "THICC");

function updateFractal(){
    var fractalN = document.getElementById("fractals").value;
    var camZ, THICC;
    switch(+fractalN){
        case 1:
            camZ = -16.0;
            THICC = 0.03;
        break;
        case 0:
            camZ = -6.0;
            THICC = 0.001;
    }
    console.log(camZ);
    gl.uniform1i(fractalL, fractalN);
    gl.uniform1f(camZL, camZ);
    gl.uniform1f(THICCL, THICC);
}
updateFractal();

// Choose best requestAnimationFrame
window.reqAnimationFrame = (function(callback){
    return window.requestAnimationFrame || window.webkitRequestAnimationFrame || window.mozRequestAnimationFrame || window.oRequestAnimationFrame || window.msRequestAnimationFrame ||
    function(callback) {
      window.setTimeout(callback, 1000 / 60);
    };
})();
var startTime = (new Date()).getTime();
function draw(){
    var time = (new Date()).getTime();

    gl.drawArrays(gl.TRIANGLES, 0, 6);
    gl.uniform1f(timeL, (time - startTime)/2000);
    
    window.reqAnimationFrame(draw, 1000/60);
}
window.addEventListener("load", draw, false);