import Foundation
import Testing
@testable import SelenophileKit

@Test
func subscriptionResponseMapsToPrinterStatus() throws {
    let data = Data(
        """
        {
          "jsonrpc": "2.0",
          "result": {
            "eventtime": 1234.5,
            "status": {
              "print_stats": {
                "state": "printing",
                "filename": "benchy.gcode",
                "message": "Layer 12"
              },
              "display_status": {
                "progress": 0.42,
                "message": "Printing"
              },
              "virtual_sdcard": {
                "progress": 0.4
              },
              "extruder": {
                "temperature": 214.8,
                "target": 220.0
              },
              "heater_bed": {
                "temperature": 59.1,
                "target": 60.0
              },
              "gcode_move": {
                "speed_factor": 1.25
              }
            }
          },
          "id": 2
        }
        """.utf8
    )

    let response = try JSONDecoder().decode(MoonrakerWebSocketMessage.self, from: data)
    let status = try #require(response.printerStatusSnapshot)

    #expect(status.state == .printing)
    #expect(status.filename == "benchy.gcode")
    #expect(status.message == "Printing")
    #expect(status.progress == 0.42)
    #expect(status.extruder?.actual == 214.8)
    #expect(status.bed?.target == 60.0)
    #expect(status.feedRateMultiplier == 1.25)
}

@Test
func statusUpdateNotificationMergesOntoExistingStatus() throws {
    let base = PrinterStatus(
        state: .printing,
        filename: "benchy.gcode",
        message: "Printing",
        progress: 0.42,
        printDuration: 600,
        estimatedTimeRemaining: 900,
        layer: nil,
        bed: TemperatureStatus(actual: 59.1, target: 60),
        extruder: TemperatureStatus(actual: 214.8, target: 220),
        feedRateMultiplier: 1.0
    )

    let data = Data(
        """
        {
          "jsonrpc": "2.0",
          "method": "notify_status_update",
          "params": [
            {
              "display_status": {
                "progress": 0.55,
                "message": "Layer 18"
              },
              "virtual_sdcard": {
                "progress": 0.57
              },
              "gcode_move": {
                "speed_factor": 0.85
              }
            },
            2234.1
          ]
        }
        """.utf8
    )

    let message = try JSONDecoder().decode(MoonrakerWebSocketMessage.self, from: data)
    let delta = try #require(message.printerStatusDelta)
    let merged = base.applying(delta: delta)

    #expect(merged.state == .printing)
    #expect(merged.filename == "benchy.gcode")
    #expect(merged.message == "Layer 18")
    #expect(merged.progress == 0.55)
    #expect(merged.printDuration == 600)
    #expect(merged.estimatedTimeRemaining == 900)
    #expect(merged.feedRateMultiplier == 0.85)
}

@Test
func unrelatedNotificationDoesNotFailDecoding() throws {
    let data = Data(
        """
        {
          "jsonrpc": "2.0",
          "method": "notify_klippy_ready",
          "params": [],
          "id": null
        }
        """.utf8
    )

    let message = try JSONDecoder().decode(MoonrakerWebSocketMessage.self, from: data)

    #expect(message.printerStatusSnapshot == nil)
    #expect(message.printerStatusDelta == nil)
    #expect(message.error == nil)
}
