import QtQuick
import Quickshell
import qs.Commons
import qs.Services.Compositor
import qs.Widgets

Item {
  id: root

  property var pluginApi: null
  property ShellScreen screen
  property string widgetId: ""
  property string section: ""
  property int sectionWidgetIndex: -1
  property int sectionWidgetsCount: 0

  readonly property string screenName: screen ? screen.name : ""

  property bool hasLeft: false
  property bool hasRight: false

  function focusedWorkspaceIdForScreen() {
    for (var i = 0; i < CompositorService.workspaces.count; i++) {
      var ws = CompositorService.workspaces.get(i);
      if (!ws.isFocused) continue;
      if (!screenName) return ws.id;
      if (ws.output && ws.output.toLowerCase() === screenName.toLowerCase()) return ws.id;
    }
    return -1;
  }

  function recompute() {
    if (!CompositorService.isNiri) {
      hasLeft = false;
      hasRight = false;
      return;
    }

    var wsId = focusedWorkspaceIdForScreen();
    if (wsId === -1) {
      hasLeft = false;
      hasRight = false;
      return;
    }

    var focusedCol = -1;
    var minCol = Number.MAX_SAFE_INTEGER;
    var maxCol = -Number.MAX_SAFE_INTEGER;
    var seenAny = false;

    for (var i = 0; i < CompositorService.windows.count; i++) {
      var w = CompositorService.windows.get(i);
      if (w.workspaceId !== wsId) continue;
      if (!w.position) continue;
      var col = w.position.x;
      if (col === Number.MAX_SAFE_INTEGER) continue;

      seenAny = true;
      if (col < minCol) minCol = col;
      if (col > maxCol) maxCol = col;
      if (w.isFocused) focusedCol = col;
    }

    if (!seenAny || focusedCol === -1) {
      hasLeft = false;
      hasRight = false;
      return;
    }

    hasLeft = focusedCol > minCol;
    hasRight = focusedCol < maxCol;
  }

  Component.onCompleted: recompute()

  Connections {
    target: CompositorService
    function onWindowListChanged() { root.recompute() }
    function onActiveWindowChanged() { root.recompute() }
    function onWorkspaceChanged() { root.recompute() }
  }

  visible: CompositorService.isNiri

  implicitWidth: contentRow.implicitWidth + Style.marginS * 2
  implicitHeight: Style.capsuleHeight

  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: Style.marginXS

    NIcon {
      icon: "chevron-left"
      applyUiScale: false
      opacity: root.hasLeft ? 1.0 : 0.2
      color: root.hasLeft ? Color.mPrimary : Color.mOnSurface
      Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    NIcon {
      icon: "chevron-right"
      applyUiScale: false
      opacity: root.hasRight ? 1.0 : 0.2
      color: root.hasRight ? Color.mPrimary : Color.mOnSurface
      Behavior on opacity { NumberAnimation { duration: 120 } }
    }
  }
}
