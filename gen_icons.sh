#!/bin/bash

input="app_icon.png"
out="ios/Runner/Assets.xcassets/AppIcon.appiconset"

convert $input -filter Lanczos -resize 20x20\!    "${out}/Icon-App-20x20@1x.png"
convert $input -filter Lanczos -resize 40x40\!    "${out}/Icon-App-20x20@2x.png"
convert $input -filter Lanczos -resize 60x60\!    "${out}/Icon-App-20x20@3x.png"

convert $input -filter Lanczos -resize 29x29\!    "${out}/Icon-App-29x29@1x.png"
convert $input -filter Lanczos -resize 58x58\!    "${out}/Icon-App-29x29@2x.png"
convert $input -filter Lanczos -resize 87x87\!    "${out}/Icon-App-29x29@3x.png"

convert $input -filter Lanczos -resize 40x40\!    "${out}/Icon-App-40x40@1x.png"
convert $input -filter Lanczos -resize 80x80\!    "${out}/Icon-App-40x40@2x.png"
convert $input -filter Lanczos -resize 120x120\!  "${out}/Icon-App-40x40@3x.png"

convert $input -filter Lanczos -resize 120x120\!  "${out}/Icon-App-60x60@2x.png"
convert $input -filter Lanczos -resize 180x180\!  "${out}/Icon-App-60x60@3x.png"

convert $input -filter Lanczos -resize 76x76\!    "${out}/Icon-App-76x76@1x.png"
convert $input -filter Lanczos -resize 152x152\!  "${out}/Icon-App-76x76@2x.png"

convert $input -filter Lanczos -resize 167x167\!  "${out}/Icon-App-83.5x83.5@2x.png"

convert $input -filter Lanczos -resize 1024x1024\!  "${out}/Icon-AppStore-1024x1024@1x.png"
