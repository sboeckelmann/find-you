//
//  main.swift
//  find-my-key-generator
//
//  Created by Sven Böckelmann on 01.03.23.
//

import Foundation
import CryptoKit

func getDownloadsDir() -> URL {
    let dirs = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask)
    return dirs[0]
}

let xml_begin = """
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
    <array>
"""
let xml_end = """

    </array>
</plist>
"""


let xml_element = """

              <dict>
                      <key>colorComponents</key>
                      <array>
                              <real>0.25</real>
                              <real>0.77600628137588501</real>
                              <real>0.99999994039535522</real>
                              <real>1</real>
                      </array>
                      <key>colorSpaceName</key>
                      <string>kCGColorSpaceExtendedSRGB</string>
                      <key>icon</key>
                      <string>creditcard.fill</string>
                      <key>id</key>
                      <integer>%D</integer>
                      <key>isActive</key>
                      <true/>
                      <key>isDeployed</key>
                      <true/>
                      <key>lastDerivationTimestamp</key>
                      <date>%@</date>
                      <key>name</key>
                      <string>%@</string>
                      <key>oldestRelevantSymmetricKey</key>
                      <data>
                      %@
                      </data>
                      <key>privateKey</key>
                      <data>
                      %@
                      </data>
                      <key>symmetricKey</key>
                      <data>
                      %@
                      </data>
                      <key>updateInterval</key>
                      <real>3600</real>
                      <key>usesDerivation</key>
                      <false/>
              </dict>
"""
if (CommandLine.arguments.count < 2) {
    print("need to pass device name")
    exit(1)
}

let plistUrl = getDownloadsDir().appendingPathComponent("openhaystack-keys.plist")
let csvUrl = getDownloadsDir().appendingPathComponent("openhaystack-keys.csv")


let isoFormatter = ISO8601DateFormatter()
isoFormatter.timeZone = TimeZone.gmt

let iso_datetime = isoFormatter.string(from: Date())
let deviceName = CommandLine.arguments[1]
let count = CommandLine.arguments.count >= 3 ?  Int(CommandLine.arguments[2]) ?? 10 : 10

try xml_begin.write(to: plistUrl, atomically: true, encoding: String.Encoding.utf8)
try "".write(to: csvUrl, atomically: true, encoding: String.Encoding.utf8)
if let plistHandle = try? FileHandle(forWritingTo: plistUrl), let csvHandle = try? FileHandle(forWritingTo: csvUrl)  {
    csvHandle.seekToEndOfFile()
    plistHandle.seekToEndOfFile()
    for i in 1...count {
        let key = BoringSSL.generateNewPrivateKey()
        let symmetricKey = SymmetricKey(size: .bits256).withUnsafeBytes { return Data($0) }
        let s = String(format: xml_element, key!.hashValue.self, iso_datetime, deviceName, symmetricKey.base64EncodedString(), key!.base64EncodedString(), symmetricKey.base64EncodedString())
        plistHandle.write(s.data(using: .utf8)!)
        if i > 1 {
            csvHandle.write(",".data(using: .utf8)!)
        }
        csvHandle.write(key!.base64EncodedString().data(using: .utf8)!)
    }
    plistHandle.write(xml_end.data(using: .utf8)!)
    plistHandle.closeFile()
    csvHandle.closeFile()
}

print("ok")
