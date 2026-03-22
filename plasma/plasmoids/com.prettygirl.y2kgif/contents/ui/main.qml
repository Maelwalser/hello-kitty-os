import QtQuick
import org.kde.plasma.plasmoid

PlasmoidItem {
    id: root

    preferredRepresentation: fullRepresentation

    fullRepresentation: Item {
        implicitWidth: 200
        implicitHeight: 200

        AnimatedImage {
            id: gifRenderer
            anchors.fill: parent
            
            // CRITICAL FIX: Data bound to the configuration schema
            source: Plasmoid.configuration.gifPath
            
            fillMode: Image.PreserveAspectFit
            playing: true

            MouseArea {
                anchors.fill: parent
                onClicked: gifRenderer.playing = !gifRenderer.playing
            }
        }
    }
}
