import requests
from datetime import datetime


def get_sunspot_count(date: str) -> int:
    """
    Retrieve the number of sunspots for a given year and month.

    Parameters:
        date (str): The date in 'YYYY-MM' format.

    Returns:
        int: Number of sunspots on the given date, or -1 if an error occurs.
    """
    # Validate the date format
    try:
        datetime.strptime(date, '%Y-%m')
    except ValueError:
        print("Error: Incorrect date format. Please use 'YYYY-MM'.")
        return -1

    # SIDC API URL
    api_url = f"https://services.swpc.noaa.gov/json/solar-cycle/observed-solar-cycle-indices.json"

    try:
        # Make the request
        response = requests.get(api_url)

        # Check if the response was successful
        if response.status_code == 200:
            data = response.json()
            # Find the entry for the specified date
            for entry in data:
                if entry['time-tag'].startswith(date):
                    return entry.get('ssn', -1)  # return sunspot number if available
            print(f"No data available for the date: {date}")
            return -1
        else:
            print(f"Error: Unable to retrieve data (Status code: {response.status_code})")
            return -1
    except Exception as e:
        print(f"Exception occurred: {e}")
        return -1


# Example usage
date = "2024-11"  # replace with your desired date
sunspot_count = get_sunspot_count(date)
print(f"Sunspot count on {date}: {sunspot_count}")