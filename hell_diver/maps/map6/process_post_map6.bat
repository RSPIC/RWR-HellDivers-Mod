rem you need ImageMagick convert.exe	

rem 1-pass terrain optimization: merge splat files to one, 4 is max

convert terrain5_alpha_rocky_mountain.png -colorspace RGB terrain5_alpha_grass.png -colorspace RGB terrain5_alpha_asphalt.png -colorspace RGB terrain5_alpha_road.png -colorspace RGB -channel RGBA -combine terrain5_combined_alpha.png
rem convert none.png -colorspace RGB effect_alpha_dirtroad.png -colorspace RGB none.png -colorspace RGB none.png -colorspace RGB -channel RGBA -combine effect_combined_alpha.png
convert effect_none.png -colorspace RGB effect_alpha_dirtroad.png -colorspace RGB effect_none.png -colorspace RGB effect_none_a.png -colorspace RGB -channel RGBA -combine -colorspace RGB PNG32:effect_combined_alpha.png
