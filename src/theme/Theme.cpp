#include "theme/Theme.h"

#include "app/Fonts.h"
#include "app/Settings.h"
#include "cpp/cam/hct.h"
#include "cpp/scheme/scheme_content.h"
#include "cpp/scheme/scheme_tonal_spot.h"
#include "theme/ColorMath.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QGuiApplication>
#include <QLoggingCategory>
#include <QQmlEngine>
#include <QStyleHints>

namespace swiftify {

Q_LOGGING_CATEGORY(lcTheme, "swiftify.theme")

namespace {

Theme *s_instance = nullptr;

bool systemPrefersLight()
{
    return QGuiApplication::styleHints()->colorScheme() == Qt::ColorScheme::Light;
}

} // namespace

Theme::Theme(Settings *settings, QObject *parent)
    : QObject(parent)
    , m_settings(settings)
    , m_colors(new MaterialScheme(this))
{
    if (!s_instance) {
        s_instance = this;
    }

    m_reloadDebounce.setSingleShot(true);
    m_reloadDebounce.setInterval(120);
    connect(&m_reloadDebounce, &QTimer::timeout, this, &Theme::reload);
    const auto scheduleReload = [this] { m_reloadDebounce.start(); };
    connect(&m_watcher, &QFileSystemWatcher::fileChanged, this, scheduleReload);
    connect(&m_watcher, &QFileSystemWatcher::directoryChanged, this, scheduleReload);
    connect(QGuiApplication::styleHints(), &QStyleHints::colorSchemeChanged, this, scheduleReload);
    connect(m_settings, &Settings::themeSourceChanged, this, scheduleReload);
    connect(m_settings, &Settings::themeModeChanged, this, scheduleReload);
    connect(m_settings, &Settings::matugenColorsPathChanged, this, scheduleReload);

    reload();
}

Theme::~Theme()
{
    if (s_instance == this) {
        s_instance = nullptr;
    }
}

Theme *Theme::instance()
{
    return s_instance;
}

Theme *Theme::create(QQmlEngine *, QJSEngine *)
{
    QJSEngine::setObjectOwnership(s_instance, QJSEngine::CppOwnership);
    return s_instance;
}

QString Theme::defaultSystemSchemePath()
{
    QString state = qEnvironmentVariable("XDG_STATE_HOME");
    if (state.isEmpty() || QDir::isRelativePath(state)) {
        state = QDir::homePath() + QStringLiteral("/.local/state");
    }
    return state + QStringLiteral("/quickshell/user/generated/colors.json");
}

QString Theme::systemSchemePath() const
{
    const QString configured = m_settings->matugenColorsPath();
    return configured.isEmpty() ? defaultSystemSchemePath() : configured;
}

QString Theme::fontFamily() const
{
    return fonts::interfaceFamily();
}

QString Theme::monoFontFamily() const
{
    return fonts::fixedFamily();
}

MaterialScheme::Roles Theme::rolesFromSeed(QColor seed, bool dark, bool fidelity)
{
    using namespace material_color_utilities;
    const Hct hct(seed.rgba() | 0xff000000u);
    if (fidelity) {
        return MaterialScheme::fromDynamicScheme(SchemeContent(hct, dark, 0.0));
    }
    return MaterialScheme::fromDynamicScheme(SchemeTonalSpot(hct, dark, 0.0));
}

QColor Theme::mix(const QColor &a, const QColor &b, qreal amountOfA)
{
    return color::mix(a, b, amountOfA);
}

QColor Theme::withAlpha(const QColor &color, qreal alpha)
{
    return color::withAlpha(color, alpha);
}

void Theme::reload()
{
    const bool wasUsingSystem = m_usingSystemScheme;
    const bool hadDark = m_colors->dark();

    watchSchemeFile();

    if (m_settings->themeSource() == QLatin1StringView("system")) {
        QFile file(systemSchemePath());
        if (file.open(QIODevice::ReadOnly)) {
            if (const auto roles = MaterialScheme::fromMatugenJson(file.readAll())) {
                const QColor background = (*roles)[static_cast<std::size_t>(MaterialScheme::Role::Background)];
                m_usingSystemScheme = true;
                m_colors->setRoles(*roles, color::luminance709(background) < 0.5);
                if (!wasUsingSystem || hadDark != m_colors->dark()) {
                    emit schemeChanged();
                }
                return;
            }
            // a half-written file reads as invalid; the next change event retries.
            qCInfo(lcTheme) << "ignoring an incomplete colour scheme in" << file.fileName();
        }
    }

    const bool dark = wantsDark();
    m_usingSystemScheme = false;
    if (const themes::Family *family = themes::find(m_settings->themeSource())) {
        m_colors->setRoles(themes::roles(dark ? family->dark : family->light, dark), dark);
    } else {
        m_colors->setRoles(rolesFromSeed(QColor::fromRgba(kAccent), dark, true), dark);
    }
    if (wasUsingSystem || hadDark != dark) {
        emit schemeChanged();
    }
}

bool Theme::wantsDark() const
{
    const QString mode = m_settings->themeMode();
    if (mode == QLatin1StringView("light")) {
        return false;
    }
    if (mode == QLatin1StringView("dark")) {
        return true;
    }
    return !systemPrefersLight();
}

QList<ThemeOption> Theme::themeOptions(bool dark) const
{
    using Role = MaterialScheme::Role;
    const auto option = [](const QString &id, const QString &name, const MaterialScheme::Roles &roles) {
        const auto role = [&roles](Role which) { return roles[static_cast<std::size_t>(which)]; };
        return ThemeOption {id, name, role(Role::Background), role(Role::SurfaceContainerLow), role(Role::OnSurface),
                            role(Role::Primary), role(Role::Secondary), role(Role::Tertiary)};
    };
    QList<ThemeOption> options;
#ifndef Q_OS_MACOS
    // the desktop's own scheme shows as it is, light or dark; before it
    // exists, as the colours it would fall back to
    QFile file(systemSchemePath());
    std::optional<MaterialScheme::Roles> desktop;
    if (file.open(QIODevice::ReadOnly)) {
        desktop = MaterialScheme::fromMatugenJson(file.readAll());
    }
    options.append(option(QStringLiteral("system"), QStringLiteral("Desktop"),
                          desktop ? *desktop : rolesFromSeed(QColor::fromRgba(kAccent), dark, true)));
#endif
    options.append(option(QStringLiteral("builtin"), QStringLiteral("Swiftify"), rolesFromSeed(QColor::fromRgba(kAccent), dark, true)));
    for (const themes::Family &family : themes::families()) {
        options.append(option(family.id, family.name, themes::roles(dark ? family.dark : family.light, dark)));
    }
    return options;
}

void Theme::watchSchemeFile()
{
    const QStringList watched = m_watcher.files() + m_watcher.directories();
    if (!watched.isEmpty()) {
        m_watcher.removePaths(watched);
    }
    if (m_settings->themeSource() != QLatin1StringView("system")) {
        return;
    }
    const QFileInfo info(systemSchemePath());
    // the directory catches the file appearing, or being replaced by a rename.
    if (info.dir().exists()) {
        m_watcher.addPath(info.absolutePath());
    }
    if (info.exists()) {
        m_watcher.addPath(info.absoluteFilePath());
    }
}

} // namespace swiftify
