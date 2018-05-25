//
//  main.swift
//  xcassetGen
//
//  Created by Jeffrey Macko on 25/05/2018.
//  Copyright © 2018 PagesJaunes. All rights reserved.
//

import Foundation

extension Collection {

  /// Ce subscript sert a renvoyer un optionel lorsque l'on extrait un element d'un tableau
  ///
  /// - Parameter index: l'index ou la clef de l'objet a extraire
  subscript (safe index: Indices.Iterator.Element) -> Element? {
    return indices.contains(index) ? self[index] : nil
  }
}

func start(args : [String]) {
  print("Start")
  defer { print("Done") }
  var shouldUseTemplate = true
  let addFileForImageToDelete = false

  guard let pdfFolder = args[safe: 1],
    let xcassetFileName = args[safe :2]
    else {
      print("Bad Parameters")
      return
  }

  if let template = args[safe :3], template == "false" {
    shouldUseTemplate = false
  }

  let components = pdfFolder.split(separator: "/")
  let directory = components.dropLast(1).map(String.init).joined(separator: "/")
  var firstCaracter = ""
  if pdfFolder.first == "/" {
    firstCaracter = "/"
  }
  let xcassetFileNameCompleteName = firstCaracter+directory+"/"+xcassetFileName+".xcassets"

  do {
    let fileNamesRaw = try FileManager.default.contentsOfDirectory(atPath: pdfFolder)
    if FileManager.default.fileExists(atPath: xcassetFileNameCompleteName) {
      try FileManager.default.removeItem(atPath: xcassetFileNameCompleteName)
    }
    try FileManager.default.createDirectory(atPath: xcassetFileNameCompleteName, withIntermediateDirectories: true, attributes: [:])

    let fileNames = fileNamesRaw.filter { (filename) -> Bool in
      let components = filename.split(separator: ".")
      if let ext = components[safe : 1], ext.lowercased() == "pdf" {
        return true
      }
      return false
    }
    let jsonForPDF = """
{
  "images" : [
    {
      "idiom" : "universal",
      "filename" : "__FILENAME__"
    }
  ],
  "info" : {
    "version" : 1,
    "author" : "xcode"
  },
  "properties" : {
    __TEMPLATE__
    "preserves-vector-representation" : true
  }
}
"""

let templateText = """
"template-rendering-intent" : "template",
"""

    var imagesToDelete : [String] = []
    let imagesToDeleteFilePath : String = "/Users/jmacko/\(xcassetFileName)_imagesToDelete.sh"

    for aFile in fileNames {
      let fileWithOutExtension = aFile.replacingOccurrences(of: ".pdf", with: "")
      let folderName = xcassetFileNameCompleteName+"/"+fileWithOutExtension+".imageset"
      let contentsJSONFile = folderName+"/Contents.json"
      let pdfFileName = folderName+"/\(fileWithOutExtension).pdf"
      let pdfFileToCopy = pdfFolder+"/"+aFile
      var contentsJSON = jsonForPDF.replacingOccurrences(of: "__FILENAME__", with: aFile)

      if addFileForImageToDelete {
        imagesToDelete.append(fileWithOutExtension+".imageset")
      }

      if shouldUseTemplate {
        contentsJSON = contentsJSON.replacingOccurrences(of: "__TEMPLATE__", with: templateText)
      } else {
        contentsJSON = contentsJSON.replacingOccurrences(of: "__TEMPLATE__", with: "")
      }

      try FileManager.default.createDirectory(atPath: folderName, withIntermediateDirectories: false, attributes: [:])
      try contentsJSON.write(toFile: contentsJSONFile, atomically: true, encoding: .utf8)
      try FileManager.default.copyItem(atPath: pdfFileToCopy, toPath: pdfFileName)
    }

    if addFileForImageToDelete {
      let textForImagesToDelete = imagesToDelete.joined(separator: "\n")
      try textForImagesToDelete.write(toFile: imagesToDeleteFilePath, atomically: true, encoding: .utf8)
    }

    print("Success")
  } catch {
    print(error)
    print("Failed")
  }

}

start(args: CommandLine.arguments)
