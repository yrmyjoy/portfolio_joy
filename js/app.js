async function loadShader(url) {
    const response = await fetch(url);
    return await response.text();
}

// 텍스처 이미지
function loadTexture(url) {
    return new Promise((resolve) => {
        new THREE.TextureLoader().load(url, (texture) => {
            resolve(texture);
        });
    });
}

async function init() {
    const vertexShaderCode = await loadShader('./shaders/vertex.glsl');
    const fragmentShaderCode = await loadShader('./shaders/fragment.glsl');
    
    // 배경 이미지
    const texture = await loadTexture('./images/header_bg.png'); 

    const scene = new THREE.Scene();
    const camera = new THREE.OrthographicCamera(-1, 1, 1, -1, 0.1, 10);
    camera.position.z = 1;

    const renderer = new THREE.WebGLRenderer({ antialias: true, alpha: true });
    renderer.setSize(window.innerWidth, window.innerHeight);
    renderer.setPixelRatio(Math.min(window.devicePixelRatio, 2));
    document.querySelector('.main').appendChild(renderer.domElement);

    // 마우스 잔상 배열 (10개)
    const trailLength = 20;
    const trail = [];
    for (let i = 0; i < trailLength; i++) {
        trail.push(new THREE.Vector2(-10.0, -10.0));
    }
    const currentMouse = new THREE.Vector2(-10.0, -10.0);

    const uniforms = {
        // 기본 데이터
        u_texture: { value: texture },
        u_resolution: { value: new THREE.Vector2(window.innerWidth, window.innerHeight) },
        u_imageResolution: { value: new THREE.Vector2(texture.image.width, texture.image.height) },
        u_time: { value: 0 },
        u_trail: { value: trail },

        // Fluid 굴절 수치 (캡처 이미지 기반)
        uSpeed: { value: 0.05 },
        uAngle: { value: 1.2 },
        uFoldFrequency: { value: 0.8 },
        uWarpAmount: { value: 4.0 },
        uNoiseScale: { value: 0.2 },
        uConnections: { value: 0.4 },
        uDepth: { value: 0.14 },
        uLightPos: { value: new THREE.Vector3(0.7, 0.2, 1.0) }
    };

    const material = new THREE.ShaderMaterial({
        vertexShader: vertexShaderCode,
        fragmentShader: fragmentShaderCode,
        uniforms: uniforms
    });

    const geometry = new THREE.PlaneGeometry(2, 2);
    const mesh = new THREE.Mesh(geometry, material);
    scene.add(mesh);

    const clock = new THREE.Clock();

    function animate() {
        requestAnimationFrame(animate);
        uniforms.u_time.value = clock.getElapsedTime();

        for (let i = trailLength - 1; i > 0; i--) {
            trail[i].copy(trail[i - 1]);
        }
        trail[0].copy(currentMouse);

        renderer.render(scene, camera);
    }
    animate();

    window.addEventListener('mousemove', (event) => {
        currentMouse.x = event.clientX / window.innerWidth;
        currentMouse.y = 1.0 - (event.clientY / window.innerHeight);
    });

    document.addEventListener('mouseleave', () => {
        // 마우스 현재 위치 아웃
        currentMouse.set(-10.0, -10.0);
        for (let i = 0; i < trailLength; i++) {
            trail[i].set(-10.0, -10.0);
        }
    });

    window.addEventListener('resize', () => {
        renderer.setSize(window.innerWidth, window.innerHeight);
        uniforms.u_resolution.value.set(window.innerWidth, window.innerHeight);
    });
}

init();