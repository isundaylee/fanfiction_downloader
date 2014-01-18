class Downloader

  require 'nokogiri'
  require 'open-uri'
  require 'gepub'

  require_relative 'readability_parser'

  HOME_URL = 'https://www.fanfiction.net/s/%d/%d'

  @@parser = ReadabilityParser.new('b8b61c5e318150118a489d72e09f63d85a654cfe')
  @@template = File.read(File.join(File.dirname(__FILE__), 'template.html'))

  def self.download_chapter(id, cid, out_dir)
    url = url(id, cid)
    parsed = @@parser.parse(url)
    page = open(url).read

    content = parsed['content']
    match = page.match(/<option value=[0-9]* selected>([^<]*)/)
    if match
      p_title = match[1].strip
    else
      match = page.match(/<b class='xcontrast_txt'>(.*)<\/b>/)
      p_title = '1. ' + match[1].strip
    end
    w_title = ('0' * (3 - cid.to_s.length)) + p_title
    filename = File.join(out_dir, "#{w_title}.html")

    File.write(filename, @@template.gsub('%title', p_title).gsub('%content', content))
  end

  def self.download(id, out_dir)
    home_url = url(id, 1)
    home_page = open(home_url).read
    match = /Chapters: ([0-9]*)/.match(home_page)
    chapters = match ? match[1].to_i : 1

    FileUtils.mkdir_p(out_dir)

    1.upto(chapters) do |cid|
      puts "Downloading chapter #{cid}"
      content = self.download_chapter(id, cid, out_dir)
    end
  end

  def self.epubify(id, out_dir)
    url = url(id, 1)
    page = open(url).read
    title = page.match(/<title>(.*?)<\/title>/)[1]
    author = page.match(/By:<\/span> <a class='xcontrast_txt' href='\/u\/[0-9]*\/[^']*'>([^<]*)<\/a>/)[1].strip

    match = /(.*)Chapter/.match(title)
    s_title = ''
    if match
      s_title = match[1].strip
    else
      match = /(.*), a harry potter fanfic/.match(title)
      s_title = match[1].strip
    end
    out_name = File.join(out_dir, "#{s_title}.epub")

    FileUtils.mkdir_p '/tmp/epubs'

    builder = GEPUB::Builder.new {
      unique_identifier url, id, url
      title s_title
      creator author

      date DateTime.now.to_s
      pages = Dir[File.join(Dir.getwd, out_dir, '*.html')].map do |f|
        {file: f, title: f.match(/[0-9]{3}\. (.*).html/)[1].strip}
      end

      resources(:workdir => '/tmp/epubs') {
        ordered {
          pages.each do |p|
            file p[:file]
            heading p[:title]
          end
        }
      }
    }

    builder.generate_epub(out_name)
  end

  def self.cleanup(out_dir)
    Dir[File.join(out_dir, '*.html')].each do |f|
      FileUtils.rm f
    end
  end

  private

    def self.url(id, page)
      HOME_URL % [id, page]
    end

end
