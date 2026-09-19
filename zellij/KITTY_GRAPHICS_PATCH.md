# Zellij Kitty Graphics crop-cache patch for Yazi

이 문서는 Yazi 이미지 미리보기용 로컬 Zellij 패치를 다시 적용하거나 새 버전으로
이식하기 위한 작업 명세다. AI agent에게 다음처럼 요청하면 된다.

> `~/.config/zellij/KITTY_GRAPHICS_PATCH.md`를 읽고 현재 설치된 Zellij 소스에
> 필요한 패치를 이식한 뒤 테스트하고, 기존 바이너리를 보존하면서 설치해 줘.

문서에 적힌 0.45.1용 코드 형태를 미래 버전에 그대로 덮어쓰면 안 된다. 먼저 현재
upstream 구현과 테스트를 읽고, 아래의 **동작 불변조건**이 이미 만족되는지 확인한다.

## 문제 요약

- 확인한 조합: Zellij 0.45.1, Yazi 26.9.1, Kitty Graphics Protocol(KGP).
- 증상: Yazi 미리보기의 모든 셀이 동일한 잘린 이미지 조각으로 렌더링된다.
- 적용일: 2026-09-14.
- 원인: Zellij가 스케일된 이미지 variant를 목적지 셀 개수 `(cols, rows)`만으로
  캐시한다.
- 해결: 캐시 키에 원본 crop 사각형과 목적지 **픽셀** 크기를 모두 포함한다.

Yazi의 `KgpOld` 드라이버는 이미지를 한 번 전송한 뒤 각 화면 셀마다 다음과 같은
placement를 만든다.

```text
같은 image id
서로 다른 source rectangle: x, y, w, h
같은 destination cells: c=1, r=1
```

Zellij 0.45.1의 캐시는 대략 다음과 같다.

```rust
scaled_variants: HashMap<(u16, u16), Vec<u8>>
//                         ^ cols, rows only
```

따라서 모든 Yazi 타일이 `(1, 1)`이라는 같은 키를 사용한다. 나중 타일이 앞 타일을
덮어쓰고, base64 캐시와 host에 전송된 이미지 캐시도 같은 variant를 재사용하여
결국 모든 셀이 같은 조각으로 보인다.

## 동작 불변조건

패치 이후에는 하나의 원본 이미지 안에서 다음 값이 다르면 반드시 서로 다른 scaled
variant와 host image로 취급해야 한다.

```text
source_x, source_y, source_width, source_height,
destination_pixel_width, destination_pixel_height
```

권장 키 형태는 다음과 같다. 실제 이름과 정수 타입은 현재 upstream 코드에 맞춘다.

```rust
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, PartialOrd, Ord)]
pub struct ScaledImageKey {
    pub source_x: usize,
    pub source_y: usize,
    pub source_width: usize,
    pub source_height: usize,
    pub destination_width: usize,
    pub destination_height: usize,
}
```

`(cols, rows)`는 키로 충분하지 않다. 같은 한 셀이라도 crop이 다를 수 있고, 폰트나
클라이언트에 따라 한 셀의 실제 픽셀 크기도 달라질 수 있기 때문이다.

## 수정해야 할 경로

0.45.1에서는 주로 다음 파일들이 관련된다. 새 버전에서는 이름이나 구조가 바뀔 수
있으므로 심볼 이름으로도 검색한다.

```text
zellij-server/src/panes/kitty_graphics/store.rs
zellij-server/src/panes/kitty_graphics/grid_state.rs
zellij-server/src/output/mod.rs
zellij-server/src/panes/kitty_graphics/unit/store_tests.rs
zellij-server/src/panes/unit/grid_tests.rs
zellij-server/src/output/unit/output_tests.rs
```

검색할 심볼:

```text
scaled_variants
scaled_variant
add_scaled_variant
base64_for
KittyPlacement
KittyImageChunk
HostKittyState
HostPlacementRecord
character_cell_size_possibly_changed
serialize_kitty_frame
```

### 1. 이미지 저장소의 키 확장

`store.rs`에서 아래 항목을 모두 동일한 전체 키 타입으로 바꾼다.

- `KittyImage.scaled_variants`
- `StoredImage.base64_cache`의 scaled variant 부분
- `scaled_variant(...)`
- `add_scaled_variant(...)`
- `base64_for(...)`

새 variant 추가 시 base64 캐시에서 제거하는 키와 byte accounting에서 교체 대상으로
보는 키도 전체 키여야 한다. source rectangle만 다른 variant가 기존 항목을
덮어쓰면 안 된다.

### 2. placement 생성 및 셀 크기 변경 경로

`grid_state.rs`에서 crop/scale을 수행할 때 다음 값으로 키를 만든다.

```text
source: source_x, source_y, source_w, source_h
destination: dst_w, dst_h
```

그 키를 `add_scaled_variant`에 전달하고, 이후 출력 단계에서도 같은 키를 사용할 수
있도록 `KittyPlacement`와 `KittyImageChunk`를 통해 전달한다. 별도
`scaled_variant_key: Option<ScaledImageKey>` 필드를 두거나 현재 자료구조에 자연스럽게
통합해도 된다.

`character_cell_size_possibly_changed`도 반드시 수정한다. 셀 픽셀 크기가 바뀌어
scaled image를 재생성할 때 새로운 `destination_width/height`로 키를 다시 만들고
placement가 가리키는 키도 갱신해야 한다.

화면 clipping으로 만들어지는 `KittyImageChunk.source_px_*`는 원본 이미지의 crop과
같은 개념이 아닐 수 있다. 캐시 키에는 placement를 처음 만들 때 사용한 원본 crop
사각형을 넣어야 한다.

### 3. host 전송 캐시 확장

`output/mod.rs`에서 다음 키들도 전체 scaled variant 키를 사용해야 한다.

- `HostKittyState.transmitted`
- `HostPlacementRecord.image_key`
- `serialize_kitty_frame`의 `variant`와 `image_key`
- `scaled_variant` 및 `base64_for` 호출

저장소만 고치고 host 전송 캐시를 `(image_id, cols, rows)`로 남겨두면 서로 다른
crop들이 다시 같은 host image id로 합쳐지므로 문제가 완전히 해결되지 않는다.

## 필수 회귀 테스트

최소한 다음 경우를 자동 테스트한다.

1. 같은 image id와 같은 `c=1,r=1`을 사용하되 source rectangle이 다른 두
   placement가 서로 다른 RGBA/base64 데이터를 얻는다.
2. source rectangle은 같지만 목적지 픽셀 크기가 다른 두 variant가 공존한다.
3. 동일한 전체 키를 다시 추가할 때만 기존 variant를 교체하고 byte accounting이
   정확하다.
4. 셀 픽셀 크기 변경 후 placement가 새 키와 새 raster 크기를 사용한다.
5. host 전송 캐시가 서로 다른 전체 키에 서로 다른 host image id를 할당한다.

현재 workspace 구조를 확인한 뒤 관련 테스트를 실행한다. 0.45.1 계열에서의 예시는
다음과 같다.

```bash
cargo test -p zellij-server kitty_graphics
cargo test -p zellij-server scaled_variant
cargo build --release --locked
```

필터 이름이나 package 이름이 바뀌었다면 `Cargo.toml`과 기존 테스트를 보고 조정한다.
컴파일만 성공한 것을 완료로 간주하지 말고, 위의 서로 다른 crop 충돌 테스트를
반드시 추가하거나 실행한다.

## 설치 절차

1. `zellij --version`, `command -v zellij`, `mise current zellij`,
   `mise where zellij@<version>`으로 실제 설치 위치를 먼저 확인한다.
2. 기존 공식 바이너리 백업이 없을 때만 `zellij.upstream`으로 보존한다. 기존 백업을
   새 파일로 덮어쓰지 않는다.
3. release 빌드 결과를 설치 디렉터리의 임시 파일로 복사한 뒤 같은 파일시스템에서
   rename하여 교체한다. 실행 중인 바이너리를 직접 truncate하지 않는다.
4. 새 바이너리의 버전, 실행 가능 여부, SHA-256을 확인하고 이 문서의 현재 설치
   기록을 갱신한다.
5. 기존 Zellij server 프로세스는 메모리에 이전 실행 파일을 유지할 수 있으므로 모든
   세션을 정상 종료한 뒤 다시 시작한다.
6. Yazi에서 가로·세로 색 변화가 뚜렷한 이미지를 열어 반복 타일이 사라졌는지 직접
   확인한다.

`mise upgrade`, 재설치 또는 새 Zellij 버전 설치는 로컬 바이너리를 덮어쓸 수 있다.
현재 설정은 `~/.config/mise/config.toml`에서 `zellij = "latest"`를 사용하므로 특히
주의한다.

## 원복

현재 버전에 대응하는 `zellij.upstream`의 버전과 해시를 먼저 확인한 다음, 설치 때와
같이 임시 파일 + rename 방식으로 원본을 복원한다. 실행 중인 세션을 정상 종료하고
재시작한다. 원복하면 upstream에 수정이 들어가지 않은 버전에서는 Yazi 반복 타일
문제가 다시 발생한다.

## 현재 로컬 설치 기록

```text
version: Zellij 0.45.1
installed through: mise
install directory: ~/.local/share/mise/installs/zellij/0.45.1
patched binary: zellij
upstream backup: zellij.upstream
note copied from: KITTY_GRAPHICS_PATCH.md in the install directory

upstream SHA-256:
d006c521dcb475a6005d741e9dd7c5758e5a23b28dd60a5c10cebfa4876319dd

patched SHA-256:
91c6c138494acd4b9fcd9103f88388554b5437482ec39f3caf2173a12a34fd98
```

2026-09-20에 확인한 결과, 실행 중이던 모든 Zellij server가 위 patched SHA-256을
사용하고 있었다. 당시 upstream `main`의 관련 `store.rs`, `grid_state.rs`,
`output/mod.rs`는 0.45.1과 동일하여 이 수정이 아직 반영되지 않은 상태였다.

## upstream 참고 링크

- Zellij 0.45.1 store:
  <https://github.com/zellij-org/zellij/blob/v0.45.1/zellij-server/src/panes/kitty_graphics/store.rs>
- Zellij output serialization:
  <https://github.com/zellij-org/zellij/blob/v0.45.1/zellij-server/src/output/mod.rs>
- Yazi 26.9.1 driver selection:
  <https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-adapter/src/drivers/drivers.rs>
- Yazi 26.9.1 KgpOld placement implementation:
  <https://github.com/sxyazi/yazi/blob/v26.9.1/yazi-adapter/src/drivers/kgp_old.rs>
- Kitty Graphics Protocol source rectangle semantics:
  <https://sw.kovidgoyal.net/kitty/graphics-protocol/>

