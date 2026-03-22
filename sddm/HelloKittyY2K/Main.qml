import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Item {
    id: root

    property color kittyPink: "#FF69B4"
    property color deepRose: "#C71585"
    property color softBlack: "#4A2040"
    property color bubbleWhite: "#FFF0F5"

    // ── Background ──
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#FFD6E8" }
            GradientStop { position: 0.5; color: "#FFB6C1" }
            GradientStop { position: 1.0; color: "#E890A8" }
        }
    }

    // Subtle sparkle / light streaks across background
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.3; color: Qt.rgba(1, 1, 1, 0.08) }
            GradientStop { position: 0.5; color: Qt.rgba(1, 1, 1, 0.15) }
            GradientStop { position: 0.7; color: Qt.rgba(1, 1, 1, 0.08) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // ── Header ──
    Text {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: parent.height * 0.04
        text: "✧ HELLO KITTY ✧"
        font.pixelSize: 44
        font.bold: true
        font.letterSpacing: 6
        color: "#FFFFFF"
        style: Text.Outline
        styleColor: deepRose
    }

    // ── Clock ──
    Text {
        id: clock
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 20
        anchors.rightMargin: 30
        font.pixelSize: 28
        font.bold: true
        color: "#FFFFFF"
        style: Text.Outline
        styleColor: kittyPink

        Timer {
            interval: 1000
            running: true
            repeat: true
            triggeredOnStart: true
            onTriggered: {
                var d = new Date();
                clock.text = d.getHours().toString().padStart(2, '0') + ":" + d.getMinutes().toString().padStart(2, '0');
            }
        }
    }

    // ── Glassy login box (centered) ──
    Rectangle {
        id: loginCard
        anchors.centerIn: parent
        anchors.verticalCenterOffset: 100
        width: Math.min(400, root.width * 0.85)
        height: 340
        radius: 26
        color: Qt.rgba(1, 1, 1, 0.25)
        border.color: Qt.rgba(1, 1, 1, 0.6)
        border.width: 2

            // Glass inner glow — top highlight
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 2
                height: parent.height * 0.45
                radius: 24
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.45) }
                    GradientStop { position: 1.0; color: "transparent" }
                }
            }

            // Pink inner border for plastic depth
            Rectangle {
                anchors.fill: parent
                anchors.margins: 5
                radius: 21
                color: "transparent"
                border.color: Qt.rgba(1, 0.41, 0.71, 0.4)
                border.width: 1.5
            }

            // Bottom shine reflection
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                anchors.margins: 2
                height: parent.height * 0.12
                radius: 24
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "transparent" }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.12) }
                }
            }

            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width - 70
                spacing: 14

                Text {
                    text: "Username"
                    font.pixelSize: 13
                    font.bold: true
                    color: deepRose
                }

                TextField {
                    id: userField
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    color: softBlack
                    text: "pretty-girl"
                    placeholderText: "enter username..."

                    onAccepted: passField.forceActiveFocus()

                    background: Rectangle {
                        radius: 10
                        color: Qt.rgba(1, 1, 1, 0.75)
                        border.color: userField.activeFocus ? deepRose : Qt.rgba(1, 0.41, 0.71, 0.5)
                        border.width: userField.activeFocus ? 2 : 1

                        // Glassy top-edge highlight inside input
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 1
                            height: parent.height * 0.4
                            radius: 9
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.5) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                    }
                }

                Text {
                    text: "Password"
                    font.pixelSize: 13
                    font.bold: true
                    color: deepRose
                }

                TextField {
                    id: passField
                    Layout.fillWidth: true
                    font.pixelSize: 14
                    color: softBlack
                    placeholderText: "enter password..."
                    echoMode: TextInput.Password
                    focus: true

                    onAccepted: sddm.login(userField.text, passField.text, sessionSelect.currentIndex)

                    background: Rectangle {
                        radius: 10
                        color: Qt.rgba(1, 1, 1, 0.75)
                        border.color: passField.activeFocus ? deepRose : Qt.rgba(1, 0.41, 0.71, 0.5)
                        border.width: passField.activeFocus ? 2 : 1

                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 1
                            height: parent.height * 0.4
                            radius: 9
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.5) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                    }
                }

                Item { Layout.preferredHeight: 5 }

                // Glassy login button
                Button {
                    id: loginBtn
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46

                    onClicked: sddm.login(userField.text, passField.text, sessionSelect.currentIndex)

                    contentItem: Text {
                        text: "✧ LOGIN ✧"
                        font.pixelSize: 16
                        font.bold: true
                        font.letterSpacing: 4
                        color: "#FFFFFF"
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        style: Text.Outline
                        styleColor: Qt.rgba(0.78, 0.08, 0.52, 0.4)
                    }

                    background: Rectangle {
                        radius: 14
                        color: loginBtn.down ? deepRose : kittyPink
                        border.color: Qt.rgba(1, 1, 1, 0.5)
                        border.width: 2

                        // Button glass shine
                        Rectangle {
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.margins: 2
                            height: parent.height * 0.45
                            radius: 12
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.5) }
                                GradientStop { position: 1.0; color: "transparent" }
                            }
                        }
                    }
                }

                Text {
                    id: errorMsg
                    Layout.alignment: Qt.AlignHCenter
                    text: ""
                    font.pixelSize: 12
                    font.bold: true
                    color: "#FF0000"
                    visible: text !== ""
                }
            }
        }

    // Animated GIF mascot — centered between header and login box
    AnimatedImage {
        id: mascotGif
        source: "mascot.gif"
        width: 180
        height: 180
        fillMode: Image.PreserveAspectFit
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: loginCard.top
        anchors.bottomMargin: 110
        playing: true
    }

    // ── Bottom row ──
    RowLayout {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 24
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 24

        ComboBox {
            id: sessionSelect
            Layout.preferredWidth: 200
            model: sessionModel
            currentIndex: sessionModel.lastIndex >= 0 ? sessionModel.lastIndex : 0
            textRole: "name"
            font.pixelSize: 12
        }

        Button {
            text: "Off"
            font.pixelSize: 12
            font.bold: true
            onClicked: sddm.powerOff()
            background: Rectangle {
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.35)
                border.color: Qt.rgba(1, 1, 1, 0.6)
                border.width: 1.5

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: parent.height * 0.45
                    radius: 9
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.35) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
            }
        }

        Button {
            text: "Reboot"
            font.pixelSize: 12
            font.bold: true
            onClicked: sddm.reboot()
            background: Rectangle {
                radius: 10
                color: Qt.rgba(1, 1, 1, 0.35)
                border.color: Qt.rgba(1, 1, 1, 0.6)
                border.width: 1.5

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.margins: 1
                    height: parent.height * 0.45
                    radius: 9
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.35) }
                        GradientStop { position: 1.0; color: "transparent" }
                    }
                }
            }
        }
    }

    // ── Footer ──
    Text {
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 4
        anchors.horizontalCenter: parent.horizontalCenter
        text: "♡ custom arch config for a pretty-girl ♡"
        font.pixelSize: 9
        color: Qt.rgba(1, 1, 1, 0.5)
        font.letterSpacing: 2
    }

    Connections {
        target: sddm
        function onLoginFailed() {
            errorMsg.text = "Incorrect password, try again!"
            passField.text = ""
            passField.forceActiveFocus()
        }
        function onLoginSucceeded() {
            errorMsg.text = ""
        }
    }

    Component.onCompleted: {
        passField.forceActiveFocus()
    }
}
