import csv


FILENAME = "adverts_full_address.csv"


advert_data_headers = []
advert_data = []
with open("adverts_2020-05-04.csv", newline="") as csv_file:
    csv_reader = csv.reader(csv_file)
    advert_data_headers = next(csv_reader)
    for row in csv_reader:
        advert_data.append(row)


leeds_adverts = [x for x in advert_data if "Leeds" in x[2]]
print(len(leeds_adverts))
