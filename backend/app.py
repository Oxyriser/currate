# -*- coding: utf-8 -*-
"""The app module, containing the app factory function."""
from flask import Flask, request
from api import get_cryptos, get_fiats, convert, historic_convert

app = Flask(__name__.split(".")[0])


@app.after_request
def after_request(response):
    header = response.headers
    header["Access-Control-Allow-Origin"] = "*"
    return response


@app.route("/list_cryptos")
def list_cryptos():
    # limit = request.args.get("limit", default=10, type=int)
    return '["BTC", "ETH", "USDT", "XRP", "BCH", "BSV", "ADA", "LTC", "BNB", "CRO"]'


@app.route("/list_fiats")
def list_fiats():
    return '["EUR", "USD", "JPY", "GBD", "AUD", "CAD", "CHF"]'


@app.route("/convertion_rate")
def value():
    fsym = request.args.get("fsym", type=str)
    tsym = request.args.get("tsym", type=str)
    # return "9701.26"
    return convert(fsym, tsym)


@app.route("/graph")
def graph():
    fsym = request.args.get("fsym", type=str)
    tsym = request.args.get("tsym", type=str)
    timeframe = request.args.get("timeframe", default="histoday", type=str)
    # return "[9292.81, 9691.61, 9624.3, 9292.94, 9241.32, 9158.07, 9007.14, 9120.39, 9187.07, 9136.47, 9238.89, 9092.8, 9066.46, 9142.2, 9081.44, 9347.05, 9257.32, 9439.2, 9238.95, 9288.57, 9237.13, 9300.95, 9237.89, 9256.07, 9193.22, 9133.23, 9156.79, 9177.22, 9216.02, 9164.42, 9378.6]"
    return historic_convert(fsym, tsym, timeframe)


if __name__ == "__main__":
    # get_cryptos()
    # get_fiats()
    app.run(host="0.0.0.0")
