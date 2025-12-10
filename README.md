# Banyule City Council Scraper

* Server - Unknown
* Cookie tracking - No
* Pagnation - No
* Javascript - No
* Clearly defined data within a row - Yes
* Scrape detail page - Yes

Enjoy

This is a scraper that runs on [Morph](https://morph.io). To get started [see the documentation](https://morph.io/documentation)

Add any issues to https://github.com/planningalerts-scrapers/issues/issues

## To run the scraper

    bundle exec ruby scraper.rb

Set `MORPH_AUSTRALIAN_PROXY` to the url for an Australian proxy

## Error handling

The scraper will
* warn if it was unable to extract the council reference and skip to the next page
* warn if it was unable to extract the address from the details page and skip to the next entry on the same page
* stop retrieving pages if no records where found or no next page link is present
* Return a non-zero status at the end of run if any warnings occurred during the run
  so morph can alert the scaper owner 

### Expected output

    Saving record P820/2025 - 3 Hebden Street, Greensborough 3088 VIC
    Saving record P1288/2015 PT3 - 4/37 The Concord, Bundoora 3083 VIC
    (etc)
    Saving record P703/2025 - 17 Bruce Street, Greensborough 3088 VIC
    Saving record P968/2025 - 47 Greville Road, Rosanna 3084 VIC

    Continuing to page 2
    Saving record P676/2025 pt1 - 29 Timor Parade, Heidelberg West 3081 VIC
    Saving record P316/2025 - 18-28 Irvine Road, Ivanhoe 3079 VIC
    (etc)
    Saving record P497/2025 - 276 Oriel Road, Heidelberg West 3081 VIC
    Saving record P851/2025 - 201 Waiora Road, Heidelberg Heights 3081 VIC

    Continuing to page 3
    Saving record P382/2025 - 3 Carisbrook Crescent, Lower Plenty 3093 VIC
    (etc)

Execution time under a minute

## To run style and coding checks

    bundle exec rubocop

## To check for security updates

    gem install bundler-audit
    bundle-audit
