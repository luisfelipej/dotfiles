#!/usr/bin/env zsh

IP=$(curl -s https://ipinfo.io/ip)
LOCATION_JSON=$(curl -s https://ipinfo.io/$IP/json)
LOCATION="$(echo $LOCATION_JSON | jq '.city' | tr -d '"')"
REGION="$(echo $LOCATION_JSON | jq '.region' | tr -d '"')"
LOCATION_ESCAPED="${LOCATION// /+}+${REGION// /+}"

WEATHER_JSON=$(curl -s "https://wttr.in/$LOCATION_ESCAPED?format=j1")

if [ -z "$WEATHER_JSON" ]; then
    sketchybar --set $NAME icon= label="--"
    return
fi

TEMPERATURE=$(echo $WEATHER_JSON | jq '.current_condition[0].temp_C' | tr -d '"')
WEATHER_CODE=$(echo $WEATHER_JSON | jq '.current_condition[0].weatherCode' | tr -d '"')

case $WEATHER_CODE in
113) ICON="󰖙" ;;           # sunny
116) ICON="󰖕" ;;           # partly cloudy
119|122) ICON="󰖐" ;;       # cloudy/overcast
143|248|260) ICON="󰖑" ;;   # fog/mist
176|263|266|293|296) ICON="󰖗" ;;  # light rain
299|302|305|308|311|314|317) ICON="󰖖" ;; # heavy rain
320|323|326|329|332|335|338|350|368|371|374|377) ICON="󰖘" ;; # snow/sleet
386|389|392|395) ICON="󰖓" ;; # thunder
*) ICON="󰖙" ;;
esac

sketchybar --set $NAME icon="$ICON" label="${TEMPERATURE}℃"
