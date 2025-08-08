#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🎨 Testing Hellwal Setup${NC}"

# Check if hellwal is installed
if ! command -v hellwal &> /dev/null; then
    echo -e "${RED}❌ Hellwal not found! Install with: yay -S hellwal${NC}"
    exit 1
fi

# Check if template exists
if [ ! -f ~/.config/hellwal/templates/wofi.css ]; then
    echo -e "${RED}❌ Wofi template not found at ~/.config/hellwal/templates/wofi.css${NC}"
    exit 1
fi

# Check if config exists
if [ ! -f ~/.config/hellwal/hellwal.conf ]; then
    echo -e "${RED}❌ Hellwal config not found at ~/.config/hellwal/hellwal.conf${NC}"
    exit 1
fi

# Test with wallpaper (use first argument or find one)
WALLPAPER="$1"
if [ -z "$WALLPAPER" ]; then
    # Try to find a wallpaper
    WALLPAPER=$(find ~/Pictures ~/Downloads -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" \) | head -1)
fi

if [ -z "$WALLPAPER" ] || [ ! -f "$WALLPAPER" ]; then
    echo -e "${RED}❌ No wallpaper found. Usage: $0 /path/to/wallpaper.jpg${NC}"
    exit 1
fi

echo -e "${BLUE}📸 Using wallpaper: $WALLPAPER${NC}"

# Run hellwal
echo -e "${BLUE}🔄 Generating colors...${NC}"
hellwal -i "$WALLPAPER"

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Hellwal completed successfully!${NC}"
    echo -e "${GREEN}✅ Wofi theme generated at: ~/.config/wofi/style.css${NC}"
    
    # Show some generated colors
    echo -e "${BLUE}🎨 Generated colors:${NC}"
    if [ -f ~/.cache/hellwal/colors ]; then
        head -8 ~/.cache/hellwal/colors
    fi
    
    # Test wofi
    echo -e "${BLUE}🚀 Testing wofi...${NC}"
    pkill wofi 2>/dev/null
    sleep 1
    wofi --conf ~/.config/wofi/config --style ~/.config/wofi/style.css &
    
else
    echo -e "${RED}❌ Hellwal failed!${NC}"
    exit 1
fi
