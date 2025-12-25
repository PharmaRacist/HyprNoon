#!/usr/bin/env python3
"""
Weather Fetcher - Simple weather data from wttr.in
Usage: ./weather.py <city> [--fahrenheit]
"""


import json
import sys
from urllib.request import urlopen, Request
from datetime import datetime, timedelta


# ============= CONFIGURATION =============
TIMEOUT = 10
API_URL = "https://wttr.in"
USER_AGENT = "curl/7.68.0"
# =========================================



def time_to_minutes(time_str):
    """Convert time to minutes (handles both 12-hour and 24-hour format)."""
    time_str = time_str.strip()
    
    # Handle 12-hour format (e.g., "06:30 AM")
    if "AM" in time_str or "PM" in time_str:
        time_part = time_str.replace("AM", "").replace("PM", "").strip()
        h, m = time_part.split(":")
        hours = int(h)
        minutes = int(m)
        
        # Convert to 24-hour format
        if "PM" in time_str and hours != 12:
            hours += 12
        elif "AM" in time_str and hours == 12:
            hours = 0
            
        return hours * 60 + minutes
    
    # Handle 24-hour format (e.g., "14:30")
    h, m = time_str.split(":")
    return int(h) * 60 + int(m)



def is_night(sunrise, sunset, current):
    """Check if it's nighttime."""
    now = time_to_minutes(current)
    return now < time_to_minutes(sunrise) or now > time_to_minutes(sunset)



def format_date(date_str):
    """Format date to day name."""
    date = datetime.strptime(date_str, "%Y-%m-%d").date()
    today = datetime.now().date()
    
    if date == today:
        return "Today"
    if date == today + timedelta(days=1):
        return "Tomorrow"
    return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][date.weekday()]



def get_icon(condition, night):
    """Get weather icon name."""
    c = condition.lower()
    
    if "clear" in c:
        return "clear_night" if night else "partly_cloudy_day"
    if "partly" in c:
        return "cloudy" if night else "partly_cloudy_day"
    if "cloud" in c or "overcast" in c:
        return "cloud"
    if "fog" in c or "mist" in c:
        return "foggy"
    if "rain" in c or "drizzle" in c:
        return "rainy"
    if "snow" in c:
        return "ac_unit"
    if "thunder" in c:
        return "thunderstorm"
    
    return "cloudy"



def fetch_weather(city, fahrenheit=False):
    """Fetch weather data."""
    try:
        url = f"{API_URL}/{city}?format=j1"
        req = Request(url, headers={"User-Agent": USER_AGENT})
        
        with urlopen(req, timeout=TIMEOUT) as response:
            data = json.loads(response.read().decode())
        
        # Extract data
        current = data["current_condition"][0]
        astro = data["weather"][0]["astronomy"][0]
        area = data.get("nearest_area", [{}])[0]
        
        # Get location
        name = area.get("areaName", [{}])[0].get("value", city)
        country = area.get("country", [{}])[0].get("value", "")
        location = f"{name}, {country}" if country else name
        
        # Units
        temp_unit = "°F" if fahrenheit else "°C"
        wind_unit = "mph" if fahrenheit else "km/h"
        vis_unit = "mi" if fahrenheit else "km"
        
        # Current weather
        condition = current["weatherDesc"][0]["value"]
        time_str = current["localObsDateTime"].split()[1][:5]
        night = is_night(astro["sunrise"], astro["sunset"], time_str)
        
        temp = current["temp_F"] if fahrenheit else current["temp_C"]
        feels = current["FeelsLikeF"] if fahrenheit else current["FeelsLikeC"]
        wind = int(current["windspeedKmph"])
        if fahrenheit:
            wind = round(wind * 0.621371)
        vis = int(current["visibility"])
        if fahrenheit:
            vis = round(vis * 0.621371)
        
        # Forecast
        forecast = []
        for day in data["weather"][1:5]:
            hourly = day["hourly"][4]
            cond = hourly["weatherDesc"][0]["value"]
            max_t = int(day["maxtempF"] if fahrenheit else day["maxtempC"])
            min_t = int(day["mintempF"] if fahrenheit else day["mintempC"])
            
            forecast.append({
                "date": format_date(day["date"]),
                "max_temp": f"{max_t}{temp_unit}",
                "min_temp": f"{min_t}{temp_unit}",
                "avg_temp": f"{round((max_t + min_t) / 2)}{temp_unit}",
                "condition": cond,
                "emoji": get_icon(cond, False),
                "sunrise": day["astronomy"][0]["sunrise"],
                "sunset": day["astronomy"][0]["sunset"],
                "uv_index": day.get("uvIndex", "N/A"),
                "chance_of_rain": f"{hourly['chanceofrain']}%"
            })
        
        return {
            "location": location,
            "sunrise": astro["sunrise"],
            "sunset": astro["sunset"],
            "current_temp": f"{temp}{temp_unit}",
            "current_emoji": get_icon(condition, night),
            "current_condition": condition,
            "feels_like": f"{feels}{temp_unit}",
            "humidity": f"{current['humidity']}%",
            "wind_speed": f"{wind} {wind_unit}",
            "visibility": f"{vis} {vis_unit}",
            "forecast": forecast
        }
        
    except Exception as e:
        return {"error": str(e)}



def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "Usage: weather.py <city> [--fahrenheit]"}))
        sys.exit(1)
    
    city = sys.argv[1]
    fahrenheit = "--fahrenheit" in sys.argv or "-f" in sys.argv
    
    weather = fetch_weather(city, fahrenheit)
    print(json.dumps(weather))



if __name__ == "__main__":
    main()