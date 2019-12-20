require 'scraperwiki'
require 'mechanize'

agent = Mechanize.new

baseurl = "https://www.banyule.vic.gov.au/Planning-building/Review-local-planning-applications/Advertised-planning-applications"
pageindex=1
comment_url = "mailto:enquiries@banyule.vic.gov.au"

url = baseurl + "?dlv_OC%20CL%20Public%20Works%20and%20Projects=(pageindex=#{pageindex})"
loop do
  page = agent.get(url)
  
  page.search('.listing-results+.list-container .list-item-container a').each_with_index do |application, index|
    detail_page = agent.get(application.attributes['href'].to_s)
    notice_date = application.search('p').inner_text.strip.split(/Final da(y|te) of notice: /)[2]
    header = detail_page.search('h1.oc-page-title').inner_text.strip.to_s
    council_reference = header.split(/(.*) - (.*)/)[2].to_s
    unless council_reference do
      puts "Fallback council_reference finding: #{header}"
      council_reference = header.split(/(.* )(P[0-9]+\/[0-9]{4})/)[1].to_s
      puts "Found #{council_reference}"
    end
    address = detail_page.search('p:contains("View Map")').inner_text.split("View Map")[0].gsub("\u00A0", " ").strip.to_s + " VIC"
  
    record = {
      "council_reference" => council_reference,
      "address" => address,
      "description" => detail_page.search('.project-details-list+p').inner_text.strip.to_s,
      "info_url"    => application.attributes['href'].to_s,
      "comment_url" => comment_url,
      "date_scraped" => Date.today.to_s,
      "on_notice_to" => DateTime.parse(notice_date).to_date.to_s
    }

    puts "Saving record " + record['council_reference'] + " - " + record['address']
      #puts record
    ScraperWiki.save_sqlite(['council_reference'], record)
  end
  
  next_link = page.search("a.page-link.next").attributes['href'].to_s.split(/.page-/)[1]
  
  puts next_link
  break unless next_link
  url = baseurl + "?dlv_OC%20CL%20Public%20Works%20and%20Projects=(pageindex=#{next_link})"
end
