/// 规则层版本信息。客户端日志与测试报告引用这里的值，便于把结果追溯到具体规则基线。
public enum CoreInfo {
    /// 对齐的 PRD 与模拟器基线（docs/prd v0.2，tools/balance_sim.py）
    public static let rulesBaseline = "PRD v0.2 @ b122c07"
    /// 武器公式版本（PRD 4.12 calc_version）
    public static let calcVersion = 1
    /// 固定逻辑步长（PRD 5.1：20 Hz）
    public static let logicStep = 0.05
}
