struct VolumeWriter {
    let settings: Settings
    let other: OtherSettings

    func commit(_ newValue: Int) {
        settings.volume = newValue
    }

    func currentVolume() -> Int {
        settings.volume
    }

    func unrelatedVolume() -> Int {
        other.volume
    }
}
