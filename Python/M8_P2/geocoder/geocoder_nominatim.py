"""
Módulo para la geocodificación de direcciones con GeoPy.

Este archivo crea la función de geocodificación usando
Nominatim y aplica un RateLimiter para controlar la frecuencia
de peticiones al servicio.
"""

from geopy.geocoders import Nominatim
from geopy.extra.rate_limiter import RateLimiter


def crear_geocode():
 
    # Crear el geolocalizador de Nominatim con un identificador de usuario
    geolocator = Nominatim(user_agent="unigis_practica2_victoria")

    # Aplicar limitador de velocidad a las peticiones para evitar bloqueos del servicio
    geocode = RateLimiter(
        geolocator.geocode,
        min_delay_seconds=2,
        max_retries=2,
        error_wait_seconds=5,
        swallow_exceptions=True
    )

    return geocode