require 'mini_magick'

parts = ARGV.first.split('.')

if parts.count != 2
  puts 'filename format :('
  return
end

dir_name = parts[0].split('\\')[0...-1].join('\\')
file_name = parts[0].split('\\')[-1]

image = MiniMagick::Image.open ARGV.first
width = image.width
height = image.height

MiniMagick::Tool::Convert.new do |img|
  img << ARGV.first
  img.background 'none'
  img.fill 'black'
  img.stroke 'white'
  img.strokewidth '1'
  img.pointsize '96'
  img.size "#{width}x#{height}"
  img.font 'Microsoft-JhengHei-Bold-&-Microsoft-JhengHei-UI-Bold'
  img.gravity 'south'
  img << "caption: 行動する人は沈黙する"
  img << '-composite'
  img << File.join(dir_name, "#{file_name}_anno.png")
end
