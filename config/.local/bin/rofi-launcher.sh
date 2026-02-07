#!/bin/bash

if pkill -x rofi; then
  exit 0
fi

rofi -show drun -theme minimal
