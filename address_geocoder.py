import json
import csv
from pathlib import Path
from typing import Optional, Tuple

from geopy.geocoders import GoogleV3
from geopy.exc import GeopyError


QUERY_TIMEOUT_WAIT = 10
CACHE_FILENAME_ADDRESS = "geocode_cache_address.json"
API_KEY_FILEPATH = Path(__file__).parent.absolute() / "api_key_geocoding_google.txt"


geocode_service = None
try:
    with open(API_KEY_FILEPATH) as key_file:
        geocode_service = GoogleV3(api_key=key_file.read())
except IOError:
    logger.error(f"Could not read the API key file '{API_KEY_FILEPATH}'.")

cache_lat_long = {}
cache_address = {}
country_hint: Optional[str] = None


def load_cache():
    if Path(CACHE_FILENAME_ADDRESS).is_file():
        with open(CACHE_FILENAME_ADDRESS, 'r', encoding="utf-8") as cache_file:
            json_object = json.loads(cache_file.read())
            for key in json_object:
                input_string = key
                address = json_object[key]
                cache_address.update({input_string: address})


def save_cache():
    with open(CACHE_FILENAME_ADDRESS, 'w', encoding="utf-8") as cache_file:
        json.dump(cache_address, cache_file, indent=4)


def geocode_query(address_string):
    result = None
    if geocode_service is None:
        logger.error("There is no geocoding service set up to use.")
    else:
        try:
            result = geocode_service.geocode(address_string + f", {country_hint}",
                                             timeout=QUERY_TIMEOUT_WAIT, region=country_hint)
        except GeopyError as error:
            print(str(error))
    return result


def cache_result(input_string, result):
    cache_lat_long[input_string] = (result.latitude, result.longitude)
    cache_address[input_string] = result.address


def get_location(address_string):
    location = geocode_query(address_string)
    if location:
        cache_result(address_string, location)
        return location
    return None


def get_address(address_string: str) -> Optional[str]:
    saved_result = cache_address.get(address_string)
    if saved_result:
        return saved_result
    location = get_location(address_string)
    if location:
        return location.address
    else:
        print(f"Could not find address for '{address_string}'")
        return None


INPUT_FILENAME = "adverts_partial_address.csv"
OUTPUT_FILENAME = "adverts_full_address.csv"
ADDRESS_COLUMN_INDEX = 2


if __name__ == "__main__":
    load_cache()
    with open(INPUT_FILENAME, newline="") as csv_file:
        csv_reader = csv.reader(csv_file)
        header_row = next(csv_reader)
        header_row.append("Full Address")
        with open(OUTPUT_FILENAME, 'w', newline="") as output_file:
            csv_writer = csv.writer(output_file)
            csv_writer.writerow(header_row)
            i = 1
            for row in csv_reader:
                partial_address = row[ADDRESS_COLUMN_INDEX]
                full_address = get_address(partial_address)
                if full_address:
                    row.append(f"{full_address}")
                else:
                    row.append("")
                csv_writer.writerow(row)
                print(f"\r{i}", flush=True, end="")
                i += 1
                save_cache()
    print("Done")

