import CryptoKit
import Foundation

public enum ManifestCacheCodec {
    public static let magic: [UInt8] = [0x53, 0x42, 0x4D, 0x43] // "SBMC"
    public static let currentFormatVersion: UInt16 = 1

    public static func encode(manifest: SpellbookManifest, extendsChain: [String]) -> Data {
        var writer = ManifestCacheWriter()
        writer.appendBytes(magic)
        writer.appendU16(currentFormatVersion)
        writer.appendStringList(extendsChain)
        writer.appendManifest(manifest)
        return writer.data
    }

    public static func decode(_ data: Data) -> DecodedManifestCache? {
        var reader = ManifestCacheReader(data: data)
        guard reader.readMagic() else { return nil }
        guard let version = reader.readU16(), version == currentFormatVersion else {
            return nil
        }
        guard let extendsChain = reader.readStringList() else { return nil }
        guard let manifest = reader.readManifest() else { return nil }
        guard reader.isAtEnd else { return nil }
        return DecodedManifestCache(
            merged: manifest, extendsChain: extendsChain, formatVersion: version
        )
    }

    public static func projectHash(absoluteManifestPath: String) -> String {
        let digest = SHA256.hash(data: Data(absoluteManifestPath.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
