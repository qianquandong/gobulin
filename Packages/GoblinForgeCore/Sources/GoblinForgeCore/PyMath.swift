import Foundation

/// 与 CPython `math` 模块逐位一致的几个函数（战斗几何用）。
public enum PyMath {
    /// `math.radians(x)` = x × (π / 180)
    @inline(__always)
    public static func radians(_ degrees: Double) -> Double { degrees * (Double.pi / 180.0) }

    /// `math.degrees(x)` = x × (180 / π)
    @inline(__always)
    public static func degrees(_ radians: Double) -> Double { radians * (180.0 / Double.pi) }

    /// `math.hypot(x, y)`：CPython 3.10+ 的 vector_norm（缩放 + 无损平方/求和 + 一次微分修正），
    /// 不是 libm 的 hypot；两者在最后一位可能不同，会改变“是否在攻击范围内”这类边界判定。
    public static func hypot(_ x: Double, _ y: Double) -> Double {
        let ax = abs(x), ay = abs(y)
        let maxValue = max(ax, ay)
        if maxValue.isInfinite { return maxValue }
        if x.isNaN || y.isNaN { return .nan }
        if maxValue == 0 { return 0 }
        let maxExponent = Int(maxValue.exponent) + 1   // frexp 的指数：max = m × 2^e，m ∈ [0.5, 1)
        if maxExponent < -1023 {
            let tiny = Double.leastNormalMagnitude
            return tiny * hypot(x / tiny, y / tiny)
        }
        let scale = Double(sign: .plus, exponent: -maxExponent, significand: 1)   // ldexp(1.0, -max_e)，精确
        var csum = 1.0, frac1 = 0.0, frac2 = 0.0
        for value in [ax, ay] {
            let v = value * scale                        // 无损缩放
            let (prHi, prLo) = twoProduct(v, v)          // 无损平方
            let (smHi, smLo) = fastTwoSum(csum, prHi)    // 无损加法
            csum = smHi
            frac1 += prLo
            frac2 += smLo
        }
        var h = (csum - 1.0 + (frac1 + frac2)).squareRoot()
        let (prHi, prLo) = twoProduct(-h, h)
        let (smHi, smLo) = fastTwoSum(csum, prHi)
        csum = smHi
        frac1 += prLo
        frac2 += smLo
        let correction = csum - 1.0 + (frac1 + frac2)
        h += correction / (2.0 * h)
        return h / scale
    }

    /// 乘积与其精确误差：(a × b, fma(a, b, −a × b))，对应 CPython 的 dl_mul
    @inline(__always)
    private static func twoProduct(_ a: Double, _ b: Double) -> (Double, Double) {
        let p = a * b
        return (p, (-p).addingProduct(a, b))
    }

    @inline(__always)
    private static func fastTwoSum(_ a: Double, _ b: Double) -> (Double, Double) {
        let s = a + b
        let z = s - a
        return (s, b - z)
    }

    /// Python 浮点取模：结果与除数同号（float_rem）
    public static func mod(_ x: Double, _ y: Double) -> Double {
        var m = fmod(x, y)
        if m != 0 {
            if (y < 0) != (m < 0) { m += y }
        } else {
            m = copysign(0.0, y)
        }
        return m
    }

    /// Python `round(x)`（无 ndigits）：银行家舍入到整数
    public static func roundEven(_ x: Double) -> Int {
        Int(x.rounded(.toNearestOrEven))
    }

    /// Python `round(x, 1)`
    public static func round1(_ x: Double) -> Double {
        Double(String(format: "%.1f", x))!
    }
}
