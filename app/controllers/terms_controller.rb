class TermsController < ApplicationController

  def lookup
    begin
      description_index = nil
      wiki_article = Scraper.define do
        array :description
        array :image
        array :follow

        i = 0
        process "#bodyContent >p", :description=>:text do |element|          
          description_index = i if (element.to_s =~ /^<p[^>]*>[a-zA-Z]|^<p[^>]*><b/) == 0 and not description_index
          i += 1
        end
        process ".infobox img, .thumb img", :image=>"@src"
        process "#bodyContent>ul>li>a", :follow=>"@href"

        result  :image, :description, :follow
      end
      
      article = wiki_article.scrape(URI.parse("http://en.wikipedia.org/wiki/#{params['term']}"))

      # follow "may refer to:"
      if article.description and article.description.size > 0 and (article.description[description_index] =~ /may refer to:$/)
        if article.follow.length > 1
          article = wiki_article.scrape(URI.parse("http://en.wikipedia.org#{article.follow[0]}"))
        end
      end

      json = {:description => "", :image => ""}
      json[:description] = article.description[description_index].gsub(/#{160.chr}/, " ")  if article.description and article.description.size > 0
      json[:image] = article.image[0] if article.image and article.image.size > 0

      render :json => json
#    rescue
#      render :status => 400, :text => '-'# :nothing => true
    end
  end

end
