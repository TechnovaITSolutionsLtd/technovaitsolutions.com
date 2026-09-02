#!/usr/bin/env python3
"""Serve a static site locally while resolving clean URLs to matching HTML files."""

from argparse import ArgumentParser
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


class CleanUrlHandler(SimpleHTTPRequestHandler):
    def translate_path(self, path: str) -> str:
        translated = Path(super().translate_path(path))
        if not translated.exists() and not translated.suffix:
            html_candidate = translated.with_suffix(".html")
            if html_candidate.is_file():
                return str(html_candidate)
        return str(translated)


def main() -> None:
    parser = ArgumentParser()
    parser.add_argument("--directory", required=True)
    parser.add_argument("--port", required=True, type=int)
    arguments = parser.parse_args()

    root = Path(arguments.directory).resolve()
    handler = partial(CleanUrlHandler, directory=str(root))
    server = ThreadingHTTPServer(("127.0.0.1", arguments.port), handler)
    print(f"Serving {root} at http://127.0.0.1:{arguments.port}/", flush=True)
    server.serve_forever()


if __name__ == "__main__":
    main()
