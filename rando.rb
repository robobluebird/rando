require 'wavefile'
include WaveFile

# sox song.wav -(bit)r(ate) 16000 -c(hannels) 2 -b(it depth) 16

def merge_samples *samples
  if samples.count == 1
    return samples[0]
  end

  initial_value = samples.shift

  things = samples.map do |s|
    if s.count > initial_value.count
      s = s[0...initial_value.count]
    else
      s
    end
  end

  things.reduce(initial_value) do |memo, sample|
    sample.each.with_index do |frame, index|
      memo[index][0] += frame[0]
      memo[index][0] = 32767 if memo[index][0] > 32767
      memo[index][0] = -32768 if memo[index][0] < -32768
      memo[index][1] += frame[1]
      memo[index][1] = 32767 if memo[index][1] > 32767
      memo[index][1] = -32768 if memo[index][1] < -32768
    end

    memo
  end
end

file_name = ARGV.first
format = Format.new :stereo, :pcm_16, 16000

begin
  r = Reader.new file_name, format
rescue
  puts "no/bad file"
  return
end

bpm = rand 40..180
puts "bpm set to #{bpm}"

puts r.format.inspect
puts r.total_sample_frames

main_buffer = Array.new r.total_sample_frames

i = 0
r.each_buffer do |b|
  b.samples.each do |s|
    main_buffer[i] = s
    i += 1
  end
end

drums = {}

%w(h r s k).each do |d|
  begin
    r = Reader.new "./drums/#{d}.wav", format
    b = Array.new r.total_sample_frames

    i = 0
    r.each_buffer do |buf|
      buf.samples.each do |s|
        b[i] = s
        i += 1
      end
    end

    if d == 'h'
      drums[:hat] = b
    elsif d == 'r'
      drums[:ride] = b
    elsif d == 's'
      drums[:snare] = b
    elsif d == 'k'
      drums[:kick] = b
    end
  rescue
    puts "no/bad file"
    return
  end
end

# puts main_buffer.count
# puts "samples per second: #{r.format.sample_rate}"
# puts "samples per minute: #{r.format.sample_rate * 60}"
# puts "samples per beat @ #{bpm} beats per minute: #{(r.format.sample_rate * 60) / bpm}"

dir_name = Time.now.to_i.to_s
Dir.mkdir dir_name

total_size = main_buffer.count

samples_per_beat = (r.format.sample_rate * 60) / bpm 
samples_per_measure = samples_per_beat * 4
samples_per_sixteenth = samples_per_beat / 4
whole_size = samples_per_beat * 4
half_size = samples_per_beat * 2
quarter_size = samples_per_beat
eighth_size = quarter_size / 2
sixteenth_size = quarter_size / 4

measures_per_minute = bpm / 4
samples_per_minute = r.format.sample_rate * 60
samples_for_song = samples_per_minute * 2
measures_needed = samples_for_song / samples_per_measure

last_whole_start = total_size - whole_size
last_half_start = total_size - half_size
last_quarter_start = total_size - quarter_size
last_eighth_start = total_size - eighth_size
last_sixteenth_start = total_size - sixteenth_size

wholes = []
halves = []
quarters = []
eighths = []
sixteenths = []

4.times do |i|
  start = nil

  if i == 0
    start = rand(last_whole_start / 3)
  elsif i == 1
    start = rand((last_whole_start / 3)..((last_whole_start / 3) * 2))
  elsif i == 2
    start = rand((last_whole_start / 3 * 2)..last_whole_start)
  else
    start = rand last_whole_start
  end

  sample = main_buffer[start...(start + whole_size)]
  wholes.push sample
end

4.times do |i|
  start = nil

  if i == 0
    start = rand(last_half_start / 3)
  elsif i == 1
    start = rand((last_half_start / 3)..(last_half_start / 3 * 2))
  elsif i == 2
    start = rand((last_half_start / 3 * 2)..last_half_start)
  else
    start = rand last_half_start
  end

  sample = main_buffer[start...(start + half_size)]
  halves.push sample
end

4.times do |i|
  start = nil

  if i == 0
    start = rand(last_quarter_start / 3)
  elsif i == 1
    start = rand((last_quarter_start / 3)..(last_quarter_start / 3 * 2))
  elsif i == 2
    start = rand((last_quarter_start / 3 * 2)..last_quarter_start)
  else
    start = rand last_quarter_start
  end

  sample = main_buffer[start...(start + quarter_size)]
  quarters.push sample
end

4.times do |i|
  start = nil

  if i == 0
    start = rand(last_eighth_start / 3)
  elsif i == 1
    start = rand((last_eighth_start / 3)..(last_eighth_start / 3 * 2))
  elsif i == 2
    start = rand((last_eighth_start / 3 * 2)..last_eighth_start)
  else
    start = rand last_eighth_start
  end

  sample = main_buffer[start...(start + eighth_size)]
  eighths.push sample
end

4.times do |i|
  start = nil

  if i == 0
    start = rand(last_sixteenth_start / 3)
  elsif i == 1
    start = rand((last_sixteenth_start / 3)..(last_sixteenth_start / 3 * 2))
  elsif i == 2
    start = rand((last_sixteenth_start / 3 * 2)..last_sixteenth_start)
  else
    start = rand last_sixteenth_start
  end

  sample = main_buffer[start...(start + sixteenth_size)]
  sixteenths.push sample
end

# make a different thingy

patterns = [
  'w---------------', # 0
  'h-------h-------', # 1
  '--------h-------', # 2
  '----h-------q---', # 3
  '----q-------q---', # 4
  'q-------q-------', # 5
  'q---q---q---q---', # 6
  '--q---q---q---e-', # 7
  '-e-e-e-e-e-e-e-e', # 8
  'e-e-e-e-e-e-e-e-', # 9
  'e-sse-sse-sse-ss', # 10
  'ssssssssssssssss', # 11
  '--ss--ss--ss--ss'  # 12
]

drum_patterns = [
  {
    hat:   'x---x---x---x---',
    ride:  '----------------',
    snare: '----x-------x---',
    kick:  'x-------x-------'
  },
  {
    hat:   'x-x-x-x-x-x-x-x-',
    ride:  '----------------',
    snare: '----x--x-x--x---',
    kick:  'x-x-------x-----'
  },
  {
    hat:   'x-x-x-x-x-x-x-x-',
    ride:  '----------------',
    snare: 'x---x---x---x---',
    kick:  'x---x---x---x-x-'
  },
  {
    hat:   '-x-x-x-x-x-x-x-x',
    ride:  '----------------',
    snare: 'x---x---x---x---',
    kick:  'x---------x-----'
  },
  {
    hat:   '----------------',
    ride:  '-x---x---x---x--',
    snare: '--xx--xx--xx--xx',
    kick:  'x---x---x---x---'
  },
  {
    hat:   '--x---x---x---x-',
    ride:  '----------------',
    snare: '----x-------x---',
    kick:  'x------xx-------'
  },
]

beats = []

drum_patterns.each do |pattern|
  x = []

  %i(hat ride snare kick).each do |instrument|
    instrument_pattern = pattern[instrument].split ''

    instrument_data = Array.new samples_per_measure
    instrument_data.map! do |ids|
      [0, 0]
    end

    instrument_pattern.each.with_index do |pattern_step, pattern_step_index|
      if pattern_step == 'x'
        copy_index = pattern_step_index * samples_per_sixteenth

        drums[instrument].each do |sample|
          instrument_data[copy_index] = sample.dup
          copy_index += 1
        end
      end
    end

    x << instrument_data
  end

  full_beat = merge_samples(*x)

  full_beat.map! do |fbs|
    fbs.map! do |lrs|
      lrs / 4
    end
  end

  beats << full_beat
end

example = [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12]]

bars = []
bars_with_beats = []

example.each.with_index do |ex, g|
  w = wholes[rand(wholes.count)]
  h = halves[rand(halves.count)]
  q = quarters[rand(quarters.count)]
  e = eighths[rand(eighths.count)]
  s = sixteenths[rand(sixteenths.count)]

  amb = []

  ex.each.with_index do |pattern_index, i|
    ns = []
    mb = []
    mbi = 0

    patterns[pattern_index].split('').each.with_index do |l, pi|
      if l != '-'
        if l == 'w'
          ns << [pi, 16, w]
        elsif l == 'h'
          ns << [pi, 8, h]
        elsif l == 'q'
          ns << [pi, 4, q]
        elsif l == 'e'
          ns << [pi, 2, e]
        elsif l == 's'
          ns << [pi, 1, s]
        end
      end
    end

    ns.each do |ns|
      mbi = ns.first * samples_per_sixteenth
      ns.last.each do |sample|
        mb[mbi] = sample
        mbi += 1
      end
    end

    mb.map! do |me|
      if me.nil?
        [0, 0]
      else
        me
      end
    end

    amb << mb
  end

  bars << merge_samples(*amb)
end

# generate random bars with no pattern

5.times do |n|
  i = 0
  sequence = []
  ns = []
  rand_whole = wholes[rand(wholes.count)]
  rand_half = halves[rand(halves.count)]
  rand_quarter = quarters[rand(quarters.count)]
  rand_eighth = eighths[rand(eighths.count)]
  rand_sixteenth = sixteenths[rand(sixteenths.count)]

  while i < 16 do
    len = [1, 2, 4, 8, 16].sample

    puts "set len to #{len}"
    s = rand 2
    did_operate = false
    thing_to_push = nil

    if s > 0 || i == 0
      if len == 16
        if i + len - 1 < 16 && !did_operate
          puts "pushing 16, len = #{len}"
          thing_to_push = rand_whole
          wholes.delete rand_whole
          did_operate = true
        else
          len = [1, 2, 4, 8].sample
        end
      end

      if len == 8
        if i + len - 1 < 16 && !did_operate
          puts "pushing 8, len = #{len}"
          thing_to_push = rand_half
          halves.delete rand_half
          did_operate = true
        else
          len = [1, 2, 4].sample
        end
      end

      if len == 4
        if i + len - 1 < 16 && !did_operate
          puts "pushing 4, len = #{len}"
          thing_to_push = rand_quarter
          quarters.delete rand_quarter
          did_operate = true
        else
          len = [1, 2].sample
        end
      end

      if len == 2
        if i + len - 1 < 16 && !did_operate
          puts "pushing 2, len = #{len}"
          thing_to_push = rand_eighth
          eighths.delete rand_eighth
          did_operate = true
        else
          len = 1
        end
      end

      if len == 1 && !did_operate
        puts "pushing 1, len = #{len}"
        thing_to_push = rand_sixteenth
        sixteenths.delete rand_sixteenth
      end

      ns << [i, len, thing_to_push]
      
      puts "wtfTOO len = #{len}"
      i = i + len
    else
      if len == 16
        if i + len - 1 < 16
          puts "silence 16"
          did_operate = true
        else
          len = [1, 2, 4, 8].sample
          "setting len in silence block 16"
        end
      end

      if len == 8
        if i + len - 1 < 16 && !did_operate
          puts "silence 8"
          did_operate = true
        else
          len = [1, 2, 4].sample
          "setting len in silence block 8"
        end
      end

      if len == 4
        if i + len - 1 < 16 && !did_operate
          puts "silence 4"
          did_operate = true
        else
          len = [1, 2].sample
          "setting len in silence block 4"
        end
      end

      if len == 2
        if i + len - 1 < 16 && !did_operate
          puts "silence 2"
          did_operate = true
        else
          len = 1
          "setting len in silence block 2"
        end
      end

      if len == 1 && !did_operate
        puts "silence 1"
        did_operate = true
      end

      puts "wtf len = #{len}"
      i = i + len
    end

    puts "i = #{i}"
  end

  raise "bad counting: #{i}" unless i == 16 # should always == 15

  mb = Array.new samples_per_measure
  mb.map! do |m|
    [0, 0]
  end

  puts "about to GENERATE SAMPLE: #{ns.map { |ns| [ns.first, ns[1]] }}"

  mbi = 0
  ns.each do |ns|
    mbi = ns.first * samples_per_sixteenth
    ns.last.each do |sample|
      mb[mbi] = sample
      mbi += 1
    end
  end

  bars << mb
end

# now add beats versions of each measure

i = 0
original_count = bars.count

while i < original_count do
  bars << merge_samples(bars[i], beats[rand(6)])
  i += 1
end

puts "NEW BAR COUNT: #{bars.count}"

# make a thingy

generated_measures = bars.map { |b| b.map { |s| s } }

generated_measures.each.with_index do |gm, gi|
  roll = rand 5

  if roll == 0
    delay = rand / 4
    decay = rand / 4

    puts "adding reverb (?) on random chance to measure #{gi}. delay: #{delay}, decay: #{decay}"

    buffer_size = (r.format.sample_rate * delay).to_i
    sample_iterator = 0
    effect_iterator = sample_iterator + buffer_size
    sample_count = gm.count

    puts "buffer_size: #{buffer_size}, effect_iterator: #{effect_iterator}, sample_count: #{sample_count}"

    while sample_iterator < sample_count do
      channel_data = gm[effect_iterator]

      channel_data = [0, 0] unless channel_data

      channel_data[0] += gm[sample_iterator][0] * decay
      channel_data[1] += gm[sample_iterator][1] * decay

      channel_data[0] =  32767 if channel_data[0] > 32767
      channel_data[0] = -32768 if channel_data[0] < -32768

      channel_data[1] = 32767  if channel_data[1] > 32767
      channel_data[1] = -32768 if channel_data[1] < -32768

      gm[effect_iterator] = channel_data

      sample_iterator += 1
      effect_iterator += 1
    end
  end
end

generated_measures.each.with_index do |gm, gmi|
  Writer.new("#{dir_name}/sampleWHAT#{gmi}.wav", Format.new(:stereo, :pcm_16, 16000)) do |w|
    b = Buffer.new gm, Format.new(:stereo, :pcm_16, 16000)
    w.write b
  end
end

# generate a song

# get first frame
sequence = []
sequence[0] = [
  [0],
  generated_measures[0].map { |sf| sf.map { |bf| bf } }
]

# now do some random shit

puts "going to count up to #{measures_needed}?"

i = 1
while i < measures_needed do
  failure = false
  roll = rand(6)
  chop = nil

  if roll == 0
    chop = 2
  elsif roll == 5
    chop = 4
  end

  frame_type = rand 4

  if frame_type == 0 # play a different measure
    new_index = rand(generated_measures.count)
    tries = 0

    while sequence[i - 1][0].include?(new_index) && tries < 10 do
      puts "conflicting new index of #{new_index} with previous frame being #{sequence[i - 1][0].inspect}"
      new_index = rand(generated_measures.count)
      puts "trying #{new_index}"
      tries += 1
    end

    if new_index > -1
      puts "got a good new index of #{new_index}"

      sequence[i] = [
        [new_index],
        generated_measures[new_index].map { |sf| sf.map { |bf| bf } }
      ]
    else
      puts "failed this round..."
      failure = true
    end
  elsif frame_type == 1 # add or remove layer to become new frame
    if sequence[i - 1][0].count == 1 # always add
      puts "adding something to previous frame (had to: #{sequence[i - 1][0]})"

      # don't layer drum parts on top of each other, so exclude drumified measures from choices
      # if a drum part exists on the previous frame
      has_a_drum_part = sequence[i - 1][0].find_index { |e| e > original_count - 1 } != nil
      choices = []

      if has_a_drum_part
        puts "found a drum part in previous frame (#{sequence[i - 1][0].inspect} so exclude drums)"
        choices = generated_measures[0...original_count].map.with_index { |g, i| i } - sequence[i - 1][0]
      else
        choices = generated_measures.map.with_index { |g, i| i } - sequence[i - 1][0]
      end

      puts "choices: #{choices.inspect}"

      if choices.count > 0
        new_index = choices[rand(choices.count)]

        puts "new chosen index: #{new_index}"

        sequence[i] = [
          sequence[i - 1][0][0..-1] << new_index,
          merge_samples(sequence[i - 1][1].map { |sf| sf.map { |bf| bf }}, generated_measures[new_index].map { |sf| sf.map { |bf| bf } })
        ]
      else
        puts "failed this round???"
        failure = true
      end
    elsif sequence[i - 1][0].count == generated_measures.count # always subtract
      rando_remove = sequence[i - 1][0].sample

      if rando_remove >= generated_measures.count / 2
        puts "REMOVING A DRUM BAR WOO"
      end

      new_seq = sequence[i - 1][0].reject.with_index { |n, i| i == rando_remove }

      puts "new seq = #{new_seq} and of course length == generated_measures length should be true: #{new_seq.count == generated_measures.count}"

      new_measures = new_seq.map { |n| generated_measures[n].map { |sf| sf.map { |bf| bf } } }

      puts "new_measures length is #{new_measures.count} and type of 0 is #{new_measures[0].class}"

      sequence[i] = [
        new_seq,
        merge_samples(*new_measures)
      ]
    else # flip a coint
      flip = rand 2

      puts "in rando add/subtract, flip = #{flip}"

      if flip == 0
        puts "adding something to previous frame (didn't have to)"

        # don't layer drum parts on top of each other, so exclude drumified measures from choices
        # if a drum part exists on the previous frame
        has_a_drum_part = sequence[i - 1][0].find_index { |e| e > original_count - 1 } != nil
        choices = []

        if has_a_drum_part
          puts "found a drum part in previous frame (#{sequence[i - 1][0].inspect} so exclude drums)"
          choices = generated_measures[0...original_count].map.with_index { |g, i| i } - sequence[i - 1][0]
        else
          choices = generated_measures.map.with_index { |g, i| i } - sequence[i - 1][0]
        end

        puts "choices: #{choices.inspect}"

        if choices.count > 0
          new_index = choices[rand(choices.count)]

          puts "new chosen index: #{new_index}"

          sequence[i] = [
            sequence[i - 1][0][0..-1] << new_index,
            merge_samples(sequence[i - 1][1].map { |sf| sf.map { |bf| bf } }, generated_measures[new_index].map { |sf| sf.map { |bf| bf } })
          ]
        else
          puts "failed this round?!?!?!"
          failure = true
        end
      else
        rando_remove = sequence[i - 1][0].sample
        new_seq = sequence[i - 1][0].reject.with_index { |n, i| i == rando_remove }

        if rando_remove >= generated_measures.count / 2
          puts "REMOVING A DRUM BAR WOO"
        end

        puts "new seq = #{new_seq}"

        new_measures = new_seq.map { |n| generated_measures[n].map { |sf| sf.map { |bf| bf } } }

        puts "new_measures length is #{new_measures.count} and type of 0 is #{new_measures[0].class}"

        sequence[i] = [
          new_seq,
          merge_samples(*new_measures)
        ]
      end
    end
  elsif frame_type == 2 # reverse last frame
    sequence[i] = [
      sequence[i - 1][0][0..-1],
      sequence[i - 1][1].map { |sf| sf.map { |bf| bf }}.reverse
    ]
  elsif frame_type == 3 # play a random previous frame
    pick = rand sequence.count

    sequence[i] = [
      sequence[pick][0],
      sequence[pick][1]
    ]
  end

  unless failure
    if chop 
      puts "chopping by #{chop}"
      sequence[i][1] = sequence[i][1][0..(sequence[i][1].count / chop)]
    end

    puts "had a good round"

    i += 1
  end
end

puts "whole sequence: #{sequence.map { |s| s[0] }.inspect}"

all_data = []

sequence.each do |s|
  s[1].each do |e|
    all_data << e
  end
end

Writer.new("C:/Users/Lenovo/Documents/Bullshit/song#{Time.now.to_i}.wav", Format.new(:stereo, :pcm_16, 16000)) do |w|
  b = Buffer.new all_data, Format.new(:stereo, :pcm_16, 16000)
  w.write b
end