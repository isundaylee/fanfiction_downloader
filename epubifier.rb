class Epubifier

  require 'gepub'

  def self.epubify(title, author, url, contents, output)
   FileUtils.mkdir_p '/tmp/epubs'

   builder = GEPUB::Builder.new {
     unique_identifier url, url, url
     title title
     creator author

     date DateTime.now.to_s

     resources(:workdir => '/tmp/epubs') {
       ordered {
         contents.each do |p|
           file p[:file]
           heading p[:title]
         end
       }
     }
   }

   builder.generate_epub(output)
  end

end