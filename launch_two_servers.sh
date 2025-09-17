#!/bin/bash

cd /app
python3 RealtimeSTT_server/stt_server.py -c 8011 -d 8012 -l en &
python3 RealtimeSTT_server/stt_server.py -c 8013 -d 8014 -l en
