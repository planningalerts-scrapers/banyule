require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

url = "https://www.banyule.vic.gov.au/Services/Planning/Planning-Applications-on-Public-Notice-Advertising/Planning-Applications-on-Public-Notice-Register/"
comment_url = "mailto:enquiries@banyule.vic.gov.au"

page = agent.get(url)

page.search('table a').each_with_index do |application, index|
  unless index == 0
    detail_page = agent.get(application.attributes['href'].to_s)

    notice_date = detail_page.search('h3:contains("Period of Notice:") span').inner_text.strip.to_s
    notice_date = notice_date.split(' to ')

    record = {
      "council_reference" => detail_page.search('h3:contains("Planning Application Reference:") span').inner_text.strip.to_s,
      "address" => detail_page.search('h3:contains("Map:") span').inner_text.gsub("\u00A0", " ").strip.to_s + " VIC",
      "description" => detail_page.search('h3:contains("Description:") span').inner_text.strip.to_s,
      "info_url"    => application.attributes['href'].to_s,
      "communt_url" => comment_url,
      "date_scraped" => Date.today.to_s,
      "on_notice_from" => DateTime.parse(notice_date[0]).to_date.to_s,
      "on_notice_to" => DateTime.parse(notice_date[1]).to_date.to_s
    }

    if (ScraperWiki.select("* from data where `council_reference`='#{record['council_reference']}'").empty? rescue true)
      puts "Saving record " + record['council_reference'] + " - " + record['address']
#      puts record
      ScraperWiki.save_sqlite(['council_reference'], record)
    else
      puts "Skipping already saved record " + record['council_reference']
    end
  end
end
