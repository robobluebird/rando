require 'mini_magick'

file_name = ARGV.first

begin
  img = MiniMagick::Image.open file_name
rescue
  puts "no/bad file"
  return
end

w = img.width
h = img.height

puts "old"
puts w
puts h

while w % 5 != 0
  w += 1
end

while h % 5 != 0
  h += 1
end

img.combine_options do |b|
  b.resize "#{w}x#{h}!"
end

puts "new"
puts img.width
puts img.height

pixels = img.get_pixels

puts "row count: #{pixels.count}"
puts "column count: #{pixels[0].count}"

chunks = pixels.map do |row|
  row.group_by.with_index { |r, i| i / 5 }.values
end

base = Array.new(chunks.count / 5).map { |row| Array.new(chunks[0].count).map { |group| [] }}

chunks.each.with_index do |row, row_index|
  # I NEVER remember reference copying rules so this just creates a totally fresh row, object-wise
  row_copy = row.map { |group| group.map { |val| val }}

  row_copy.each.with_index do |group, group_index|
    base[row_index / 5][group_index].concat group
  end
end

averages = base.map do |row|
  row.map do |group|
    r = 0
    g = 0
    b = 0
    c = group.count

    group.each do |rgb|
      r += rgb[0]
      g += rgb[1]
      b += rgb[2]
    end

    [r / c, g / c, b / c]
  end
end

final = []

64.times do
  row = averages.sample
  less_row = []

  64.times do
    less_row << row.sample
  end

  final << less_row
end

width = final[0].count * 16
height = final.count * 16

filename = "#{Time.now.to_i.to_s}.png"

MiniMagick::Tool::Magick.new do |magick|
  magick.size "#{width}x#{height}"
  magick << 'xc:none'
  magick << filename
end

final.each.with_index do |row, index|
  magick = MiniMagick::Tool::Magick.new
  magick << filename
  x = 0
  y = index * 16

  puts "#{y}"

  row.each do |rgb|
    magick.fill "rgba(#{rgb[0]}, #{rgb[1]}, #{rgb[2]}, 1)"
    magick.draw "rectangle #{x},#{y} #{x + 16},#{y + 16}"
    x += 16
  end

  puts "final x = #{x}"
  magick << filename
  magick.call
end
