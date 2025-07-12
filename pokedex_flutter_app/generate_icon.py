#!/usr/bin/env python3
"""
Script to generate a Pokeball icon for the Shiny Tracker app
"""

try:
    from PIL import Image, ImageDraw
    import os
except ImportError:
    print("PIL not found. Installing...")
    import subprocess
    subprocess.run(["pip", "install", "Pillow"])
    from PIL import Image, ImageDraw
    import os

def create_pokeball_icon():
    """Create a 512x512 pokeball icon"""
    size = 512
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)

    center = size // 2
    border_width = 12

    # Background circle (white with black border)
    draw.ellipse([border_width, border_width, size-border_width, size-border_width], 
                 fill='white', outline='black', width=border_width)

    # Red top half
    draw.pieslice([border_width, border_width, size-border_width, size-border_width], 
                  180, 360, fill='#DC143C', outline=None)

    # Middle black line (slightly thicker)
    line_thickness = 16
    draw.rectangle([border_width, center-line_thickness//2, size-border_width, center+line_thickness//2], 
                   fill='black')

    # Center white circle (larger)
    center_radius = 50
    draw.ellipse([center-center_radius, center-center_radius, center+center_radius, center+center_radius], 
                 fill='white', outline='black', width=8)

    # Center inner circle
    inner_radius = 25
    draw.ellipse([center-inner_radius, center-inner_radius, center+inner_radius, center+inner_radius], 
                 fill='white', outline='black', width=4)

    # Save the icon
    os.makedirs('assets/icon', exist_ok=True)
    icon_path = 'assets/icon/pokeball_icon.png'
    img.save(icon_path, 'PNG')
    print(f"✅ Pokeball icon created successfully: {icon_path}")
    return True

if __name__ == "__main__":
    create_pokeball_icon() 