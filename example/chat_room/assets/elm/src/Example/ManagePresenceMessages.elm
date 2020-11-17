module Example.ManagePresenceMessages exposing
    ( Model
    , Msg
    , init
    , subscriptions
    , update
    , view
    )

import Device exposing (Device)
import Element as El exposing (DeviceClass(..), Element, Orientation(..))
import Example.Utils exposing (batch, updatePhoenixWith)
import Extra.String as String
import Json.Decode as JD
import Json.Decode.Extra exposing (andMap)
import Json.Encode exposing (Value)
import Phoenix
import Types exposing (presenceToString)
import UI
import View.Button as Button
import View.Example as Example
import View.Example.ApplicableFunctions as ApplicableFunctions
import View.Example.Controls as Controls
import View.Example.Feedback as Feedback
import View.Example.Feedback.Content as FeedbackContent
import View.Example.Feedback.Info as FeedbackInfo
import View.Example.Feedback.Panel as FeedbackPanel
import View.Example.LabelAndValue as LabelAndValue
import View.Example.UsefulFunctions as UsefulFunctions
import View.Group as Group



{- Init -}


init : Phoenix.Model -> ( Model, Cmd Msg )
init phoenix =
    let
        ( phx, phxCmd ) =
            Phoenix.join "example:manage_presence_messages" phoenix
    in
    ( { phoenix = phx
      , messages = []
      , receiveMessages = True
      , maybeExampleId = Nothing
      , maybeUserId = Nothing
      }
    , Cmd.map PhoenixMsg phxCmd
    )



{- Model -}


type alias Model =
    { phoenix : Phoenix.Model
    , messages : List PresenceInfo
    , receiveMessages : Bool
    , maybeExampleId : Maybe ID
    , maybeUserId : Maybe ID
    }


type alias PresenceInfo =
    { topic : String
    , event : String
    , payload : Value
    }


type alias ID =
    String


type Action
    = Join
    | Leave
    | On
    | Off



{- Update -}


type Msg
    = GotControlClick Action
    | PhoenixMsg Phoenix.Msg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotControlClick action ->
            case action of
                Join ->
                    Phoenix.join (controllerTopic model.maybeExampleId) model.phoenix
                        |> updatePhoenixWith PhoenixMsg model

                Leave ->
                    Phoenix.leave (controllerTopic model.maybeExampleId) model.phoenix
                        |> updatePhoenixWith PhoenixMsg model

                On ->
                    ( { model | receiveMessages = True }
                    , Phoenix.socketPresenceMessagesOn model.phoenix
                        |> Cmd.map PhoenixMsg
                    )

                Off ->
                    ( { model | receiveMessages = False }
                    , Phoenix.socketPresenceMessagesOff model.phoenix
                        |> Cmd.map PhoenixMsg
                    )

        PhoenixMsg subMsg ->
            let
                ( newModel, cmd ) =
                    Phoenix.update subMsg model.phoenix
                        |> updatePhoenixWith PhoenixMsg model
            in
            case Phoenix.phoenixMsg newModel.phoenix of
                Phoenix.SocketMessage (Phoenix.PresenceMessage message) ->
                    ( { newModel | messages = message :: model.messages }, cmd )

                Phoenix.SocketMessage (Phoenix.ChannelMessage { topic, event, payload }) ->
                    case ( Phoenix.topicParts topic, event ) of
                        ( ( "example", "manage_presence_messages" ), "phx_reply" ) ->
                            case decodeExampleId payload of
                                Ok exampleId ->
                                    Phoenix.leave "example:manage_presence_messages" newModel.phoenix
                                        |> updatePhoenixWith PhoenixMsg { newModel | maybeExampleId = Just exampleId }
                                        |> batch [ cmd ]

                                Err _ ->
                                    ( newModel, cmd )

                        ( ( "example", _ ), "phx_reply" ) ->
                            case decodeUserId payload of
                                Ok userId ->
                                    ( { newModel | maybeUserId = Just userId }, cmd )

                                Err _ ->
                                    ( newModel, cmd )

                        _ ->
                            ( newModel, cmd )

                _ ->
                    ( newModel, cmd )


controllerTopic : Maybe ID -> String
controllerTopic maybeId =
    case maybeId of
        Just id ->
            "example:manage_presence_messages_" ++ id

        Nothing ->
            ""



{- Decoders -}


decodeExampleId : Value -> Result JD.Error String
decodeExampleId payload =
    JD.decodeValue (JD.field "response" exampleIdDecoder) payload


exampleIdDecoder : JD.Decoder String
exampleIdDecoder =
    JD.succeed
        identity
        |> andMap (JD.field "example_id" JD.string)


decodeUserId : Value -> Result JD.Error String
decodeUserId payload =
    JD.decodeValue (JD.field "response" userIdDecoder) payload


userIdDecoder : JD.Decoder String
userIdDecoder =
    JD.succeed
        identity
        |> andMap (JD.field "user_id" JD.string)



{- Subscriptions -}


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.map PhoenixMsg <|
        Phoenix.subscriptions model.phoenix



{- View -}


view : Device -> Model -> Element Msg
view device model =
    Example.init
        |> Example.id model.maybeExampleId
        |> Example.description description
        |> Example.controls (controls device model)
        |> Example.feedback (feedback device model)
        |> Example.view device



{- Description -}


description : List (List (Element msg))
description =
    [ [ El.text "Choose whether to receive Presence messages as an incoming Socket message." ] ]



{- Controls -}


controls : Device -> Model -> Element Msg
controls device { phoenix, maybeUserId, maybeExampleId, receiveMessages } =
    let
        joinedChannel =
            Phoenix.channelJoined (controllerTopic maybeExampleId) phoenix
    in
    Controls.init
        |> Controls.userId maybeUserId
        |> Controls.elements
            [ join device GotControlClick (not <| joinedChannel)
            , on device (not receiveMessages)
            , off device receiveMessages
            , leave device GotControlClick joinedChannel
            ]
        |> Controls.group
            (Group.init
                |> Group.layouts
                    [ ( Phone, Portrait, [ 2, 2 ] ) ]
                |> Group.order
                    [ ( Phone, Portrait, [ 0, 2, 3, 1 ] ) ]
            )
        |> Controls.view device


join : Device -> (Action -> Msg) -> Bool -> Element Msg
join device onPress enabled =
    Button.init
        |> Button.label "Join"
        |> Button.onPress (Just (onPress Join))
        |> Button.enabled enabled
        |> Button.view device


leave : Device -> (Action -> Msg) -> Bool -> Element Msg
leave device onPress enabled =
    Button.init
        |> Button.label "Leave"
        |> Button.onPress (Just (onPress Leave))
        |> Button.enabled enabled
        |> Button.view device


on : Device -> Bool -> Element Msg
on device enabled =
    Button.init
        |> Button.label "Presence On"
        |> Button.onPress (Just (GotControlClick On))
        |> Button.enabled enabled
        |> Button.view device


off : Device -> Bool -> Element Msg
off device enabled =
    Button.init
        |> Button.label "Presence Off"
        |> Button.onPress (Just (GotControlClick Off))
        |> Button.enabled enabled
        |> Button.view device



{- Feedback -}


feedback : Device -> Model -> Element Msg
feedback device { phoenix, maybeExampleId, messages } =
    Feedback.init
        |> Feedback.elements
            [ FeedbackPanel.init
                |> FeedbackPanel.title "Info"
                |> FeedbackPanel.static (static device messages)
                |> FeedbackPanel.scrollable (scrollable device messages)
                |> FeedbackPanel.view device
            , FeedbackPanel.init
                |> FeedbackPanel.title "Applicable Functions"
                |> FeedbackPanel.scrollable [ applicableFunctions device ]
                |> FeedbackPanel.view device
            , FeedbackPanel.init
                |> FeedbackPanel.title "Useful Functions"
                |> FeedbackPanel.scrollable [ usefulFunctions device phoenix maybeExampleId ]
                |> FeedbackPanel.view device
            ]
        |> Feedback.group
            (Group.init
                |> Group.layouts
                    [ ( Phone, Landscape, [ 1, 2 ] )
                    , ( Tablet, Portrait, [ 1, 2 ] )
                    , ( Tablet, Landscape, [ 1, 2 ] )
                    , ( Desktop, Portrait, [ 1, 2 ] )
                    ]
            )
        |> Feedback.view device


static : Device -> List PresenceInfo -> List (Element Msg)
static device messages =
    [ LabelAndValue.init
        |> LabelAndValue.label "Message Count"
        |> LabelAndValue.value (messages |> List.length |> String.fromInt)
        |> LabelAndValue.view device
    ]


scrollable : Device -> List PresenceInfo -> List (Element Msg)
scrollable device messages =
    List.map
        (\info ->
            FeedbackContent.init
                |> FeedbackContent.title (Just "SocketMessage")
                |> FeedbackContent.label "PresenceMessage"
                |> FeedbackContent.element (presenceInfo device info)
                |> FeedbackContent.view device
        )
        messages


presenceInfo : Device -> PresenceInfo -> Element Msg
presenceInfo device info =
    FeedbackInfo.init
        |> FeedbackInfo.topic info.topic
        |> FeedbackInfo.event info.event
        |> FeedbackInfo.payload info.payload
        |> FeedbackInfo.view device


applicableFunctions : Device -> Element Msg
applicableFunctions device =
    ApplicableFunctions.init
        |> ApplicableFunctions.functions
            [ "Phoenix.join"
            , "Phoenix.socketPresenceMessagesOn"
            , "Phoenix.socketPresenceMessagesOff"
            , "Phoeinx.leave"
            ]
        |> ApplicableFunctions.view device


usefulFunctions : Device -> Phoenix.Model -> Maybe ID -> Element Msg
usefulFunctions device phoenix maybeExampleId =
    let
        topic =
            controllerTopic maybeExampleId
    in
    UsefulFunctions.init
        |> UsefulFunctions.functions
            [ ( "Phoenix.socketState", Phoenix.socketStateToString phoenix )
            , ( "Phoenix.connectionState", Phoenix.connectionState phoenix |> String.printQuoted )
            , ( "Phoenix.isConnected", Phoenix.isConnected phoenix |> String.printBool )
            , ( "Phoenix.channelJoined", Phoenix.channelJoined topic phoenix |> String.printBool )
            , ( "Phoenix.joinedChannels", Phoenix.joinedChannels phoenix |> String.printList )
            , ( "Phoenix.lastPresenceJoin", Phoenix.lastPresenceJoin topic phoenix |> String.printMaybe "Presence" )
            , ( "Phoenix.lastPresenceLeave", Phoenix.lastPresenceLeave topic phoenix |> String.printMaybe "Presence" )
            ]
        |> UsefulFunctions.view device
