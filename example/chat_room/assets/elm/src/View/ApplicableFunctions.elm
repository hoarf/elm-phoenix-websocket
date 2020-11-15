module View.ApplicableFunctions exposing
    ( functions
    , init
    , view
    )

import Device exposing (Device)
import Element as El exposing (Attribute, DeviceClass(..), Element)
import UI


type Config
    = Config (List String)


init : Config
init =
    Config []


functions : List String -> Config -> Config
functions functions_ (Config _) =
    Config functions_


view : Device -> Config -> Element msg
view { class } (Config functions_) =
    El.column
        (spacing class
            :: [ El.width El.fill ]
        )
        (List.map UI.functionLink functions_)


spacing : DeviceClass -> Attribute msg
spacing class =
    case class of
        Phone ->
            El.spacing 5

        _ ->
            El.spacing 10
