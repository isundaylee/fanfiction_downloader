require 'bundler/setup'

class PortkeyDownloader

  require 'nokogiri'
  require 'open-uri'
  require 'fileutils'

  require_relative 'readability_parser'
  require_relative 'epubifier'

  URL_REGEX = /http:\/\/fanfiction.portkey.org\/story\/([0-9]*)/
  URL = 'http://fanfiction.portkey.org/index.php?act=read&storyid=%d&chapterid=%d&agree=1'

  @@parser = ReadabilityParser.new('b8b61c5e318150118a489d72e09f63d85a654cfe')
  @@template = File.read('template.html')

  def initialize(url)
    @url = url
    @id = URL_REGEX.match(@url)[1].to_i
    @url = URL % [@id, 1]
  end

  def download(out_dir)
    FileUtils.mkdir_p(out_dir)
    @chapters = download_content('/tmp/portkey_downloader')
    epubify(File.join(out_dir, "#{retrieve_metas[:title]}.epub"))
  end

  def epubify(output)
    puts "正在整合成电子书至 #{output}"
    meta = retrieve_metas

    pages = (1..@chapters).collect do |c|
      {
        file: "/tmp/portkey_downloader/#{c}.html",
        title: "Chapter #{c}"
      }
    end

    puts @chapters

    Epubifier.epubify(meta[:title], meta[:author], @url, pages, output)
  end

  def check
    URL_REGEX =~ @url
  end

  def download_content(out_dir)
    FileUtils.rm_rf(out_dir)
    FileUtils.mkdir_p(out_dir)

    current_chapter = 1

    while true
      break unless download_chapter(current_chapter, File.join(out_dir, "#{current_chapter}.html"))
      current_chapter += 1
    end

    @chapters = current_chapter - 1
  end

  def retrieve_metas
    return @metas if @metas

    page = Nokogiri::HTML(open(@url).read)

    @metas = {
      title: page.at_css('td.normallh strong font em').text,
      author: page.at_css('td.normallh a').text
    }
  end

  def download_chapter(chapter, out_file)
    puts "正在下载第 #{chapter} 章至 #{out_file}"

    url = URL % [@id, chapter]
    page = Nokogiri::HTML(open(url).read)
    content = page.to_s
    content.encode!('UTF-8', 'binary', invalid: :replace, undef: :replace, replace: '')

    return false if (/Chapter does not exist!/ =~ content)

    content = @@parser.parse(url)["content"]
    html = @@template.gsub('%title', retrieve_metas[:title]).gsub('%content', content)

    File.write(out_file, html)

    true
  end

end
