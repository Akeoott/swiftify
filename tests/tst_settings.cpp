#include "app/Settings.h"

#include <QSignalSpy>
#include <QTemporaryDir>
#include <QTest>

using swiftify::Settings;

class SettingsTest : public QObject {
    Q_OBJECT

private slots:
    void defaultsMatchTheMacApp()
    {
        QTemporaryDir directory;
        Settings settings(directory.filePath(QStringLiteral("swiftify.conf")));
        QCOMPARE(settings.visualizersEnabled(), true);
        QCOMPARE(settings.circularVisualizer(), false);
        QCOMPARE(settings.visualizerShape(), QStringLiteral("bars"));
        QCOMPARE(settings.visualizerSensitivity(), 1.0);
        QCOMPARE(settings.streamingQuality(), 160);
        QCOMPARE(settings.livingBackdrop(), true);
        QCOMPARE(settings.backdropBlur(), 16.0);
        QCOMPARE(settings.backdropReactivity(), 1.0);
        QCOMPARE(settings.immersivePlayerPanel(), QStringLiteral("lyrics"));
        QCOMPARE(settings.sleepTimerFade(), QStringLiteral("finalSeconds"));
    }

    void valuesAreSanitized()
    {
        QTemporaryDir directory;
        Settings settings(directory.filePath(QStringLiteral("swiftify.conf")));
        settings.setVisualizerSensitivity(4.0);
        QCOMPARE(settings.visualizerSensitivity(), 1.8);
        settings.setStreamingQuality(128);
        QCOMPARE(settings.streamingQuality(), 160);
        settings.setVisualizerShape(QStringLiteral("spiral"));
        QCOMPARE(settings.visualizerShape(), QStringLiteral("bars"));
        settings.setBackdropBlur(-3);
        QCOMPARE(settings.backdropBlur(), 0.0);
    }

    void changesNotifyOnceAndPersistUnderTheMacKeys()
    {
        QTemporaryDir directory;
        const QString path = directory.filePath(QStringLiteral("swiftify.conf"));
        {
            Settings settings(path);
            QSignalSpy spy(&settings, &Settings::visualizerShapeChanged);
            settings.setVisualizerShape(QStringLiteral("wave"));
            settings.setVisualizerShape(QStringLiteral("wave"));
            QCOMPARE(spy.count(), 1);
            settings.setStreamingQuality(96);
            settings.setPerformanceMode(true);
            settings.setNoShapes(true);
        }
        QSettings raw(path, QSettings::IniFormat);
        QCOMPARE(raw.value(QStringLiteral("circularVisualizerShape")).toString(), QStringLiteral("wave"));

        Settings reopened(path);
        QCOMPARE(reopened.visualizerShape(), QStringLiteral("wave"));
        QCOMPARE(reopened.streamingQuality(), 96);
        QVERIFY(reopened.performanceMode());
        QVERIFY(reopened.noShapes());
        QVERIFY(!reopened.reduceMotion());
    }
};

QTEST_GUILESS_MAIN(SettingsTest)
#include "tst_settings.moc"
