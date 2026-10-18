#pragma once

#include "stats/StatsTypes.h"

#include <QCoroTask>
#include <QJsonValue>
#include <QString>
#include <QUrlQuery>

class QNetworkAccessManager;

namespace swiftify {

/// a stats.fm account, as its public profile tells
struct StatsFmProfile {
    QString id;
    QString displayName;
    QUrl imageUrl;
    /// plus accounts get top albums and play counts by time
    bool isPlus = false;
};

/// what stats.fm says when asked about a user who is not there, or whose
/// stats are private
class StatsFmError : public std::exception {
public:
    enum class Kind { NotFound, Private, Network, RateLimited, Other };

    StatsFmError(Kind kind, QString message)
        : m_kind(kind)
        , m_message(std::move(message))
    {
    }

    Kind kind() const { return m_kind; }
    const QString &message() const { return m_message; }
    const char *what() const noexcept override { return "stats.fm request failed"; }

private:
    Kind m_kind;
    QString m_message;
};

/// stats.fm's public api, read with nothing but the username: a public
/// profile's stats are open to anyone, as on the website
class StatsFmClient {
public:
    explicit StatsFmClient(QNetworkAccessManager *network);

    /// the username the way stats.fm takes it: trimmed, a profile link
    /// reduced to its last part. empty when it cannot be one
    static QString normalizeUsername(const QString &raw);
    static QString rangeName(StatsPeriod period);

    QCoro::Task<StatsFmProfile> profile(QString username);
    /// everything the stats page shows for `period`
    QCoro::Task<StatsSnapshot> snapshot(QString username, StatsPeriod period, bool isPlus);

    // --- the parts of a reply, public for the tests ---------------------------------
    static StatEntry track(const QJsonObject &entry);
    static StatEntry artist(const QJsonObject &entry);
    static StatEntry album(const QJsonObject &entry);
    static StatEntry genre(const QJsonObject &entry);
    static StatEntry recentStream(const QJsonObject &entry);
    static Song song(const QJsonObject &track);
    static void readDates(const QJsonObject &dates, StatsSnapshot &snapshot);
    static void readDays(const QJsonObject &perDay, StatsSnapshot &snapshot);
    /// albums worked out from the top tracks, for accounts without plus
    static QList<StatEntry> albumsFromTracks(const QList<StatEntry> &tracks);

private:
    QCoro::Task<QJsonValue> get(QString path, QUrlQuery query = {});

    QNetworkAccessManager *m_network;
};

} // namespace swiftify
