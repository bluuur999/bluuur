# Modified test runner for bluuur; original test assertions remain unchanged.
from pathlib import Path
import json,re,sys
root=Path.cwd();out=Path(sys.argv[1]);calls=[]
for file in sorted((root/'Tests/MacDuoTests').glob('*.swift')):
    source=file.read_text()
    struct=re.search(r'struct (\w+)',source)[1]
    source=re.sub(r'import Testing\n|@testable import MacDuo\n','',source)
    source=re.sub(r'@Test(?:\([^\n]*\))?\s*','',source)
    source=source.replace('#expect(', 'precondition(').replace('#require(', 'require(')
    source=source.replace('#filePath',json.dumps(str(file)))
    (out/file.name).write_text(source)
    for method, throws in re.findall(r'func (\w+)\(\)( throws)? \{',source):
        if method.startswith('test') or struct=='MouseInteractionTests':
            calls.append(f'{"try " if throws else ""}{struct}().{method}()')
# Parameterized upstream test has two filesystem layouts.
calls += [f'try SettingsLanguageTests().testFindsTheChineseTableInBothBundleLayouts(lprojPath: {json.dumps(path)})' for path in ['zh-hans.lproj','Contents/Resources/zh-Hans.lproj']]
(out/'main.swift').write_text('''import Foundation
func require<T>(_ value: T?) throws -> T {
    guard let value else { throw NSError(domain: "check", code: 1) }
    return value
}
extension Bundle { static var module: Bundle { Bundle(path: '''+json.dumps(str(root/'Sources/MacDuo/Resources'))+''')! } }
'''+ '\n'.join(calls)+'''
precondition(SettingsLanguage.russian.localized("Blur") == "Размытие")
print("OK: upstream lid/language assertions, Russian resources, mouse flattening/restoration and delayed effect entry")
''')
