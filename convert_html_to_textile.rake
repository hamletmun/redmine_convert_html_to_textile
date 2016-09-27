task :convert_html_to_textile => :environment do
  convert = {
    Comment =>  [:comments],
    WikiContent => [:text],
    Issue =>  [:description],
    Message => [:content],
    News => [:description],
    Document => [:description],
    Project => [:description],
    Journal => [:notes],
  }

  count = 0
  convert.each do |the_class, attributes|
    print the_class.name
    the_class.find_each do |model|
      attributes.each do |attribute|

        html = model[attribute]
        if html != nil
          textile = convert_html_to_textile(html)
          model.update_column(attribute, textile)
        end
      end
      count += 1
      print '.'
    end
    puts
  end
  puts "Done converting #{count} models"
end

def convert_html_to_textile(html)
  require 'tempfile'

  # Pre-process
  html.gsub!(/\*/, 'preprocessedstar')
  html.gsub!(/\n/, 'preprecessedendofline')
  html.gsub!(/<pre>/, 'preprocessedpreopening')
  html.gsub!(/<\/pre>/, 'preprocessedpreclosing')
  html.gsub!(/<tr>|<tr[^>]+>/, 'preprocessedtropening')
  html.gsub!(/<td>|<td[^>]+>/, '')
  html.gsub!(/<\/td>/, 'preprocessedtdclosing')
  html.gsub!(/<\/tr>/, 'preprocessedtrclosing')
  html.gsub!(/<\/table>/, "</table>\npreprocessedtableclosing")

  # Remove problematic tags
  html.gsub!(/<\/?code>/, '')
  html.gsub!(/<p>|<p\ [^>]+>|<\/p>/, '')
  html.gsub!(/<span>|<span\ [^>]+>|<\/span>/, '')

  # HTML code for Nonbreaking space
  html.gsub!(/&nbsp;+/, ' ')

  src = Tempfile.new('src')
  src.write(html)
  src.close
  dst = Tempfile.new('dst')
  dst.close

  command = [
    'pandoc',
    '--wrap=preserve',
    '-f',
    'html',
    '-t',
    'textile',
    src.path,
    '-o',
    dst.path,
  ]
  system(*command, :out => $stdout) or raise 'pandoc failed'

  dst.open
  textile = dst.read

  # Post-process
  textile.gsub!(/preprocessedstar/, '*')
  textile.gsub!(/preprecessedendofline/, "\n")
  textile.gsub!(/preprocessedpreopening/, '<pre>')
  textile.gsub!(/preprocessedpreclosing/, '</pre>')
  textile.gsub!(/preprocessedtropening\s+/, "\n|")
  textile.gsub!(/\s+preprocessedtdclosing\s+/, '|')
  textile.gsub!(/preprocessedtrclosing\s+/, "\n")
  textile.gsub!(/preprocessedtableclosing/, "\n")

  # HTML codes
  textile.gsub!(/&quot;/, '"')
  textile.gsub!(/&gt;/, '>')
  textile.gsub!(/&lt;/, '<')
  textile.gsub!(/&#39;/, '\'')
  textile.gsub!(/&#43;/, '\+')
  textile.gsub!(/&#45;/, '-')
  textile.gsub!(/&#64;/, '@')
  textile.gsub!(/&#95;/, '_')

  # pandoc converts <a href="http://a.com">http://a.com</a> to "$":http://a.com
  textile.gsub!(/\"\$\":(\S*)\./, "\\1")

  return textile
end
