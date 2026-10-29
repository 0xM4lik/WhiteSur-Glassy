#!/usr/bin/env python3
"""
Generates an interactive animated SVG and high-resolution PNG preview of the terminal
comparing WhiteSur-Glassy-Transparent (100% clear) and WhiteSur-Glassy-Tinted (75% dark frosted glass).
"""

import math
from PIL import Image, ImageDraw, ImageFilter, ImageFont

SVG_CONTENT = """<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1080 680" width="100%" height="100%">
  <defs>
    <!-- Background Gradient for Desktop Wallpaper -->
    <linearGradient id="wall-grad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#141E30" />
      <stop offset="35%" stop-color="#243B55" />
      <stop offset="70%" stop-color="#2B1055" />
      <stop offset="100%" stop-color="#7597DE" />
    </linearGradient>

    <!-- Ambient Wallpaper Glow Blobs -->
    <radialGradient id="glow-1" cx="20%" cy="30%" r="50%">
      <stop offset="0%" stop-color="#ff007f" stop-opacity="0.3" />
      <stop offset="100%" stop-color="#ff007f" stop-opacity="0" />
    </radialGradient>
    <radialGradient id="glow-2" cx="80%" cy="70%" r="60%">
      <stop offset="0%" stop-color="#00f2fe" stop-opacity="0.35" />
      <stop offset="100%" stop-color="#4facfe" stop-opacity="0" />
    </radialGradient>
    <radialGradient id="glow-3" cx="50%" cy="50%" r="40%">
      <stop offset="0%" stop-color="#9b51e0" stop-opacity="0.25" />
      <stop offset="100%" stop-color="#9b51e0" stop-opacity="0" />
    </radialGradient>

    <!-- Gaussian Blur Simulation for Wallpaper behind Glass -->
    <filter id="desk-blur" x="-20%" y="-20%" width="140%" height="140%">
      <feGaussianBlur stdDeviation="36" />
    </filter>

    <!-- Window Drop Shadow -->
    <filter id="window-shadow" x="-10%" y="-10%" width="130%" height="130%">
      <feDropShadow dx="0" dy="24" stdDeviation="32" flood-color="#000000" flood-opacity="0.55" />
    </filter>

    <!-- Handle Glow Shadow -->
    <filter id="handle-shadow" x="-50%" y="-50%" width="200%" height="200%">
      <feDropShadow dx="0" dy="2" stdDeviation="6" flood-color="#000000" flood-opacity="0.5" />
    </filter>

    <!-- Clipping path for the Tinted side (Animated width) -->
    <clipPath id="tint-clip">
      <rect id="tint-rect" x="50" y="50" width="490" height="580" rx="12" ry="12" />
    </clipPath>

    <!-- Clip path for the whole terminal window -->
    <clipPath id="window-clip">
      <rect x="50" y="50" width="980" height="580" rx="12" ry="12" />
    </clipPath>
  </defs>

  <style>
    @keyframes slideSplit {
      0%, 15% { width: 320px; }
      45%, 60% { width: 680px; }
      85%, 100% { width: 320px; }
    }
    @keyframes moveHandle {
      0%, 15% { transform: translateX(370px); }
      45%, 60% { transform: translateX(730px); }
      85%, 100% { transform: translateX(370px); }
    }
    #tint-rect {
      animation: slideSplit 10s cubic-bezier(0.45, 0.05, 0.55, 0.95) infinite;
    }
    #slider-group {
      animation: moveHandle 10s cubic-bezier(0.45, 0.05, 0.55, 0.95) infinite;
    }
    .mono {
      font-family: 'JetBrains Mono', 'Fira Code', 'Cascadia Code', 'Ubuntu Mono', 'SF Mono', Consolas, monospace;
    }
    .sans {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
    }
  </style>

  <!-- 1. Blurred Desktop Wallpaper -->
  <rect width="1080" height="680" fill="url(#wall-grad)" />
  <g filter="url(#desk-blur)">
    <circle cx="250" cy="220" r="300" fill="url(#glow-1)" />
    <circle cx="850" cy="480" r="350" fill="url(#glow-2)" />
    <circle cx="540" cy="340" r="280" fill="url(#glow-3)" />
  </g>

  <!-- 2. Terminal Window Container (With Shadow) -->
  <g filter="url(#window-shadow)">
    <!-- Base Transparent Window: 100% Clear (Background shines straight through) -->
    <rect x="50" y="50" width="980" height="580" rx="12" ry="12" fill="none" stroke="rgba(255, 255, 255, 0.18)" stroke-width="1.5" />

    <!-- Terminal Window Content under Window Clip -->
    <g clip-path="url(#window-clip)">
      <!-- Transparent Side Underlay -->
      <rect x="50" y="50" width="980" height="580" fill="rgba(0, 0, 0, 0.05)" />

      <!-- Tinted Side Overlay (Clipped by Animated tint-rect) -->
      <g clip-path="url(#tint-clip)">
        <rect x="50" y="50" width="980" height="580" fill="rgba(28, 28, 30, 0.78)" />
      </g>

      <!-- Terminal Headerbar / Titlebar -->
      <g id="headerbar">
        <rect x="50" y="50" width="980" height="42" fill="rgba(255, 255, 255, 0.03)" />
        <line x1="50" y1="92" x2="1030" y2="92" stroke="rgba(255, 255, 255, 0.08)" stroke-width="1" />

        <!-- macOS Traffic Light Window Buttons (Left side) -->
        <circle cx="74" cy="71" r="6" fill="#ff5f56" stroke="#e0443e" stroke-width="0.5" />
        <circle cx="94" cy="71" r="6" fill="#ffbd2e" stroke="#dea125" stroke-width="0.5" />
        <circle cx="114" cy="71" r="6" fill="#27c93f" stroke="#1aab29" stroke-width="0.5" />

        <!-- Titlebar Center Label -->
        <text class="sans" x="540" y="76" font-size="12" font-weight="500" fill="#dedede" text-anchor="middle" letter-spacing="0.3">
          malik@fedora: ~ (ptyxis)
        </text>
      </g>

      <!-- Mode Indicator Badges -->
      <g transform="translate(70, 110)">
        <rect x="0" y="0" width="200" height="26" rx="13" fill="rgba(0, 0, 0, 0.45)" stroke="rgba(255, 255, 255, 0.15)" stroke-width="1" />
        <circle cx="14" cy="13" r="4.5" fill="#30d158" />
        <text class="sans" x="26" y="17" font-size="11" font-weight="600" fill="#ffffff" letter-spacing="0.5">TRANSPARENT (100% CLEAR)</text>
      </g>
      <g transform="translate(810, 110)">
        <rect x="0" y="0" width="190" height="26" rx="13" fill="rgba(0, 0, 0, 0.55)" stroke="rgba(255, 255, 255, 0.15)" stroke-width="1" />
        <circle cx="14" cy="13" r="4.5" fill="#0a84ff" />
        <text class="sans" x="26" y="17" font-size="11" font-weight="600" fill="#ffffff" letter-spacing="0.5">TINTED (75% GLASS)</text>
      </g>

      <!-- Terminal Body Content (Monospace, Fastfetch Output) -->
      <g transform="translate(75, 160)" class="mono" font-size="13" xml:space="preserve">
        <!-- Shell Prompt 1 -->
        <text y="0" fill="#70a5fd">┌──(</text><text y="0" x="32" fill="#5af78e">malik㉿fedora</text><text y="0" x="140" fill="#70a5fd">)-[</text><text y="0" x="162" fill="#dedede">~</text><text y="0" x="170" fill="#70a5fd">]</text>
        <text y="20" fill="#70a5fd">└─$</text><text y="20" x="35" fill="#ffffff" font-weight="600">fastfetch</text>

        <!-- Fastfetch Fedora Logo (Left Column) -->
        <g fill="#51a2da" font-weight="bold">
          <text y="50">        ', - - '</text>
          <text y="70">       /  ___  \</text>
          <text y="90">      (?   /   ?)</text>
          <text y="110">        \  \__</text>
          <text y="130">         ' - - '</text>
          <text y="150">       /  ___  \</text>
          <text y="170">      (?   /   ?)</text>
          <text y="190">        \  \__</text>
          <text y="210">         ' - - '</text>
        </g>

        <!-- Fastfetch Info Key-Values (Right Column) -->
        <g transform="translate(190, 50)">
          <text y="0"><tspan fill="#5af78e" font-weight="bold">malik</tspan><tspan fill="#dedede">@</tspan><tspan fill="#5af78e" font-weight="bold">fedora</tspan></text>
          <text y="18" fill="rgba(255, 255, 255, 0.3)">---------------------------</text>
          <text y="36"><tspan fill="#70a5fd" font-weight="bold">OS: </tspan><tspan fill="#ffffff">Fedora Linux 41 (Workstation Edition)</tspan></text>
          <text y="54"><tspan fill="#70a5fd" font-weight="bold">Host: </tspan><tspan fill="#ffffff">Framework Laptop 13 (AMD Ryzen 7 7840U)</tspan></text>
          <text y="72"><tspan fill="#70a5fd" font-weight="bold">Kernel: </tspan><tspan fill="#ffffff">6.11.4-200.fc41.x86_64</tspan></text>
          <text y="90"><tspan fill="#70a5fd" font-weight="bold">Uptime: </tspan><tspan fill="#ffffff">4 hours, 28 mins</tspan></text>
          <text y="108"><tspan fill="#70a5fd" font-weight="bold">Desktop: </tspan><tspan fill="#ffffff">GNOME 47.1 (Wayland)</tspan></text>
          <text y="126"><tspan fill="#70a5fd" font-weight="bold">Theme: </tspan><tspan fill="#ff79c6" font-weight="bold">WhiteSur-Glassy </tspan><tspan fill="#9aedfe">[GTK 3/4 • Libadwaita]</tspan></text>
          <text y="144"><tspan fill="#70a5fd" font-weight="bold">Icons: </tspan><tspan fill="#ffffff">WhiteSur-dark [GTK]</tspan></text>
          <text y="162"><tspan fill="#70a5fd" font-weight="bold">Terminal: </tspan><tspan fill="#ffffff">Ptyxis 47.1 (Seamless Glass)</tspan></text>
          <text y="180"><tspan fill="#70a5fd" font-weight="bold">Blur Engine: </tspan><tspan fill="#5af78e">Blur my Shell + gnome-rounded-blur</tspan></text>
          <text y="198"><tspan fill="#70a5fd" font-weight="bold">Memory: </tspan><tspan fill="#ffffff">4.82 GiB / 31.20 GiB (15%)</tspan></text>

          <!-- 8 Color ANSI Palette Blocks -->
          <g transform="translate(0, 222)">
            <rect x="0" y="0" width="22" height="15" rx="3" fill="#282a36" />
            <rect x="28" y="0" width="22" height="15" rx="3" fill="#ff5555" />
            <rect x="56" y="0" width="22" height="15" rx="3" fill="#50fa7b" />
            <rect x="84" y="0" width="22" height="15" rx="3" fill="#f1fa8c" />
            <rect x="112" y="0" width="22" height="15" rx="3" fill="#bd93f9" />
            <rect x="140" y="0" width="22" height="15" rx="3" fill="#ff79c6" />
            <rect x="168" y="0" width="22" height="15" rx="3" fill="#8be9fd" />
            <rect x="196" y="0" width="22" height="15" rx="3" fill="#f8f8f2" />
          </g>
        </g>

        <!-- Prompt 2 with cursor -->
        <g transform="translate(0, 340)">
          <text y="0" fill="#70a5fd">┌──(</text><text y="0" x="32" fill="#5af78e">malik㉿fedora</text><text y="0" x="140" fill="#70a5fd">)-[</text><text y="0" x="162" fill="#dedede">~</text><text y="0" x="170" fill="#70a5fd">]</text>
          <text y="20" fill="#70a5fd">└─$</text><text y="20" x="35" fill="#ffffff">_</text>
          <rect x="35" y="7" width="8" height="15" fill="#5af78e" opacity="0.85" />
        </g>
      </g>

      <!-- 3. Dynamic Comparison Slider Divider & Handle -->
      <g id="slider-group">
        <!-- Vertical Line -->
        <line x1="0" y1="50" x2="0" y2="630" stroke="#ffffff" stroke-width="2.5" opacity="0.9" />
        <line x1="0" y1="50" x2="0" y2="630" stroke="rgba(0, 0, 0, 0.4)" stroke-width="1" />

        <!-- Circular Grip Handle -->
        <g transform="translate(0, 340)" filter="url(#handle-shadow)">
          <circle cx="0" cy="0" r="18" fill="#ffffff" />
          <circle cx="0" cy="0" r="15" fill="#1c1c1e" />
          <!-- Left and Right Arrows -->
          <path d="M-6 0 L-2 -4 L-2 4 Z" fill="#ffffff" />
          <path d="M6 0 L2 -4 L2 4 Z" fill="#ffffff" />
        </g>
      </g>
    </g>
  </g>
</svg>
"""

def generate():
    svg_path = "assets/screenshots/terminal-slider.svg"
    with open(svg_path, "w", encoding="utf-8") as f:
        f.write(SVG_CONTENT.strip())
    print(f"Generated {svg_path}")

    # Generate a static 1080x680 PNG preview for fallback / fast loading
    w, h = 1080, 680
    im = Image.new("RGBA", (w, h), (20, 30, 48, 255))
    draw = ImageDraw.Draw(im)

    # Gradient background
    for y in range(h):
        r = int(20 + (43 - 20) * (y / h))
        g = int(30 + (16 - 30) * (y / h))
        b = int(48 + (85 - 48) * (y / h))
        draw.line([(0, y), (w, y)], fill=(r, g, b, 255))

    # Ambient glow blobs
    blob = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    blob_draw = ImageDraw.Draw(blob)
    blob_draw.ellipse([100, 100, 500, 500], fill=(255, 0, 128, 90))
    blob_draw.ellipse([600, 300, 1050, 750], fill=(0, 242, 254, 100))
    blob_draw.ellipse([350, 200, 800, 650], fill=(155, 81, 224, 80))
    blob = blob.filter(ImageFilter.GaussianBlur(50))
    im = Image.alpha_composite(im, blob)

    # Window
    win_x, win_y, win_w, win_h = 50, 50, 980, 580
    split_x = win_x + win_w // 2

    # Transparent side: very subtle glass base
    win_layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    wdraw = ImageDraw.Draw(win_layer)

    # Left: 100% transparent (alpha 15 for subtle specular)
    wdraw.rounded_rectangle([win_x, win_y, split_x, win_y + win_h], radius=12, fill=(0, 0, 0, 15))
    # Right: 75% dark tinted glass
    wdraw.rounded_rectangle([split_x, win_y, win_x + win_w, win_y + win_h], radius=12, fill=(28, 28, 30, 195))

    # Headerbar line
    wdraw.line([(win_x, win_y + 42), (win_x + win_w, win_y + 42)], fill=(255, 255, 255, 30), width=1)
    # Window specular border
    wdraw.rounded_rectangle([win_x, win_y, win_x + win_w, win_y + win_h], radius=12, outline=(255, 255, 255, 45), width=2)

    # Traffic lights
    wdraw.ellipse([win_x + 20, win_y + 15, win_x + 32, win_y + 27], fill=(255, 95, 86, 255))
    wdraw.ellipse([win_x + 40, win_y + 15, win_x + 52, win_y + 27], fill=(255, 189, 46, 255))
    wdraw.ellipse([win_x + 60, win_y + 15, win_x + 72, win_y + 27], fill=(39, 201, 63, 255))

    # Badges
    wdraw.rounded_rectangle([win_x + 20, win_y + 55, win_x + 210, win_y + 82], radius=13, fill=(0, 0, 0, 140), outline=(255, 255, 255, 40))
    wdraw.ellipse([win_x + 30, win_y + 64, win_x + 38, win_y + 72], fill=(48, 209, 88, 255))
    wdraw.text((win_x + 46, win_y + 61), "TRANSPARENT (100% CLEAR)", fill=(255, 255, 255, 230))

    wdraw.rounded_rectangle([win_x + win_w - 200, win_y + 55, win_x + win_w - 20, win_y + 82], radius=13, fill=(0, 0, 0, 170), outline=(255, 255, 255, 40))
    wdraw.ellipse([win_x + win_w - 190, win_y + 64, win_x + win_w - 182, win_y + 72], fill=(10, 132, 255, 255))
    wdraw.text((win_x + win_w - 174, win_y + 61), "TINTED (75% GLASS)", fill=(255, 255, 255, 230))

    # Title
    wdraw.text((win_x + win_w // 2 - 70, win_y + 14), "malik@fedora: ~ (ptyxis)", fill=(222, 222, 222, 240))

    # Fastfetch text output
    lines = [
        ("┌──(malik㉿fedora)-[~]", (112, 165, 253)),
        ("└─$ fastfetch", (255, 255, 255)),
        ("", (0,0,0)),
        ("  malik@fedora", (90, 247, 142)),
        ("  ---------------------------", (150, 150, 150)),
        ("  OS: Fedora Linux 41 (Workstation Edition)", (255, 255, 255)),
        ("  Host: Framework Laptop 13 (AMD Ryzen 7 7840U)", (255, 255, 255)),
        ("  Kernel: 6.11.4-200.fc41.x86_64", (255, 255, 255)),
        ("  Desktop: GNOME 47.1 (Wayland)", (255, 255, 255)),
        ("  Theme: WhiteSur-Glassy [GTK 3/4 • Libadwaita]", (255, 121, 198)),
        ("  Terminal: Ptyxis 47.1 (Seamless Glass)", (255, 255, 255)),
        ("  Blur Engine: Blur my Shell + gnome-rounded-blur", (90, 247, 142)),
        ("  Memory: 4.82 GiB / 31.20 GiB (15%)", (255, 255, 255)),
        ("", (0,0,0)),
        ("┌──(malik㉿fedora)-[~]", (112, 165, 253)),
        ("└─$ _", (255, 255, 255)),
    ]

    ty = win_y + 105
    for text, color in lines:
        if text:
            wdraw.text((win_x + 30, ty), text, fill=color)
        ty += 24

    # Split divider line
    wdraw.line([(split_x, win_y), (split_x, win_y + win_h)], fill=(255, 255, 255, 240), width=3)
    # Handle circle
    wdraw.ellipse([split_x - 18, win_y + win_h // 2 - 18, split_x + 18, win_y + win_h // 2 + 18], fill=(255, 255, 255, 255))
    wdraw.ellipse([split_x - 14, win_y + win_h // 2 - 14, split_x + 14, win_y + win_h // 2 + 14], fill=(28, 28, 30, 255))
    wdraw.polygon([(split_x - 7, win_y + win_h // 2), (split_x - 3, win_y + win_h // 2 - 4), (split_x - 3, win_y + win_h // 2 + 4)], fill=(255, 255, 255, 255))
    wdraw.polygon([(split_x + 7, win_y + win_h // 2), (split_x + 3, win_y + win_h // 2 - 4), (split_x + 3, win_y + win_h // 2 + 4)], fill=(255, 255, 255, 255))

    im = Image.alpha_composite(im, win_layer)

    png_path = "assets/screenshots/preview.png"
    im.save(png_path, "PNG")
    print(f"Generated {png_path}")

if __name__ == "__main__":
    generate()
