import QtQuick 2.15
import App 1.0
import Dex.Themes 1.0 as Dex
import "../Constants"

// Add button
DexAppButton {
    btnPressedColor:  Dex.CurrentTheme.buttonCancelColorPressed
    btnHoveredColor:  Dex.CurrentTheme.buttonCancelColorHovered
    btnEnabledColor:  Dex.CurrentTheme.buttonCancelColorEnabled
    btnDisabledColor: Dex.CurrentTheme.buttonCancelColorDisabled
}
