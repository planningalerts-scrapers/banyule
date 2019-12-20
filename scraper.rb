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
  header = detail_page.search('h1 .oc-page-title').inner_text.strip.to_s
  council_reference = header.split(/(.*) - (.*)/)[1].to_s
  puts detail_page.search('p:contains("View Map")').inner_text.split"View Map")[0]
  puts detail_page.search('p:contains("View Map")').inner_text.split"View Map")[0].strip
  address = detail_page.search('p:contains("View Map")').inner_text.gsub("\u00A0", " ").strip.to_s + " VIC",

  record = {
    "council_reference" => council_reference,
    "address" => address,
    "description" => detail_page.search('.main-content p:first-of-type').inner_text.strip.to_s,
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
