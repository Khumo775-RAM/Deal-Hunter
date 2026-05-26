import httpx
from fastapi import HTTPException

FRANKFURTER_BASE = "https://api.frankfurter.dev/v1"

SUPPORTED_CURRENCIES = {
    # Major / commonly used
    "USD", "EUR", "GBP", "JPY", "CHF", "AUD", "CAD", "NZD",
    # Africa
    "ZAR", "NGN", "KES", "GHS", "EGP", "MAD", "DZD", "ETB",
    "TZS", "UGX", "ZMW", "MZN", "BWP", "NAD", "MWK", "LSL",
    "SZL", "RWF", "SDG", "SSP", "GMD", "GNF", "MGA", "ZWG",
    "SCR", "MUR", "CVE", "STN", "SLE", "DJF", "KMF", "SOS",
    "LRD", "SBD", "XAF", "XOF",
    # Asia
    "CNY", "CNH", "INR", "KRW", "SGD", "HKD", "TWD", "MYR",
    "THB", "IDR", "PHP", "PKR", "BDT", "LKR", "NPR", "MMK",
    "VND", "KHR", "LAK", "MNT", "BND", "MVR", "BTN", "KZT",
    "UZS", "TJS", "KGS", "AZN", "AMD", "GEL", "ILS", "AED",
    "SAR", "QAR", "KWD", "BHD", "OMR", "JOD", "IQD", "IRR",
    "YER", "LBP", "SYP", "AFN",
    # Europe
    "DKK", "SEK", "NOK", "PLN", "CZK", "HUF", "RON", "BGN",
    "HRK", "RSD", "MKD", "BAM", "ALL", "MDL", "UAH", "RUB",
    "BYN", "ISK", "TRY", "GIP", "FKP", "SHP",
    # Americas
    "BRL", "MXN", "ARS", "COP", "CLP", "PEN", "UYU", "BOB",
    "PYG", "VES", "GTQ", "CRC", "HNL", "NIO", "DOP", "JMD",
    "TTD", "BBD", "BSD", "BZD", "GYD", "SRD", "HTG", "PAB",
    "SVC", "KYD", "XCD", "AWG", "ANG", "BMD", "CUP",
    # Pacific & Other
    "FJD", "PGK", "WST", "VUV", "TOP", "XPF", "XCG",
    # Precious metals
    "XAG", "XAU", "XPD", "XPT",
    # Other active
    "AOA", "AZN", "BIF", "BYN", "CDF", "CVE", "ERN", "MOP",
    "MRU", "MUR", "TMT", "TND", "TZS",
}

_rate_cache: dict[str, float] = {}


async def get_exchange_rate(target_currency: str) -> float:
    """Fetch USD → target_currency exchange rate from Frankfurter. Results are cached per session."""
    currency = target_currency.upper()

    if currency == "USD":
        return 1.0

    if currency not in SUPPORTED_CURRENCIES:
        raise HTTPException(
            status_code=400,
            detail=f"Currency '{currency}' is not supported. Supported currencies: {sorted(SUPPORTED_CURRENCIES)}",
        )

    if currency in _rate_cache:
        return _rate_cache[currency]

    async with httpx.AsyncClient(timeout=10) as client:
        try:
            response = await client.get(
                f"{FRANKFURTER_BASE}/latest",
                params={"base": "USD", "symbols": currency},
            )
            response.raise_for_status()
        except httpx.HTTPStatusError:
            raise HTTPException(status_code=502, detail="Currency conversion service unavailable.")
        except httpx.RequestError:
            raise HTTPException(status_code=503, detail="Could not reach the currency conversion service.")

    rate = response.json()["rates"][currency]
    _rate_cache[currency] = rate
    return rate


def convert_price(amount: float, rate: float) -> float:
    return round(amount * rate, 2)
