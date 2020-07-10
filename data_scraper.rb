require 'net/http'

HEADERS = {

}
COOKIES = {
    # "hl" => "en_GB",
    "PHPSESSID" => "570s93likrtnofot7i3ocb7am1",
    # "LONGSESS" => "U2lnbmtpY2tcRm91bmRhdGlvblxTZWN1cml0eVxBdXRoZW50aWNhdGlvblxVc2VyXFVzZXI6Ykc5MWNITjFhbUV3TTBCb2IzUnRZV2xzTG1OdmJRPT06MTczMjA5ODMzMDpkZDgxMmQ5MDgyZmRlNTZhMDkwYmRjM2JhYTMyNzlmM2U3MTk0M2UzNmZiOWQ2MzNkNTcxY2U2YTY2Y2UxZTk1",
}
ADVERT_PARTIAL_OUTPUT_FILENAME = "adverts_partial_address.csv"
ADVERT_FULL_OUTPUT_FILENAME = "adverts_full_data.csv"

def http_get_response(uri)
    req = Net::HTTP::Get.new(uri)
    HEADERS.each do |key, value|
        req[key] = value
    end
    req["Cookie"] = COOKIES.to_a.map { |key, value| "#{key}=#{value}" }.join("; ")
    res = Net::HTTP.start(uri.hostname, uri.port) do |http|
        http.request(req)
    end
    return res
end

def get_ad_http_response(numeric_id)
    uri = URI("http://buy.bubbleoutdoor.com/search/tooltip/#{numeric_id}")
    return http_get_response(uri)
end

def get_ad_details_http_response(ad_id)
    uri = URI("http://buy.bubbleoutdoor.com/popup-ad-detail/#{ad_id}/1")
    return http_get_response(uri)
end

def extract_info_from_html(numeric_id, html_text)
    info = {
        url_id: numeric_id,
        # original_text: html_text,
    }
    html_text.match(/<h5.+?>(.+?)<\/h5>/m) do |match|
        info[:ad_type] = match[1].strip
    end
    html_text.match(/<li class="fa fa-map-marker"><\/li>(.+?)<\/span>/m) do |match|
        info[:address] = match[1].strip
    end
    html_text.match(/<strong>ID:<\/strong>(.+?)<\/span>/m) do |match|
        info[:ad_id] = match[1].strip
    end
    html_text.match(/<span class="weekprice text-xlg text-weight-regular">(.+?)<\/span>/m) do |match|
        info[:week_cost] = match[1].strip.gsub(",", "").gsub("£", "")
    end
    return info
end

def add_details_from_html(info, html_text)
    address_match = html_text.match(/<i class="fa fa-map-marker"><\/i>(.+?)<\/div>/m)
    full_address = address_match.captures.first.strip
    unless full_address.empty?
        info[:address] = full_address.lines.first.chomp
        unless full_address.lines[1].nil?
            info[:postcode] = full_address.lines[1].strip.tr("()", "")
        end
    end
    return info
end

def get_ad_info(numeric_id)
    http_response = get_ad_http_response(numeric_id)
    if http_response.is_a?(Net::HTTPSuccess)
        return extract_info_from_html(numeric_id, http_response.body)
    else
        puts "Skipping #{numeric_id}."
        return nil
    end 
end

def add_ad_details(advert_data)
    http_response = get_ad_details_http_response(advert_data[:ad_id])
    if http_response.is_a?(Net::HTTPSuccess)
        add_details_from_html(advert_data, http_response.body)
    else
        if http_response.body.include?("Redirecting to <a href=\"https://buy.bubbleoutdoor.com/login")
            puts "\nCouldn't process #{advert_data[:ad_id]}. Account has been logged out. (Get new cookie)"
            exit(0)
        end
        puts "Skipping #{advert_data[:ad_id]}."
    end
end

def refresh_ad_info_file
    csv_headers = [
        "URL ID",
        "Advert Type",
        "Address",
        "Weekly Cost",
        "BubbleOutdoor ID",
    ] 
    File.open(ADVERT_PARTIAL_OUTPUT_FILENAME, 'w') do |file|
        file.puts(csv_headers.join(","))
    end
end

def refresh_ad_details_file
    csv_headers = [
        "URL ID",
        "Advert Type",
        "Address",
        "Postcode",
        "Weekly Cost",
        "BubbleOutdoor ID",
    ] 
    File.open(ADVERT_FULL_OUTPUT_FILENAME, 'w') do |file|
        file.puts(csv_headers.join(","))
    end
end

def save_ad_info(ad_info)
    File.open(ADVERT_PARTIAL_OUTPUT_FILENAME, 'a') do |file|
        url_id = ad_info[:url_id]
        ad_type = ad_info[:ad_type]
        address = ad_info[:address]
        cost = ad_info[:week_cost] || "-1"
        bubble_id = ad_info[:ad_id]
        # TODO: Make sure the output file is all valid unicode.
        # TODO: Convert HTML-safe text into normal text (eg `&amp;` -> `&`)
        file.puts("#{url_id},#{ad_type},\"#{address}\",#{cost},#{bubble_id}")
    end
end

def save_ad_details(ad_info)
    File.open(ADVERT_FULL_OUTPUT_FILENAME, 'a') do |file|
        url_id = ad_info[:url_id]
        ad_type = ad_info[:ad_type]
        address = ad_info[:address]
        postcode = ad_info[:postcode]
        cost = ad_info[:week_cost] || "-1"
        bubble_id = ad_info[:ad_id]
        # TODO: Make sure the output file is all valid unicode.
        # TODO: Convert HTML-safe text into normal text (eg `&amp;` -> `&`)
        file.puts("#{url_id},#{ad_type},\"#{address}\",#{postcode},#{cost},#{bubble_id}")
    end
end

def scrape_ad_info(refresh=false)
    refresh_ad_info_file if refresh
    1.upto(209_000) do |i|
        ad_info = get_ad_info(i)
        save_ad_info(ad_info) unless ad_info.nil?
    end
end

def scrape_ad_details(refresh=false, start_id=0)
    refresh_ad_details_file if refresh
    # start_id + 1 because the header line is also skipped
    File.foreach(ADVERT_PARTIAL_OUTPUT_FILENAME).drop(start_id+1).each do |line|
        data = line.chomp.match(/(\d+),(.+?),"(.*)",(\-?\d+),(\w+)/)
        print "\r#{data.captures[0].to_i} / 208327"
        $stdout.flush
        ad_info = {
            url_id: data.captures[0].to_i,
            ad_type: data.captures[1],
            address: data.captures[2],
            week_cost: data.captures[3].to_i,
            ad_id: data.captures[4],
        }
        if ad_info[:ad_id].start_with?("BOUK")
            add_ad_details(ad_info)
        end
        save_ad_details(ad_info)
    end
end

# If the following line is uncommented, the entire data file is reset to empty when this file is run.
# refresh_ad_info_file

# If the follwing block is uncommented, the first 200,000 adverts will be scraped and added to the file.
# scrape_ad_info

scrape_ad_details(false, 104015)





# NOTES:
=begin

This page has prices, and postcodes, and other details
https://buy.bubbleoutdoor.com/popup-ad-detail/BOUK54148378/1
Obvs replacing BOUK54148378 with the bubble_id of the advert


Started skipping at BOUK221002
Getting a 500 Internal Server Error error at
https://buy.bubbleoutdoor.com/popup-ad-detail/BOUK221002/1


2020-07-04 13:00
It looks like they've blocked the account?
Not sure when the last postcode was?
Possibly #72154
There are loads of stations, with maybe a different format of postcode which is tripping up,
but then #74064 which is the first non-station I saw also had no postcode.

2020-07-04 17:06
Looks like another account was blocked.
The last postcode was #90341 (row 77170 in `adverts_partial_address.csv`)
Make a new account and go again, I guess.

TODO: 
  - [X] Delete last invalid ones to remove duplicates
  - [X] Create new account
  - [X] Get account cookies
  - [X] Run from #74064 (line 73925) to #74121 (line 73980)
  - [X] Run from #90341 (line 77170)
  - [X] Run from #121546 (line 104015)
  - [ ] Check full results
  - [ ] Send to S and Lydia


=end

