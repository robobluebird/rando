# ruby anno.rb path-to-image-file caption location-on-image font

require 'mini_magick'

parts = ARGV[0].split('.')
caption = ARGV[1]
location = ARGV[2] || 'Center'
font = ARGV[3] || 'Times-New-Roman'

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
  img.fill 'white'
  img.stroke 'black'
  img.strokewidth '1'
  img.pointsize '120'
  img.size "#{width}x#{height}"
  # img.font 'Microsoft-JhengHei-Bold-&-Microsoft-JhengHei-UI-Bold'
  img.font 'Times-New-Roman'
  img.gravity 'southwest'
  # img << "caption: 行動する人は沈黙する"
  # img << "caption:\\n\\n行動計画"
  img << "caption:#{caption}"
  img << '-composite'
  img << File.join(dir_name, "#{file_name}_anno.png")
end
