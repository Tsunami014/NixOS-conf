import json
import os
import time
import urllib.parse
import urllib.request

OUT = os.path.expanduser("~/.cache/weather.json")
INTERVAL = 300
FAIL_INTERVAL = 60

FAIL_ICON = "󰼯"
SUNNY, NIGHT = "󰖙", "󰖔"
PARTLY, PARTLY_NIGHT = "󰖕", "󰼱"
CLOUDY, FOG = "󰖐", "󰖑"
RAIN, POURING = "󰖗", "󰖖"
SNOW, STORM = "󰖘", "󰖓"

# WMO weather code -> (description, day icon, night icon)
CODES = {
    0: ("Clear", SUNNY, NIGHT),
    1: ("Mostly clear", SUNNY, NIGHT),
    2: ("Partly cloudy", PARTLY, PARTLY_NIGHT),
    3: ("Overcast", CLOUDY, CLOUDY),
    45: ("Fog", FOG, FOG), 48: ("Rime fog", FOG, FOG),
    51: ("Light drizzle", RAIN, RAIN), 53: ("Drizzle", RAIN, RAIN),
    55: ("Heavy drizzle", RAIN, RAIN),
    56: ("Freezing drizzle", RAIN, RAIN), 57: ("Freezing drizzle", RAIN, RAIN),
    61: ("Light rain", RAIN, RAIN), 63: ("Rain", RAIN, RAIN),
    65: ("Heavy rain", POURING, POURING),
    66: ("Freezing rain", RAIN, RAIN), 67: ("Freezing rain", POURING, POURING),
    71: ("Light snow", SNOW, SNOW), 73: ("Snow", SNOW, SNOW),
    75: ("Heavy snow", SNOW, SNOW), 77: ("Snow grains", SNOW, SNOW),
    80: ("Light showers", RAIN, RAIN), 81: ("Showers", RAIN, RAIN),
    82: ("Heavy showers", POURING, POURING),
    85: ("Snow showers", SNOW, SNOW), 86: ("Heavy snow showers", SNOW, SNOW),
    95: ("Thunderstorm", STORM, STORM),
    96: ("Thunderstorm, hail", STORM, STORM), 99: ("Thunderstorm, hail", STORM, STORM),
}


def get_json(url):
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.load(r)


def locate():
    lat, lon = os.environ.get("WEATHER_LAT"), os.environ.get("WEATHER_LON")
    city = os.environ.get("WEATHER_CITY", "")
    if lat and lon:
        return float(lat), float(lon), city
    try:
        d = get_json("https://ipapi.co/json/")
        return d["latitude"], d["longitude"], city or d.get("city", "")
    except Exception:
        d = get_json("http://ip-api.com/json/")
        return d["lat"], d["lon"], city or d.get("city", "")


def fetch(lat, lon, city):
    params = {
        "latitude": lat,
        "longitude": lon,
        "current": "temperature_2m,apparent_temperature,relative_humidity_2m,"
                   "weather_code,wind_speed_10m,is_day",
        "daily": "temperature_2m_max,temperature_2m_min,precipitation_probability_max",
        "timezone": "auto",
        "forecast_days": 1,
    }
    d = get_json("https://api.open-meteo.com/v1/forecast?" + urllib.parse.urlencode(params))
    c, day = d["current"], d["daily"]
    desc, ico_day, ico_night = CODES.get(c["weather_code"], ("Unknown", CLOUDY, CLOUDY))
    return {
        "city": city,
        "desc": desc,
        "icon": ico_day if c["is_day"] else ico_night,
        "temp": round(c["temperature_2m"]),
        "feels": round(c["apparent_temperature"]),
        "humidity": round(c["relative_humidity_2m"]),
        "wind": round(c["wind_speed_10m"]),
        "high": round(day["temperature_2m_max"][0]),
        "low": round(day["temperature_2m_min"][0]),
        "rain": day["precipitation_probability_max"][0] or 0,
        "tunit": "°C",
        "wunit": "km/h",
        "updated": time.strftime("%H:%M"),
    }


def write(data):
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w") as f:
        f.write(json.dumps(data, ensure_ascii=False))


def main():
    loc = None
    while True:
        try:
            if loc is None:
                loc = locate()
            write(fetch(*loc))
        except Exception as e:
            print("Weather update failed:", e, flush=True)
            write({
                "error": str(e),
                "icon": FAIL_ICON,
                "updated": time.strftime("%H:%M"),
            })
            time.sleep(FAIL_INTERVAL)
            continue
        time.sleep(INTERVAL)


if __name__ == "__main__":
    main()
