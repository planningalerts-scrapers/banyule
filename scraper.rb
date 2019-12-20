require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

url = "https://www.banyule.vic.gov.au/Services/Planning/Planning-Applications-on-Public-Notice-Advertising/Planning-Applications-on-Public-Notice-Register/"
comment_url = "mailto:enquiries@banyule.vic.gov.au"

page = agent.get(url)

nopage = true

page.search('.listing-results+.list-container .list-item-container a').each_with_index do |application, index|
  detail_page = agent.get(application.attributes['href'].to_s)
  notice_date = application.search('p').inner_text.strip.split(/Final da(y|te) of notice: /)[2]
  address_and_reference = application.search('h3 .oc-page-title').inner_text.strip.to_s
  address = address_and_reference.split(/(.*) - (.*)/)[0].to_s
  council_reference = address_and_reference.split(/(.*) - (.*)/)[1].to_s

  record = {
    "council_reference" => council_reference,
    "address" => address + " VIC",
    "description" => detail_page.search('h3:contains("Description:") span').inner_text.strip.to_s,
    "info_url"    => application.attributes['href'].to_s,
    "comment_url" => comment_url,
    "date_scraped" => Date.today.to_s,
    #"on_notice_from" => DateTime.parse(notice_date[0]).to_date.to_s,
    "on_notice_to" => DateTime.parse(notice_date).to_date.to_s
  }

  puts "Saving record " + record['council_reference'] + " - " + record['address']
    puts record
  ScraperWiki.save_sqlite(['council_reference'], record)
end
