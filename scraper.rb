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

def strip_whitespace(str)
  str.to_s.gsub("\u00A0", " ").strip
end

baseurl = "https://www.banyule.vic.gov.au/Planning-building/Review-local-planning-applications/Planning-applications-on-public-notice"
pageindex = 1
comment_url = "mailto:enquiries@banyule.vic.gov.au"
references_seen = Set.new
exit_status = 0
loop do
  something_new = false
  url = baseurl + "?dlv_BCC%20CL%20Public%20Works%20and%20Projects=(pageindex=#{pageindex})"
  page = agent.get(url)

  next_button = page.at("span.button-next input")
  next_button_disabled = next_button.nil? || next_button.attributes.member?("disabled")

  page.search(".listing-results+.list-container .list-item-container a").each do |application|
    # Get the detail page for each application
    info_url = application.attributes["href"].to_s
    if info_url !~ %r{https?://.*\..*\..*/}
      warn "WARNING: info_url is not a valid URL: #{info_url}"
      warn "  [Skipping to next application]"
      exit_status = 4
      next
    end
    # puts "Retrieving detail page: #{info_url}"
    detail_page = agent.get(info_url)
    begin
      notice_date = strip_whitespace(application.search("p").inner_text).split(/Final da(y|te) of notice: /)[2]
      if notice_date.nil?
        notice_date = strip_whitespace(application.search("p").inner_text).split(/Final da(y|te) of notice : /)[2]
      end
      # There was an extra spacebar in one application which caused an error, this is to avoid those moments
      header = strip_whitespace(detail_page.search("h1.oc-page-title").inner_text)
      council_reference = header.split(/(.*) - (.*)/)[2]
      council_reference ||= header.split(%r{(.* )(P[0-9]+/[0-9]+)})[2]

      if council_reference.to_s == ""
        warn "WARNING: Could not extract a council_reference from: #{header} from:\n  #{url}"
        warn "  [Skipping to next page]"
        exit_status = 1
        break
      end
      p_view_map_split = detail_page.search('p:contains("View Map")').inner_text.split("View Map")
      unless p_view_map_split&.any?
        warn "WARNING: Unable to extract address from detail page (no map view?) from:\n  #{info_url}"
        warn "  [Skipping to next application]"
        exit_status = 3
        next
      end
      address = strip_whitespace p_view_map_split[0]
      if address.size < 5
        warn "WARNING: Address is too small to be realistic (#{address.size} characters): #{address} from:\n  #{info_url}"
      else
        address = "#{address} VIC"
      end

      description_parts = []
      detail_page.search("p strong").each do |strong_elem|
        para = strong_elem.parent
        sibling = para.next_element
        next unless para.name == "p" && sibling&.name == "ul"

        heading = strip_whitespace para.inner_text
        next if heading.empty?

        description_parts << "" unless description_parts.empty?
        description_parts << heading

        # Add each list item
        sibling.search("li").each do |li|
          description_parts << "* #{strip_whitespace li.inner_text}"
        end
      end

      if description_parts.empty?
        warn "WARNING: Could not extract a description from:\n  #{info_url}"
        warn "  [Passing to planning alert so it logs it as well]"
      end
      description = description_parts.join("\n").strip

      record = {
        "council_reference" => council_reference.to_s,
        "address" => address,
        "description" => description,
        "info_url" => info_url,
        "comment_url" => comment_url,
        "date_scraped" => Date.today.to_s,
        "on_notice_to" => DateTime.parse(notice_date).to_date.to_s,
      }
    rescue StandardError => e
      warn "WARNING: Unable to extract details: #{e}"
      warn "  [Skipping to next record]"
      exit_status = 2
      next
    end

    puts "Saving record #{record['council_reference']} - #{record['address']}"
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
  puts "", "Continuing to page #{pageindex}"
end
puts "Finished #{exit_status.zero? ? 'successfully' : "with errors, exit status #{exit_status}"}"
exit(exit_status)
