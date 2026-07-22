# 3D Visualization Source Code Reference

> [!NOTE]
> Markdown and GitHub do not natively support executing 3D WebGL (JavaScript/Three.js) code directly within a `.md` file for security reasons. 

To experience the interactive 3D visualization, you can copy the code below and save it as an `.html` file (e.g., `3d_visualization.html`) on your computer, then open it in any modern web browser.

---

Below is the complete HTML, CSS, and Three.js source code used to generate the interactive 3D model of the **Precision-Scalable Sparse Attention Accelerator**. It demonstrates the unified FSM logic, showing dynamic precision switching and sparsity power-gating across the 8-lane Fracturable MAC Array.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Precision-Scalable Sparse Attention Accelerator - 3D Visualization</title>
    <style>
        body { margin: 0; overflow: hidden; background-color: #121212; font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; }
        #canvas-container { width: 100vw; height: 100vh; }
        #ui {
            position: absolute;
            top: 20px;
            left: 20px;
            color: white;
            background: rgba(0, 0, 0, 0.85);
            padding: 25px;
            border-radius: 12px;
            border: 1px solid #444;
            max-width: 380px;
            box-shadow: 0 8px 15px rgba(0,0,0,0.5);
            backdrop-filter: blur(5px);
        }
        h1 { margin-top: 0; font-size: 22px; color: #00e5ff; letter-spacing: 0.5px; }
        p { font-size: 14px; line-height: 1.6; color: #ddd; }
        .legend { margin-top: 20px; background: rgba(255,255,255,0.05); padding: 15px; border-radius: 8px; }
        .legend-item { display: flex; align-items: center; margin-bottom: 8px; font-size: 13px; font-weight: 500; }
        .color-box { width: 16px; height: 16px; margin-right: 12px; border-radius: 4px; border: 1px solid rgba(255,255,255,0.2); }
        .btn {
            margin-top: 15px;
            background: #00e5ff;
            color: #000;
            border: none;
            padding: 12px 15px;
            border-radius: 6px;
            cursor: pointer;
            font-weight: bold;
            width: 100%;
            transition: all 0.2s ease;
            text-transform: uppercase;
            letter-spacing: 1px;
            font-size: 12px;
        }
        .btn:hover { background: #00b8cc; transform: translateY(-1px); box-shadow: 0 4px 8px rgba(0, 229, 255, 0.3); }
        .btn-fp16 { background: #ff4081; color: white; }
        .btn-fp16:hover { background: #c60055; box-shadow: 0 4px 8px rgba(255, 64, 129, 0.3); }
        .btn-int8 { background: #ffd54f; color: black; }
        .btn-int8:hover { background: #c8a415; box-shadow: 0 4px 8px rgba(255, 213, 79, 0.3); }
    </style>
    <!-- Load Three.js from CDN -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/three.js/r128/three.min.js"></script>
</head>
<body>
    <div id="ui">
        <h1>Unified FSM Datapath</h1>
        <p>This interactive visualization demonstrates the <strong>8-Lane Fracturable MAC Array</strong> reacting dynamically to the <strong>Sparsity Predictor</strong> and <strong>Precision Target</strong>.</p>
        
        <div class="legend">
            <div class="legend-item"><div class="color-box" style="background: #222;"></div> Lane Power-Gated (Zero / Sparse)</div>
            <div class="legend-item"><div class="color-box" style="background: #00e5ff;"></div> Computing INT4 (Low Power)</div>
            <div class="legend-item"><div class="color-box" style="background: #ffd54f;"></div> Computing INT8 (Medium Power)</div>
            <div class="legend-item"><div class="color-box" style="background: #ff4081;"></div> Computing FP16 (High Power)</div>
        </div>

        <button class="btn" onclick="triggerMode('INT4', 0.75)">Simulate Sparse INT4 (75% Zeros)</button>
        <button class="btn btn-int8" onclick="triggerMode('INT8', 0.40)">Simulate Mixed INT8 (40% Zeros)</button>
        <button class="btn btn-fp16" onclick="triggerMode('FP16', 0.0)">Simulate Dense FP16 (0% Zeros)</button>
    </div>
    
    <div id="canvas-container"></div>

    <script>
        // 1. Scene Setup
        const scene = new THREE.Scene();
        scene.fog = new THREE.FogExp2(0x121212, 0.04);
        const camera = new THREE.PerspectiveCamera(50, window.innerWidth / window.innerHeight, 0.1, 1000);
        const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
        renderer.setSize(window.innerWidth, window.innerHeight);
        renderer.setClearColor(0x121212, 1);
        document.getElementById('canvas-container').appendChild(renderer.domElement);

        // 2. Lighting
        const ambientLight = new THREE.AmbientLight(0xffffff, 0.6);
        scene.add(ambientLight);
        const directionalLight = new THREE.DirectionalLight(0xffffff, 0.8);
        directionalLight.position.set(5, 15, 5);
        scene.add(directionalLight);

        // 3. Materials representing Precisions
        const idleMat = new THREE.MeshPhysicalMaterial({ color: 0x222222, metalness: 0.8, roughness: 0.2 });
        const int4Mat = new THREE.MeshPhysicalMaterial({ color: 0x00e5ff, emissive: 0x007b8a, emissiveIntensity: 0.5, metalness: 0.3, roughness: 0.1 });
        const int8Mat = new THREE.MeshPhysicalMaterial({ color: 0xffd54f, emissive: 0x8a7000, emissiveIntensity: 0.5, metalness: 0.3, roughness: 0.1 });
        const fp16Mat = new THREE.MeshPhysicalMaterial({ color: 0xff4081, emissive: 0x8a0035, emissiveIntensity: 0.6, metalness: 0.3, roughness: 0.1 });

        const materials = {
            'INT4': int4Mat,
            'INT8': int8Mat,
            'FP16': fp16Mat
        };

        // 4. Create the 8-Lane MAC Array
        const numLanes = 8;
        const spacing = 1.8;
        const offset = (numLanes * spacing) / 2 - (spacing / 2);
        
        const lanes = [];
        const geometry = new THREE.BoxGeometry(1.2, 1.2, 1.2);

        for (let i = 0; i < numLanes; i++) {
            const lane = new THREE.Mesh(geometry, idleMat);
            lane.position.set(i * spacing - offset, 0, 0);
            
            // Wireframe for tech look
            const edges = new THREE.EdgesGeometry(geometry);
            const line = new THREE.LineSegments(edges, new THREE.LineBasicMaterial({ color: 0x444444 }));
            lane.add(line);
            
            scene.add(lane);
            lanes.push({ mesh: lane, isActive: false, timer: 0 });
        }

        // Decorator: Floating rings representing data flow pipelines
        const ringGeo = new THREE.TorusGeometry(0.8, 0.05, 16, 32);
        const ringMat = new THREE.MeshBasicMaterial({ color: 0x444444, transparent: true, opacity: 0.5 });
        for(let i = 0; i < numLanes; i++) {
            let ring = new THREE.Mesh(ringGeo, ringMat);
            ring.rotation.x = Math.PI / 2;
            ring.position.set(i * spacing - offset, 1.5, 0);
            scene.add(ring);
        }

        // Grid Plane
        const gridHelper = new THREE.GridHelper(30, 30, 0x333333, 0x222222);
        gridHelper.position.y = -1.5;
        scene.add(gridHelper);

        // 5. Camera Positioning
        camera.position.set(0, 8, 14);
        camera.lookAt(0, 0, 0);

        // 6. Animation Logic
        let clock = new THREE.Clock();
        let currentMode = 'INT4';
        let currentSparsity = 0.75;
        let activePulses = []; 

        function triggerMode(precision, sparsity) {
            currentMode = precision;
            currentSparsity = sparsity;
            
            // Visual feedback: flash background slightly
            scene.fog.color.setHex(0x1a1a1a);
            setTimeout(() => scene.fog.color.setHex(0x121212), 200);

            // Send a wave of data based on mode
            for(let j=0; j<numLanes; j++) {
                if(Math.random() > currentSparsity) {
                    createDataPulse(j, true);
                } else {
                    createDataPulse(j, false);
                }
            }
        }

        function createDataPulse(laneIndex, isValid) {
            const pulseGeo = new THREE.SphereGeometry(0.25, 16, 16);
            const matColor = isValid ? (currentMode === 'FP16' ? 0xff4081 : (currentMode === 'INT8' ? 0xffd54f : 0x00e5ff)) : 0x444444;
            const pulseMat = new THREE.MeshBasicMaterial({ color: matColor });
            const pulse = new THREE.Mesh(pulseGeo, pulseMat);
            
            // Start pulse high above
            pulse.position.set(laneIndex * spacing - offset, 6, 0);
            scene.add(pulse);
            
            activePulses.push({
                mesh: pulse,
                lane: laneIndex,
                valid: isValid,
                progress: 6,
                targetPrecision: currentMode
            });
        }

        // 7. Render Loop
        function animate() {
            requestAnimationFrame(animate);
            const delta = clock.getDelta();
            const time = clock.getElapsedTime();

            // Camera hover effect
            camera.position.x = Math.sin(time * 0.2) * 4;
            camera.position.y = 8 + Math.cos(time * 0.3) * 1;
            camera.lookAt(0, 0, 0);

            // Animate pulses flowing downwards
            for (let i = activePulses.length - 1; i >= 0; i--) {
                let p = activePulses[i];
                p.progress -= delta * 8; // Drop speed
                p.mesh.position.y = p.progress;
                
                // When pulse hits the MAC lane
                if (p.progress <= 0) {
                    if (p.valid) {
                        lanes[p.lane].mesh.material = materials[p.targetPrecision];
                        lanes[p.lane].timer = 0.8; // Keeps lit for 0.8 seconds
                        
                        // Impact animation (scale up)
                        lanes[p.lane].mesh.scale.set(1.3, 1.3, 1.3);
                    } else {
                        // Power Gated - no reaction
                        lanes[p.lane].mesh.material = idleMat;
                    }
                    scene.remove(p.mesh);
                    activePulses.splice(i, 1);
                }
            }

            // Animate MAC lane state decay
            for (let i = 0; i < numLanes; i++) {
                let lane = lanes[i];
                // Idle floating animation
                lane.mesh.rotation.y = Math.sin(time + i) * 0.1;

                if (lane.timer > 0) {
                    lane.timer -= delta;
                    // Interpolate scale back to normal
                    lane.mesh.scale.lerp(new THREE.Vector3(1, 1, 1), 0.15);
                    if (lane.timer <= 0) {
                        lane.mesh.material = idleMat;
                    }
                }
            }

            renderer.render(scene, camera);
        }

        // Handle resize
        window.addEventListener('resize', () => {
            camera.aspect = window.innerWidth / window.innerHeight;
            camera.updateProjectionMatrix();
            renderer.setSize(window.innerWidth, window.innerHeight);
        });

        // Start animation
        animate();
        
        // Auto-inject data every 1.5 seconds to keep simulation alive
        setInterval(() => {
            triggerMode(currentMode, currentSparsity);
        }, 1500);

    </script>
</body>
</html>
```
