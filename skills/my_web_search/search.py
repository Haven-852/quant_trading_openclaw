from duckduckgo_search import DDGS
import requests
from bs4 import BeautifulSoup


def search(query, max_results=5):
    results = []

    with DDGS() as ddgs:
        for r in ddgs.text(query, max_results=max_results):
            results.append({
                "title": r["title"],
                "url": r["href"],
                "snippet": r["body"]
            })

    return results


def fetch_page(url):

    r = requests.get(url, timeout=10)

    soup = BeautifulSoup(r.text, "html.parser")

    paragraphs = soup.find_all("p")

    text = "\n".join(p.get_text() for p in paragraphs)

    return text[:5000]