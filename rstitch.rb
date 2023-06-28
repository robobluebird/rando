# ruby rstitch.rb path-to-directory-of-audio-files

require 'wavefile'

include WaveFile

format = Format.new :stereo, :pcm_16, 16000

dir = ARGV.first

files = Dir.entries(dir).keep_if do |f|
  f.end_with? '.wav'
end

choices = files.map { |f| f.split('.').first }

while choices.count > 0 do
  totals = []
  total_samples = 0
  required_samples = 30 * 16000

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

  puts "loading drums..."

  drum_choice = %w(505 606 707 808 909).sample
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

  drum_sample = []

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
