import QtQuick
import Quickshell
import Quickshell.Io
import "../../"

// Monitor — CPU, memory and GPU, live while the page is open (every 2 s).
// Numbers come from DanSmith888's cpustatus/gpustatus (MIT, in
// scripts/monitor/, originals by DanSmith888, MIT).
Column {
  id: page
  property bool showing: false
  spacing: 10

  property var cpu: ({})
  property var gpu: ({})
  property var gpuUse: ({})   // pid → % of the whole GPU
  // Busiest programs as a share of the WHOLE CPU (top counts 100% per thread,
  // so on 32 threads it would say 120% for under 4% of the chip).
  readonly property var cpuTop: (cpu.top || []).map(p => ({ name: p.name, pct: p.cpu / Math.max(1, cpu.threads || 1) }))
  readonly property var gpuTop: (gpu.processes || []).map(p => ({ name: p.name, pct: gpuUse[String(p.pid)] || 0, memMiB: p.memMiB }))
    .sort((a, b) => (b.pct - a.pct) || (b.memMiB - a.memMiB))
  function pctText(v) { return v > 0 && v < 10 ? v.toFixed(1) + "%" : Math.round(v) + "%" }

  readonly property string dir: Qt.resolvedUrl("../../scripts/monitor/").toString().replace("file://", "")
  Process {
    id: poll
    command: ["bash", "-c", "python3 -I '" + page.dir + "cpustatus'; echo '@@'; python3 -I '" + page.dir + "gpustatus' 0; echo '@@'; nvidia-smi pmon -c 1 -s u 2>/dev/null"]
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = text.split("@@")
        try { page.cpu = JSON.parse(parts[0]) || {} } catch (e) { }
        try { page.gpu = JSON.parse(parts[1]) || {} } catch (e) { }
        // nvidia-smi pmon: how much of the whole GPU each program is using (sm %).
        const sm = {}
        for (const line of (parts[2] || "").split("\n")) {
          const f = line.trim().split(/\s+/)
          if (f.length < 5 || f[0].charAt(0) === "#") continue
          const v = parseInt(f[3]); if (!isNaN(v)) sm[f[1]] = (sm[f[1]] || 0) + v
        }
        page.gpuUse = sm
      }
    }
  }
  Timer { interval: 2000; repeat: true; triggeredOnStart: true; running: page.showing; onTriggered: if (!poll.running) poll.running = true }

  function hot(c, warm, burn) { return c >= burn ? Theme.urgent : c >= warm ? Theme.accent : Theme.text }

  // A big number with a small label under it.
  component Stat: Column {
    property string value: ""
    property string label: ""
    property color tint: Theme.text
    spacing: 0
    Text { text: parent.value; color: parent.tint; font.family: Theme.fontDisplay; font.pixelSize: 20; font.weight: Font.Bold }
    Text { text: parent.label; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10 }
  }
  // A thin labelled bar.
  component Meter: Column {
    property string label: ""
    property string valueText: ""
    property real frac: 0
    width: parent ? parent.width : 300
    spacing: 4
    Item {
      width: parent.width; height: 14
      Text { text: parent.parent.label; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10 }
      Text { anchors.right: parent.right; text: parent.parent.valueText; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 10 }
    }
    Rectangle {
      width: parent.width; height: 6; radius: 3; color: Theme.surface
      Rectangle { width: parent.width * Math.max(0, Math.min(1, parent.parent.frac)); height: parent.height; radius: 3; color: Theme.accent
        Behavior on width { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } } }
    }
  }

  // ── CPU ───────────────────────────────────────
  Card {
    width: parent.width
    visible: !!page.cpu.present
    DeviceHeader {
      icon: "memory"
      title: String(page.cpu.model || "CPU").replace(/\(R\)|\(TM\)|13th Gen |Intel |Core /g, "").trim()
      subtitle: (page.cpu.cores || "?") + " cores · " + (page.cpu.threads || "?") + " threads"
      active: true
    }
    Row {
      spacing: 26
      Stat { value: Math.round(page.cpu.usage || 0) + "%"; label: "in use" }
      Stat { value: page.cpu.tempC != null ? Math.round(page.cpu.tempC) + "°" : "—"; label: "hottest"; tint: page.hot(page.cpu.tempC || 0, 75, 90) }
      Stat { value: page.cpu.freqMhz ? (page.cpu.freqMhz / 1000).toFixed(1) + " GHz" : "—"; label: "clock" }
      Stat { value: page.cpu.load ? page.cpu.load[0].toFixed(1) : "—"; label: "load" }
    }
    // One bar per thread.
    Row {
      width: parent.width
      height: 34
      spacing: 2
      Repeater {
        model: page.cpu.perCore || []
        Item {
          required property var modelData
          width: (parent.width - 2 * ((page.cpu.perCore || []).length - 1)) / Math.max(1, (page.cpu.perCore || []).length)
          height: 34
          Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: parent.height; radius: 2; color: Theme.surface }
          Rectangle {
            anchors.bottom: parent.bottom; width: parent.width; radius: 2
            height: Math.max(2, parent.height * Math.min(100, modelData) / 100)
            color: modelData > 85 ? Theme.urgent : Theme.accent
            Behavior on height { NumberAnimation { duration: Motion.ms(Motion.move); easing.type: Easing.OutCubic } }
          }
        }
      }
    }
    Meter {
      label: "Memory"
      valueText: (page.cpu.memUsedGiB || 0).toFixed(1) + " / " + Math.round(page.cpu.memTotalGiB || 0) + " GiB"
      frac: (page.cpu.memUsedPct || 0) / 100
    }
  }

  // ── GPU ───────────────────────────────────────
  Card {
    width: parent.width
    visible: !!page.gpu.present
    DeviceHeader {
      icon: "developer_board"
      title: String(page.gpu.name || "GPU").replace(/NVIDIA GeForce /, "")
      subtitle: (page.gpu.pstate ? page.gpu.pstate + " · " : "") + "driver " + (page.gpu.driver || "?")
      active: true
    }
    Row {
      spacing: 26
      Stat { value: (page.gpu.load || 0) + "%"; label: "in use" }
      Stat { value: page.gpu.tempC != null ? page.gpu.tempC + "°" : "—"; label: "temp"; tint: page.hot(page.gpu.tempC || 0, 75, 85) }
      Stat { value: page.gpu.powerW != null ? Math.round(page.gpu.powerW) + " W" : "—"; label: "of " + (page.gpu.powerLimitW || "?") + " W" }
      Stat { value: page.gpu.fanPct != null ? page.gpu.fanPct + "%" : "—"; label: "fan" }
    }
    Meter {
      label: "VRAM"
      valueText: ((page.gpu.memUsedMiB || 0) / 1024).toFixed(1) + " / " + Math.round((page.gpu.memTotalMiB || 0) / 1024) + " GiB"
      frac: (page.gpu.memUsedMiB || 0) / Math.max(1, page.gpu.memTotalMiB || 1)
    }
    Meter {
      label: "Clock"
      valueText: (page.gpu.clockMhz || 0) + " / " + (page.gpu.maxClockMhz || 0) + " MHz"
      frac: (page.gpu.clockMhz || 0) / Math.max(1, page.gpu.maxClockMhz || 1)
    }
  }

  // ── What's busy ───────────────────────────────
  Card {
    width: parent.width
    visible: (page.cpu.top || []).length > 0
    Text { text: "Busiest right now · share of the whole chip"; color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold; font.capitalization: Font.AllUppercase }
    Row {
      width: parent.width
      spacing: 16
      Column {
        width: (parent.width - 16) / 2
        spacing: 3
        Text { text: "CPU"; color: Theme.accent; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold }
        Repeater {
          model: page.cpuTop.slice(0, 5)
          Item {
            required property var modelData
            width: parent.width; height: 16
            Text { width: parent.width - 50; text: modelData.name; elide: Text.ElideRight; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11 }
            Text { anchors.right: parent.right; text: page.pctText(modelData.pct); color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11 }
          }
        }
      }
      Column {
        width: (parent.width - 16) / 2
        spacing: 3
        Text { text: "GPU"; color: Theme.accent; font.family: Theme.fontText; font.pixelSize: 10; font.weight: Font.DemiBold }
        Repeater {
          model: page.gpuTop.slice(0, 5)
          Item {
            required property var modelData
            width: parent.width; height: 16
            Text { width: parent.width - 110; text: modelData.name; elide: Text.ElideRight; color: Theme.text; font.family: Theme.fontText; font.pixelSize: 11 }
            Text { anchors.right: parent.right; text: page.pctText(modelData.pct) + "  ·  " + (modelData.memMiB >= 1024 ? (modelData.memMiB / 1024).toFixed(1) + " GiB" : modelData.memMiB + " MiB"); color: Theme.textDim; font.family: Theme.fontText; font.pixelSize: 11 }
          }
        }
      }
    }
  }
}
