
##
# Separate notes from slide content, writing to two separate files

slides = File.open('slides.md', 'w')
notes  = File.open('notes.md',  'w')

fenced = false

File.read('source.md').each_line do |line|
  if line.include?('%%')
    prefix, *rest = line.split('%%')
    slides.puts prefix.strip
    notes.puts  rest.join.strip
  elsif line.start_with?('```')
    fenced = !fenced
    slides.puts line
    notes.puts  line
  elsif fenced \
     or line.start_with?('#') \
     or line.start_with?('-') \
     or line.start_with?('|') \
     or line.start_with?('!') \
     or line.start_with?('>') \
     or line.start_with?('*') \
     or line.start_with?("\n")
    slides.puts line
    notes.puts  line
  else
    slides.puts line
  end
end

slides.close
notes.close

##
# Condense multiple consecutive empty lines wherever found

%w{slides.md notes.md}.each do |filename|
  content = File.read(filename)
  content.gsub!(/\n\n+/, "\n\n")
  File.write(filename, content)
end
