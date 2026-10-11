#!/usr/bin/env bash
# 检查 Prototype（Release 类）配置编出的 .app：版本信息、最低系统、仅 iPhone，
# 调试入口已剔除，M0 未链接广告/内购/追踪框架（CLAUDE.md）。输出 Markdown（写入 Step Summary）。
# 用法：bash ci/check-release-binary.sh path/to/GoblinForge.app
set -uo pipefail
app="$1"
plist="$app/Info.plist"
binary="$app/$(/usr/libexec/PlistBuddy -c 'Print :CFBundleExecutable' "$plist")"
fail=0

value() { /usr/libexec/PlistBuddy -c "Print :$1" "$plist" 2>/dev/null; }

echo "## Release 配置二进制检查"
echo
echo "| 项 | 值 | 结果 |"
echo "|---|---|---|"
row() { echo "| $1 | $2 | $3 |"; [ "$3" = "PASS" ] || fail=1; }

version="$(value CFBundleShortVersionString)"
build="$(value CFBundleVersion)"
minos="$(value MinimumOSVersion)"
family="$(value UIDeviceFamily | tr -d ' \n' )"
row "CFBundleShortVersionString" "$version" "$([ -n "$version" ] && echo PASS || echo FAIL)"
row "CFBundleVersion" "$build" "$([[ "$build" =~ ^[0-9]+$ ]] && echo PASS || echo FAIL)"
row "MinimumOSVersion" "$minos" "$([ "$minos" = "17.0" ] && echo PASS || echo FAIL)"
row "UIDeviceFamily" "$family" "$([ "$family" = "Array{1}" ] && echo PASS || echo FAIL)"
row "Bundle ID" "$(value CFBundleIdentifier)" "PASS"

# 调试入口（启动参数、探针、调试菜单）只能存在于 Debug 构建
for marker in "-gf-case" "-gf-participant" "-gf-rack" "debug.probe" "UITEST"; do
  if strings -a "$binary" | grep -qF -- "$marker"; then
    row "无调试入口：$marker" "found" "FAIL"
  else
    row "无调试入口：$marker" "absent" "PASS"
  fi
done

# M0 不接广告、IAP、商业分析 SDK（CLAUDE.md）：不得链接相关系统框架
linked="$(otool -L "$binary" | tail -n +2)"
for framework in StoreKit AdSupport AppTrackingTransparency GoogleMobileAds; do
  if echo "$linked" | grep -q "/$framework.framework/"; then
    row "未链接 $framework" "linked" "FAIL"
  else
    row "未链接 $framework" "not linked" "PASS"
  fi
done

echo
if [ $fail -ne 0 ]; then
  echo "**FAILED**"
  exit 1
fi
echo "**PASS**（未签名；签名与上传需要用户的 Team / Bundle ID，见 docs/production/build.md）"
