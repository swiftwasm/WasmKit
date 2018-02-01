const fs = require("fs");
const { performance } = require('perf_hooks');

let iterations = 100.0;

let instantiationSum = 0.0;
let executionSum = 0.0;

function complete() {
    console.log('Instantiation avg', instantiationSum / iterations);
    console.log('Execution avg', executionSum / iterations);
    console.log(process.memoryUsage());
    
}

fs.readFile('test.wasm', (err, data) => {
    function test(i) {
        console.log(i);
        
        let startInstantiation;
        let endInstantiation;
        let endExecution;
        startInstantiation = performance.now()
        WebAssembly.instantiate(new Uint8Array(data), []).then(({ instance }) => {
            console.log(instance);
            endInstantiation = performance.now()
            console.log(instance.exports.f())
            endExecution = performance.now()
            
            console.log('Instantiation', endInstantiation - startInstantiation)
            instantiationSum += (endInstantiation - startInstantiation)
            console.log('Execution', endExecution - endInstantiation)
            executionSum += (endExecution - endInstantiation)
            if (i < iterations) {
                test(i + 1);
            } else {
                complete();
            }
        });
    }
    
    test(0);
})