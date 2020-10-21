import requests
import xlrd
import xlwt
from xlwt import Workbook

def main():
    # Reading an excel file using Python and Write the Data to excel File
    #Api Key
    api_key_file = open("Api-Key.txt",'r')
    api_key = api_key_file.read()
    api_key_file.close()

    url = "https://maps.googleapis.com/maps/api/distancematrix/json?units=imperial&"
    # Give the location of the file
    # To open Workbook
    wb = xlrd.open_workbook('CityListName.xlsx')
    wbs = Workbook()
    # add_sheet is used to create sheet.
    sheet1 = wbs.add_sheet('destinations')
    sheet2 = wbs.add_sheet('Time')
    sheet = wb.sheet_by_index(0)

    destinations = ""
    # For row 0 and column 0
    CitiesArray = []
    for i in range(sheet.nrows):
        CitiesArray.append((sheet.cell_value(i, 0)))
        destinations = destinations + CitiesArray[i]
        if i != sheet.nrows - 1:
            destinations = destinations + '|'
    for i in range(sheet.nrows):
        r = requests.get(url + "origins=" + CitiesArray[i] + "&destinations=" + destinations + "&key=" + api_key)
        sheet1.write(i+1, 0, CitiesArray[i].split(",")[0])
        sheet1.write(0, i+1, CitiesArray[i].split(",")[0])
        sheet2.write(i+1, 0, CitiesArray[i].split(",")[0])
        sheet2.write(0, i+1, CitiesArray[i].split(",")[0])
        for j in range(sheet.nrows):
            dis = r.json()["rows"][0]["elements"][j]["distance"]["value"]
            times = r.json()["rows"][0]["elements"][j]["duration"]["value"]
            sheet1.write(i+1, j+1, dis / 1000)
            sheet2.write(i+1, j+1, times / 3600)
    wbs.save('ProjectData.xls')

if __name__ == "__main__":
    main()