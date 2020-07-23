module Main exposing (main)

import About
import Browser exposing (Document, UrlRequest(..))
import Browser.Navigation as Nav
import Home
import Html exposing (..)
import Html.Attributes exposing (alt, height, href, src)
import Tuple exposing (mapSecond)
import Url exposing (Url)
import Url.Parser as UrlParser


type alias Flag =
    ()


main : Program Flag Model Msg
main =
    Browser.application
        { init = init
        , update = update
        , subscriptions = subscriptions
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChange
        , view = view
        }



-- MODEL


type Page
    = Home Home.Model
    | About


type alias Model =
    { navKey : Nav.Key
    , page : Page
    }


init : Flag -> Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    let
        defaultModel =
            { navKey = key, page = Home Home.empty }
    in
    changePage url defaultModel



-- UPDATE


type Msg
    = GotHomeMsg Home.Msg
    | LinkClicked UrlRequest
    | UrlChange Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model.page ) of
        ( LinkClicked urlRequest, _ ) ->
            case urlRequest of
                Internal url ->
                    ( model
                    , Nav.pushUrl model.navKey (Url.toString url)
                    )

                External url ->
                    ( model
                    , Nav.load url
                    )

        ( UrlChange url, page ) ->
            let
                ( newModel, cmd ) =
                    changePage url model
            in
            if newModel.page == page then
                ( model, cmd )

            else
                ( newModel, cmd )

        ( GotHomeMsg subMsg, Home home ) ->
            Home.update subMsg home
                |> updateWith Home GotHomeMsg model

        ( _, _ ) ->
            ( model, Cmd.none )


updateWith : (subModel -> Page) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toPage toMsg model ( subModel, subCmd ) =
    ( { model | page = toPage subModel }
    , Cmd.map toMsg subCmd
    )


changePage : Url -> Model -> ( Model, Cmd Msg )
changePage url model =
    url
        |> UrlParser.parse (urlParser model)
        |> Maybe.withDefault (updateWith Home GotHomeMsg model Home.init)


urlParser : Model -> UrlParser.Parser (( Model, Cmd Msg ) -> a) a
urlParser model =
    UrlParser.oneOf
        [ UrlParser.map (updateWith Home GotHomeMsg model Home.init) UrlParser.top
        , UrlParser.map ( { model | page = About }, Cmd.none ) (UrlParser.s "about")
        ]



-- SUBSCRIPTIONS


subscriptions : Model -> Sub Msg
subscriptions _ =
    Sub.none



-- VIEW


view : Model -> Document Msg
view model =
    let
        ( title, page ) =
            case model.page of
                Home home ->
                    ( Home.title home, Home.view home )
                        |> mapSecond (Html.map GotHomeMsg)

                About ->
                    ( About.title, About.view )
    in
    { title = title
    , body =
        [ viewNavbar, page, viewFooter ]
    }


viewNavbar : Html Msg
viewNavbar =
    header []
        [ nav []
            [ a [ href "/" ]
                [ img [ alt "Logo", height 70, src "../img/logo.svg" ]
                    []
                ]
            , ul []
                [ li []
                    [ a [ href "/about" ]
                        [ b []
                            [ span []
                                [ text "About" ]
                            ]
                        ]
                    ]
                ]
            ]
        ]


viewFooter : Html Msg
viewFooter =
    footer []
        [ hr []
            []
        , p []
            [ small []
                [ text "Made by Théo Danneels" ]
            ]
        ]
