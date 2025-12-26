import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import qs.modules.common
import qs.modules.common.widgets
import qs.services

// Visualizer
Canvas {
    id: root

    property list<var> points
    property list<var> smoothPoints
    property real maxVisualizerValue: 1000
    property int smoothing: 2
    property bool live: true
    property color color: Colors.m3.m3primary
    property string visualizerType: "filled" // "filled", "bars", "thickbars", "circular", "waveform", "particles", "gradient", "fluid", "neural", "ripple", "plasma", "crystal", "wave3d", "atom"
    // Additional properties for specific visualizer types
    property real barSpacing: 2
    property real thickBarSpacing: 4
    property real thickBarCornerRadius: 6
    property real innerRadius: Math.min(width, height) * 0.2
    property real outerRadius: Math.min(width, height) * 0.4
    property real dotSize: 4
    property real lineWidth: 3
    property real animationTime: 0
    property real fluidIntensity: 0.8
    property real crystalSegments: 6
    property real waveSpeed: 2

    function drawFilledVisualizer(ctx, w, h, n, maxVal) {
        ctx.beginPath();
        ctx.moveTo(0, h);
        for (var i = 0; i < n; ++i) {
            var x = i * w / (n - 1);
            var y = h - (root.smoothPoints[i] / maxVal) * h;
            ctx.lineTo(x, y);
        }
        ctx.lineTo(w, h);
        ctx.closePath();
        ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.15);
        ctx.fill();
    }

    function drawBarVisualizer(ctx, w, h, n, maxVal) {
        var barWidth = (w - (n - 1) * barSpacing) / n;
        ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.8);
        for (var i = 0; i < n; ++i) {
            var x = i * (barWidth + barSpacing);
            var barHeight = (root.smoothPoints[i] / maxVal) * h;
            var y = h - barHeight;
            ctx.fillRect(x, y, barWidth, barHeight);
        }
    }

    function drawThickBarVisualizer(ctx, w, h, n, maxVal) {
        var barWidth = (w - (n - 1) * thickBarSpacing) / n;
        var cornerRadius = Math.min(thickBarCornerRadius, barWidth / 2);
        ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.85);
        for (var i = 0; i < n; ++i) {
            var x = i * (barWidth + thickBarSpacing);
            var barHeight = Math.max(cornerRadius * 2, (root.smoothPoints[i] / maxVal) * h);
            var y = h - barHeight;
            // Draw rounded rectangle (bar with rounded top corners)
            ctx.beginPath();
            // Start from bottom left
            ctx.moveTo(x, h);
            // Left side
            ctx.lineTo(x, y + cornerRadius);
            // Top left rounded corner
            ctx.quadraticCurveTo(x, y, x + cornerRadius, y);
            // Top side
            ctx.lineTo(x + barWidth - cornerRadius, y);
            // Top right rounded corner
            ctx.quadraticCurveTo(x + barWidth, y, x + barWidth, y + cornerRadius);
            // Right side
            ctx.lineTo(x + barWidth, h);
            // Bottom side
            ctx.lineTo(x, h);
            ctx.closePath();
            ctx.fill();
            // Add subtle gradient for depth
            var gradient = ctx.createLinearGradient(x, y, x + barWidth, y);
            gradient.addColorStop(0, Qt.rgba(root.color.r, root.color.g, root.color.b, 0.9));
            gradient.addColorStop(0.5, Qt.rgba(root.color.r, root.color.g, root.color.b, 1));
            gradient.addColorStop(1, Qt.rgba(root.color.r, root.color.g, root.color.b, 0.9));
            ctx.fillStyle = gradient;
            ctx.fill();
        }
    }

    function drawCircularVisualizer(ctx, w, h, n, maxVal) {
        var centerX = w / 2;
        var centerY = h / 2;
        ctx.beginPath();
        for (var i = 0; i < n; ++i) {
            var angle = (i / n) * 2 * Math.PI;
            var amplitude = (root.smoothPoints[i] / maxVal) * (outerRadius - innerRadius);
            var radius = innerRadius + amplitude;
            var x = centerX + radius * Math.cos(angle);
            var y = centerY + radius * Math.sin(angle);
            if (i === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        }
        ctx.closePath();
        ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.3);
        ctx.fill();
        ctx.strokeStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.8);
        ctx.lineWidth = 2;
        ctx.stroke();
    }

    function drawFluidVisualizer(ctx, w, h, n, maxVal) {
        // Organic fluid-like shapes that morph with music
        var centerY = h / 2;
        var amplitude = 0;
        ctx.beginPath();
        for (var i = 0; i < n; ++i) {
            var x = i * w / (n - 1);
            var baseY = centerY;
            var audioInfluence = (root.smoothPoints[i] / maxVal) * h * 0.3;
            // Create organic flowing motion
            var waveOffset = Math.sin(animationTime * 2 + i * 0.1) * 20;
            var fluidOffset = Math.sin(animationTime * 3 + i * 0.05) * 15;
            var y1 = baseY - audioInfluence - waveOffset;
            var y2 = baseY + audioInfluence + fluidOffset;
            if (i === 0) {
                ctx.moveTo(x, y1);
            } else {
                // Smooth curves instead of straight lines
                var prevX = (i - 1) * w / (n - 1);
                var cpX = (prevX + x) / 2;
                ctx.quadraticCurveTo(cpX, y1, x, y1);
            }
        }
        // Complete the fluid shape
        for (var i = n - 1; i >= 0; --i) {
            var x = i * w / (n - 1);
            var baseY = centerY;
            var audioInfluence = (root.smoothPoints[i] / maxVal) * h * 0.3;
            var fluidOffset = Math.sin(animationTime * 3 + i * 0.05) * 15;
            var y2 = baseY + audioInfluence + fluidOffset;
            if (i === n - 1) {
                ctx.lineTo(x, y2);
            } else {
                var nextX = (i + 1) * w / (n - 1);
                var cpX = (nextX + x) / 2;
                ctx.quadraticCurveTo(cpX, y2, x, y2);
            }
        }
        ctx.closePath();
        // Gradient fill
        var gradient = ctx.createLinearGradient(0, 0, 0, h);
        gradient.addColorStop(0, Qt.rgba(root.color.r, root.color.g, root.color.b, 0.8));
        gradient.addColorStop(1, Qt.rgba(root.color.r, root.color.g, root.color.b, 0.1));
        ctx.fillStyle = gradient;
        ctx.fill();
    }

    function drawNeuralVisualizer(ctx, w, h, n, maxVal) {
        // Neural network-like connections between audio points
        var nodes = [];
        var nodeRadius = 3;
        // Create nodes based on audio data
        for (var i = 0; i < n; i += 3) {
            var x = i * w / (n - 1);
            var amplitude = root.smoothPoints[i] / maxVal;
            var y = h - amplitude * h;
            // Add some randomness influenced by audio
            var offsetX = Math.sin(animationTime + i * 0.1) * amplitude * 20;
            var offsetY = Math.cos(animationTime + i * 0.15) * amplitude * 15;
            nodes.push({
                "x": x + offsetX,
                "y": y + offsetY,
                "amplitude": amplitude,
                "index": i
            });
        }
        // Draw connections
        ctx.strokeStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.3);
        ctx.lineWidth = 1;
        for (var i = 0; i < nodes.length; ++i) {
            for (var j = i + 1; j < nodes.length; ++j) {
                var node1 = nodes[i];
                var node2 = nodes[j];
                var distance = Math.sqrt(Math.pow(node1.x - node2.x, 2) + Math.pow(node1.y - node2.y, 2));
                // Only connect nearby nodes
                if (distance < 100) {
                    var connectionStrength = (node1.amplitude + node2.amplitude) / 2;
                    var alpha = connectionStrength * (1 - distance / 100);
                    ctx.beginPath();
                    ctx.moveTo(node1.x, node1.y);
                    ctx.lineTo(node2.x, node2.y);
                    ctx.strokeStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, alpha * 0.5);
                    ctx.stroke();
                }
            }
        }
        // Draw nodes
        for (var i = 0; i < nodes.length; ++i) {
            var node = nodes[i];
            var pulseSize = nodeRadius + node.amplitude * 5;
            ctx.beginPath();
            ctx.arc(node.x, node.y, pulseSize, 0, 2 * Math.PI);
            ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.8);
            ctx.fill();
            // Outer glow
            ctx.beginPath();
            ctx.arc(node.x, node.y, pulseSize * 1.5, 0, 2 * Math.PI);
            ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.2);
            ctx.fill();
        }
    }

    function drawRippleVisualizer(ctx, w, h, n, maxVal) {
        // Concentric ripples emanating from center
        var centerX = w / 2;
        var centerY = h / 2;
        var maxRadius = Math.min(w, h) / 2;
        // Calculate average amplitude for ripple intensity
        var avgAmplitude = 0;
        for (var i = 0; i < n; ++i) {
            avgAmplitude += root.smoothPoints[i];
        }
        avgAmplitude /= n;
        var normalizedAmplitude = avgAmplitude / maxVal;
        // Draw multiple ripples
        var rippleCount = 5;
        for (var r = 0; r < rippleCount; ++r) {
            var baseRadius = (r + 1) * maxRadius / rippleCount;
            var rippleRadius = baseRadius + Math.sin(animationTime * 4 - r * 0.5) * normalizedAmplitude * 30;
            // Audio-reactive ripple distortion
            ctx.beginPath();
            var segments = 64;
            for (var i = 0; i <= segments; ++i) {
                var angle = (i / segments) * 2 * Math.PI;
                var audioIndex = Math.floor((i / segments) * n);
                var audioInfluence = (root.smoothPoints[audioIndex] / maxVal) * 20;
                var radius = rippleRadius + audioInfluence;
                var x = centerX + radius * Math.cos(angle);
                var y = centerY + radius * Math.sin(angle);
                if (i === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.closePath();
            var alpha = (1 - r / rippleCount) * normalizedAmplitude * 0.7;
            ctx.strokeStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, alpha);
            ctx.lineWidth = 2;
            ctx.stroke();
        }
    }

    function drawatomVisualizer(ctx, w, h, n, maxVal) {
        // atom-style animated orb with flowing energy
        var centerX = w / 2;
        var centerY = h / 2;
        var baseRadius = Math.min(w, h) * 0.15;
        // Calculate average amplitude for overall energy
        var avgAmplitude = 0;
        for (var i = 0; i < n; ++i) {
            avgAmplitude += root.smoothPoints[i];
        }
        avgAmplitude /= n;
        var energy = avgAmplitude / maxVal;
        // Main orb with audio-reactive size
        var mainRadius = baseRadius + energy * 30;
        // Create multiple energy rings
        var ringCount = 4;
        for (var ring = 0; ring < ringCount; ++ring) {
            var ringRadius = mainRadius + ring * 20;
            var ringAlpha = (1 - ring / ringCount) * energy * 0.6;
            // Create flowing, organic ring shape
            ctx.beginPath();
            var segments = 32;
            for (var i = 0; i <= segments; ++i) {
                var angle = (i / segments) * 2 * Math.PI;
                // Multiple wave layers for organic movement
                var wave1 = Math.sin(angle * 3 + animationTime * 2) * 8;
                var wave2 = Math.sin(angle * 5 + animationTime * -1.5) * 5;
                var wave3 = Math.sin(angle * 7 + animationTime * 3) * 3;
                // Audio influence on each segment
                var audioIndex = Math.floor((i / segments) * n);
                var audioInfluence = (root.smoothPoints[audioIndex] / maxVal) * 15;
                var radius = ringRadius + wave1 + wave2 + wave3 + audioInfluence;
                var x = centerX + radius * Math.cos(angle);
                var y = centerY + radius * Math.sin(angle);
                if (i === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.closePath();
            // Gradient fill for depth
            var gradient = ctx.createRadialGradient(centerX, centerY, 0, centerX, centerY, ringRadius * 2);
            gradient.addColorStop(0, Qt.rgba(root.color.r, root.color.g, root.color.b, ringAlpha));
            gradient.addColorStop(1, Qt.rgba(root.color.r, root.color.g, root.color.b, 0));
            ctx.fillStyle = gradient;
            ctx.fill();
        }
        // Inner core with pulsing effect
        var coreRadius = baseRadius * 0.6 + energy * 20;
        var coreGradient = ctx.createRadialGradient(centerX, centerY, 0, centerX, centerY, coreRadius);
        coreGradient.addColorStop(0, Qt.rgba(root.color.r, root.color.g, root.color.b, 0.9));
        coreGradient.addColorStop(0.7, Qt.rgba(root.color.r, root.color.g, root.color.b, 0.4));
        coreGradient.addColorStop(1, Qt.rgba(root.color.r, root.color.g, root.color.b, 0));
        ctx.beginPath();
        ctx.arc(centerX, centerY, coreRadius, 0, 2 * Math.PI);
        ctx.fillStyle = coreGradient;
        ctx.fill();
        // Energy particles around the orb
        var particleCount = 12;
        for (var p = 0; p < particleCount; ++p) {
            var particleAngle = (p / particleCount) * 2 * Math.PI + animationTime * 0.5;
            var particleDistance = mainRadius * 1.5 + Math.sin(animationTime * 3 + p) * 20;
            var particleX = centerX + particleDistance * Math.cos(particleAngle);
            var particleY = centerY + particleDistance * Math.sin(particleAngle);
            // Particle size based on audio
            var audioIndex = Math.floor((p / particleCount) * n);
            var particleSize = 2 + (root.smoothPoints[audioIndex] / maxVal) * 6;
            var particleAlpha = energy * 0.8;
            // Particle with glow
            ctx.beginPath();
            ctx.arc(particleX, particleY, particleSize, 0, 2 * Math.PI);
            ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, particleAlpha);
            ctx.fill();
            // Particle glow
            ctx.beginPath();
            ctx.arc(particleX, particleY, particleSize * 2, 0, 2 * Math.PI);
            ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, particleAlpha * 0.3);
            ctx.fill();
        }
        // Connecting energy streams between particles
        ctx.strokeStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, energy * 0.3);
        ctx.lineWidth = 1;
        for (var p = 0; p < particleCount; ++p) {
            var angle1 = (p / particleCount) * 2 * Math.PI + animationTime * 0.5;
            var angle2 = ((p + 1) / particleCount) * 2 * Math.PI + animationTime * 0.5;
            var distance1 = mainRadius * 1.5 + Math.sin(animationTime * 3 + p) * 20;
            var distance2 = mainRadius * 1.5 + Math.sin(animationTime * 3 + p + 1) * 20;
            var x1 = centerX + distance1 * Math.cos(angle1);
            var y1 = centerY + distance1 * Math.sin(angle1);
            var x2 = centerX + distance2 * Math.cos(angle2);
            var y2 = centerY + distance2 * Math.sin(angle2);
            // Only draw connection if particles are close enough
            var connectionDistance = Math.sqrt(Math.pow(x2 - x1, 2) + Math.pow(y2 - y1, 2));
            if (connectionDistance < 100) {
                ctx.beginPath();
                ctx.moveTo(x1, y1);
                ctx.lineTo(x2, y2);
                ctx.stroke();
            }
        }
    }

    function drawPlasmaVisualizer(ctx, w, h, n, maxVal) {
        // Plasma-like effect with flowing colors
        var imageData = ctx.createImageData(w, h);
        var data = imageData.data;
        for (var x = 0; x < w; x += 2) {
            for (var y = 0; y < h; y += 2) {
                var audioIndex = Math.floor((x / w) * n);
                var audioAmplitude = root.smoothPoints[audioIndex] / maxVal;
                // Plasma calculation
                var value = Math.sin(x * 0.02 + animationTime * 2) + Math.sin(y * 0.02 + animationTime * 1.5) + Math.sin((x + y) * 0.02 + animationTime * 3) + Math.sin(Math.sqrt(x * x + y * y) * 0.02 + animationTime * 2.5);
                value = (value + 4) / 8; // Normalize to 0-1
                value *= audioAmplitude * 2; // Audio influence
                var intensity = Math.max(0, Math.min(1, value));
                var pixelIndex = (y * w + x) * 4;
                if (pixelIndex < data.length) {
                    data[pixelIndex] = root.color.r * 255 * intensity; // Red
                    data[pixelIndex + 1] = root.color.g * 255 * intensity; // Green
                    data[pixelIndex + 2] = root.color.b * 255 * intensity; // Blue
                    data[pixelIndex + 3] = 255 * intensity * 0.8; // Alpha
                }
            }
        }
        ctx.putImageData(imageData, 0, 0);
    }

    function drawCrystalVisualizer(ctx, w, h, n, maxVal) {
        // Crystal-like geometric patterns
        var centerX = w / 2;
        var centerY = h / 2;
        var segments = crystalSegments;
        for (var layer = 0; layer < 3; ++layer) {
            ctx.beginPath();
            for (var i = 0; i <= segments; ++i) {
                var angle = (i / segments) * 2 * Math.PI;
                var audioIndex = Math.floor((i / segments) * n);
                var audioAmplitude = root.smoothPoints[audioIndex] / maxVal;
                // Crystal facet calculation
                var baseRadius = (layer + 1) * 60;
                var radius = baseRadius + audioAmplitude * 80;
                // Add crystalline distortion
                var crystalWave = Math.sin(angle * 3 + animationTime * 2) * 10;
                radius += crystalWave;
                var x = centerX + radius * Math.cos(angle);
                var y = centerY + radius * Math.sin(angle);
                if (i === 0)
                    ctx.moveTo(x, y);
                else
                    ctx.lineTo(x, y);
            }
            ctx.closePath();
            // Gradient fill for crystal effect
            var gradient = ctx.createRadialGradient(centerX, centerY, 0, centerX, centerY, 200);
            gradient.addColorStop(0, Qt.rgba(root.color.r, root.color.g, root.color.b, 0.8 - layer * 0.2));
            gradient.addColorStop(1, Qt.rgba(root.color.r, root.color.g, root.color.b, 0.1));
            ctx.fillStyle = gradient;
            ctx.fill();
            ctx.strokeStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.6 - layer * 0.15);
            ctx.lineWidth = 2;
            ctx.stroke();
        }
    }

    function drawWave3DVisualizer(ctx, w, h, n, maxVal) {
        // Pseudo-3D wave effect with perspective
        var waves = 5;
        var waveHeight = h / waves;
        for (var wave = 0; wave < waves; ++wave) {
            var baseY = wave * waveHeight + waveHeight / 2;
            var perspective = (wave + 1) / waves; // Front waves are larger
            var waveOffset = animationTime * waveSpeed + wave * 0.5;
            ctx.beginPath();
            ctx.moveTo(0, baseY);
            for (var i = 0; i < n; ++i) {
                var x = i * w / (n - 1);
                var audioInfluence = (root.smoothPoints[i] / maxVal) * waveHeight * 0.4 * perspective;
                // 3D wave motion
                var waveMotion = Math.sin(x * 0.01 + waveOffset) * 20 * perspective;
                var y = baseY - audioInfluence + waveMotion;
                // Smooth curves for 3D effect
                if (i === 0) {
                    ctx.moveTo(x, y);
                } else {
                    var prevX = (i - 1) * w / (n - 1);
                    var cpX = (prevX + x) / 2;
                    ctx.quadraticCurveTo(cpX, y, x, y);
                }
            }
            // Create depth with alpha and stroke width
            var alpha = perspective * 0.8;
            var strokeWidth = perspective * 3;
            ctx.strokeStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, alpha);
            ctx.lineWidth = strokeWidth;
            ctx.lineCap = "round";
            ctx.stroke();
        }
    }

    function drawWaveformVisualizer(ctx, w, h, n, maxVal) {
        var centerY = h / 2;
        // Main waveform (top)
        ctx.beginPath();
        ctx.moveTo(0, centerY);
        for (var i = 0; i < n; ++i) {
            var x = i * w / (n - 1);
            var amplitude = (root.smoothPoints[i] / maxVal) * (centerY * 0.8);
            var y = centerY - amplitude;
            ctx.lineTo(x, y);
        }
        ctx.lineTo(w, centerY);
        ctx.closePath();
        ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.6);
        ctx.fill();
        // Reflection (bottom)
        ctx.beginPath();
        ctx.moveTo(0, centerY);
        for (var i = 0; i < n; ++i) {
            var x = i * w / (n - 1);
            var amplitude = (root.smoothPoints[i] / maxVal) * (centerY * 0.8);
            var y = centerY + amplitude;
            ctx.lineTo(x, y);
        }
        ctx.lineTo(w, centerY);
        ctx.closePath();
        ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.2);
        ctx.fill();
    }

    function drawParticleVisualizer(ctx, w, h, n, maxVal) {
        for (var i = 0; i < n; ++i) {
            var x = i * w / (n - 1);
            var amplitude = root.smoothPoints[i] / maxVal;
            var dotCount = Math.floor(amplitude * 20); // Max 20 dots per column
            for (var j = 0; j < dotCount; ++j) {
                var y = h - (j / 20) * h;
                var alpha = 1 - (j / dotCount) * 0.5; // Fade out towards top
                ctx.beginPath();
                ctx.arc(x, y, dotSize, 0, 2 * Math.PI);
                ctx.fillStyle = Qt.rgba(root.color.r, root.color.g, root.color.b, alpha * 0.8);
                ctx.fill();
            }
        }
    }

    function drawGradientVisualizer(ctx, w, h, n, maxVal) {
        // Create gradient
        var gradient = ctx.createLinearGradient(0, 0, w, 0);
        gradient.addColorStop(0, Qt.rgba(root.color.r, root.color.g, root.color.b, 0.3));
        gradient.addColorStop(0.5, Qt.rgba(root.color.r, root.color.g, root.color.b, 1));
        gradient.addColorStop(1, Qt.rgba(root.color.r, root.color.g, root.color.b, 0.3));
        ctx.beginPath();
        for (var i = 0; i < n; ++i) {
            var x = i * w / (n - 1);
            var y = h - (root.smoothPoints[i] / maxVal) * h;
            if (i === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        }
        ctx.strokeStyle = gradient;
        ctx.lineWidth = lineWidth;
        ctx.lineCap = "round";
        ctx.lineJoin = "round";
        ctx.stroke();
    }

    onPointsChanged: () => {
        root.requestPaint();
    }
    anchors.fill: parent
    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        var points = root.points;
        var maxVal = root.maxVisualizerValue || 1;
        var h = height;
        var w = width;
        var n = points.length;
        if (n < 2)
            return ;

        // Smoothing: simple moving average
        var smoothWindow = root.smoothing;
        root.smoothPoints = [];
        for (var i = 0; i < n; ++i) {
            var sum = 0, count = 0;
            for (var j = -smoothWindow; j <= smoothWindow; ++j) {
                var idx = Math.max(0, Math.min(n - 1, i + j));
                sum += points[idx];
                count++;
            }
            root.smoothPoints.push(sum / count);
        }
        if (!root.live)
            root.smoothPoints.fill(0);

        // Switch between visualizer types
        switch (root.visualizerType) {
        case "filled":
            drawFilledVisualizer(ctx, w, h, n, maxVal);
            break;
        case "bars":
            drawBarVisualizer(ctx, w, h, n, maxVal);
            break;
        case "thickbars":
            drawThickBarVisualizer(ctx, w, h, n, maxVal);
            break;
        case "circular":
            drawCircularVisualizer(ctx, w, h, n, maxVal);
            break;
        case "waveform":
            drawWaveformVisualizer(ctx, w, h, n, maxVal);
            break;
        case "particles":
            drawParticleVisualizer(ctx, w, h, n, maxVal);
            break;
        case "gradient":
            drawGradientVisualizer(ctx, w, h, n, maxVal);
            break;
        case "fluid":
            drawFluidVisualizer(ctx, w, h, n, maxVal);
            break;
        case "neural":
            drawNeuralVisualizer(ctx, w, h, n, maxVal);
            break;
        case "ripple":
            drawRippleVisualizer(ctx, w, h, n, maxVal);
            break;
        case "plasma":
            drawPlasmaVisualizer(ctx, w, h, n, maxVal);
            break;
        case "crystal":
            drawCrystalVisualizer(ctx, w, h, n, maxVal);
            break;
        case "wave3d":
            drawWave3DVisualizer(ctx, w, h, n, maxVal);
            break;
        case "atom":
            drawatomVisualizer(ctx, w, h, n, maxVal);
            break;
        default:
            drawFilledVisualizer(ctx, w, h, n, maxVal);
        }
    }
    layer.enabled: true

    // Animation timer for modern effects
    Timer {
        id: animationTimer

        interval: 16
        running: root.live
        repeat: true
        onTriggered: {
            root.animationTime += 0.05;
            root.requestPaint();
        }
    }

    layer.effect: MultiEffect {
        // Blur a bit to obscure away the points
        source: root
        saturation: visualizerType === "bars" ? 0.3 : visualizerType === "thickbars" ? 0.4 : visualizerType === "circular" ? 0.4 : visualizerType === "waveform" ? 0.3 : visualizerType === "particles" ? 0.5 : visualizerType === "gradient" ? 0.6 : visualizerType === "fluid" ? 0.7 : visualizerType === "neural" ? 0.8 : visualizerType === "ripple" ? 0.5 : visualizerType === "plasma" ? 0.9 : visualizerType === "crystal" ? 0.6 : visualizerType === "wave3d" ? 0.4 : visualizerType === "atom" ? 0.8 : 0.2
        blurEnabled: true
        blurMax: visualizerType === "bars" ? 3 : visualizerType === "thickbars" ? 4 : visualizerType === "circular" ? 5 : visualizerType === "waveform" ? 4 : visualizerType === "particles" ? 2 : visualizerType === "gradient" ? 3 : visualizerType === "fluid" ? 6 : visualizerType === "neural" ? 4 : visualizerType === "ripple" ? 5 : visualizerType === "plasma" ? 8 : visualizerType === "crystal" ? 7 : visualizerType === "wave3d" ? 5 : visualizerType === "atom" ? 6 : 7
        blur: visualizerType === "bars" ? 0.5 : visualizerType === "thickbars" ? 0.6 : visualizerType === "circular" ? 0.8 : visualizerType === "waveform" ? 0.6 : visualizerType === "particles" ? 0.3 : visualizerType === "gradient" ? 0.4 : visualizerType === "fluid" ? 0.9 : visualizerType === "neural" ? 0.5 : visualizerType === "ripple" ? 0.7 : visualizerType === "plasma" ? 1 : visualizerType === "crystal" ? 0.8 : visualizerType === "wave3d" ? 0.6 : visualizerType === "atom" ? 0.9 : 1
    }

}
