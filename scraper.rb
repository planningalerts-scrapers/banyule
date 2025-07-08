require "scraperwiki"
require "mechanize"

agent = Mechanize.new
# It looks like the morph.io server is specifically getting blocked here
# It's not just that it doesn't like non-Australian web requests
if ENV["MORPH_AUSTRALIAN_PROXY"]
  # On morph.io set the environment variable MORPH_AUSTRALIAN_PROXY to
  # http://morph:password@au.proxy.oaf.org.au:8888 replacing password with
  # the real password.
  puts "Using Australian proxy..."
  agent.agent.set_proxy(ENV["MORPH_AUSTRALIAN_PROXY"])
end

baseurl = "https://www.banyule.vic.gov.au/Planning-building/Review-local-planning-applications/Planning-applications-on-public-notice"
pageindex = 1
comment_url = "mailto:enquiries@banyule.vic.gov.au"
references_seen = Set.new
something_new = true
loop do
  something_new = false
  url = baseurl + "?dlv_BCC%20CL%20Public%20Works%20and%20Projects=(pageindex=#{pageindex})"
  page = agent.get(url)

  next_button = page.at("span.button-next input")
  next_button_disabled = next_button.nil? || next_button.attributes.member?("disabled")

  page.search(".listing-results+.list-container .list-item-container a").each do |application|
    detail_page = agent.get(application.attributes["href"].to_s)
    notice_date = application.search("p").inner_text.strip.split(/Final da(y|te) of notice: /)[2]
    notice_date = application.search("p").inner_text.strip.split(/Final da(y|te) of notice : /)[2] if notice_date.nil?
    # There was an extra spacebar in one application which caused an error, this is to avoid those moments
    header = detail_page.search("h1.oc-page-title").inner_text.strip.to_s
    council_reference = header.split(/(.*) - (.*)/)[2]
    council_reference ||= header.split(%r{(.* )(P[0-9]+/[0-9]+)})[2]

    unless council_reference
      puts "Could not extract a council_reference from: #{header}"
      puts "Skipping to next record"
      break
    end

    address = detail_page.search('p:contains("View Map")').inner_text.split("View Map")[0].gsub("\u00A0",
                                                                                                " ").strip.to_s + " VIC"

    record = {
      "council_reference" => council_reference.to_s,
      "address" => address,
      "description" => detail_page.search(".project-details-list+p").inner_text.strip.to_s,
      "info_url" => application.attributes["href"].to_s,
      "comment_url" => comment_url,
      "date_scraped" => Date.today.to_s,
      "on_notice_to" => DateTime.parse(notice_date).to_date.to_s,
    }

    puts "Saving record " + record["council_reference"] + " - " + record["address"]
    # puts record
    ScraperWiki.save_sqlite(["council_reference"], record)
    something_new ||= !references_seen.include?(record["council_reference"])
    references_seen.add record["council_reference"]
  end

  if next_button_disabled
    puts "Exiting on last page (no Next button)"
    break
  elsif !something_new
    puts "Exiting as there was nothing new on this page (infinite loop?)"
    break
  end
  pageindex += 1
  puts "Continuing to page #{pageindex}"
end
