import QtQuick
import Quickshell
import Quickshell.Io

ThemedPopup {
    id: menu
    implicitWidth: 560
    implicitHeight: 250 + (results.visible ? results.height + 14 : 0)
    keyTarget: weatherContent
    property var weatherData: ({})
    property var city: null
    property bool searching: false
    property var cities: []
    property string searchError: ""
    property string requestedCity: ""
    property string requestedSearch: ""
    readonly property string temperature: String(weatherData.temp || "--").split("°")[0]
    readonly property string unit: String(weatherData.temp || "").indexOf("°") >= 0 ? "°" + String(weatherData.temp).split("°")[1] : ""
    readonly property string alternate: isFinite(Number(temperature)) && temperature !== "" ? unit === "°F" ? Math.round((Number(temperature) - 32) * 5 / 9) + "°C" : unit === "°C" ? Math.round(Number(temperature) * 9 / 5 + 32) + "°F" : "" : ""

    function refresh() {
        if (!weatherQuery.running) {
            requestedCity = JSON.stringify(city);
            weatherQuery.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/weather-popup.py", "weather", requestedCity];
            weatherQuery.running = true;
        }
    }
    function cancelSearch() {
        searching = false;
        cities = [];
        searchError = "";
        debounce.stop();
        if (visible) weatherContent.forceActiveFocus();
    }
    function selectCity(value) {
        city = value;
        cancelSearch();
        refresh();
    }
    function forecastIcon(code) {
        // Keep the existing panel's forecast glyph mapping.
        if (code === "113") return "󰖙";
        if (code === "116") return "󰖕";
        if (["143", "248", "260"].indexOf(code) >= 0) return "󰖑";
        if (["176", "263", "266", "293", "296", "353"].indexOf(code) >= 0) return "󰖗";
        if (["179", "182", "185", "281", "284", "311", "314", "317", "320", "362", "365", "374", "377"].indexOf(code) >= 0) return "󰖒";
        if (["200", "386", "389", "392", "395"].indexOf(code) >= 0) return "󰙾";
        if (["227", "230", "323", "326", "329", "332", "335", "338", "350", "368", "371"].indexOf(code) >= 0) return "󰖘";
        if (["299", "302", "305", "308", "356", "359"].indexOf(code) >= 0) return "󰖖";
        return "󰖐";
    }
    onVisibleChanged: {
        if (visible) {
            city = null;
            weatherData = {};
            refresh();
        } else {
            city = null;
            cancelSearch();
        }
    }
    Timer { interval: 900000; running: menu.visible; repeat: true; onTriggered: menu.refresh() }
    Timer {
        id: debounce
        interval: 300
        onTriggered: {
            if (searchQuery.running || !menu.searching || cityInput.text.trim().length < 2) return;
            menu.requestedSearch = cityInput.text.trim();
            searchQuery.command = ["python3", Quickshell.env("HOME") + "/.config/quickshell/desktop-bar/scripts/weather-popup.py", "search", menu.requestedSearch];
            searchQuery.running = true;
        }
    }
    Process {
        id: weatherQuery
        stdout: StdioCollector { id: weatherOutput }
        onExited: function(code) {
            if (!menu.visible) return;
            if (menu.requestedCity !== JSON.stringify(menu.city)) {
                menu.refresh();
                return;
            }
            try {
                if (code !== 0) throw new Error("weather unavailable");
                menu.weatherData = JSON.parse(weatherOutput.text);
            } catch (e) { menu.weatherData = {temp: "--", condition: "Unavailable", location: menu.city ? menu.city.name : "Weather"}; }
        }
    }
    Process {
        id: searchQuery
        stdout: StdioCollector { id: searchOutput }
        onExited: function(code) {
            if (!menu.searching) return;
            if (menu.requestedSearch !== cityInput.text.trim()) { debounce.restart(); return; }
            try {
                if (code !== 0) throw new Error("search unavailable");
                var result = JSON.parse(searchOutput.text);
                menu.cities = result.cities;
                menu.searchError = result.error;
            } catch (e) { menu.searchError = "City search unavailable"; }
        }
    }
    Item {
        id: weatherContent
        anchors.fill: parent
        focus: true
        Keys.onEscapePressed: {
            if (menu.searching) menu.cancelSearch();
            else menu.visible = false;
        }
        Column {
            x: 18
            y: 18
            width: parent.width - 36
            spacing: 14
            Item {
                width: parent.width
                height: 116
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12
                    Text { width: 76; horizontalAlignment: Text.AlignHCenter; text: String(menu.weatherData.text || "󰖐").split(" ")[0]; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 64 }
                    Text { text: menu.temperature; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 56; font.bold: true }
                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 5
                        Text { text: menu.unit; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 20 }
                        Text { text: menu.alternate; color: menu.foreground; opacity: 0.72; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                    }
                }
                Column {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    width: 250
                    spacing: 12
                    Item {
                        width: parent.width
                        height: 30
                        Row {
                            visible: !menu.searching
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 6
                            Text { text: "󰍎"; color: menu.foreground; opacity: 0.72; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 14 }
                            Text { width: 228; text: String(menu.weatherData.location || "Weather").toUpperCase(); elide: Text.ElideRight; color: menu.foreground; opacity: 0.72; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.bold: true }
                        }
                        MouseArea {
                            id: cityMouse
                            hoverEnabled: true
                            anchors.fill: parent
                            enabled: !menu.searching
                            cursorShape: Qt.PointingHandCursor
                            onClicked: { menu.searching = true; cityInput.text = ""; cityInput.forceActiveFocus(); }
                        }
                        Rectangle {
                            visible: menu.searching
                            width: parent.width - 36
                            height: 30
                            radius: 7
                            color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.08)
                            border.color: cityInput.activeFocus ? menu.accent : Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.12)
                            Text { x: 10; anchors.verticalCenter: parent.verticalCenter; text: "Search city"; visible: cityInput.text === ""; color: menu.foreground; opacity: 0.58; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
                            TextInput {
                                id: cityInput
                                activeFocusOnTab: true
                                anchors.fill: parent
                                anchors.margins: 8
                                verticalAlignment: TextInput.AlignVCenter
                                clip: true
                                color: menu.foreground
                                selectionColor: menu.accent
                                selectedTextColor: menu.background
                                font.family: "JetBrainsMono Nerd Font"
                                font.pixelSize: 12
                                onTextChanged: { menu.cities = []; menu.searchError = ""; debounce.restart(); }
                                Keys.onEscapePressed: menu.cancelSearch()
                            }
                        }
                        PanelButton { visible: menu.searching; anchors.right: parent.right; width: 30; height: 30; text: "×"; foreground: menu.foreground; onClicked: menu.cancelSearch() }
                    }
                    Text { text: menu.weatherData.condition || ""; color: menu.foreground; opacity: 0.72; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12; font.bold: true }
                    Row {
                        spacing: 25
                        Repeater {
                            model: [{label: "FEELS", key: "feels"}, {label: "WIND", key: "wind"}, {label: "HUMID", key: "humidity"}]
                            Column {
                                required property var modelData
                                spacing: 5
                                Text { text: parent.modelData.label; color: menu.foreground; opacity: 0.58; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true }
                                Text { text: menu.weatherData[parent.modelData.key] || "--"; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
                            }
                        }
                    }
                }
            }
            Column {
                id: results
                visible: menu.searching && (menu.cities.length > 0 || menu.searchError !== "")
                width: parent.width
                spacing: 4
                Repeater {
                    model: menu.cities
                    PanelButton {
                        required property var modelData
                        width: results.width
                        height: 34
                        text: [modelData.name, modelData.admin1 || "", modelData.country || ""].filter(value => value !== "").join(", ")
                        foreground: menu.foreground
                        onClicked: menu.selectCity(modelData)
                    }
                }
                Text { visible: menu.searchError !== ""; text: menu.searchError; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 12 }
            }
            Rectangle { width: parent.width; height: 1; color: Qt.rgba(menu.foreground.r, menu.foreground.g, menu.foreground.b, 0.12) }
            Row {
                width: parent.width
                Repeater {
                    model: 3
                    Item {
                        required property int index
                        readonly property var day: (menu.weatherData.forecastDays || [])[index] || {}
                        width: 524 / 3
                        height: 60
                        Row {
                            anchors.centerIn: parent
                            spacing: 14
                            Text { anchors.verticalCenter: parent.verticalCenter; text: menu.forecastIcon(String(parent.parent.day.icon || "")); color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 28 }
                            Column {
                                spacing: 2
                                Text { text: parent.parent.parent.day.day || ""; color: menu.foreground; opacity: 0.58; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 10; font.bold: true }
                                Text { text: (parent.parent.parent.day.high || "--") + "°  " + (parent.parent.parent.day.low || "--") + "°"; color: menu.foreground; font.family: "JetBrainsMono Nerd Font"; font.pixelSize: 13; font.bold: true }
                            }
                        }
                    }
                }
            }
        }
    }
}
