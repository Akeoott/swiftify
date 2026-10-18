#pragma once

// stats.fm replies for tst_stats, kept out of its .cpp: moc cannot read
// raw string literals

inline constexpr const char kTrackJson[] = R"({
            "position": 1, "streams": 42, "playedMs": 7560000,
            "track": {
                "name": "Song", "durationMs": 180000,
                "externalIds": {"spotify": ["4uLU6hMCjMI75M1A2tKUQC"]},
                "albums": [{"name": "Record", "image": "https://i.scdn.co/image/abc",
                            "externalIds": {"spotify": ["alb1"]}}],
                "artists": [{"name": "Singer", "externalIds": {"spotify": ["art1"]}},
                            {"name": "Guest", "externalIds": {"spotify": ["art2"]}}]
            }
        })";

inline constexpr const char kEstimatedTrackJson[] = R"({
            "streams": 3, "track": {"name": "S", "durationMs": 1000, "externalIds": {"spotify": ["t"]}}
        })";

inline constexpr const char kArtistJson[] = R"({
            "streams": 9, "artist": {"name": "Singer", "image": "https://x/y.jpg", "genres": ["indie", "pop", "rock"],
                                     "externalIds": {"spotify": ["art1"]}}
        })";

inline constexpr const char kGenreJson[] = R"({"streams": 5, "genre": {"tag": "shoegaze"}})";

inline constexpr const char kDatesJson[] = R"({
            "hours": {"0": {"count": 2}, "21": {"count": 9}, "30": {"count": 1}},
            "weekDays": {"1": {"count": 4}, "7": {"count": 6}}
        })";

inline constexpr const char kDaysJson[] = R"({"days": {"2026-10-16": {"count": 3}, "2026-10-17": {"count": 0}}})";

