# Windows 단일 설치 파일(MSIX) 생성 및 배포 가이드

`msix` 패키지를 사용하면 별도의 외부 인스톨러 프로그램(예: Inno Setup)을 설치하지 않고도, Flutter/Dart 명령어를 통해 Windows 앱 단일 설치 패키지(`.msix`)를 직접 생성할 수 있습니다.

---

## 1. `pubspec.yaml` 설정

프로젝트 루트의 `pubspec.yaml` 파일에 `msix` 패키지를 `dev_dependencies`로 추가하고, 하단에 `msix_config` 설정을 추가합니다.

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^6.0.0
  msix: ^3.16.8

msix_config:
  display_name: BloodSugarTracker
  publisher_display_name: MyCompany
  identity_name: com.bloodsugartracker.app
  msix_version: 1.0.0.0
  logo_path: windows/runner/resources/app_icon.ico
```

> **주요 설정 옵션 설명:**
> - `display_name`: 시작 메뉴 및 설치 화면에 표시될 앱 이름
> - `publisher_display_name`: 게시자(개발사/개발자) 이름
> - `identity_name`: 고유 식별자 패키지 이름
> - `msix_version`: 패키지 버전 (`x.x.x.x` 4자리 포맷)
> - `logo_path`: 앱 타일 및 설치 패키지에 사용할 아이콘 경로

---

## 2. 릴리즈 빌드 및 MSIX 패키지 생성

터미널(PowerShell 또는 명령 프롬프트)에서 아래 명령어를 순서대로 실행합니다.

```powershell
# 1. 패키지 의존성 가져오기
flutter pub get

# 2. Windows 릴리즈 빌드
flutter build windows --release

# 3. MSIX 설치 파일 생성
dart run msix:create
```

명령어 실행이 완료되면 다음 경로에 단일 설치 파일이 생성됩니다:
- `build\windows\x64\runner\Release\BloodSugarTracker.msix`

---

## 3. 다른 PC에서 설치 시 인증서 등록 가이드 (자체 서명 인증서 해결)

기본 설정으로 생성된 `.msix` 파일은 **자체 서명(Self-Signed) 테스트 인증서**가 포함되어 있습니다. 공식 인증 기관(CA)의 인증서가 없는 경우, 다른 PC에서 실행 시 **"신뢰할 수 없는 앱/인증서 오류(0x800B010A, 0x80070005 등)"**로 인해 설치 버튼이 비활성화되거나 차단될 수 있습니다.

대상 PC에서 **최초 1회** 인증서를 수동으로 등록해주면 정상적으로 설치할 수 있습니다.

### 대상 PC 인증서 수동 등록 절차

1. **설치 파일 속성 열기**
   - 대상 PC에서 `BloodSugarTracker.msix` 파일을 **마우스 우클릭** → **[속성]**을 클릭합니다.
2. **디지털 서명 확인**
   - 상단 **[디지털 서명]** 탭 선택 → 서명 목록에 있는 항목을 클릭하고 **[자세히]** 버튼을 누릅니다.
3. **인증서 설치 마법사 실행**
   - **[인증서 보기]** → **[인증서 설치(I)...]** 버튼을 클릭합니다.
4. **저장소 위치 설정**
   - 저장소 위치를 **[로컬 컴퓨터(L)]**로 선택하고 **[다음]**을 누릅니다. *(UAC 관리자 권한 확인 창이 뜨면 '예' 클릭)*
5. **인증서 저장소 지정**
   - **[모든 인증서를 다음 저장소에 저장(P)]**을 선택한 뒤 **[찾아보기(R)...]**를 클릭합니다.
   - 목록에서 **[신뢰할 수 있는 루트 인증 기관]** (Trusted Root Certification Authorities)을 선택하고 **[확인]**을 누릅니다.
6. **설치 완료 후 앱 설치**
   - **[다음]** → **[마침]**을 누르면 "가져오기를 완료했습니다" 메시지가 표시됩니다.
   - 속성 창을 닫고 `.msix` 파일을 다시 더블 클릭하면 **[설치]** 버튼이 활성화되어 정상적으로 설치가 진행됩니다.
