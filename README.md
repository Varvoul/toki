---
title: Toki
emoji: 🌸
colorFrom: blue
colorTo: purple
sdk: docker
app_port: 8080
pinned: false
---

# Toki — Jikan v4 REST API (Self-Hosted)

Unofficial MyAnimeList REST API powered by [Jikan v4](https://github.com/jikan-me/jikan-rest).

All v4 endpoints, parameters, pagination, and filters work identically to the official Jikan v4 API.

**Base URL:** `https://<your-space>.hf.space/v4/`

## Example Endpoints

- `GET /v4/anime/1` — Cowboy Bebop
- `GET /v4/manga/1` — Monster
- `GET /v4/characters/1` — Spike Spiegel
- `GET /v4/search/anime?q=naruto`
- `GET /v4/top/anime`
- `GET /v4/seasons/now`
- `GET /v4/random/anime`