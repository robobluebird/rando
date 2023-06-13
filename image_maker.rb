require 'mini_magick'
require 'wavefile'

include WaveFile

file_name = ARGV.first
format = Format.new :stereo, :pcm_16, 16000
channels = 2

dir_name = File.dirname file_name
base_name = File.basename file_name

begin
  r = Reader.new file_name, format
rescue
  puts 'no/bad file'
  return
end

main_buffer = Array.new r.total_sample_frames

puts 'copying to main buffer'

i = 0
r.each_buffer do |b|
  b.samples.each do |s|
    main_buffer[i] = s
    i += 1
  end
end

slots = 256 * 3
group_size = main_buffer.count / slots

puts 'doing rms'

rms = main_buffer.each_slice(group_size).inject([]) do |memo, s|
  i = 0
  sum = [0, 0]

  while i < s.count do
    sum[0] += s[i][0] * s[i][0]
    sum[1] += s[i][1] * s[i][1]
    i += 1
  end

  memo << ((Math.sqrt(sum[0] / s.count).to_i + Math.sqrt(sum[1] / s.count).to_i) / 2)
end

outs = rms.each_slice(3).to_a.map do |trips|
  trips.map do |val|
    slope = 255.0 / 32767.0
    output = slope * val
    output.to_i
  end
end

puts 'writing image'

str = ""

MiniMagick::Tool::Convert.new do |convert|
  convert.size "1024x1024"
  convert << 'xc:none'

  row = 0
  outs[0..255].each.with_index do |chunk, index|
    str << (chunk.reduce(&:+) / 3).chr
    column = index % 16
    convert.fill "rgba(#{chunk[0]}, #{chunk[1]}, #{chunk[2]}, 1)"
    convert.draw "rectangle #{64 * column},#{64 * row} #{(64 * column) + 64},#{(64 * row) + 64}"
    row += 1 if column == 15
  end

=begin
  convert.background 'none'
  convert.gravity 'NorthWest'
  convert.fill 'white'
  convert.stroke 'black'
  convert.strokewidth '2'
  convert.pointsize '96'
  convert.font 'Courier-New'
  convert << "caption: #{str.gsub("\u0000", ' ')}"
=end

  base = base_name.split('.')[0][4..-1] # "songXYZ"
  convert << File.join(dir_name, "#{base}.png")
end

=begin
base = base_name.split('.')[0][4..-1] # "songXYZ"

t1 = File.join(dir_name, 'visual-0.png')
t2 = File.join(dir_name, 'visual-1.png')
t3 = File.join(dir_name, "#{base}.png")

first_image  = MiniMagick::Image.new(t1)
second_image = MiniMagick::Image.new(t2)

result = first_image.composite(second_image) do |c|
  c.compose "Over"
end

result.write t3

File.delete t1
File.delete t2
=end
