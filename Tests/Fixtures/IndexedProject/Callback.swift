struct VolumeCallback {
    let writer: VolumeWriter

    func handle(_ value: Int) {
        writer.commit(value)
    }
}
