import requests
import pandas as pd
import pyodbc


# API endpoint
url = 'https://weather.visualcrossing.com/VisualCrossingWebServices/rest/services/timeline/london/2024-01-01/2024-10-11?unitGroup=us&elements=datetime%2Clatitude%2Clongitude%2Ctemp%2Cwindspeed%2Cdescription&include=days&key=LBVACBFKYTCZKLBKQGQD29DR4&contentType=json'


# Fetch data from the API
response = requests.get(url)

if response.status_code == 200:
    data = response.json()

    latitude = data.get('latitude')
    longitude = data.get('longitude')
    location_name = data.get('resolvedAddress', 'Unknown Location')

    # Prepare weather data for insertion
    weather_data = []

    for day in data['days']:
        date = pd.to_datetime(day['datetime']).strftime('%Y-%m-%d')  # Parse and transform date to 'Year-Month-Day'
        weather_data.append((
            date,
            location_name,
            latitude,
            longitude,
            day.get('temp'),
            day.get('windspeed'),
            day.get('description')
        ))

    # Connect to SQL Server
    connection_string = (
        "Driver={ODBC Driver 17 for SQL Server};"
        "Server=DESKTOP-OHKRMHE;"
        "Database=ProductManagementDW;"
        "UID=DESKTOP-OHKRMHE\m;"
        "Trusted_Connection=yes;"
    )
    try:
        conn = pyodbc.connect(connection_string)
        cursor = conn.cursor()

        # Insert data into dpo.Dim_Weather
        insert_query = """
        INSERT INTO dbo.Dim_Weather (date, Location, Latitude, Longitude, Temperature, WindSpeed, Description)
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """
        cursor.executemany(insert_query, weather_data)

        # Commit the transaction
        conn.commit()

        print("Weather data successfully loaded into dpo.Dim_Weather.")
    except Exception as e:
        print(f"Error: {e}")
    finally:
        # Close the connection
        if conn:
            conn.close()

else:
    print(f"Failed to retrieve data. HTTP Status code: {response.status_code}")
