import Foundation
import PathKit

public class PackageManager {

    public var path: Path
    public var name: String
    public var beakFile: BeakFile

    var sourcesPath: Path { return path + "Sources" }
    var mainFilePath: Path { return sourcesPath + "\(name)/main.swift" }

    public init(path: Path, name: String, beakFile: BeakFile) {
        self.path = path
        self.name = name
        self.beakFile = beakFile
    }

    public func write(functionCall: String) throws {
        try write()

        let swiftFile = beakFile.contents + "\n\n" + functionCall
        try mainFilePath.writeIfUnchanged(swiftFile)
    }

    public func write(filePath: Path) throws {
        try write()

        try? mainFilePath.delete()
        try mainFilePath.writeIfUnchanged(beakFile.contents)
    }

    func write() throws {
        try path.mkpath()
        try mainFilePath.parent().mkpath()
        let package = createPackage()
        try (path + "Package.Swift").writeIfUnchanged(package)
    }

    public func createPackage() -> String {
        let dependenciesString = beakFile.dependencies.map { ".package(url: \($0.package.quoted), \($0.requirement))," }.joined(separator: "\n")
        let librariesString = beakFile.libraries.map { "\($0.quoted)," }.joined(separator: "\n")
        return """
        // swift-tools-version:4.0

        import PackageDescription

        let package = Package(
            name: \(name.quoted),
            dependencies: [
                \(dependenciesString)
            ],
            targets: [
                .target(
                    name: \(name.quoted),
                    dependencies: [
                        \(librariesString)
                    ]
                )
            ]
        )
        """
    }
}

extension Path {

    func writeIfUnchanged(_ string: String) throws {
        if let existingContent: String = try? read() {
            if existingContent == string {
                return
            }
        }
        try write(string)
    }
}
