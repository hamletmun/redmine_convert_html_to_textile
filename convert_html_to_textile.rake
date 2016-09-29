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

  html.gsub!(/<pre>(.*?)<\/pre>/m) do |match|
    match.gsub!(/<\/?code>/, '')
    match.gsub!(/\n/, 'preprocessedlinefeed')
    match.gsub(/<\/?p>|<p [^>]*>/, '')
  end

  html.gsub!(/<blockquote>(.*?)<\/blockquote>/m) do |match|
    match.gsub!(/\n/, 'preprocessedlinefeed')
    match.gsub(/<\/?p>|<p [^>]*>/, '')
  end

  html.gsub!(/<li\ [^>]+>/, '<li>')
  html.gsub!(/<ol\ [^>]+>/, '<ol>')
  html.gsub!(/<ul\ [^>]+>/, '<ul>')

  html.gsub!(/<li>(.*?)<\/li>/m) do |match|
    match.gsub(/<\/?p>|<p [^>]*>/, '')
  end

  html.gsub!(/<table(.*?)<\/table>/m) do |match|
    match.gsub!(/<tr>|<tr[^>]*>/, 'preprocessedtropening')
    match.gsub!(/<th>|<td>|<td[^>]*>/, '')
    match.gsub!(/<\/th>|<\/td>/, 'preprocessedtdclosing')
    match.gsub!(/<\/tr>/, '')
    match.gsub(/<\/?p>|<p [^>]*>/, '')
  end
  html.gsub!(/<\/table>/, "</table>\npreprocessedtableclosing")

  # Pre-process
  html.gsub!(/\*/, 'preprocessedstar')
  html.gsub!(/<pre>/, "preprocessedpreopening")
  html.gsub!(/<\/pre>/, "preprocessedpreclosing")

  # Remove problematic tags
  html.gsub!(/<\/?div[^>]*?>/, '')
  html.gsub!(/<\/?span[^>]*?>/, '')
  html.gsub!(/<\/?address[^>]*?>/, '')

  # HTML code for Nonbreaking space
  html.gsub!(/&nbsp;+/, ' ')


#  return html
#end
#def test

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
  textile.gsub!(/preprocessedlinefeed/, "\n")
  textile.gsub!(/preprocessedpreopening/, '<pre>')
  textile.gsub!(/preprocessedpreclosing/, '</pre>')
  textile.gsub!(/ *<pre> */, '<pre>')
  textile.gsub!(/ *<\/pre> */, '</pre>')
  textile.gsub!(/(\S+)<pre>/, "\\1\n<pre>")
  textile.gsub!(/(\S+)<\/pre>/, "\\1\n<\/pre>")
  textile.gsub!(/preprocessedtropening\s+?/, "\n|")
  textile.gsub!(/\s*?preprocessedtdclosing\s+?/, '|')
  textile.gsub!(/preprocessedtableclosing/, "\n")

  # HTML codes
  textile.gsub!(/&amp;/, '&')
  textile.gsub!(/&quot;/, '"')
  textile.gsub!(/&gt;/, '>')
  textile.gsub!(/&lt;/, '<')
  textile.gsub!(/&#39;/, '\'')
  textile.gsub!(/&#43;/, '\+')
  textile.gsub!(/&#45;/, '-')
  textile.gsub!(/&#64;/, '@')
  textile.gsub!(/&#95;/, '_')
  textile.gsub!(/&#124;/, '|')

  # pandoc converts <a href="http://a.com">http://a.com</a> to "$":http://a.com
  textile.gsub!(/\"\$\":(\S*)\.?/, "\\1")

  textile.gsub!(/<blockquote>(.*?)<\/blockquote>/m) do |match|
    match.gsub(/^/, ">\ ")
  end
  textile.gsub!(/<\/?blockquote>/, '')

  textile.gsub!(/"":/, '')

  return textile
end
