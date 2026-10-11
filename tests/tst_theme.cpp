#include "app/Settings.h"
#include "theme/MaterialScheme.h"
#include "theme/Theme.h"
#include "theme/Themes.h"

#include <QFile>
#include <QGuiApplication>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>

using namespace swiftify;

namespace {

QByteArray matugenJson(const MaterialScheme::Roles &roles)
{
    QJsonObject object;
    for (std::size_t index = 0; index < roles.size(); ++index) {
        QString snake;
        for (const QChar character : MaterialScheme::roleKey(MaterialScheme::Role(index))) {
            if (character.isUpper()) {
                snake += u'_';
            }
            snake += character.toLower();
        }
        object.insert(snake, roles[index].name());
    }
    return QJsonDocument(object).toJson();
}

} // namespace

class ThemeTest : public QObject {
    Q_OBJECT

private slots:
    void seedSchemesFollowMaterialTones()
    {
        const auto dark = Theme::rolesFromSeed(QColor::fromRgba(Theme::kAccent), true, true);
        const auto light = Theme::rolesFromSeed(QColor::fromRgba(Theme::kAccent), false, true);
        const auto role = [](const MaterialScheme::Roles &roles, MaterialScheme::Role which) {
            return roles[static_cast<std::size_t>(which)];
        };
        // dark surfaces are dark and their text light, and the other way round.
        QVERIFY(role(dark, MaterialScheme::Role::Surface).lightnessF() < 0.2);
        QVERIFY(role(dark, MaterialScheme::Role::OnSurface).lightnessF() > 0.8);
        QVERIFY(role(light, MaterialScheme::Role::Surface).lightnessF() > 0.9);
        // a content scheme keeps the seed's hue for primary.
        QVERIFY(qAbs(role(light, MaterialScheme::Role::Primary).hueF()
                     - QColor::fromRgba(Theme::kAccent).hueF()) < 0.05);
    }

    void derivedColorsFollowEnd4()
    {
        MaterialScheme scheme;
        const auto roles = Theme::rolesFromSeed(QColor(Qt::blue), true, false);
        scheme.setRoles(roles, true);
        QCOMPARE(scheme.layer1(), scheme.surfaceContainerLow());
        QCOMPARE(scheme.subtext(), scheme.outline());
        QVERIFY(qAbs(scheme.shadowColor().alphaF() - 0.3) < 0.001);
        // hover sits 8% of the way from the layer towards its text.
        const QColor hover = scheme.layer1Hover();
        const qreal expected = scheme.layer1().redF() * 0.92 + scheme.onLayer1().redF() * 0.08;
        QVERIFY(qAbs(hover.redF() - expected) < 0.01);
    }

    void readsAndFollowsTheMatugenFile()
    {
        QTemporaryDir directory;
        Settings settings(directory.filePath(QStringLiteral("swiftify.conf")));
        settings.setThemeSource(QStringLiteral("system"));
        const QString path = directory.filePath(QStringLiteral("colors.json"));
        settings.setMatugenColorsPath(path);

        const auto green = Theme::rolesFromSeed(QColor(Qt::green), false, false);
        QFile file(path);
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write(matugenJson(green));
        file.close();

        Theme theme(&settings);
        QVERIFY(theme.usingSystemScheme());
        QVERIFY(!theme.dark());
        QCOMPARE(theme.colors()->primary(), green[static_cast<std::size_t>(MaterialScheme::Role::Primary)]);

        QSignalSpy changed(theme.colors(), &MaterialScheme::changed);
        const auto red = Theme::rolesFromSeed(QColor(Qt::red), true, false);
        QVERIFY(file.open(QIODevice::WriteOnly | QIODevice::Truncate));
        file.write(matugenJson(red));
        file.close();
        QTRY_VERIFY_WITH_TIMEOUT(changed.count() > 0, 3000);
        QVERIFY(theme.dark());
        QCOMPARE(theme.colors()->primary(), red[static_cast<std::size_t>(MaterialScheme::Role::Primary)]);
    }

    void fallsBackWhenTheFileIsMissingOrIncomplete()
    {
        QTemporaryDir directory;
        Settings settings(directory.filePath(QStringLiteral("swiftify.conf")));
        settings.setThemeSource(QStringLiteral("system"));
        const QString path = directory.filePath(QStringLiteral("colors.json"));
        settings.setMatugenColorsPath(path);
        QFile file(path);
        QVERIFY(file.open(QIODevice::WriteOnly));
        file.write("{\"primary\": \"#ff0000\"}");
        file.close();

        Theme theme(&settings);
        QVERIFY(!theme.usingSystemScheme());
        QVERIFY(theme.colors()->primary().isValid());
    }

    void everyThemeReadsInLightAndDark_data()
    {
        QTest::addColumn<QString>("id");
        QTest::addColumn<bool>("dark");
        for (const themes::Family &family : themes::families()) {
            QTest::addRow("%s light", qPrintable(family.id)) << family.id << false;
            QTest::addRow("%s dark", qPrintable(family.id)) << family.id << true;
        }
    }

    // text on the page, and every accent with what is drawn on it, stays
    // legible: wcag's 4.5 for body text, 3 for the rest
    void everyThemeReadsInLightAndDark()
    {
        QFETCH(QString, id);
        QFETCH(bool, dark);
        const themes::Family *family = themes::find(id);
        QVERIFY(family);
        const MaterialScheme::Roles roles = themes::roles(dark ? family->dark : family->light, dark);
        const auto role = [&roles](MaterialScheme::Role which) { return roles[static_cast<std::size_t>(which)]; };
        using Role = MaterialScheme::Role;
        const auto check = [&](Role ink, Role ground, qreal minimum) {
            const qreal ratio = themes::contrast(role(ink), role(ground));
            QVERIFY2(ratio >= minimum, qPrintable(QStringLiteral("%1 on %2: %3 (%4 and %5)")
                                                      .arg(int(ink)).arg(int(ground)).arg(ratio, 0, 'f', 2)
                                                      .arg(role(ink).name(), role(ground).name())));
        };
        check(Role::OnSurface, Role::SurfaceContainerLow, 4.5);
        check(Role::OnSurface, Role::Background, 4.5);
        check(Role::OnSurfaceVariant, Role::SurfaceContainerLow, 3);
        check(Role::OnPrimary, Role::Primary, 3);
        check(Role::OnPrimaryContainer, Role::PrimaryContainer, 3);
        check(Role::OnSecondaryContainer, Role::SecondaryContainer, 3);
        check(Role::OnTertiaryContainer, Role::TertiaryContainer, 3);
        check(Role::OnError, Role::Error, 3);
        // a dark theme is dark and a light one light
        QCOMPARE(themes::contrast(role(Role::SurfaceContainerLow), Qt::black) < themes::contrast(role(Role::SurfaceContainerLow), Qt::white), dark);
    }

    void aThemeFollowsTheMode()
    {
        QTemporaryDir directory;
        Settings settings(directory.filePath(QStringLiteral("swiftify.conf")));
        settings.setThemeSource(QStringLiteral("catppuccin-mocha"));
        settings.setThemeMode(QStringLiteral("dark"));
        Theme theme(&settings);
        QVERIFY(!theme.usingSystemScheme());
        QVERIFY(theme.dark());
        QCOMPARE(theme.colors()->background(), QColor(0x18, 0x18, 0x25));

        QSignalSpy changed(&theme, &Theme::schemeChanged);
        settings.setThemeMode(QStringLiteral("light"));
        QTRY_VERIFY(changed.count() > 0);
        QVERIFY(!theme.dark());
        QCOMPARE(theme.colors()->background(), QColor(0xe6, 0xe9, 0xef));

        // an id nobody knows is the app's own colours rather than nothing
        settings.setThemeSource(QStringLiteral("not-a-theme"));
        QTRY_VERIFY(theme.colors()->primary().isValid());
        QCOMPARE(theme.themeOptions(false).size(), themes::families().size() + (theme.themeOptions(false).first().id == QLatin1String("system") ? 2 : 1));
    }
};

QTEST_MAIN(ThemeTest)
#include "tst_theme.moc"
