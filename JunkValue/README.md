# Junk Value

Junk Value is a World of Warcraft addon that displays the combined vendor sell
price of poor-quality (gray) items currently in your carried bags. It updates
when bag contents change and saves the window position between sessions.

## Install

Copy the `JunkValue` folder into your WoW Forever client's
`Interface\AddOns` directory. For the beta client, the path is:

`World of Warcraft\_classic_beta_\Interface\AddOns\JunkValue`

The TOC declares interface version `16001`, matching WoW Forever build
`1.60.1.70532`. Update the `## Interface` value in `JunkValue.toc` if a later
Forever client reports the addon as out of date.

## Use

The value window appears after logging in. Drag it to move it, and type
`/junkvalue` to hide or show it. The total is an estimate based on item vendor
prices and stack counts; items in the bank are not included.
