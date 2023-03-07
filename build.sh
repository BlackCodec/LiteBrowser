#!/bin/bash

[[ ! -d "./bin" ]] && mkdir ./bin
valac --pkg gtk+-3.0 --pkg webkit2gtk-4.1 --pkg json-glib-1.0 logger.vala configs.vala litebrowser.vala -o ./bin/litebrowser && ./bin/litebrowser
