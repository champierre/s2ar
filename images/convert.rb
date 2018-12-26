Dir.glob("*.png") do |f|
  p "resizing and compressing #{f}"
  system "convert -resize 800x -quality 100 #{f} resized/#{f}"
  system "zopflipng -y -m resized/#{f} resized/#{f}"
end
