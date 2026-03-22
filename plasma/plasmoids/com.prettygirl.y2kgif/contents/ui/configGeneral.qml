import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Kirigami.FormLayout {
    id: page
    
    // The engine automatically binds "cfg_gifPath" to the XML schema
    property alias cfg_gifPath: pathField.text

    TextField {
        id: pathField
        Kirigami.FormData.label: "GIF File Path or URL:"
        Layout.fillWidth: true
        placeholderText: "e.g., file:///home/pretty-girl/Downloads/new_kitty.gif"
    }
}
