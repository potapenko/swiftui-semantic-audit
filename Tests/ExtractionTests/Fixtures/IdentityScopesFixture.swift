#if canImport(FirstBackend)
struct ConditionalService {
    func resolve(_ input: Int) -> Int {
        let result = input
        return result
    }
}
#else
struct ConditionalService {
    func resolve(_ input: Int) -> Int {
        let result = input
        return result
    }
}
#endif

struct ScopeHost {
    func repeatedBlocks() {
        for _ in [1] {
            let value = 1
            _ = value
        }
        for _ in [2] {
            let value = 2
            _ = value
        }
    }

    func closureScopes() {
        let first = {
            let value = 1
            return value
        }
        let second = {
            let value = 2
            return value
        }
        _ = first()
        _ = second()
    }
}

extension ScopeHost {
    func extended() {}
}
