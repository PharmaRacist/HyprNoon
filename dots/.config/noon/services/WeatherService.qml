pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    id: root

    property bool useFehrenheit: Mem.options.services.weather.useFehrenheit ?? false
    property string weatherLocation: Mem.options.services.location ?? "Cairo"
    property string currentCity: weatherLocation
    property string sunrise: "06:00"
    property string sunset: "18:00"
    property bool isLoading: false
    property bool hasError: false

    property var weatherData: ({
        "currentTemp": "...",
        "currentEmoji": "sunny",
        "currentCondition": "Loading...",
        "feelsLike": "...",
        "humidity": "...",
        "windSpeed": "...",
        "visibility": "..."
    })
    property var weatherPredictions: []

    readonly property string tempUnit: useFehrenheit ? "°F" : "°C"
    readonly property string windUnit: useFehrenheit ? "mph" : "km/h"
    readonly property string visUnit: useFehrenheit ? "mi" : "km"

    // Cache frequently used regex
    readonly property var unknownLocationRegex: /Unknown location; please try ~?([\d.,-]+)/

    function isNight(sunrise, sunset, time) {
        const toMins = t => {
            const parts = t.split(":");
            return parseInt(parts[0]) * 60 + parseInt(parts[1]);
        };
        const now = toMins(time);
        return now < toMins(sunrise) || now > toMins(sunset);
    }

    function emojiFor(condition, night) {
        const c = condition.toLowerCase();

        if (c.includes("clear")) return night ? "clear_night" : "partly_cloudy_day";
        if (c.includes("partly")) return night ? "cloudy" : "partly_cloudy_day";
        if (c.includes("cloud") || c.includes("overcast")) return "cloud";
        if (c.includes("fog") || c.includes("mist")) return "foggy";
        if (c.includes("rain") || c.includes("drizzle")) return "rainy";
        if (c.includes("snow")) return "ac_unit";
        if (c.includes("thunderstorm")) return "thunderstorm";
        if (c.includes("hail")) return "hail";
        if (c.includes("sleet")) return "sleet";

        return night ? "clear_night" : "cloudy";
    }

    function formatDate(dateStr) {
        const date = new Date(dateStr);
        const today = new Date();
        const tomorrow = new Date(today);
        tomorrow.setDate(today.getDate() + 1);

        if (date.toDateString() === today.toDateString()) return "Today";
        if (date.toDateString() === tomorrow.toDateString()) return "Tomorrow";
        return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"][date.getDay()];
    }

    function fail(message) {
        hasError = true;
        isLoading = false;
        weatherData = {
            currentTemp: "",
            currentEmoji: "cloud_off",
            currentCondition: message,
            feelsLike: "",
            humidity: "",
            windSpeed: "",
            visibility: ""
        };
        weatherPredictions = [];
        currentCity = message;
    }

    function processWeatherData(data) {
        const current = data.current_condition[0];
        const astro = data.weather[0].astronomy[0];

        root.sunrise = astro.sunrise;
        root.sunset = astro.sunset;

        const cond = current.weatherDesc[0].value;
        const time = current.localObsDateTime.split(" ")[1].slice(0, 5);
        const night = isNight(astro.sunrise, astro.sunset, time);

        const area = data.nearest_area?.[0];
        const name = area?.areaName?.[0]?.value ?? weatherLocation;
        const country = area?.country?.[0]?.value;
        currentCity = country ? `${name}, ${country}` : name;

        const temp = useFehrenheit ? current.temp_F : current.temp_C;
        const feels = useFehrenheit ? current.FeelsLikeF : current.FeelsLikeC;
        const windSpeed = useFehrenheit
            ? Math.round(current.windspeedKmph * 0.621371)
            : current.windspeedKmph;
        const visibility = useFehrenheit
            ? Math.round(current.visibility * 0.621371)
            : current.visibility;

        weatherData = {
            currentTemp: `${temp}${tempUnit}`,
            currentEmoji: emojiFor(cond, night),
            currentCondition: cond,
            feelsLike: `${feels}${tempUnit}`,
            humidity: `${current.humidity}%`,
            windSpeed: `${windSpeed} ${windUnit}`,
            visibility: `${visibility} ${visUnit}`
        };

        weatherPredictions = data.weather.slice(1, 5).map(d => {
            const hourlyData = d.hourly[4];
            const condition = hourlyData.weatherDesc[0].value;
            const max = useFehrenheit ? d.maxtempF : d.maxtempC;
            const min = useFehrenheit ? d.mintempF : d.mintempC;
            const avg = Math.round((parseInt(max) + parseInt(min)) / 2);

            return {
                date: formatDate(d.date),
                maxTemp: `${max}${tempUnit}`,
                minTemp: `${min}${tempUnit}`,
                avgTemp: `${avg}${tempUnit}`,
                condition: condition,
                emoji: emojiFor(condition, false),
                sunrise: d.astronomy[0].sunrise,
                sunset: d.astronomy[0].sunset,
                uvIndex: d.uvIndex || "N/A",
                chanceOfRain: `${hourlyData.chanceofrain}%`
            };
        });

        hasError = false;
        isLoading = false;
    }

    function loadWeather(retryLocation) {
        if (isLoading) return;

        isLoading = true;
        const location = retryLocation || weatherLocation;
        const url = `https://wttr.in/${encodeURIComponent(location)}?format=j1`;
        const xhr = new XMLHttpRequest();

        xhr.timeout = 10000;

        xhr.onload = function() {
            if (xhr.status !== 200) {
                fail(`Network error (${xhr.status})`);
                return;
            }

            const response = xhr.responseText?.trim();
            if (!response) {
                fail("Empty response");
                return;
            }

            const unknownMatch = response.match(unknownLocationRegex);
            if (unknownMatch && !retryLocation) {
                isLoading = false;
                loadWeather(unknownMatch[1]);
                return;
            }

            try {
                const data = JSON.parse(response);

                if (!data.current_condition?.[0] || !data.weather?.[0]) {
                    throw new Error("Invalid response structure");
                }

                processWeatherData(data);
            } catch (e) {
                fail("Parse error");
            }
        };

        xhr.onerror = function() {
            fail("Connection failed");
        };

        xhr.ontimeout = function() {
            fail("Request timeout");
        };

        xhr.open("GET", url);
        xhr.send();
    }

    Timer {
        interval: 3600000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.loadWeather()
    }
}
