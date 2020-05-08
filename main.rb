require 'net/http'

HEADERS = {

}
COOKIES = {
    # "hl" => "en_GB",
    # "PHPSESSID" => "fc8mo1kphec4une6bh3njemci0",
    "LONGSESS" => "U2lnbmtpY2tcRm91bmRhdGlvblxTZWN1cml0eVxBdXRoZW50aWNhdGlvblxVc2VyXFVzZXI6Ykc5MWNITjFhbUV3TTBCb2IzUnRZV2xzTG1OdmJRPT06MTczMjA5ODMzMDpkZDgxMmQ5MDgyZmRlNTZhMDkwYmRjM2JhYTMyNzlmM2U3MTk0M2UzNmZiOWQ2MzNkNTcxY2U2YTY2Y2UxZTk1",
}
OUTPUT_FILENAME = "adverts.csv"

def get_ad_http_response(id)
    uri = URI("http://buy.bubbleoutdoor.com/search/tooltip/#{id}")
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

def extract_info_from_html(id, html_text)
    info = {
        url_id: id,
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
        info[:week_cost] = match[1].strip
    end
    return info
end

def get_ad_info(id)
    http_response = get_ad_http_response(id)
    if http_response.is_a?(Net::HTTPSuccess)
        return extract_info_from_html(id, http_response.body)
    else
        puts "Skipping #{id}."
        return nil
    end 
end

def refresh_ad_info_file
    File.open(OUTPUT_FILENAME, 'w') do |file|
        file.puts("URL ID, Advert Type, Address, Weekly Cost, BubbleOutdoor ID")
    end
end

def save_ad_info(ad_info)
    File.open(OUTPUT_FILENAME, 'a') do |file|
        url_id = ad_info[:url_id]
        ad_type = ad_info[:ad_type]
        address = ad_info[:address]
        cost = ad_info[:week_cost] || "-1"
        bubble_id = ad_info[:ad_id]
        file.puts("#{url_id},#{ad_type},\"#{address}\",#{cost},#{bubble_id}")
    end
end

# If the following line is uncommented, the entire data file is reset to empty when this file is run.
# refresh_ad_info_file

1.upto(200_000) do |i|
    ad_info = get_ad_info(i)
    save_ad_info(ad_info) unless ad_info.nil?
end
