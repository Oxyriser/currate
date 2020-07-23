module Home exposing (Model, Msg, empty, init, title, update, view)

import Html exposing (..)
import Html.Attributes exposing (..)
import Html.Events exposing (custom, keyCode, onClick, onInput)
import Http
import Json.Decode as Decode exposing (Decoder)
import LineChart
import LineChart.Area as Area
import LineChart.Axis as Axis
import LineChart.Axis.Intersection as Intersection
import LineChart.Axis.Line as AxisLine
import LineChart.Axis.Range as Range
import LineChart.Axis.Ticks as Ticks
import LineChart.Axis.Title as Title
import LineChart.Colors as Colors
import LineChart.Container as Container
import LineChart.Dots as Dots
import LineChart.Events as Events
import LineChart.Grid as Grid
import LineChart.Interpolation as Interpolation
import LineChart.Junk as Junk
import LineChart.Legends as Legends
import LineChart.Line as Line
import String exposing (fromFloat, fromInt)
import Time exposing (Month(..), Weekday(..))
import Url.Builder exposing (crossOrigin, string)


url : String
url =
    crossOrigin "http://localhost:5000" [] []


type alias Currency =
    String


type alias Data =
    ( Float, Float )


type alias Model =
    { listCryptos : List Currency
    , listFiats : List Currency
    , srcCurrency : Currency
    , destCurrency : Currency
    , srcAmount : Maybe Float
    , destAmount : Maybe Float
    , graph : Maybe (List Data)
    , timeFrame : Maybe String
    , hovering : List Data
    }


empty : Model
empty =
    { listCryptos = [ "BTC", "ETH" ]
    , listFiats = [ "USD", "EUR" ]
    , srcCurrency = "BTC"
    , destCurrency = "USD"
    , srcAmount = Just 1.0
    , destAmount = Nothing
    , graph = Nothing
    , timeFrame = Nothing
    , hovering = []
    }


init : ( Model, Cmd Msg )
init =
    ( empty
    , Cmd.batch
        [ Http.get
            { url = crossOrigin url [ "list_cryptos" ] []
            , expect = Http.expectJson GotListCryptos (Decode.list Decode.string)
            }
        , Http.get
            { url = crossOrigin url [ "list_fiats" ] []
            , expect = Http.expectJson GotListFiats (Decode.list Decode.string)
            }
        ]
    )


type Msg
    = GotListCryptos (Result Http.Error (List String))
    | GotListFiats (Result Http.Error (List String))
    | GotConvertion (Result Http.Error Float)
    | GotGraph (Result Http.Error (List Data))
    | NewSrcCurrency Currency
    | NewDestCurrency Currency
    | NewSrcAmount String
    | Convert
    | HoverPoint (List Data)


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GotListCryptos res ->
            case res of
                Err _ ->
                    ( model, Cmd.none )

                Ok listCryptos ->
                    ( { model | listCryptos = listCryptos }, Cmd.none )

        GotListFiats res ->
            case res of
                Err _ ->
                    ( model, Cmd.none )

                Ok listFiats ->
                    ( { model | listFiats = listFiats }, Cmd.none )

        GotConvertion res ->
            case res of
                Err _ ->
                    ( { model | destAmount = Nothing }, Cmd.none )

                Ok convertionRate ->
                    ( { model
                        | destAmount =
                            Maybe.map
                                ((*) convertionRate)
                                model.srcAmount
                      }
                    , Cmd.none
                    )

        GotGraph res ->
            case res of
                Err _ ->
                    ( { model | graph = Nothing }, Cmd.none )

                Ok graph ->
                    ( { model | graph = Just graph }, Cmd.none )

        NewSrcCurrency srcCurrency ->
            update Convert { model | srcCurrency = srcCurrency }

        NewDestCurrency destCurrency ->
            update Convert { model | destCurrency = destCurrency }

        NewSrcAmount newSrcAmount ->
            ( { model | srcAmount = String.toFloat newSrcAmount }, Cmd.none )

        Convert ->
            ( model
            , Cmd.batch
                [ Http.get
                    { url =
                        crossOrigin url
                            [ "convertion_rate" ]
                            [ string "fsym" model.srcCurrency
                            , string "tsym" model.destCurrency
                            ]
                    , expect = Http.expectJson GotConvertion Decode.float
                    }
                , Http.get
                    { url =
                        crossOrigin url
                            [ "graph" ]
                            [ string "fsym" model.srcCurrency
                            , string "tsym" model.destCurrency
                            , string "timeframe" "histoday"
                            ]
                    , expect = Http.expectJson GotGraph decodeGraph
                    }
                ]
            )

        HoverPoint hovering ->
            ( { model | hovering = hovering }, Cmd.none )


decodeGraph : Decoder (List Data)
decodeGraph =
    Decode.list <|
        Decode.map2 Tuple.pair
            (Decode.field "time" Decode.float)
            (Decode.field "close" Decode.float)


title : Model -> String
title _ =
    "Currate - Home"


view : Model -> Html Msg
view model =
    main_ []
        [ section []
            -- only use form ?
            [ Html.div []
                [ label [ for "amount" ]
                    [ text "FROM:" ]
                , select [ id "src", onInput NewSrcCurrency ]
                    (List.map
                        (\currency ->
                            option
                                [ selected (currency == model.srcCurrency) ]
                                [ text currency ]
                        )
                        (model.listFiats ++ model.listCryptos)
                    )
                , label [ for "select1" ]
                    [ text "TO:" ]
                , select [ id "dest", onInput NewDestCurrency ]
                    (List.map
                        (\currency ->
                            option
                                [ selected (currency == model.destCurrency) ]
                                [ text currency ]
                        )
                        (model.listFiats ++ model.listCryptos)
                    )
                , textarea [ cols 20, id "textareasrc", rows 1, onEnter Convert, onInput NewSrcAmount ]
                    []
                , div [ onClick Convert ]
                    [ img [ alt "Convert", height 30, src "../img/double_arrow.svg" ]
                        []
                    ]
                , textarea [ cols 20, id "textareadest", readonly True, rows 1 ]
                    [ model.destAmount
                        |> Maybe.map String.fromFloat
                        |> Maybe.withDefault ""
                        |> text
                    ]
                ]
            ]
        , viewChart model
        ]


viewChart : Model -> Html Msg
viewChart model =
    case model.graph of
        Nothing ->
            text ""

        Just data ->
            LineChart.viewCustom (chartConfig model)
                [ LineChart.line Colors.blueLight Dots.none model.srcCurrency data ]


chartConfig : Model -> LineChart.Config Data Msg
chartConfig model =
    { x = Axis.picky 600 "" Tuple.first []
    , y =
        Axis.custom
            { title = Title.default model.destCurrency
            , variable = Just << Tuple.second
            , pixels = 300
            , range = Range.default
            , axisLine = AxisLine.default
            , ticks = Ticks.float 4
            }
    , container = Container.styled "line-chart-1" [ ( "display", "block" ), ( "margin", "auto" ) ]
    , interpolation = Interpolation.default
    , intersection = Intersection.default
    , legends = Legends.none
    , events = Events.hoverMany HoverPoint
    , junk =
        Junk.hoverMany model.hovering
            (formatDate << Tuple.first)
            (\( _, y ) -> String.fromFloat y ++ model.destCurrency)
    , grid = Grid.default
    , area = Area.default
    , line = Line.default
    , dots = Dots.default
    }


formatDate : Float -> String
formatDate floatPosix =
    let
        posix =
            Time.millisToPosix <| floor (1000 * floatPosix)

        weekday =
            Time.toWeekday Time.utc posix
                |> toStringWeekday

        month =
            Time.toMonth Time.utc posix
                |> toStringMonth

        day =
            Time.toDay Time.utc posix
                |> String.fromInt

        year =
            Time.toYear Time.utc posix
                |> String.fromInt

        hour =
            Time.toHour Time.utc posix
                |> String.fromInt
                |> twoDigit

        minute =
            Time.toMinute Time.utc posix
                |> String.fromInt
                |> twoDigit
    in
    String.concat
        [ weekday
        , ", "
        , month
        , " "
        , day
        , " "
        , year
        , ", "
        , hour
        , ":"
        , minute
        , " UTC"
        ]


toStringWeekday : Time.Weekday -> String
toStringWeekday weekday =
    case weekday of
        Mon ->
            "Mon"

        Tue ->
            "Tue"

        Wed ->
            "Wed"

        Thu ->
            "Thu"

        Fri ->
            "Fri"

        Sat ->
            "Sat"

        Sun ->
            "Sun"


toStringMonth : Time.Month -> String
toStringMonth month =
    case month of
        Jan ->
            "Jan"

        Feb ->
            "Feb"

        Mar ->
            "Mar"

        Apr ->
            "Apr"

        May ->
            "May"

        Jun ->
            "Jun"

        Jul ->
            "Jul"

        Aug ->
            "Aug"

        Sep ->
            "Sep"

        Oct ->
            "Oct"

        Nov ->
            "Nov"

        Dec ->
            "Dec"


twoDigit : String -> String
twoDigit n =
    if String.length n == 1 then
        "0" ++ n

    else
        n


onEnter : Msg -> Attribute Msg
onEnter msg =
    let
        isEnter code =
            if code == 13 then
                Decode.succeed msg

            else
                Decode.fail "not ENTER"
    in
    custom "keydown"
        (Decode.map
            (\message ->
                { message = message
                , stopPropagation = False
                , preventDefault = True
                }
            )
            (Decode.andThen isEnter keyCode)
        )
