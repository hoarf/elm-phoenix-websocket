module View.StatusReports exposing
    ( Config
    , init
    , scrollable
    , static
    , title
    , view
    )

import Element as El exposing (Device, Element)
import Template.StatusReports.PhonePortrait as PhonePortrait


type Config msg
    = Config
        { title : String
        , static : List (Element msg)
        , scrollable : List (Element msg)
        }


init : Config msg
init =
    Config
        { title = ""
        , static = []
        , scrollable = []
        }


view : Device -> Config msg -> Element msg
view { class, orientation } (Config config) =
    PhonePortrait.view config


title : String -> Config msg -> Config msg
title title_ (Config config) =
    Config { config | title = title_ }


scrollable : List (Element msg) -> Config msg -> Config msg
scrollable scrollable_ (Config config) =
    Config { config | scrollable = scrollable_ }


static : List (Element msg) -> Config msg -> Config msg
static static_ (Config config) =
    Config { config | static = static_ }
