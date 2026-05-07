"""
Funciones auxiliares para buscar imágenes HLS, cargar bandas raster,
calcular índices espectrales y representar la severidad del incendio.
"""

import os

os.environ.pop("PROJ_LIB", None)
os.environ.pop("PROJ_DATA", None)

from pystac_client import Client
import planetary_computer
import rasterio
import rasterio.mask
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.patches as mpatches
from matplotlib.colors import ListedColormap, BoundaryNorm


def buscar_imagenes(bbox, fecha_inicio, fecha_fin):
    """
    Busca imágenes HLS en el área y rango temporal indicado.
    """

    catalog = Client.open("https://planetarycomputer.microsoft.com/api/stac/v1")

    search = catalog.search(
        collections=["hls2-s30"],
        bbox=bbox,
        datetime=f"{fecha_inicio}/{fecha_fin}",
        query={"eo:cloud_cover": {"lt": 20}}
    )

    items = list(search.items())
    items = [planetary_computer.sign(item) for item in items]

    return items


def seleccionar_menor_nubosidad(items):
    """
    Selecciona la imagen con menor porcentaje de nubosidad.
    """

    items_ordenados = sorted(
        items,
        key=lambda item: item.properties.get("eo:cloud_cover", 999)
    )

    return items_ordenados[0]


from shapely.geometry import box, mapping
from rasterio.warp import transform_geom


def cargar_banda(item, nombre_banda, bbox):
    """
    Carga una banda y aplica un clip al área de estudio.
    """

    url = item.assets[nombre_banda].href

    with rasterio.open(url) as src:
        # Crear bbox en WGS84
        geom_wgs84 = mapping(box(*bbox))

        # Reproyectar bbox al CRS del raster
        geom_proj = transform_geom(
            "EPSG:4326",  # origen (lat/lon)
            src.crs,  # destino (CRS raster)
            geom_wgs84
        )

        # Aplicar clip
        banda_clip, transform = rasterio.mask.mask(
            src, [geom_proj], crop=True
        )

        banda_clip = banda_clip[0]  # eliminar dimensión extra

    return banda_clip


def calcular_nbr(nir, swir):
    """
    Calcula el índice NBR evitando divisiones no válidas.
    """

    nir = nir.astype(float)
    swir = swir.astype(float)

    denominador = nir + swir
    nbr = np.full(nir.shape, np.nan)

    mascara_valida = denominador != 0

    nbr[mascara_valida] = (
        nir[mascara_valida] - swir[mascara_valida]
    ) / denominador[mascara_valida]

    return nbr


def calcular_dnbr(nbr_pre, nbr_post):
    """
    Calcula el índice de severidad del incendio, dNBR.
    """

    dnbr = np.where(
        np.isfinite(nbr_pre) & np.isfinite(nbr_post),
        nbr_pre - nbr_post,
        np.nan
    )

    return dnbr


def clasificar_dnbr(dnbr):
    """
    Clasifica el dNBR en niveles de severidad.
    """

    bins = [-np.inf, -0.25, -0.1, 0.1, 0.27, 0.44, np.inf]
    clases = np.digitize(dnbr, bins)

    return clases


def plot_dnbr(clases):
    """
    Representa el dNBR clasificado con leyenda por categorías.
    """

    clases = np.nan_to_num(clases)

    colores = [
        "#006837",
        "#31a354",
        "#addd8e",
        "#fdae61",
        "#f46d43",
        "#a50026"
    ]

    cmap = ListedColormap(colores)
    norm = BoundaryNorm([1, 2, 3, 4, 5, 6, 7], cmap.N)

    etiquetas = [
        "Alto crecimiento de vegetación posterior al fuego",
        "Bajo crecimiento de vegetación posterior al fuego",
        "Zonas estables o sin quemar",
        "Zonas quemadas con gravedad baja",
        "Zonas quemadas con gravedad moderada-baja",
        "Zonas quemadas con gravedad moderada-alta"
    ]

    fig, ax = plt.subplots(figsize=(14, 8))
    plt.subplots_adjust(right=0.75)

    ax.imshow(clases, cmap=cmap, norm=norm)
    ax.set_title(
        "Índice de severidad del incendio (dNBR) - Evros, Grecia 2023",
        fontweight="bold"
    )
    ax.axis("off")

    patches = [
        mpatches.Patch(color=colores[i], label=etiquetas[i])
        for i in range(len(etiquetas))
    ]

    ax.legend(
        handles=patches,
        loc="center left",
        bbox_to_anchor=(1.02, 0.5),
        frameon=False,
        title="Nivel de severidad",
        fontsize=9
    )

    plt.savefig("outputs/dnbr.png", dpi=300, bbox_inches="tight")
    plt.show()