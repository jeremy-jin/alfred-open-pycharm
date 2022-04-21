#!/usr/bin/env bash

function formatResult() {
    projects=("$@")
    printf "{\n"
    printf '\t"items":[\n'

    for project in "${projects[@]}"
    do
        project_name=$(echo "$project" | awk -F '/' '{print $NF}')
        printf '\t\t{\n'
        printf '\t\t\t"uid": "%s",\n' "$project_name"
        printf '\t\t\t"type": "file",\n'
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
        "subtitle": "This version of Pycharm is not supported, please use version 2019/2020/2021.",
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

function noResultsFound() {
    echo '{"items": [
    {
        "uid": "",
        "type": "",
        "title": "No Results Found",
        "subtitle": "Try other query conditions......",
        "arg": "",
        "icon": {
            "path": "./no-results.png"
        },
        "autocomplete": "",
    }]}'
}