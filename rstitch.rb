require 'wavefile'

include WaveFile

format = Format.new :stereo, :pcm_16, 16000

rounds = ARGV.last.to_i

puts "#{rounds} rounds"

dir = ARGV.first

puts dir
puts Dir.exist? dir

files = Dir.entries(dir).keep_if do |f|
  f.end_with? '.wav'
end

puts files.inspect

choices = files.map { |f| f.split('.').first }
choices.delete 'stitched'

puts choices.inspect

=begin
while choices.count > 0 do
  puts "choices: #{choices.inspect}"
  puts "next choice?"

  choice = STDIN.gets.chomp

  list << choices.delete(choice)
  list.compact!
end
=end

# RANDOMLY choose a sequence

rounds.times do
  totals = []
  total_samples = 0
  required_samples = rand(60..120) * 16000
  while total_samples < required_samples && choices.count > 0 do
    name = choices.sample
    choices.delete name

    file_path = File.join dir, "#{name}.wav"

    begin
      reader = Reader.new file_path, format
    rescue
      raise 'bad/no file'
    end

    i = 0
    yes = []
    reader.each_buffer do |buffer|
      buffer.samples.each do |sample|
        yes[i] = sample
        i += 1
      end
    end

    totals << yes
    total_samples += yes.count
  end

  puts totals.count
  puts totals.map &:count

  puts "append final beat? (y/n)"

  beat = STDIN.gets.chomp
  drum_sample = []

  if beat[0].downcase == 'y'
    drum_types = %w(505 606 707 808 909)
    drum_choice = nil

    while !drum_types.include?(drum_choice)
      puts "drum type? (505, 606, 707, 808, 909)"
      drum_choice = STDIN.gets.chomp
    end

    puts "loading drums..."

    drums = {}

    %w(h r s k).each do |drum|
      begin
        reader = Reader.new "./drums/#{drum_choice}/#{drum}.wav", format
        buffer = Array.new reader.total_sample_frames

        index = 0
        reader.each_buffer do |buffer_segment|
          buffer_segment.samples.each do |sample|
            buffer[index] = sample
            index += 1
          end
        end

        if drum == 'h'
          drums[:hat] = buffer
        elsif drum == 'r'
          drums[:ride] = buffer
        elsif drum == 's'
          drums[:snare] = buffer
        elsif drum == 'k'
          drums[:kick] = buffer
        end
      rescue
        raise "no/bad file"
      end
    end

    puts drums[:hat].count
    puts drums[:ride].count
    puts drums[:snare].count
    puts drums[:kick].count

    puts "writing drums..."

    include_snare = rand 2
    hat_or_ride = rand 2

    drums[:kick].each.with_index do |sample, index|
      drum_sample[index] = sample
    end

    if include_snare
      drums[:snare].each.with_index do |sample, index|
        drum_sample[index] = [0, 0] if drum_sample[index].nil?

        drum_sample[index][0] += sample[0]
        drum_sample[index][1] += sample[1]

        drum_sample[index][0] =  32767 if drum_sample[index][0] > 32767
        drum_sample[index][0] = -32768 if drum_sample[index][0] < -32768

        drum_sample[index][1] =  32767 if drum_sample[index][1] > 32767
        drum_sample[index][1] = -32768 if drum_sample[index][1] < -32768
      end
    end

    if hat_or_ride == 0
      drums[:hat].each.with_index do |sample, index|
        drum_sample[index] = [0, 0] if drum_sample[index].nil?

        drum_sample[index][0] += sample[0]
        drum_sample[index][1] += sample[1]

        drum_sample[index][0] =  32767 if drum_sample[index][0] > 32767
        drum_sample[index][0] = -32768 if drum_sample[index][0] < -32768

        drum_sample[index][1] =  32767 if drum_sample[index][1] > 32767
        drum_sample[index][1] = -32768 if drum_sample[index][1] < -32768
      end
    else
      drums[:ride].each.with_index do |sample, index|
        drum_sample[index] = [0, 0] if drum_sample[index].nil?

        drum_sample[index][0] += sample[0]
        drum_sample[index][1] += sample[1]

        drum_sample[index][0] =  32767 if drum_sample[index][0] > 32767
        drum_sample[index][0] = -32768 if drum_sample[index][0] < -32768

        drum_sample[index][1] =  32767 if drum_sample[index][1] > 32767
        drum_sample[index][1] = -32768 if drum_sample[index][1] < -32768
      end
    end

    puts drum_sample.count
  else
    puts "okay i'll just stitch 'em up"
  end

  puts 'writing the whole thing...'

  out_name = "#{Time.now.to_i}.wav"

  Writer.new(File.join(dir, out_name), format) do |writer|
    totals.each do |segment|
      buffer = Buffer.new segment, format
      writer.write buffer
    end

    if drum_sample.count > 0
      drum_buffer = Buffer.new drum_sample, format
      writer.write drum_buffer
    end
  end

  puts "wrote #{out_name}"
end
