require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

url = "https://www.banyule.vic.gov.au/Services/Planning/Planning-Applications-on-Public-Notice-Advertising/Planning-Applications-on-Public-Notice-Register/"
comment_url = "mailto:enquiries@banyule.vic.gov.au"

page = agent.get(url)

nopage = true

page.search('.list-item-container a').each_with_index do |application, index|
  puts application
  puts index
  detail_page = agent.get(application.attributes['href'].to_s)
  puts application.search('p')
  puts application.search('p').inner_text
  puts application.search('p').inner_text.split(/Final da(y|te) of notice: /)
  notice_date = application.search('p').inner_text.strip.split(/Final da(y|te) of notice: /)
  puts notice_date
  record = {
    "council_reference" => detail_page.search('h3:contains("Planning Application Reference:") span').inner_text.strip.to_s,
    "address" => detail_page.search('h3:contains("Map:") span').inner_text.gsub("\u00A0", " ").strip.to_s + " VIC",
    "description" => detail_page.search('h3:contains("Description:") span').inner_text.strip.to_s,
    "info_url"    => application.attributes['href'].to_s,
    "communt_url" => comment_url,
    "date_scraped" => Date.today.to_s,
    #"on_notice_from" => DateTime.parse(notice_date[0]).to_date.to_s,
    "on_notice_to" => DateTime.parse(notice_date[1]).to_date.to_s
  }

  puts "Saving record " + record['council_reference'] + " - " + record['address']
    puts record
  ScraperWiki.save_sqlite(['council_reference'], record)
end
