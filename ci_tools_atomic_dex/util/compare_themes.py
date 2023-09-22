#!/usr/bin/env python3
import json
import requests

'''
Purpose: Scans the light and dark theme json files for a list of whitelabel
         branches, and compares them with the dev branch to identify theme
         selectors which are obsolete or not present in the whitelabel branch.

Usage:   `./compare_themes.py`
'''

REPO_URL = "https://raw.githubusercontent.com/KomodoPlatform/komodo-wallet-desktop"
BRANCHES = ['smartdex', 'GleecDEX', 'shibadex']


def get_theme_url(branch, theme):
    '''Returns a github url for a branch theme.'''
    path = f"assets/themes/Default%20-%20{theme.title()}"
    return f"{REPO_URL}/{branch}/{path}/colors.json"


def get_themes_data(branches):
    '''Returns a dict of dark/light theme data for each branch.'''
    themes = {}
    for branch in branches+['dev']:
        themes.update({branch: {}})
        for theme in ['light', 'dark']:
            url = get_theme_url(branch, theme)
            themes[branch].update({
                theme: requests.get(url).json()
            })
    return themes


def get_selectors(themes, branch='dev'):
    '''Returns a list of selectors within each theme for a branch.'''
    return {
        'light': set(themes[branch]['light'].keys()),
        'dark': set(themes[branch]['dark'].keys())
    }


def compare_branch_themes(branches, show_results=True):
    '''Scans whitelabel theme data to identify missing/obsolete selectors.'''
    themes = get_themes_data(branches)
    dev_selectors = get_selectors(themes, 'dev')

    for branch in branches:
        for theme in ['light', 'dark']:
            selectors = set(themes[branch][theme].keys())
            missing = dev_selectors[theme].difference(selectors)
            themes[branch].update({
                f"missing_{theme}": missing,
                f"obsolete_{theme}": selectors.difference(dev_selectors[theme])
            })
            if show_results:
                output_results(themes, branch, theme)


def output_results(themes, branch, theme):
    '''Outputs results for a branch to the console.'''
    print(f"\n#### {branch} {theme} ####")
    if len(themes[branch][f"obsolete_{theme}"]) == 0:
        print(f"No obsolete selectors")
    else:
        for i in themes[branch][f"obsolete_{theme}"]:
            print(f"Obsolete selector: {i}...")

    if len(themes[branch][f"missing_{theme}"]) == 0:
        print(f"No obsolete selectors")
    else:
        for i in themes[branch][f"missing_{theme}"]:
            dev_color = themes['dev'][theme][i]
            for j in themes['dev'][theme]:
                if dev_color == themes['dev'][theme][j]:
                    if j in themes[branch][theme]:
                        print(f"Missing {i}... Try {themes[branch][theme][j]}")
                        break


if __name__ == '__main__':
    compare_branch_themes(BRANCHES, True)
