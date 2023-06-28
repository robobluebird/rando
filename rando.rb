# ruby rando.rb path-to-file number-of-iterations

require 'mini_magick'
require 'wavefile'

include WaveFile

# sox song.wav -(bit)r(ate) 16000 -c(hannels) 2 -b(it depth) 16

format = Format.new :stereo, :pcm_16, 16000

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

iterations = 1
if ARGV.count > 1
  iterations = ARGV[1].to_i
end

puts "#{iterations} iterations"

dir_name = file_name.split('.').first
Dir.mkdir(dir_name) unless Dir.exist? dir_name

begin
  r = Reader.new file_name, format
rescue
  puts "no/bad file"
  return
end

drums = {}

puts "making drums"

drum_types = %w(909)

drum_types.each do |drum_type|
  drums[drum_type] = {}

  %w(h r s k).each do |d|
    begin
      path = "./drums/#{505}/#{d}.wav"
      dr = Reader.new path, format
      b = Array.new dr.total_sample_frames

      i = 0
      dr.each_buffer do |buf|
        buf.samples.each do |s|
          b[i] = s
          i += 1
        end
      end

      if d == 'h'
        drums[drum_type][:hat] = b
      elsif d == 'r'
        drums[drum_type][:ride] = b
      elsif d == 's'
        drums[drum_type][:snare] = b
      elsif d == 'k'
        drums[drum_type][:kick] = b
      end
    rescue e
      puts "no/bad file"
      return
    end
  end
end

main_buffer = Array.new r.total_sample_frames

puts "copying to main buffer"

i = 0
r.each_buffer do |b|
  b.samples.each do |s|
    main_buffer[i] = s
    i += 1
  end
end

total_size = main_buffer.count

iterations.times do
  bpm = rand 60..110
  puts "bpm set to #{bpm}"

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
  measures_needed = samples_per_minute / samples_per_measure / 2

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

  puts "collecting samples"

  while wholes.count < 4 do
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

    sample = main_buffer[start...(start + whole_size)].map { |s| s }

    # do rms here fuck u
    sum = [0, 0]
    i = 0
    rms = sample.each do |s|
      sum[0] += s[0] * s[0]
      sum[1] += s[1] * s[1]
      i += 1
    end

    rms = (Math.sqrt(sum[0] / sample.count).to_i + Math.sqrt(sum[1] / sample.count).to_i) / 2

    if rms < 12000
      wholes.push sample
    else
      puts "reject a whole sample because rms = #{rms}"
    end
  end

  while halves.count < 4
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

    sample = main_buffer[start...(start + half_size)].map { |s| s }

    # do rms here fuck u
    sum = [0, 0]
    i = 0
    rms = sample.each do |s|
      sum[0] += s[0] * s[0]
      sum[1] += s[1] * s[1]
      i += 1
    end

    rms = (Math.sqrt(sum[0] / sample.count).to_i + Math.sqrt(sum[1] / sample.count).to_i) / 2

    if rms < 11000
      halves.push sample
    else
      puts "reject a half sample because rms = #{rms}"
    end
  end

  while quarters.count < 4 do
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

    sample = main_buffer[start...(start + quarter_size)].map { |s| s }

    # do rms here fuck u
    sum = [0, 0]
    i = 0
    rms = sample.each do |s|
      sum[0] += s[0] * s[0]
      sum[1] += s[1] * s[1]
      i += 1
    end

    rms = (Math.sqrt(sum[0] / sample.count).to_i + Math.sqrt(sum[1] / sample.count).to_i) / 2

    if rms < 10000
      quarters.push sample
    else
      puts "reject a quarter sample because rms = #{rms}"
    end
  end

  while eighths.count < 4 do
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

    sample = main_buffer[start...(start + eighth_size)].map { |s| s }

    sum = [0, 0]
    i = 0
    rms = sample.each do |s|
      sum[0] += s[0] * s[0]
      sum[1] += s[1] * s[1]
      i += 1
    end

    rms = (Math.sqrt(sum[0] / sample.count).to_i + Math.sqrt(sum[1] / sample.count).to_i) / 2

    if rms < 9000
      eighths.push sample
    else
      puts "reject a eighth sample because rms = #{rms}"
    end
  end

  while sixteenths.count < 4 do
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

    sample = main_buffer[start...(start + sixteenth_size)].map { |s| s }

    sum = [0, 0]
    i = 0
    rms = sample.each do |s|
      sum[0] += s[0] * s[0]
      sum[1] += s[1] * s[1]
      i += 1
    end

    rms = (Math.sqrt(sum[0] / sample.count).to_i + Math.sqrt(sum[1] / sample.count).to_i) / 2

    if rms < 8000
      sixteenths.push sample
    else
      puts "reject a sixteenth sample because rms = #{rms}"
    end
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
      hat:   'x-x-x-x-x-x-x-x-',
      ride:  '----------------',
      snare: '----------------',
      kick:  '----------------'
    },
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
      snare: '----------------',
      kick:  'x---x---x---x-x-'
    },
    {
      hat:   '--x---x---x---x-',
      ride:  '----------------',
      snare: '----x-------x---',
      kick:  'x------xx-------'
    },
    {
      hat:   '----------------',
      ride:  '----------------',
      snare: '----------------',
      kick:  'x---x---x---x---'
    },
    {
      hat:   '----------------',
      ride:  'x---x---x---x---',
      snare: '----------------',
      kick:  '----------------'
    },
    {
      hat:   '----------------',
      ride:  '----------------',
      snare: '------------x---',
      kick:  '------------x---'
    },
    {
      hat:   '--x---x---x---x-',
      ride:  '----------------',
      snare: '----------------',
      kick:  '----------------'
    },
    {
      hat:   '----------------',
      ride:  '----------------',
      snare: '----x---xx--x---',
      kick:  'x--x--x---x-x---'
    },
    {
      hat:   '----------------',
      ride:  'x---------------',
      snare: '----------------',
      kick:  '----------------'
    },
    {
      hat:   '----------------',
      ride:  '----------------',
      snare: '----x-x-----x---',
      kick:  'x-x-------x-----'
    },
    {
      hat:   '----------------',
      ride:  '----------------',
      snare: '----x-------x---',
      kick:  'x--x------x--x--'
    }
  ]

  puts "making beats"

  beats = []

  drum_patterns.each do |pattern|
    rand_drum = drum_types.sample
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

          drums[rand_drum][instrument].each do |sample|
            instrument_data[copy_index] = sample.dup
            copy_index += 1
          end
        end
      end

      x << instrument_data
    end

    full_beat = merge_samples(*x)

    beats << full_beat
  end

  puts "making patterns"

  example = [[0], [1], [2], [3], [4], [5], [6], [7], [8], [9], [10], [11], [12]]

  bars = []
  bars_with_beats = []

  example.each.with_index do |ex, g|
    w = wholes.sample
    h = halves.sample
    q = quarters.sample
    e = eighths.sample
    s = sixteenths.sample

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

=begin

  puts "making random samples"

  5.times do |n|
    i = 0
    sequence = []
    ns = []
    rand_whole = wholes.sample
    rand_half = halves.sample
    rand_quarter = quarters.sample
    rand_eighth = eighths.sample
    rand_sixteenth = sixteenths.sample

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
            did_operate = true
          else
            len = [1, 2, 4, 8].sample
          end
        end

        if len == 8
          if i + len - 1 < 16 && !did_operate
            puts "pushing 8, len = #{len}"
            thing_to_push = rand_half
            did_operate = true
          else
            len = [1, 2, 4].sample
          end
        end

        if len == 4
          if i + len - 1 < 16 && !did_operate
            puts "pushing 4, len = #{len}"
            thing_to_push = rand_quarter
            did_operate = true
          else
            len = [1, 2].sample
          end
        end

        if len == 2
          if i + len - 1 < 16 && !did_operate
            puts "pushing 2, len = #{len}"
            thing_to_push = rand_eighth
            did_operate = true
          else
            len = 1
          end
        end

        if len == 1 && !did_operate
          puts "pushing 1, len = #{len}"
          thing_to_push = rand_sixteenth
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
=end

  # now add beats versions of each measure

  puts "making beats-versions of samples"

  i = 0
  original_count = bars.count

  puts "ORIGNAL BAR COUNT: #{bars.count}"

  bb = beats.map.with_index { |b, l| l }.shuffle

  while i < original_count do
    if bb.count == 0
      bb = beats.map.with_index { |b, l| l }.shuffle
    end

    bars << merge_samples(bars[i].map { |s| s }, beats[bb.shift])

    i += 1
  end

  puts "NEW BAR COUNT: #{bars.count}"

  # make a thingy

  generated_measures = bars.map { |b| b.map { |s| s } }

  puts "randomly applying reverb"

=begin

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

=end

  # generate a song

  puts "making song"

  # get first frame
  sequence = []
  idx = 0
  rand_start = rand(3) == 2

  if rand_start
    idx = rand generated_measures.count
  end

  sequence[0] = [
    [idx],
    generated_measures[idx].map { |sf| sf.map { |bf| bf } }
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

      if choices.count > 0 && sequence[i - 1][0].count < 4
        new_index = choices.sample

        puts "new chosen index: #{new_index}"

        new_sequence = sequence[i - 1][0][0..-1] << new_index

        if new_index > original_count - 1
          if sequence[i - 1][0].include? new_index - original_count
            puts "GOTTA REMOVE THAT NON-DRUM VERSION BRO"
            puts new_sequence.inspect
            new_sequence.delete new_index - original_count
            puts new_sequence.inspect
          end
        end

        sequence[i] = [
          new_sequence, 
          merge_samples(sequence[i - 1][1].map { |sf| sf.map { |bf| bf }}, generated_measures[new_index].map { |sf| sf.map { |bf| bf } })
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
          new_index = choices.sample

          puts "new chosen index: #{new_index}"

          new_sequence = sequence[i - 1][0][0..-1] << new_index

          if new_index > original_count - 1
            if sequence[i - 1][0].include? new_index - original_count
              puts "GOTTA REMOVE THAT NON-DRUM VERSION BRO"
              puts new_sequence.inspect
              new_sequence.delete new_index - original_count
              puts new_sequence.inspect
            end
          end

          sequence[i] = [
            new_sequence, 
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

        if flip == 0 && sequence[i - 1][0].count < 4
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
            new_index = choices.sample

            puts "new chosen index: #{new_index}"

            new_sequence = sequence[i - 1][0][0..-1] << new_index

            if new_index > original_count - 1
              if sequence[i - 1][0].include? new_index - original_count
                puts "GOTTA REMOVE THAT NON-DRUM VERSION BRO"
                puts new_sequence.inspect
                new_sequence.delete new_index - original_count
                puts new_sequence.inspect
              end
            end

            sequence[i] = [
              new_sequence,
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
    elsif frame_type == 3 # play a random previous frame or just the last frame
      roll = rand 2
      pick = i - 1

      if roll == 1
        pick = rand sequence.count
      end

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

  # samples_per_measure.times do
  #   all_data << [0, 0]
  # end

  time = Time.now.to_i

  Writer.new("#{dir_name}/song#{time}.wav", format) do |writer|
    writer.write Buffer.new(all_data, format)
  end

  puts 'doing rms'

  slots = 256 * 3
  group_size = all_data.count / slots

  rms = all_data.each_slice(group_size).inject([]) do |m, s|
    i = 0
    sum = [0, 0]

    while i < s.count do
      sum[0] += s[i][0] * s[i][0]
      sum[1] += s[i][1] * s[i][1]
      i += 1
    end

    m << ((Math.sqrt(sum[0] / s.count).to_i + Math.sqrt(sum[1] / s.count).to_i) / 2)
  end

  outs = rms.each_slice(3).to_a.map do |trips|
    trips.map do |val|
      slope = 255.0 / 32767.0
      (slope * val).to_i
    end
  end

  puts 'writing image'

  str = ''

  MiniMagick::Tool::Convert.new do |convert|
    convert.size '1024x1024'
    convert << 'xc:none'

    row = 0
    outs[0..255].each.with_index do |chunk, index|
      str << (chunk.reduce(&:+) / 3).chr
      column = index % 16
      convert.fill "rgba(#{chunk[0]}, #{chunk[1]}, #{chunk[2]}, 1)"
      convert.draw "rectangle #{64 * column},#{64 * row} #{64 * column + 64},#{64 * row + 64}"
      row += 1 if column == 15
    end

    convert << File.join(dir_name, "#{time}.png")
  end
end
