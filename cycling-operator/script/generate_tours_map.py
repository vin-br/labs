"""Generate tours map HTML (Leaflet) directly from XML, without XSLT.

Usage
-----
python python/12_generate_tours_map.py
"""

import argparse
import json
import xml.etree.ElementTree as ET
from pathlib import Path
from typing import Any, Dict, List, Optional


def read_text(element: Optional[ET.Element]) -> str:
    """Return stripped text content or an empty string.

    Parameters
    ----------
    element : xml.etree.ElementTree.Element or None
        Node whose textual content will be read.

    Returns
    -------
    str
        Trimmed content, or an empty string when the node is missing.
    """

    if element is None or element.text is None:
        return ""
    return element.text.strip()


def read_float(element: Optional[ET.Element]) -> Optional[float]:
    """Convert element text to float where possible.

    Parameters
    ----------
    element : xml.etree.ElementTree.Element or None
        Node that should contain a numeric value.

    Returns
    -------
    float or None
        Numeric value, or ``None`` if conversion fails.
    """

    try:
        return float(read_text(element))
    except (TypeError, ValueError):
        return None


def extract_tours(xml_path: Path) -> List[Dict[str, Any]]:
    """Parse the XML file and return a list of tour dictionaries.
    The function performs the following steps:
    1. Parse the XML dataset and collect only the fields that the map needs.
    2. Serialize the list into JSON and embed it in an HTML template.
    3. Let Leaflet render markers/lines straight from the JSON payload in the browser.

    Parameters
    ----------
    xml_path : Path
        Path to the XML dataset containing tour nodes.

    Returns
    -------
    list of dict
        Each dict stores the fields needed for rendering the Leaflet cards.
    """

    tree = ET.parse(xml_path)
    root = tree.getroot()

    # Support datasets with their namespace defined
    ns_prefix = ""
    if root.tag.startswith("{"):
        ns_prefix = root.tag.split("}")[0] + "}"

    def qualify(path: str) -> str:
        """Prefix XPath fragments with the dataset namespace when needed."""

        if not ns_prefix:
            return path
        return "/".join(f"{ns_prefix}{segment}" for segment in path.split("/"))

    tours: List[Dict[str, Any]] = []
    tours_section = root.find(qualify("tours"))
    if tours_section is None:
        return tours

    for tour_element in tours_section.findall(qualify("tour")):
        start_latitude = read_float(
            tour_element.find(qualify("starting_point/coordinates/latitude"))
        )
        start_longitude = read_float(
            tour_element.find(qualify("starting_point/coordinates/longitude"))
        )
        end_latitude = read_float(
            tour_element.find(qualify("final_destination/coordinates/latitude"))
        )
        end_longitude = read_float(
            tour_element.find(qualify("final_destination/coordinates/longitude"))
        )

        # Normalize coordinate pairs so the browser code only checks for None
        start_pair = (
            [start_latitude, start_longitude]
            if None not in (start_latitude, start_longitude)
            else None
        )
        end_pair = (
            [end_latitude, end_longitude] if None not in (end_latitude, end_longitude) else None
        )

        # Build representations for price and date ranges
        price_text = (
            read_text(tour_element.find(qualify("price/amount")))
            + " "
            + read_text(tour_element.find(qualify("price/currency")))
        ).strip()
        date_text = (
            read_text(tour_element.find(qualify("duration/start_date")))
            + " - "
            + read_text(tour_element.find(qualify("duration/end_date")))
        ).strip()

        # Collect a dictionary with only the fields needed by the client-side map renderer
        tours.append(
            {
                "name": read_text(tour_element.find(qualify("tour_name"))),
                "category": read_text(tour_element.find(qualify("category"))),
                "distance": read_text(tour_element.find(qualify("distance"))),
                "start": start_pair,
                "end": end_pair,
                "price": price_text,
                "dates": date_text,
                "availability": read_text(
                    tour_element.find(qualify("tour_availability/availability"))
                ),
            }
        )

    return tours


def build_html(tours: List[Dict[str, Any]], title: str = "Tours Map") -> str:
    """Render the final Leaflet-ready HTML string.

    Parameters
    ----------
    tours : list of dict
        Result of :func:`extract_tours`.
    title : str, optional
        Heading that appears on top of the HTML page.

    Returns
    -------
    str
        A full HTML document ready to be written to disk.
    """

    tours_json = json.dumps(tours, ensure_ascii=False)
    return f"""<!DOCTYPE html>
<html>
  <head>
    <meta charset=\"utf-8\" />
    <title>{title}</title>
     <meta name="author"
      content="Audrey Costes, Halima Lemmouchi, Lina Marcela Diaz Bejarano, Vincent Boettcher" />
    <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\" />
    <link rel=\"stylesheet\" href=\"../css/styles.css\" />
    <link rel=\"stylesheet\"
      href=\"https://unpkg.com/leaflet@1.9.4/dist/leaflet.css\"
      integrity=\"sha256-p4NxAoJBhIIN+hmNHrzRCf9tD/miZyoHS5obTRR9BMY=\"
      crossorigin=\"\" />
    <style>
      #map {{
        height: 80vh;
        margin: 1.5rem;
        border-radius: 0.4rem;
        box-shadow: 0 0.4rem 1rem rgba(0,0,0,0.18);
      }}
    </style>
  </head>
  <body>
    <header class=\"page-header\"><h1>{title}</h1></header>
    <div id=\"map\"></div>
    <script
      src=\"https://unpkg.com/leaflet@1.9.4/dist/leaflet.js\"
      integrity=\"sha256-20nQCchB9co0qIjJZRGuk2/Z9VM+kNiyxNV1lvTlZBo=\"
      crossorigin=\"\"></script>
    <script>
      const map = L.map('map');
      L.tileLayer(
        'https://{{s}}.tile.openstreetmap.org/{{z}}/{{x}}/{{y}}.png',
        {{ attribution: '&copy; OpenStreetMap contributors' }}
      ).addTo(map);
      const tours = {tours_json};
      const bounds = L.latLngBounds([]);

      function valid(coord) {{
        return Array.isArray(coord) && coord.length===2 &&
               !isNaN(coord[0]) && !isNaN(coord[1]);
      }}

      tours.forEach(tourData => {{
        const popupHtml = `
          <b>${{tourData.name}}</b><br/>
          ${{tourData.category}} • ${{tourData.distance}} km<br/>
          ${{tourData.dates}}<br/>
          ${{tourData.price}}<br/>
          ${{tourData.availability}}
        `;
        if (valid(tourData.start)) {{
          const startMarker = L.marker(tourData.start)
            .addTo(map)
            .bindPopup(popupHtml + '<br/><i>Start</i>');
          bounds.extend(tourData.start);
        }}
        if (valid(tourData.end)) {{
          const endMarker = L.marker(tourData.end, {{opacity:0.9}})
            .addTo(map)
            .bindPopup(popupHtml + '<br/><i>End</i>');
          bounds.extend(tourData.end);
        }}
        if (valid(tourData.start) && valid(tourData.end)) {{
          L.polyline(
            [tourData.start, tourData.end],
            {{color:'#0a84ff', weight:4, opacity:0.7}}
          ).addTo(map);
        }}
      }});

      if (bounds.isValid()) {{
        map.fitBounds(bounds.pad(0.15));
      }} else {{
        map.setView([0,0], 2);
      }}
    </script>
  </body>
</html>
"""


def main() -> None:
    """Run the CLI pipeline (parse XML → render HTML → write file).

    Returns
    -------
    None
        This function writes files for its side effect.
    """

    parser = argparse.ArgumentParser(
        description="Generate tours map HTML directly from XML (no XSLT)"
    )
    parser.add_argument(
        "--xml",
        default="dataset/merged_datasets.xml",
        help="Path to the XML input file (default: dataset/merged_datasets.xml)",
    )
    parser.add_argument(
        "--out",
        default="outputs/html/11_tours_map_py.html",
        help="Path to the HTML output file (default: outputs/html/11_tours_map_py.html)",
    )
    parser.add_argument("--title", default="Tours Map (Python)", help="Page title")
    args = parser.parse_args()

    xml_path = Path(args.xml)
    output_path = Path(args.out)

    tours = extract_tours(xml_path)
    html_document = build_html(tours, title=args.title)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(html_document, encoding="utf-8")
    print(f"Wrote: {output_path} (tours: {len(tours)})")


if __name__ == "__main__":
    main()
