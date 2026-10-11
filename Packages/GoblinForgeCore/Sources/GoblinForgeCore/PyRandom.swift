/// Python `random.Random` 的逐位移植（MT19937 + CPython 的整数播种、random()、uniform()、shuffle()）。
/// 战斗只把随机数用于刷怪角度与刷怪顺序（PRD 5.1），与 tools/balance_sim.py 用同一种子得到同一序列，
/// 才能逐场比对模拟结果。只实现模拟器用到的部分。
public struct PyRandom: Sendable {
    private var state = [UInt32](repeating: 0, count: 624)
    private var index = 625

    /// 等同 `random.Random(seed)`（seed 为非负整数）
    public init(seed: UInt64) {
        var key: [UInt32] = []
        var n = seed
        repeat {
            key.append(UInt32(truncatingIfNeeded: n))
            n >>= 32
        } while n > 0
        initByArray(key)
    }

    private mutating func initGenrand(_ s: UInt32) {
        state[0] = s
        for i in 1..<624 {
            state[i] = 1_812_433_253 &* (state[i - 1] ^ (state[i - 1] >> 30)) &+ UInt32(i)
        }
        index = 624
    }

    private mutating func initByArray(_ key: [UInt32]) {
        initGenrand(19_650_218)
        var i = 1, j = 0
        for _ in 0..<max(624, key.count) {
            state[i] = (state[i] ^ ((state[i - 1] ^ (state[i - 1] >> 30)) &* 1_664_525)) &+ key[j] &+ UInt32(j)
            i += 1; j += 1
            if i >= 624 { state[0] = state[623]; i = 1 }
            if j >= key.count { j = 0 }
        }
        for _ in 0..<623 {
            state[i] = (state[i] ^ ((state[i - 1] ^ (state[i - 1] >> 30)) &* 1_566_083_941)) &- UInt32(i)
            i += 1
            if i >= 624 { state[0] = state[623]; i = 1 }
        }
        state[0] = 0x8000_0000
        index = 624
    }

    public mutating func nextUInt32() -> UInt32 {
        if index >= 624 {
            for k in 0..<624 {
                let y = (state[k] & 0x8000_0000) | (state[(k + 1) % 624] & 0x7FFF_FFFF)
                state[k] = state[(k + 397) % 624] ^ (y >> 1) ^ (y & 1 == 1 ? 0x9908_B0DF : 0)
            }
            index = 0
        }
        var y = state[index]
        index += 1
        y ^= y >> 11
        y ^= (y << 7) & 0x9D2C_5680
        y ^= (y << 15) & 0xEFC6_0000
        y ^= y >> 18
        return y
    }

    /// `random.random()`：53 位精度 [0, 1)
    public mutating func random() -> Double {
        let a = Double(nextUInt32() >> 5)
        let b = Double(nextUInt32() >> 6)
        return (a * 67_108_864.0 + b) * (1.0 / 9_007_199_254_740_992.0)
    }

    /// `random.uniform(a, b)` = a + (b − a) × random()
    public mutating func uniform(_ a: Double, _ b: Double) -> Double {
        a + (b - a) * random()
    }

    /// `random.getrandbits(k)`，k ≤ 32
    public mutating func getrandbits(_ k: Int) -> UInt32 {
        precondition(k > 0 && k <= 32)
        return nextUInt32() >> UInt32(32 - k)
    }

    /// `Random._randbelow_with_getrandbits(n)`
    public mutating func randbelow(_ n: Int) -> Int {
        precondition(n > 0 && n <= Int(UInt32.max))
        let k = Int.bitWidth - n.leadingZeroBitCount
        var r = Int(getrandbits(k))
        while r >= n { r = Int(getrandbits(k)) }
        return r
    }

    /// `random.shuffle(x)`：从尾到头交换
    public mutating func shuffle<T>(_ array: inout [T]) {
        guard array.count > 1 else { return }
        for i in stride(from: array.count - 1, to: 0, by: -1) {
            let j = randbelow(i + 1)
            array.swapAt(i, j)
        }
    }
}
