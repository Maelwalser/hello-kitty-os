import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls 2.15

Rectangle {
    id: root

    // ── Fill the entire screen ──
    width: Screen.width
    height: Screen.height

    property color kittyPink: "#FF69B4"
    property color deepRose: "#C71585"
    property color softBlack: "#4A2040"

    gradient: Gradient {
        GradientStop { position: 0.0; color: "#FFD6E8" }
        GradientStop { position: 0.5; color: "#FFB6C1" }
        GradientStop { position: 1.0; color: "#E890A8" }
    }

    // Header
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.06
        text: "HELLO KITTY"
        font.pixelSize: 36
        font.bold: true
        font.letterSpacing: 4
        color: "#FFFFFF"
        style: Text.Outline
        styleColor: deepRose
    }

    // Clock
    Text {
        id: clock
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 16
        anchors.rightMargin: 24
        font.pixelSize: 24
        font.bold: true
        color: "#FFFFFF"

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                var now = new Date()
                clock.text = Qt.formatTime(now, "hh:mm")
            }
        }
    }

    // Login box
    Rectangle {
        anchors.centerIn: parent
        width: Math.min(350, parent.width * 0.85)
        height: 320
        radius: 16
        color: Qt.rgba(1, 0.94, 0.96, 0.92)
        border.color: kittyPink
        border.width: 2

        ColumnLayout {
            anchors.centerIn: parent
            width: parent.width - 60
            spacing: 12

            // Username
            Text {
                text: "Username"
                font.pixelSize: 12
                font.bold: true
                color: deepRose
            }

            TextField {
                id: userField
                Layout.fillWidth: true
                font.pixelSize: 14
                color: softBlack
                placeholderText: "enter username"
                focus: true
                Keys.onReturnPressed: sddm.login(userField.text, passField.text, sessionSelect.currentIndex)
                KeyNavigation.tab: passField
            }

            // Password
            Text {
                text: "Password"
                font.pixelSize: 12
                font.bold: true
                color: deepRose
            }

            TextField {
                id: passField
                Layout.fillWidth: true
                font.pixelSize: 14
                color: softBlack
                placeholderText: "enter password"
                echoMode: TextInput.Password
                Keys.onReturnPressed: sddm.login(userField.text, passField.text, sessionSelect.currentIndex)
                KeyNavigation.tab: userField
            }

            // Login button
            Button {
                id: loginBtn
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                text: "LOGIN"
                font.pixelSize: 14
                font.bold: true
                font.letterSpacing: 3
                onClicked: sddm.login(userField.text, passField.text, sessionSelect.currentIndex)

                contentItem: Text {
                    text: loginBtn.text
                    font: loginBtn.font
                    color: "#FFFFFF"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    radius: 10
                    color: loginBtn.down ? deepRose : kittyPink
                    border.color: deepRose
                    border.width: 1
                }
            }

            // Error
            Text {
                id: errorMsg
                Layout.alignment: Qt.AlignHCenter
                text: ""
                font.pixelSize: 11
                color: "#D04060"
                visible: text !== ""
            }
        }
    }

    // Bottom row
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 20

        ComboBox {
            id: sessionSelect
            Layout.preferredWidth: 180
            model: sessionModel
            currentIndex: sessionModel.lastIndex
            textRole: "name"
            font.pixelSize: 11
        }

        Button {
            text: "Off"
            font.pixelSize: 11
            onClicked: sddm.powerOff()

            background: Rectangle {
                radius: 6
                color: Qt.rgba(1, 1, 1, 0.4)
                border.color: Qt.rgba(1, 0.41, 0.71, 0.4)
            }

            contentItem: Text {
                text: "Off"
                font.pixelSize: 11
                color: softBlack
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }

        Button {
            text: "Reboot"
            font.pixelSize: 11
            onClicked: sddm.reboot()

            background: Rectangle {
                radius: 6
                color: Qt.rgba(1, 1, 1, 0.4)
                border.color: Qt.rgba(1, 0.41, 0.71, 0.4)
            }

            contentItem: Text {
                text: "Reboot"
                font.pixelSize: 11
                color: softBlack
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }

    // Footer
    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        text: "hello kitty y2k - arch linux"
        font.pixelSize: 9
        color: Qt.rgba(1, 1, 1, 0.4)
        font.letterSpacing: 2
    }

    Connections {
        target: sddm
        onLoginFailed: {
            errorMsg.text = "Wrong password, try again"
            passField.text = ""
            passField.focus = true
        }
        onLoginSucceeded: {
            errorMsg.text = ""
        }
    }

    Component.onCompleted: {
        userField.focus = true
    }
}
