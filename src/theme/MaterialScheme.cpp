#include "theme/MaterialScheme.h"

#include "cpp/dynamiccolor/dynamic_scheme.h"
#include "theme/ColorMath.h"

#include <QJsonDocument>
#include <QJsonObject>

namespace swiftify {

namespace {

constexpr std::array<const char *, static_cast<std::size_t>(MaterialScheme::Role::Count)> kRoleKeys {
    "background",
    "onBackground",
    "surface",
    "surfaceDim",
    "surfaceBright",
    "surfaceContainerLowest",
    "surfaceContainerLow",
    "surfaceContainer",
    "surfaceContainerHigh",
    "surfaceContainerHighest",
    "onSurface",
    "surfaceVariant",
    "onSurfaceVariant",
    "inverseSurface",
    "inverseOnSurface",
    "outline",
    "outlineVariant",
    "shadow",
    "scrim",
    "surfaceTint",
    "primary",
    "onPrimary",
    "primaryContainer",
    "onPrimaryContainer",
    "inversePrimary",
    "secondary",
    "onSecondary",
    "secondaryContainer",
    "onSecondaryContainer",
    "tertiary",
    "onTertiary",
    "tertiaryContainer",
    "onTertiaryContainer",
    "error",
    "onError",
    "errorContainer",
    "onErrorContainer",
    "primaryFixed",
    "primaryFixedDim",
    "onPrimaryFixed",
    "onPrimaryFixedVariant",
    "secondaryFixed",
    "secondaryFixedDim",
    "onSecondaryFixed",
    "onSecondaryFixedVariant",
    "tertiaryFixed",
    "tertiaryFixedDim",
    "onTertiaryFixed",
    "onTertiaryFixedVariant",
};

} // namespace

MaterialScheme::MaterialScheme(QObject *parent)
    : QObject(parent)
{
}

QString MaterialScheme::roleKey(Role role)
{
    return QString::fromLatin1(kRoleKeys[static_cast<std::size_t>(role)]);
}

void MaterialScheme::setRoles(const Roles &roles, bool dark)
{
    if (roles == m_roles && dark == m_dark && m_derived[0].isValid()) {
        return;
    }
    m_roles = roles;
    m_dark = dark;
    derive();
    emit changed();
}

void MaterialScheme::derive()
{
    const auto r = [this](Role role) { return m_roles[static_cast<std::size_t>(role)]; };
    const auto d = [this](Derived derived) { return m_derived[static_cast<std::size_t>(derived)]; };
    using color::mix;
    using color::withAlpha;
    // in order: later entries read earlier ones through d().
    m_derived[0] = r(Role::Outline);
    m_derived[1] = r(Role::Background);
    m_derived[2] = r(Role::OnBackground);
    m_derived[3] = mix(r(Role::Background), r(Role::OnBackground), 0.9);
    m_derived[4] = mix(r(Role::Background), r(Role::OnBackground), 0.8);
    m_derived[5] = mix(r(Role::OutlineVariant), r(Role::Background), 0.4);
    m_derived[6] = r(Role::SurfaceContainerLow);
    m_derived[7] = r(Role::OnSurfaceVariant);
    m_derived[8] = mix(r(Role::OnSurfaceVariant), r(Role::SurfaceContainerLow), 0.45);
    m_derived[9] = mix(r(Role::SurfaceContainerLow), r(Role::OnSurfaceVariant), 0.92);
    m_derived[10] = mix(r(Role::SurfaceContainerLow), r(Role::OnSurfaceVariant), 0.85);
    m_derived[11] = r(Role::SurfaceContainer);
    m_derived[12] = r(Role::OnSurface);
    m_derived[13] = mix(r(Role::SurfaceContainer), r(Role::OnSurface), 0.90);
    m_derived[14] = mix(r(Role::SurfaceContainer), r(Role::OnSurface), 0.80);
    m_derived[15] = mix(r(Role::SurfaceContainer), r(Role::Background), 0.8);
    m_derived[16] = mix(r(Role::OnSurface), r(Role::Background), 0.4);
    m_derived[17] = r(Role::SurfaceContainerHigh);
    m_derived[18] = r(Role::OnSurface);
    m_derived[19] = mix(r(Role::SurfaceContainerHigh), r(Role::OnSurface), 0.90);
    m_derived[20] = mix(r(Role::SurfaceContainerHigh), r(Role::OnSurface), 0.80);
    m_derived[21] = r(Role::SurfaceContainerHighest);
    m_derived[22] = r(Role::OnSurface);
    m_derived[23] = mix(r(Role::SurfaceContainerHighest), r(Role::OnSurface), 0.90);
    m_derived[24] = mix(r(Role::SurfaceContainerHighest), r(Role::OnSurface), 0.80);
    m_derived[25] = mix(r(Role::Primary), d(Derived::Layer1Hover), 0.87);
    m_derived[26] = mix(r(Role::Primary), d(Derived::Layer1Active), 0.7);
    m_derived[27] = mix(r(Role::PrimaryContainer), r(Role::OnPrimaryContainer), 0.9);
    m_derived[28] = mix(r(Role::PrimaryContainer), r(Role::OnPrimaryContainer), 0.8);
    m_derived[29] = mix(r(Role::Secondary), d(Derived::Layer1Hover), 0.85);
    m_derived[30] = mix(r(Role::Secondary), d(Derived::Layer1Active), 0.4);
    m_derived[31] = mix(r(Role::SecondaryContainer), r(Role::OnSecondaryContainer), 0.90);
    m_derived[32] = mix(r(Role::SecondaryContainer), r(Role::OnSecondaryContainer), 0.54);
    m_derived[33] = mix(r(Role::Tertiary), d(Derived::Layer1Hover), 0.85);
    m_derived[34] = mix(r(Role::Tertiary), d(Derived::Layer1Active), 0.4);
    m_derived[35] = mix(r(Role::TertiaryContainer), r(Role::OnTertiaryContainer), 0.90);
    m_derived[36] = mix(r(Role::TertiaryContainer), d(Derived::Layer1Active), 0.54);
    m_derived[37] = mix(r(Role::SurfaceContainerHighest), r(Role::OnSurface), 0.95);
    m_derived[38] = mix(r(Role::SurfaceContainerHighest), r(Role::OnSurface), 0.85);
    m_derived[39] = r(Role::InverseSurface);
    m_derived[40] = r(Role::InverseOnSurface);
    m_derived[41] = withAlpha(r(Role::Scrim), 0.5);
    m_derived[42] = withAlpha(r(Role::Shadow), 0.3);
    m_derived[43] = mix(r(Role::Error), d(Derived::Layer1Hover), 0.85);
    m_derived[44] = mix(r(Role::Error), d(Derived::Layer1Active), 0.7);
    m_derived[45] = mix(r(Role::ErrorContainer), r(Role::OnErrorContainer), 0.90);
    m_derived[46] = mix(r(Role::ErrorContainer), r(Role::OnErrorContainer), 0.70);
}

MaterialScheme::Roles MaterialScheme::fromDynamicScheme(
    const material_color_utilities::DynamicScheme &scheme)
{
    const auto argb = [](material_color_utilities::Argb value) { return QColor::fromRgba(value); };
    return {
        argb(scheme.GetBackground()),
        argb(scheme.GetOnBackground()),
        argb(scheme.GetSurface()),
        argb(scheme.GetSurfaceDim()),
        argb(scheme.GetSurfaceBright()),
        argb(scheme.GetSurfaceContainerLowest()),
        argb(scheme.GetSurfaceContainerLow()),
        argb(scheme.GetSurfaceContainer()),
        argb(scheme.GetSurfaceContainerHigh()),
        argb(scheme.GetSurfaceContainerHighest()),
        argb(scheme.GetOnSurface()),
        argb(scheme.GetSurfaceVariant()),
        argb(scheme.GetOnSurfaceVariant()),
        argb(scheme.GetInverseSurface()),
        argb(scheme.GetInverseOnSurface()),
        argb(scheme.GetOutline()),
        argb(scheme.GetOutlineVariant()),
        argb(scheme.GetShadow()),
        argb(scheme.GetScrim()),
        argb(scheme.GetSurfaceTint()),
        argb(scheme.GetPrimary()),
        argb(scheme.GetOnPrimary()),
        argb(scheme.GetPrimaryContainer()),
        argb(scheme.GetOnPrimaryContainer()),
        argb(scheme.GetInversePrimary()),
        argb(scheme.GetSecondary()),
        argb(scheme.GetOnSecondary()),
        argb(scheme.GetSecondaryContainer()),
        argb(scheme.GetOnSecondaryContainer()),
        argb(scheme.GetTertiary()),
        argb(scheme.GetOnTertiary()),
        argb(scheme.GetTertiaryContainer()),
        argb(scheme.GetOnTertiaryContainer()),
        argb(scheme.GetError()),
        argb(scheme.GetOnError()),
        argb(scheme.GetErrorContainer()),
        argb(scheme.GetOnErrorContainer()),
        argb(scheme.GetPrimaryFixed()),
        argb(scheme.GetPrimaryFixedDim()),
        argb(scheme.GetOnPrimaryFixed()),
        argb(scheme.GetOnPrimaryFixedVariant()),
        argb(scheme.GetSecondaryFixed()),
        argb(scheme.GetSecondaryFixedDim()),
        argb(scheme.GetOnSecondaryFixed()),
        argb(scheme.GetOnSecondaryFixedVariant()),
        argb(scheme.GetTertiaryFixed()),
        argb(scheme.GetTertiaryFixedDim()),
        argb(scheme.GetOnTertiaryFixed()),
        argb(scheme.GetOnTertiaryFixedVariant()),
    };
}

std::optional<MaterialScheme::Roles> MaterialScheme::fromMatugenJson(const QByteArray &json)
{
    QJsonParseError error;
    const QJsonDocument document = QJsonDocument::fromJson(json, &error);
    if (error.error != QJsonParseError::NoError || !document.isObject()) {
        return std::nullopt;
    }
    QJsonObject object = document.object();
    // matugen's own template nests the scheme under "colors".
    if (object.value(QStringLiteral("colors")).isObject()) {
        object = object.value(QStringLiteral("colors")).toObject();
    }

    Roles roles;
    for (std::size_t index = 0; index < roles.size(); ++index) {
        const QString camel = QString::fromLatin1(kRoleKeys[index]);
        QString snake;
        for (const QChar character : camel) {
            if (character.isUpper()) {
                snake += u'_';
            }
            snake += character.toLower();
        }
        QString prefixed = camel;
        prefixed[0] = prefixed[0].toUpper();
        prefixed.prepend(QStringLiteral("m3"));

        QJsonValue value;
        for (const QString &key : {snake, camel, prefixed}) {
            value = object.value(key);
            if (!value.isUndefined()) {
                break;
            }
        }
        // matugen can also write {"dark": "#..", "light": ".."} per role; the
        // file end4 reads already holds the active mode's value as a string.
        const QColor color = QColor::fromString(value.toString());
        if (!color.isValid()) {
            return std::nullopt;
        }
        roles[index] = color;
    }
    return roles;
}

MaterialScheme::Roles MaterialScheme::interpolate(const Roles &from, const Roles &to, qreal progress)
{
    Roles roles;
    for (std::size_t index = 0; index < roles.size(); ++index) {
        roles[index] = color::mix(to[index], from[index], progress);
    }
    return roles;
}

} // namespace swiftify
