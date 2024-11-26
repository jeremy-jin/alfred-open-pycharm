#!/usr/bin/env bash

function formatResult() {
    read -ra projects <<< "$1"

    printf "{\n"
    printf '\t"items":[\n'
    for project in "${projects[@]}"
    do
        project_name=$(echo "$project" | awk -F '/' '{print $NF}')
        printf '\t\t{\n'
        printf '\t\t\t"uid": "%s",\n' "$project_name"
        printf '\t\t\t"type": "project",\n'
        printf '\t\t\t"title": "%s",\n' "$project_name"
        printf '\t\t\t"subtitle": "%s",\n' "${project}"
        printf '\t\t\t"arg": "%s",\n' "${project}"
        printf '\t\t\t"autocomplete": "%s",\n' "$project_name"
        printf '\t\t},\n'
    done

    printf "\t]\n"
    printf "}\n"
}

function unSupportVersion() {
    echo '{"items": [
    {
        "uid": "",
        "type": "",
        "title": "Not supported the version of Pycharm",
        "subtitle": "This version of Pycharm is not supported, Please use 2019 or later.",
        "arg": "",
        "icon": {
            "path": "./warning.png"
        },
        "autocomplete": "",
    }]}'
}

function noPycharmApp() {
    echo '{"items": [
    {
        "uid": "",
        "type": "",
        "title": "Pycharm is not installed",
        "subtitle": "please check that if Pycharm APP is already installed.",
        "arg": "",
        "icon": {
            "path": "./warning.png"
        },
        "autocomplete": "",
    }]}'
}


function noFoundCommandLine() {
    echo '{"items": [
    {
        "uid": "",
        "type": "",
        "title": "Can'\''t find command line launcher for '\''/usr/local/bin/charm'\''",
        "subtitle": "Create/Update command line launcher in Tools > Create Command-Line Launcher",
        "arg": "",
        "icon": {
            "path": "./warning.png"
        },
        "autocomplete": "",
    }]}'
}

function noProjectMatched() {
  echo '{"items": [
    {
      "uid": "",
      "type": "",
      "title": "No Project matched",
      "subtitle": "Try other query conditions......",
      "arg": "",
      "icon": {
          "path": "./no-results.png"
      },
      "autocomplete": "",
    }]}'
}