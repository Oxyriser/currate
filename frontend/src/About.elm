module About exposing (title, view)

import Html exposing (Html, a, h1, header, p, text)
import Html.Attributes exposing (href)


title : String
title =
    "About"


view : Html msg
view =
    header []
        [ h1 [] [ text "About this website" ]
        , p []
            [ text "This website uses the api of "
            , a [ href "https://min-api.cryptocompare.com/" ] [ text "CryptoCompare" ]
            ]
        ]
