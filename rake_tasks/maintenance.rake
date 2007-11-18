desc "add copyright to all .rb files in the distribution"
task 'add-copyright' do
  ignore = File.readlines('doc/LEGAL').
    select{|line| line.strip!; File.exist?(line)}.
    map{|file| File.expand_path(file)}

  puts "adding copyright to files that don't have it currently"
  puts COPYRIGHT
  puts

  Dir['{lib,test}/**/*{.rb}'].each do |file|
    file = File.expand_path(file)
    next if file =~ /_darcs/ or ignore.include? file
    lines = File.readlines(file).map{|l| l.chomp}
    unless lines.first(COPYRIGHT.size) == COPYRIGHT
      puts "#{file} seems to need attention, first 4 lines:"
      puts lines[0..3]
      puts
    end
  end
end

desc "doc/README to html"
Rake::RDocTask.new('readme2html-build') do |rd|
  rd.options = %w[
    --quiet
    --opname readme.html
  ]

  rd.rdoc_dir = 'readme'
  rd.rdoc_files = ['doc/README']
  rd.main = 'doc/README'
  rd.title = "Ramaze documentation"
end

desc "doc/README to doc/README.html"
task 'readme2html' => ['readme-build', 'readme2html-build'] do
  cp('readme/files/doc/README.html', 'doc/README.html')
  rm_rf('readme')
end

desc "generate doc/TODO from the TODO tags in the source"
task 'todolist' do
  list = `rake todo`
  tasks = {}
  current = nil

  list.split("\n")[2..-1].each do |line|
    if line =~ /TODO/ or line.empty?
    elsif line =~ /^vim/
      current = line.split[1]
      tasks[current] = []
    else
      tasks[current] << line
    end
  end

  lines = tasks.map{ |name, items| [name, items, ''] }.flatten
  lines.pop

  File.open(File.join('doc', 'TODO'), 'w+') do |f|
    f.puts "This list is programmaticly generated by `rake todolist`"
    f.puts "If you want to add/remove items from the list, change them at the"
    f.puts "position specified in the list."
    f.puts
    f.puts(lines)
  end
end

desc "remove those annoying spaces at the end of lines"
task 'fix-end-spaces' do
  Dir['{lib,spec}/**/*.rb'].each do |file|
    next if file =~ /_darcs/
    lines = File.readlines(file)
    new = lines.dup
    lines.each_with_index do |line, i|
      if line =~ /\s+\n/
        puts "fixing #{file}:#{i + 1}"
        p line
        new[i] = line.rstrip
      end
    end

    unless new == lines
      File.open(file, 'w+') do |f|
        new.each do |line|
          f.puts(line)
        end
      end
    end
  end
end

desc "Compile the doc/README from the parts of doc/readme"
task 'readme-build' do
  require 'enumerator'

  chapters = [
    'About Ramaze',         'introduction',
    'Features Overview',    'features',
    'Basic Principles',     'principles',
    'Installation',         'installing',
    'Getting Started',      'getting_started',
    'A couple of Examples', 'examples',
    'How to find Help',     'getting_help',
    'Appendix',             'appendix',
    'And thanks to...',     'thanks',
  ]

  File.open('doc/README', 'w+') do |readme|
    readme.puts COPYRIGHT.map{|l| l[1..-1]}, ''

    chapters.each_slice(2) do |title, file|
      file = File.join('doc', 'readme_chunks', "#{file}.txt")
      chapter = File.read(file)
      readme.puts "= #{title}", '', chapter
      readme.puts '', '' unless title == chapters[-2]
    end
  end
end

task 'tutorial2html' do
  require 'bluecloth'

  basefile = File.join('doc', 'tutorial', 'todolist')

  content = File.read(basefile + '.mkd')

  html = BlueCloth.new(content).to_html

  wrap = %{
  <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN"
    "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
  <html>
    <head>
      <title>Ramaze Tutorial: Todolist</title>
      <style>
        body {
          background: #eee;
        }
        code {
          background: #ddd;
        }
        pre code {
          background: #ddd;
          width: 70%;
          display: block;
          margin: 1em;
          padding: 0.7em;
          overflow: auto;
        }
      </style>
      <meta content="text/html; charset=UTF-8" http-equiv="content-type" />
    </head>
    <body>
      #{html}
    </body>
  </html>
  }.strip

  File.open(basefile + '.html', 'w+'){|f| f.puts(wrap) }
end

desc "Rebuild doc/tutorial/todolist.html"
task 'tutorial' => ['tutorial2html'] do
  require 'hpricot'

  system 'rake tutorial2html'

  filename = 'doc/tutorial/todolist.html'
  file = File.read(filename)
  doc = Hpricot(file)

  to_links = []

  (doc/:h2).each do |h2|
    text      = h2.inner_html
    link_id   = text.gsub(' ', '_')
    to_links << %{<a href="##{link_id}">#{text}</a>}
    to_link   = %{<a name="#{link_id}"><h2>#{text}</h2></a>}

    file.gsub!(h2.to_html, to_link)
  end

  links = to_links.join("</ol>\n    <ol>")
  h1 = "<h1>To-do List Tutorial</h1>"
  menu =
%{
  #{h1}

<div class="menu">
  <h3>Table of Contents</h3>
  <li>
    <ol>#{links}</ol>
  </li>
</div>
}

  file.gsub!(h1, menu)

  File.open(filename, 'w+') do |f|
    f.puts file
  end
end

def authors
  author_map = {
    'm.fellinger@gmail.com'                   => 'Michael Fellinger',
    'manveru@weez-int.com'                    => 'Michael Fellinger',
    'clive@crous.co.za'                       => 'Clive Crous',
    'blueonyx@dev-area.net'                   => 'Martin Hilbig',
    'rff.rff@gmail.com'                       => 'Gabriele Renzi',
    'comp.lang.zenix+ramaze@gmail.com'        => 'zenix',
    'jesuswasramazing.10.pistos@geoshell.com' => 'Pistos',
    'stephan@spaceboyz.net'                   => 'Stephan Maka',
  }

  mapping = {}
  `darcs changes`.split("\n").grep(/^\w/).each do |line|
    author = line.split[6..-1]
    email  = author.pop.gsub(/<(.*?)>/, '\1')
    name   = author.join(' ')
    name   = author_map[email] if name.empty?
    mapping[name] ||= { :email => email, :patches => 0 }
    mapping[name][:patches] += 1
  end

  max = mapping.map{|k,v| k.length}.max
  mapping.inject({}) {|h,(k,v)| h[k.ljust(max)] = v; h}
end

desc "Update /doc/AUTHORS"
task 'authors' do
  File.open('doc/AUTHORS', 'w+') do |fp|
    fp.puts "Following persons (in alphabetical order) have contributed to Ramaze:"
    fp.puts
    authors.sort_by{|k,v| k}.each do |name, author|
      fp.puts "   #{name}  -  #{author[:email]}"
    end
    fp.puts
  end
end

desc "upload packages to rubyforge"
task 'release' => ['distribute'] do
  sh 'rubyforge login'
  #sh "rubyforge add_release ramaze ramaze #{VERS} pkg/ramaze-#{VERS}.gem"

  require 'open-uri'
  require 'hpricot'

  url = "http://rubyforge.org/frs/?group_id=3034"
  doc = Hpricot(open(url))
  a = (doc/:a).find{|a| a[:href] =~ /release_id/}

  version = a.inner_html
  release_id = Hash[*a[:href].split('?').last.split('=').flatten]['release_id']

  sh "rubyforge add_file ramaze ramaze #{release_id} pkg/ramaze-#{VERS}.tar.gz"
  sh "rubyforge add_file ramaze ramaze #{release_id} pkg/ramaze-#{VERS}.tar.bz2"
end

task 'undocumented-module' do
  require 'strscan'
  require 'term/ansicolor'

  class String
    include Term::ANSIColor
  end

  class SimpleDoc
    def initialize(string)
      @s = StringScanner.new(string)
    end

    def scan
      comment = false
      total, missing = [], []
      until @s.eos?
        unless @s.scan(/^\s*#.*/)
          comment = true if @s.scan(/^=begin[^$]*$/)
          comment = false if comment and @s.scan(/^=end$/)

          unless comment
            if @s.scan(/(?:class ).*/)
              #p @s.matched
            elsif @s.scan(/(?:module ).*/)
              #p @s.matched
            elsif @s.scan(/(?:def )[\w?!*+\/-]+(?=[\(\s])/)
              total << @s.matched.split.last
              prev = @s.pre_match.split("\n")
              prev.delete_if{|s| s.strip.empty?}
              unless prev.last =~ /^\s*#.*/
                missing << @s.matched.split.last
              end
            else
              @s.scan(/./m)
            end
          end
        end
      end

      return total, missing
    end
  end

  all = {}
  files = Dir['lib/**/*.rb']

  files.each do |file|
    t, m = SimpleDoc.new(File.read(file)).scan
    all[file] = [t, m]
  end

  failed = all.reject{|k,(t,m)| m.size == 0}

  max = failed.keys.sort_by{|f| f.size}.last.size

  colors = {
    (0..25  ) => :blue,
    (25..50 ) => :green,
    (50..75 ) => :yellow,
    (75..100) => :red,
  }

  puts "\nAll undocumented methods\n\n"
  
  failed.sort.each do |file, (t, m)|
    ts, ms = t.size, m.size
    tss, mss = ts.to_s, ms.to_s
    ratio = ((ms.to_f/ts)*100).to_i
    color = colors.find{|k,v| k.include?(ratio)}.last
    complete = ms.to_f/ts.to_f
    mthc = "method"
    if ratio != 100
      puts "#{file.ljust(max)}\t[#{[mss, tss].join('/').center(8)}]".send(color)
      mthc = "methods" if ts > 1
      if $VERBOSE
        puts "Of #{tss} #{mthc}, #{mss} still needs documenting (#{100 - ratio}% documented, #{ratio}% undocumented)".send(color)
        mthc = "method"
        mthc = "methods" if ms > 1
        print "#{mthc.capitalize}: "
      end
      puts m.join(', ')
      puts
    end
  end

  puts "The colors mean percentages of documentation left (ratio of undocumented methods to total):"
  colors.sort_by{|k,v| k.begin}.each do |r, color|
    print "[#{r.inspect}] ".send(color)
  end
  puts
end

desc "list all undocumented methods"
task 'undocumented' do
	$VERBOSE = false
	Rake::Task['undocumented-module'].execute
end

desc "list all undocumented methods verbosely"
task 'undocumented-verbose' do
	$VERBOSE = true
	Rake::Task['undocumented-module'].execute
end