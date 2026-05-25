"""Validate XML with XSD and run XSLT via Saxon-HE.

Usage
-----
python python/11_validate_and_transform.py
"""

import argparse
import subprocess
import sys
import lxml.etree as ET

from pathlib import Path
from typing import List

# Classpath for Saxon-HE and XML Resolver libraries
SAXON_CLASSPATH = ":".join(["libs/saxon-he-12.4.jar", "libs/xmlresolver-5.1.1.jar"])

# Supported languages for the filtering guides transformation (scenario 3)
SUPPORTED_LANGUAGES = (
    "danish",
    "english",
    "french",
    "german",
    "icelandic",
    "irish",
    "italian",
    "japanese",
    "norwegian",
    "scottish gaelic",
    "spanish",
    "swedish",
)

# Keywords to exit the CLI program
EXIT_KEYWORDS = {"quit", "exit", "q", "leave", "bye", "close", "stop", "end"}

# Default dataset and output paths (centralized for easier maintenance)
XML_PATH = "dataset/merged_datasets.xml"
XSL_DIR = "xsl/"
OUTPUTS_DIR = "outputs/"
XSD_PATH = "schema/schema.xsd"

# Homepage message for the CLI program
INTRO_MESSAGE = """
This CLI program lets you select different XSLT transformations.

You can use the following commands:
    • 0  : exit the program
    • 01 : list all tours (HTML)
    • 02 : list all guides (HTML)
    • 03 --lang <language> : list guides that speak a specific language (HTML)
    • 04 : map all tour locations (HTML)
    • 05 : emergency contacts dashboard (HTML)
    • 06 : bikes inventory dashboard (HTML)
    • 07 : business analysis (JSON)
    • 08 : operational analysis (JSON)
    • 09 : merge every sub-dataset XML (XML)
    • 10 : anonymize the dataset (XML)
"""


def validate(xml_path_list: list[Path], xsd_path: Path) -> None:
    """Validate XML files against the XSD schema.

    Parameters
    ----------
    xml_path_list : list of Path
        XML documents to validate.
    xsd_path : Path
        Schema describing the structure.

    Raises
    ------
    SystemExit
        If validation fails.
    """
    schema_doc = ET.parse(str(xsd_path))
    schema = ET.XMLSchema(schema_doc)
    for xml_path in xml_path_list:
        xml_doc = ET.parse(str(xml_path))
        if not schema.validate(xml_doc):
            print("XSD validation failed:", file=sys.stderr)
            for entry in schema.error_log:
                print(f"- Line {entry.line}: {entry.message}", file=sys.stderr)
            sys.exit(1)


def transform_with_saxon(
    xml_paths: list[Path],
    xsl_path: Path,
    out_path: Path,
    lang: str | None,
    merge: bool = False,
) -> None:
    """Run Saxon-HE for the requested transformation.

    Parameters
    ----------
    xml_paths : list of Path
        Input XML documents (the first entry is used unless merge is True).
    xsl_path : Path
        Stylesheet to execute.
    out_path : Path
        Destination file for the transformation result.
    lang : str or None
        Optional language parameter forwarded to the XSLT.
    merge : bool, default=False
        When True, execute the initial template and pass every XML via source-files.
    """

    # If a language is provided, we pass it as a parameter to the XSLT.
    # The XML files use the Title Case for language tags, so we convert
    # the language to title case here before sending it to Saxon.
    if lang:
        command: List[str] = [
            "java",
            "-cp",
            SAXON_CLASSPATH,
            "net.sf.saxon.Transform",
            f"-s:{xml_paths[0]}",
            f"-xsl:{xsl_path}",
            f"-o:{out_path}",
            f"lang={lang.title()}",  # using title case to match with tag content in xml file
        ]

    # The 'merge' transformation is used when we want the stylesheet to read
    # multiple source files in a single run. Some XSLTs expect
    # relative paths, so we prefix with "../" for Saxon's libs working directory.
    elif merge:

        # Build a space-separated list of relative paths for Saxon's
        # `source-files` parameter. Keep this as a single string because
        # Saxon expects one argument (not a Python list) for that parameter.
        new_xml_path = [f"../{p}" for p in xml_paths]
        merged_path = " ".join(new_xml_path)
        command: List[str] = [
            "java",
            "-cp",
            SAXON_CLASSPATH,
            "net.sf.saxon.Transform",
            f"-xsl:{xsl_path}",
            f"-o:{out_path}",
            "-it:main",
            f"source-files={merged_path}",
        ]

    else:
        command: List[str] = [
            "java",
            "-cp",
            SAXON_CLASSPATH,
            "net.sf.saxon.Transform",
            f"-s:{xml_paths[0]}",
            f"-xsl:{xsl_path}",
            f"-o:{out_path}",
        ]
    try:
        subprocess.run(command, check=True)
    except FileNotFoundError:
        print("Error: 'java' not found. Please install Java (JRE/JDK).", file=sys.stderr)
        sys.exit(1)
    except subprocess.CalledProcessError as exc:
        print("Saxon transform failed.", file=sys.stderr)
        print("Command:", " ".join(command), file=sys.stderr)
        sys.exit(exc.returncode)


def check_paths_exist(paths: list[Path]) -> None:
    """Check every listed path exists before proceeding."""
    for element in paths:
        if element.exists():
            continue
        print(f"Missing file: {element}", file=sys.stderr)
        sys.exit(1)


def apply_transformation(
    xml_path: list[Path],
    xsl_path: Path,
    out_path: Path,
    xsd_path: Path,
    lang: str | None = None,
    merge: bool = False,
) -> None:
    """Validate inputs then perform the XSLT transformation.

    Parameters
    ----------
    xml_path : list of Path
        XML sources to validate and transform.
    xsl_path : Path
        Stylesheet that drives the transformation.
    out_path : Path
        Destination path for the generated artifact.
    xsd_path : Path
        XSD schema used for validation.
    lang : str or None, optional
        Optional language argument forwarded to the stylesheet.
    merge : bool, default=False
        Whether to merge multiple XML files via Saxon's ``source-files``.
    """
    # Validate inputs before attempting transformation
    check_paths_exist(xml_path + [xsl_path])
    validate(xml_path, xsd_path)
    # Check the output directory exists before calling Saxon
    out_path.parent.mkdir(parents=True, exist_ok=True)
    transform_with_saxon(xml_path, xsl_path, out_path, lang, merge=merge)
    print(f"Wrote: {out_path}")


def handle_language_arg(raw: str) -> str:
    """Normalize user-provided language text.

    Parameters
    ----------
    raw : str
        Language text as typed by the user.

    Returns
    -------
    str
        Lowercase language name with spaces normalized.
    """

    # Prevents an issue with "Scottish-Gaelic", "scottish_gaelic" or 'Scottish Gaelic'
    # which all map to "scottish gaelic" used by SUPPORTED_LANGUAGES
    cleaned = raw.strip(" \"'<>")
    cleaned = cleaned.lower().replace("_", " ").replace("-", " ")
    return " ".join(cleaned.split())


def main() -> None:
    """Launch the interactive validate → transform pipeline."""

    print(INTRO_MESSAGE)

    while True:
        # Configure the CLI program
        parser = argparse.ArgumentParser(description="Process some inputs.")
        parser.add_argument("command")
        parser.add_argument(
            "--lang",
            dest="language",
            # `--lang` uses `nargs="+"` so the user can enter multi-word languages without quotes
            nargs="+",
            help="Specify the language",
        )

        query = input("Enter your command: ").strip()

        if not query:
            print("Command cannot be empty")
            continue

        if query.lower() in EXIT_KEYWORDS:
            print("Exiting the program")
            break

        tokens = query.split()

        try:
            args = parser.parse_args(tokens)
        except SystemExit:
            print("Invalid command syntax.")
            continue

        # After parsing, produce a single-string language value (or None)
        # We keep the raw `args.language` list if we need to get
        # what the user typed when using unsupported values
        language_arg = None
        if args.language:
            language_arg = handle_language_arg(" ".join(args.language))

        xml_path = XML_PATH
        xsl_path = XSL_DIR
        out_path = OUTPUTS_DIR
        xsd_path = XSD_PATH

        match args.command:
            case "0":
                print("Exiting the program")
                break

            case "01":
                print("Running 01: tours → HTML")
                xsl_path += "01_tours_to_html.xsl"
                out_path += "html/01_tours.html"
                apply_transformation(
                    xml_path=[Path(xml_path)],
                    xsl_path=Path(xsl_path),
                    out_path=Path(out_path),
                    xsd_path=Path(xsd_path),
                )

            case "02":
                print("Running 02: guides → HTML")
                xsl_path += "02_guides_to_html.xsl"
                out_path += "html/02_guides.html"
                apply_transformation(
                    xml_path=[Path(xml_path)],
                    xsl_path=Path(xsl_path),
                    out_path=Path(out_path),
                    xsd_path=Path(xsd_path),
                )

            case "03":
                if not language_arg:
                    print("Command 03 requires --lang <language>.")
                    continue
                language = language_arg
                if language not in SUPPORTED_LANGUAGES:
                    print(" ".join(args.language) + " is not supported; choose from:")
                    for entry in SUPPORTED_LANGUAGES:
                        print(f"- {entry}")
                    continue
                print("Running 03: guides filtered by language")
                xsl_path += "03_guides_filtered_by_language_to_html.xsl"
                out_path += f"html/03_{language}_speaking_guides.html"
                apply_transformation(
                    xml_path=[Path(xml_path)],
                    xsl_path=Path(xsl_path),
                    out_path=Path(out_path),
                    xsd_path=Path(xsd_path),
                    lang=language,
                )

            case "04":
                print("Running 04: tours map → HTML")
                xsl_path += "04_tours_map_to_html.xsl"
                out_path += "html/04_tours_map.html"
                apply_transformation(
                    xml_path=[Path(xml_path)],
                    xsl_path=Path(xsl_path),
                    out_path=Path(out_path),
                    xsd_path=Path(xsd_path),
                )

            case "05":
                print("Running 05: emergency contacts dashboard")
                xsl_path += "05_emergency_contacts_to_html.xsl"
                out_path += "html/05_emergency_contacts.html"
                apply_transformation(
                    xml_path=[Path(xml_path)],
                    xsl_path=Path(xsl_path),
                    out_path=Path(out_path),
                    xsd_path=Path(xsd_path),
                )

            case "06":
                print("Running 06: bikes inventory dashboard")
                xsl_path += "06_bikes_inventory_to_html.xsl"
                out_path += "html/06_bikes_inventory.html"
                apply_transformation(
                    xml_path=[Path(xml_path)],
                    xsl_path=Path(xsl_path),
                    out_path=Path(out_path),
                    xsd_path=Path(xsd_path),
                )

            case "07":
                print("Running 07: business analysis JSON")
                xsl_path += "07_business_analysis_to_json.xsl"
                out_path += "json/07_business_analysis.json"
                apply_transformation(
                    xml_path=[Path(xml_path)],
                    xsl_path=Path(xsl_path),
                    out_path=Path(out_path),
                    xsd_path=Path(xsd_path),
                )

            case "08":
                print("Running 08: operational analysis JSON")
                xsl_path += "08_operational_analysis_to_json.xsl"
                out_path += "json/08_operational_analysis.json"
                apply_transformation(
                    xml_path=[Path(xml_path)],
                    xsl_path=Path(xsl_path),
                    out_path=Path(out_path),
                    xsd_path=Path(xsd_path),
                )

            case "09":
                print("Running 09: merge sub-datasets")
                # For the merge scenario we point to the sub-datasets folder
                xml_path = "dataset/sub_datasets"
                xsl_path += "09_merge_datasets_to_xml.xsl"
                out_path += "xml/09_merged_datasets.xml"
                xml_list = sorted(Path(xml_path).glob("*.xml"))
                apply_transformation(
                    xml_path=xml_list,
                    xsl_path=Path(xsl_path),
                    out_path=Path(out_path),
                    xsd_path=Path(xsd_path),
                    merge=True,
                )

            case "10":
                print("Running 10: anonymized dataset")
                xsl_path += "10_data_anonymization_to_xml.xsl"
                out_path += "xml/10_anonymized_data.xml"
                apply_transformation(
                    xml_path=[Path(xml_path)],
                    xsl_path=Path(xsl_path),
                    out_path=Path(out_path),
                    xsd_path=Path(xsd_path),
                )

            case _:
                print("Command not found. Use 0 or 01-10 as documented.")


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        # Exit quietly on user interrupt (Ctrl-C / Cmd-C)
        print("\nExiting.")
        sys.exit(0)
