#pragma once

#include "theme/MaterialScheme.h"
#include "theme/Themes.h"

#include <QColor>
#include <QFileSystemWatcher>
#include <QObject>
#include <QTimer>
#include <QtQml/qqmlregistration.h>

class QQmlEngine;
class QJSEngine;

namespace swiftify {

class Settings;

/// the app chrome's colours. with the "system" source it follows the scheme
/// end4 generates from the wallpaper with matugen, live; otherwise, or when no
/// such file exists, or another source is chosen, it builds one from the
/// swiftify accent or from one of the rice themes (Themes.h), light or dark as
/// the theme mode says.
class Theme : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    Q_PROPERTY(swiftify::MaterialScheme *colors READ colors CONSTANT FINAL)
    Q_PROPERTY(bool dark READ dark NOTIFY schemeChanged FINAL)
    Q_PROPERTY(bool usingSystemScheme READ usingSystemScheme NOTIFY schemeChanged FINAL)
    Q_PROPERTY(QString systemSchemePath READ systemSchemePath NOTIFY schemeChanged FINAL)
    Q_PROPERTY(QString fontFamily READ fontFamily CONSTANT FINAL)
    Q_PROPERTY(QString monoFontFamily READ monoFontFamily CONSTANT FINAL)

public:
    /// swiftify's accent, #ff3d8a (MusicStyle.accent)
    static constexpr QRgb kAccent = 0xffff3d8a;

    explicit Theme(Settings *settings, QObject *parent = nullptr);
    ~Theme() override;

    static Theme *instance();
    static Theme *create(QQmlEngine *, QJSEngine *);

    MaterialScheme *colors() const { return m_colors; }
    bool dark() const { return m_colors->dark(); }
    bool usingSystemScheme() const { return m_usingSystemScheme; }
    /// the matugen file in use or looked for
    QString systemSchemePath() const;
    QString fontFamily() const;
    QString monoFontFamily() const;

    /// material 3 roles built from a seed colour, the way the fallback scheme is.
    /// `fidelity` keeps the seed's own chroma (artwork); otherwise tonal spot.
    static MaterialScheme::Roles rolesFromSeed(QColor seed, bool dark, bool fidelity);

    /// every colour source the settings offer, as swatches in light or dark:
    /// the desktop's scheme (on linux), the app's own, then the rice themes
    Q_INVOKABLE QList<swiftify::ThemeOption> themeOptions(bool dark) const;

    Q_INVOKABLE static QColor mix(const QColor &a, const QColor &b, qreal amountOfA);
    Q_INVOKABLE static QColor withAlpha(const QColor &color, qreal alpha);

signals:
    void schemeChanged();

private:
    void reload();
    void watchSchemeFile();
    /// light or dark, from the theme mode and the desktop's preference
    bool wantsDark() const;
    static QString defaultSystemSchemePath();

    Settings *m_settings;
    MaterialScheme *m_colors;
    QFileSystemWatcher m_watcher;
    /// matugen replaces the file, which fires several events in a row
    QTimer m_reloadDebounce;
    bool m_usingSystemScheme = false;
};

} // namespace swiftify
