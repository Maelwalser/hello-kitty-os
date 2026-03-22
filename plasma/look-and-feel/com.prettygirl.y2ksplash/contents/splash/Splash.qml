import QtQuick 2.15
import QtQuick.Window 2.15

Rectangle {
    id: root
    // Binds the background to the exact dimensions of the primary display
    anchors.fill: parent
    color: "#ffb0d8" // Your established Y2K hot pink base

    AnimatedImage {
        id: animatedSplash
        // Relative path to your GIF asset
        source: "images/loader.gif"
        
        // Enforces absolute true-center alignment
        anchors.centerIn: parent
        
        // Optional parameter: Ensures the GIF scales cleanly if it is small
        // fillMode: Image.PreserveAspectFit
    }
}
