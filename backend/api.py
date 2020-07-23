import json

from requests import Session
from requests.exceptions import ConnectionError, Timeout, TooManyRedirects
from cachetools import cached, TTLCache
from glom import glom
from contextlib import contextmanager
import os

cmc_url = "https://pro-api.coinmarketcap.com/v1"
cmc_headers = {
    "Accepts": "application/json",
    "X-CMC_PRO_API_KEY": os.getenv("CMC_API_KEY"),
}

cmc_session = Session()
cmc_session.headers.update(cmc_headers)


@contextmanager
def api_request(session, url, parameters=None):  # reset to dict?
    try:
        response = session.get(url, params=parameters)
        data = json.loads(response.text)
        yield data
    except (ConnectionError, Timeout, TooManyRedirects) as e:
        print(e)


@cached(cache=TTLCache(1, ttl=60 * 60 * 24))
def get_cryptos(limit=100):
    url = f"{cmc_url}/cryptocurrency/map"
    parameters = {"limit": str(limit), "sort": "cmc_rank"}
    with api_request(cmc_session, url, parameters) as data:
        return str(glom(data, ("data", ["symbol"]))).replace("'", '"')


@cached(cache=TTLCache(1, ttl=60 * 60 * 24))
def get_fiats():
    url = f"{cmc_url}/fiat/map"
    parameters = {"sort": "name"}
    with api_request(cmc_session, url, parameters) as data:
        return str(glom(data, ("data", ["symbol"]))).replace("'", '"')


cryptoc_url = "https://min-api.cryptocompare.com"
cryptoc_session = Session()
cryptoc_session.headers.update({"authorization": os.getenv("CRYPTOCOMPARE_API_KEY")})


def convert(fsym, tsym):
    url = f"{cryptoc_url}/data/price"
    parameters = {"fsym": fsym, "tsyms": tsym}
    with api_request(cryptoc_session, url, parameters) as data:
        return str(glom(data, tsym))


def historic_convert(fsym, tsym, timeframe="histoday"):
    url = f"{cryptoc_url}/data/v2/{timeframe}"
    parameters = {"fsym": fsym, "tsym": tsym, "limit": 30}
    with api_request(cryptoc_session, url, parameters) as data:
        return str(
            glom(data, ("Data.Data", [{"time": "time", "close": "close"}]))
        ).replace("'", '"')
