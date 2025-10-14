#!/bin/bash
niri_config=~/.config/niri
source "${niri_config}/niri.colors"
sed -i "s|active-gradient from=\"[^\"]*\" to=\"[^\"]*\" angle=[0-9]*|active-gradient ${NIRI_ACTIVE_GRADIENT}|g" "$niri_config/config.kdl"
sed -i "s|inactive-gradient from=\"[^\"]*\" to=\"[^\"]*\" angle=[0-9]*|inactive-gradient ${NIRI_INACTIVE_GRADIENT}|g" "$niri_config/config.kdl"
sed -i "s|backdrop-color \"[^\"]*\"|backdrop-color ${NIRI_BACKDROP_COLOR}|g" "$niri_config/config.kdl"
