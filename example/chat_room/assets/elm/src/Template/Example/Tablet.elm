module Template.Example.Tablet exposing (view)

import Colors.Opaque as Color
import Element as El exposing (Element)
import Element.Background as Background
import Element.Border as Border
import Element.Font as Font
import Template.Example.Common as Common


view : Common.Config msg c -> Element msg
view config =
    El.column
        Common.containerAttrs
        [ introduction config.introduction
        , config.menu
        , description config.description
        , maybeId "Example" config.id
        , config.controls
        , remoteControls config.remoteControls
        , config.feedback
        , El.row
            [ El.spacing 10
            , El.centerX
            ]
            [ El.el [ El.alignTop, El.width El.fill ] <| info config.info
            ]
        ]



{- Introduction -}


introduction : List (Element msg) -> Element msg
introduction intro =
    El.column
        (List.append
            [ Font.size 24
            , El.spacing 30
            ]
            Common.introductionAttrs
        )
        intro



{- Description -}


description : List (Element msg) -> Element msg
description content =
    El.paragraph
        (List.append
            [ Font.size 24
            , El.paddingEach
                { left = 0
                , top = 10
                , right = 0
                , bottom = 0
                }
            ]
            Common.descriptionAttrs
        )
        content



{- Example ID -}


maybeId : String -> Maybe String -> Element msg
maybeId type_ maybeId_ =
    case maybeId_ of
        Nothing ->
            El.none

        Just id ->
            El.paragraph
                (Font.size 20
                    :: Common.idAttrs
                )
                [ El.el Common.idLabelAttrs (El.text (type_ ++ " ID: "))
                , El.el Common.idValueAttrs (El.text id)
                ]



{- Remote Controls -}


remoteControls : List (Element msg) -> Element msg
remoteControls cntrls =
    El.column
        [ El.width El.fill
        , El.spacing 10
        ]
        cntrls



{- Info -}


info : List (Element msg) -> Element msg
info content =
    if content == [] then
        El.none

    else
        El.column
            [ Background.color Color.white
            , Border.width 1
            , Border.color Color.black
            , El.paddingEach
                { left = 10
                , top = 10
                , right = 10
                , bottom = 0
                }
            , El.spacing 10
            , El.centerX
            ]
            [ El.el
                [ El.centerX
                , Font.bold
                , Font.underline
                , Font.color Color.darkslateblue
                ]
                (El.text "Information")
            , El.column
                [ El.height <|
                    El.maximum 300 El.shrink
                , El.clip
                , El.scrollbars
                , El.spacing 16
                ]
                content
            ]
